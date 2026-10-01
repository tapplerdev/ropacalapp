import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:fused_location/fused_location.dart' as fused;
import 'package:fused_location/fused_location_provider.dart';
import 'package:fused_location/fused_location_options.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/constants/api_constants.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/services/centrifugo_service.dart';
import 'package:ropacalapp/providers/api_provider.dart';
import 'package:ropacalapp/providers/auth_provider.dart';

/// Location tracking service for drivers using fused_location with native
/// FusedLocationProviderClient for maximum accuracy and update frequency.
///
/// Streams GPS updates and sends them to backend via HTTP POST.
/// Backend flow: Save to DB → OSRM snap → Publish to Centrifugo
///
/// Platform-specific optimizations:
/// - Android: 1 second intervals with PRIORITY_HIGH_ACCURACY (500ms minimum)
/// - iOS: ~1 second updates via native CoreLocation
///
/// Lifecycle:
/// - START: When driver accepts shift
/// - STOP: When driver ends shift or takes break
class LocationTrackingService {
  // One-shot pre-shift fix (see _oneShotLocation).
  static const _oneShotTimeout = Duration(seconds: 20);
  static const _oneShotFallbackTimeout = Duration(seconds: 15);
  static const _lastKnownMaxAge = Duration(minutes: 2);
  static const _lastKnownMaxAccuracyMeters = 100.0;

  // How long the fused_location stream may stay silent before we replace it.
  static const _streamWatchdogDelay = Duration(seconds: 15);

  final Ref _ref;
  final FusedLocationProvider _fusedLocation = FusedLocationProvider();
  StreamSubscription<fused.FusedLocation>? _locationSubscription;
  StreamSubscription<geolocator.Position>? _geoSubscription;
  Timer? _streamWatchdog; // See _armStreamWatchdog
  bool _usingGeolocatorStream = false;
  Timer? _simulatorTimer; // For iOS simulator fake GPS stream
  String? _currentShiftId;
  bool _isTracking = false;
  fused.FusedLocation? _lastLocation; // Cache last received location
  double? _lastCourse; // Last known direction of travel (held while stopped)

  // Last DISTINCT position we published, to (a) suppress compass-event
  // re-emissions of the same fix (the plugin re-fires on heading change,
  // which spammed identical coordinates with fresh timestamps and a creeping
  // compass heading — corrupting the manager's playback clock and pointing
  // the truck off-road) and (b) derive course-over-ground from real movement.
  double? _lastPubLat;
  double? _lastPubLng;
  DateTime? _lastPublishSentAt; // for the parked-driver keepalive below

  // Callback for location updates (for UI integration)
  void Function(fused.FusedLocation)? _onLocationUpdate;

  LocationTrackingService(this._ref);

  /// Get the last cached location (null if not tracking or no location yet)
  fused.FusedLocation? get lastLocation => _lastLocation;

  /// Set callback for location updates (for UI integration)
  /// This allows other parts of the app to react to location changes
  void setLocationUpdateCallback(void Function(fused.FusedLocation)? callback) {
    _onLocationUpdate = callback;
    // If we already have a location, notify immediately
    if (callback != null && _lastLocation != null) {
      callback(_lastLocation!);
    }
  }

  /// Check and request location permissions
  /// Returns true if permissions are granted, false otherwise
  Future<bool> _checkLocationPermissions() async {
    AppLogger.general('🔐 Checking location permissions...');

    // Check if location services are enabled
    bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.general('❌ Location services are disabled');
      return false;
    }

    // Check location permissions
    geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
    AppLogger.general('   Current permission status: $permission');

    if (permission == geolocator.LocationPermission.denied) {
      AppLogger.general('   📱 Requesting location permission...');
      permission = await geolocator.Geolocator.requestPermission();
      AppLogger.general('   Permission after request: $permission');

      if (permission == geolocator.LocationPermission.denied) {
        AppLogger.general('❌ Location permission denied by user');
        return false;
      }
    }

    if (permission == geolocator.LocationPermission.deniedForever) {
      AppLogger.general('❌ Location permission permanently denied - user must enable in settings');
      return false;
    }

    AppLogger.general('✅ Location permissions granted');
    return true;
  }

  /// Start background location tracking (no shift required)
  /// Used when driver logs in to allow managers to see their location
  Future<void> startBackgroundTracking() async {
    if (_isTracking && _currentShiftId == null) {
      AppLogger.general('📍 Background tracking already active');
      return;
    }

    stopTracking();

    _currentShiftId = null; // No shift ID for background tracking
    _isTracking = true;

    AppLogger.general('📍 Starting BACKGROUND location tracking (no shift)');

    await _startLocationUpdates();
  }

  /// Start location tracking for a shift
  Future<void> startTracking(String shiftId) async {
    AppLogger.general('═══════════════════════════════════════════');
    AppLogger.general('📍 [LocationTracking] startTracking() called');
    AppLogger.general('   Shift ID: $shiftId');
    AppLogger.general('   Current tracking status: $_isTracking');
    AppLogger.general('   Timestamp: ${DateTime.now().toIso8601String()}');
    AppLogger.general('═══════════════════════════════════════════');

    if (_isTracking && _currentShiftId == shiftId) {
      AppLogger.general('📍 Already tracking location for shift: $shiftId');
      return;
    }

    stopTracking();

    _currentShiftId = shiftId;
    _isTracking = true;

    AppLogger.general('📍 Starting location tracking for shift: $shiftId');

    await _startLocationUpdates();
  }

  /// Internal method to configure and start location updates
  Future<void> _startLocationUpdates() async {
    _usingGeolocatorStream = false;

    try {
      // Check and request location permissions BEFORE starting GPS
      final hasPermission = await _checkLocationPermissions();
      if (!hasPermission) {
        AppLogger.general(
          '❌ Cannot start location tracking - permissions not granted',
          level: AppLogger.error,
        );
        _isTracking = false;
        _currentShiftId = null;
        throw Exception('LOCATION_PERMISSION_DENIED');
      }

      // ═══════════════════════════════════════════════════════════════════════
      // 🧪 SIMULATOR TESTING WORKAROUND (DISABLED FOR REAL DEVICE TESTING)
      // ═══════════════════════════════════════════════════════════════════════
      // iOS Simulator GPS stream never produces updates (causes infinite loading).
      // This section creates a fake periodic GPS stream for testing.
      //
      // ⚠️ DISABLED: Using real GPS coordinates from device
      // ═══════════════════════════════════════════════════════════════════════
      // if (kDebugMode && Platform.isIOS) {
      //   AppLogger.general('   🧪 SIMULATOR DETECTED: Starting fake GPS stream');
      //   AppLogger.general('   📍 Using hardcoded warehouse location with 3-second interval');
      //
      //   // Hardcoded warehouse coordinates (2220 Bridgepointe Pkwy, San Mateo)
      //   const warehouseLat = 37.558690;
      //   const warehouseLng = -122.283370;
      //
      //   // Create periodic timer that sends fake location every 3 seconds
      //   _simulatorTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      //     if (!_isTracking) {
      //       timer.cancel();
      //       return;
      //     }
      //
      //     // Create fake location with warehouse coordinates
      //     final fakeLocation = fused.FusedLocation(
      //       position: fused.Position(
      //         latitude: warehouseLat,
      //         longitude: warehouseLng,
      //         accuracy: 5.0,
      //       ),
      //       timestamp: DateTime.now(),
      //       heading: fused.Heading(direction: 0.0, accuracy: 0.0),
      //       speed: fused.Speed(magnitude: 0.0, accuracy: 0.0),
      //       elevation: fused.Elevation(meanSeaLevel: 0.0, meanSeaLevelAccuracy: 0.0),
      //       course: fused.Course(direction: 0.0, accuracy: 0.0),
      //     );
      //
      //     // Cache the location
      //     _lastLocation = fakeLocation;
      //
      //     // Notify callback (for UI integration)
      //     _onLocationUpdate?.call(fakeLocation);
      //
      //     // Send location to backend
      //     _sendLocation(fakeLocation);
      //   });
      //
      //   AppLogger.general('✅ Fake GPS stream started for simulator (3s interval)');
      //   return; // Skip real GPS setup
      // }
      // ═══════════════════════════════════════════════════════════════════════

      // Configure fused_location with 3-second interval (REAL DEVICE)
      // This balances real-time updates with battery life and server load
      // Industry standard: Uber uses 4 seconds, we use 3 seconds
      // - Android: 3000ms interval with PRIORITY_HIGH_ACCURACY
      // - iOS: CoreLocation with kCLLocationAccuracyBestForNavigation
      const options = FusedLocationProviderOptions(
        distanceFilter: 0, // No distance filter - get all updates
        // Note: iOS doesn't support interval directly, but Android does
        // For iOS, updates will be based on significant location changes
      );

      // Start location updates
      await _fusedLocation.startLocationUpdates(options: options);

      AppLogger.general(
        '✅ FusedLocation configured: distanceFilter=0m, '
        'native intervals (~1s)',
      );

      // Subscribe to location stream
      _locationSubscription = _fusedLocation.dataStream.listen(
        (fused.FusedLocation location) {
          // Cache the location for instant access by sendCurrentLocation()
          _lastLocation = location;

          // Notify callback (for UI integration like currentLocationProvider)
          _onLocationUpdate?.call(location);

          // Measure actual GPS update interval (commented out to reduce log clutter)
          // final now = DateTime.now();
          // if (_lastGpsUpdate != null) {
          //   final interval = now.difference(_lastGpsUpdate!).inMilliseconds;
          //   AppLogger.general(
          //     '⏱️  GPS interval: ${interval}ms (${(interval / 1000).toStringAsFixed(1)}s)',
          //   );
          // }
          // _lastGpsUpdate = now;

          // Extract position data (logging commented out to reduce clutter)
          // final lat = location.position.latitude;
          // final lng = location.position.longitude;
          // final accuracy = location.position.accuracy ?? -1.0;
          // final speedMs = location.speed.magnitude ?? 0.0;
          // final speedKmh = speedMs * 3.6;

          // AppLogger.general(
          //   '📍 GPS: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)} '
          //   '(${speedKmh.toStringAsFixed(1)} km/h, '
          //   'accuracy: ${accuracy.toStringAsFixed(1)}m)',
          // );

          _sendLocation(location);
        },
        onError: (error) {
          AppLogger.general('❌ GPS error: $error', level: AppLogger.error);
        },
      );

      // fused_location may never emit at all — watch for that and fail over.
      _armStreamWatchdog();

      AppLogger.general('✅ Location tracking started with fused_location');
    } catch (e) {
      AppLogger.general(
        '❌ Failed to start location tracking: $e',
        level: AppLogger.error,
      );
      _isTracking = false;
      _currentShiftId = null;
    }
  }

  /// Send current location immediately (one-time update)
  /// Used before starting shift to ensure backend has a location
  ///
  /// Strategy:
  /// - If already tracking: Use cached location from stream (INSTANT!)
  /// - If not tracking: Start new stream temporarily (slower, but necessary)
  Future<void> sendCurrentLocation() async {
    try {
      final startTime = DateTime.now();
      AppLogger.general('📍 Getting current location for pre-shift update...');
      AppLogger.general('   ⏱️  Start time: ${startTime.toIso8601String()}');
      AppLogger.general('   🔍 Already tracking: $_isTracking');
      AppLogger.general('   🔍 Cached location available: ${_lastLocation != null}');

      fused.FusedLocation? location;

      // ═══════════════════════════════════════════════════════════════════════
      // 🧪 SIMULATOR TESTING WORKAROUND (DISABLED FOR REAL DEVICE TESTING)
      // ═══════════════════════════════════════════════════════════════════════
      // iOS Simulator GPS is extremely slow (30-60+ seconds for first fix).
      // This section uses hardcoded warehouse coordinates for testing.
      //
      // ⚠️ DISABLED: Using real GPS coordinates from device
      // ═══════════════════════════════════════════════════════════════════════
      // if (kDebugMode && Platform.isIOS) {
      //   AppLogger.general('   🧪 SIMULATOR DETECTED: Using hardcoded warehouse location');
      //
      //   // Hardcoded warehouse coordinates (2220 Bridgepointe Pkwy, San Mateo)
      //   const warehouseLat = 37.558690;
      //   const warehouseLng = -122.283370;
      //
      //   location = fused.FusedLocation(
      //     position: fused.Position(
      //       latitude: warehouseLat,
      //       longitude: warehouseLng,
      //       accuracy: 5.0,
      //     ),
      //     timestamp: DateTime.now(),
      //     heading: fused.Heading(direction: 0.0, accuracy: 0.0),
      //     speed: fused.Speed(magnitude: 0.0, accuracy: 0.0),
      //     elevation: fused.Elevation(meanSeaLevel: 0.0, meanSeaLevelAccuracy: 0.0),
      //     course: fused.Course(direction: 0.0, accuracy: 0.0),
      //   );
      //
      //   AppLogger.general('   ✅ Using hardcoded location: $warehouseLat, $warehouseLng');
      //
      //   // Send the hardcoded location
      //   _sendLocation(location);
      //   await Future.delayed(const Duration(milliseconds: 500));
      //
      //   final endTime = DateTime.now();
      //   final totalDuration = endTime.difference(startTime).inMilliseconds;
      //   AppLogger.general('   ✅ sendCurrentLocation() completed in ${totalDuration}ms (hardcoded)');
      //   return;
      // }
      // ═══════════════════════════════════════════════════════════════════════

      // OPTION 1: Use cached location from already-running stream (INSTANT!)
      if (_isTracking && _lastLocation != null) {
        AppLogger.general('   ⚡ Using cached location from active stream (INSTANT!)');

        location = _lastLocation!;

        final gotLocationTime = DateTime.now();
        final gpsDuration = gotLocationTime.difference(startTime).inMilliseconds;
        AppLogger.general('   ✅ Got cached location in ${gpsDuration}ms');

        // Calculate age of cached location
        final locationAge = DateTime.now().millisecondsSinceEpoch -
                           _lastLocation!.timestamp.millisecondsSinceEpoch;
        AppLogger.general('   📅 Location age: ${locationAge}ms (${(locationAge / 1000).toStringAsFixed(1)}s)');
      }
      // OPTION 2: One-shot fix via geolocator. This deliberately does NOT
      // touch fused_location — see _oneShotLocation for why.
      else {
        AppLogger.general('   🆕 No cached location - one-shot fix via geolocator');

        location = await _oneShotLocation();

        final gotLocationTime = DateTime.now();
        final gpsDuration = gotLocationTime.difference(startTime).inMilliseconds;
        AppLogger.general('   ✅ Got one-shot GPS location in ${gpsDuration}ms');
      }

      AppLogger.general(
        '📍 Current location: ${location.position.latitude.toStringAsFixed(6)}, ${location.position.longitude.toStringAsFixed(6)}',
      );
      AppLogger.general('   Accuracy: ${location.position.accuracy?.toStringAsFixed(2)}m');

      AppLogger.general('   📤 Publishing location to Centrifugo...');
      _sendLocation(location);

      // Wait a bit to ensure WebSocket message is sent
      AppLogger.general('   ⏳ Waiting 500ms for WebSocket delivery...');
      await Future.delayed(const Duration(milliseconds: 500));

      final endTime = DateTime.now();
      final totalDuration = endTime.difference(startTime).inMilliseconds;
      AppLogger.general('   ✅ sendCurrentLocation() completed in ${totalDuration}ms');
    } catch (e) {
      AppLogger.general('❌ Error getting current location: $e');
      // Rethrow to allow caller to handle (e.g., show permission modal)
      rethrow;
    }
  }

  /// Convert a geolocator [geolocator.Position] into the [fused.FusedLocation]
  /// shape the rest of this service already speaks, so swapping the GPS source
  /// changes nothing downstream of here.
  ///
  /// `course` carries geolocator's `heading`, which on Android is
  /// `Location.getBearing()` — direction of TRAVEL, which is what
  /// `_sendLocation` actually wants. `heading` gets the same value because
  /// geolocator exposes no separate compass field; that slot is only read for
  /// diagnostics and as a last-resort fallback.
  fused.FusedLocation _positionToFused(geolocator.Position p) {
    final bearing = p.heading.isNaN ? 0.0 : p.heading;
    return fused.FusedLocation(
      position: fused.Position(
        latitude: p.latitude,
        longitude: p.longitude,
        accuracy: p.accuracy,
      ),
      elevation: fused.Elevation(ellipsoidal: p.altitude),
      course: fused.Course(direction: bearing),
      speed: fused.Speed(magnitude: p.speed),
      heading: fused.Heading(direction: bearing, accuracy: p.headingAccuracy),
      timestamp: p.timestamp,
    );
  }

  /// One-shot position for the pre-shift update.
  ///
  /// Deliberately geolocator, NOT fused_location. The fused_location Android
  /// plugin gates EVERY emission on a compass reading — notifySubscribers()
  /// opens with `val orientation = lastOrientation ?: return`
  /// (FusedLocationPlugin.kt:179) — so on a device whose magnetometer never
  /// reports, that stream stays permanently silent even with a perfect GPS
  /// lock. The old code here waited 30s on `dataStream.first` and threw
  /// GPS_TIMEOUT_NEW_STREAM, which is what stopped drivers starting a shift.
  ///
  /// geolocator drives FusedLocationProviderClient over its own channel with
  /// no orientation involvement, and throws typed errors — so a denied
  /// permission or a disabled location service stops masquerading as a
  /// timeout.
  Future<fused.FusedLocation> _oneShotLocation() async {
    // Permissions FIRST. The old fallback skipped this entirely, and the
    // plugin's native side is annotated @SuppressLint("MissingPermission"), so
    // a missing grant produced silence rather than an error.
    final hasPermission = await _checkLocationPermissions();
    if (!hasPermission) {
      throw Exception('LOCATION_PERMISSION_DENIED');
    }

    // A recent cached fix is good enough to start a shift and costs nothing.
    // Bounded on BOTH age and accuracy: preflight rejects accuracy > 100m, and
    // a stale fix would start the route from wherever the phone last was.
    try {
      final last = await geolocator.Geolocator.getLastKnownPosition();
      if (last != null) {
        final age = DateTime.now().difference(last.timestamp);
        final acc = last.accuracy;
        if (age <= _lastKnownMaxAge &&
            acc > 0 &&
            acc <= _lastKnownMaxAccuracyMeters) {
          AppLogger.general(
            '   ⚡ Using last-known fix (${age.inSeconds}s old, '
            '${acc.toStringAsFixed(1)}m)',
          );
          return _positionToFused(last);
        }
        AppLogger.general(
          '   ↩ Ignoring last-known fix (${age.inSeconds}s old, '
          '${acc.toStringAsFixed(1)}m) — outside bounds',
        );
      }
    } catch (e) {
      AppLogger.general('   ⚠️  getLastKnownPosition failed: $e');
    }

    // Live fix. timeLimit lives inside LocationSettings in geolocator 14 (the
    // bare `timeLimit:` parameter is deprecated), and on timeout it cancels
    // the native request instead of leaking it the way the old path did.
    AppLogger.general(
      '   ⏳ Requesting live fix (${_oneShotTimeout.inSeconds}s limit)...',
    );
    try {
      final p = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: const geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          timeLimit: _oneShotTimeout,
        ),
      );
      return _positionToFused(p);
    } on TimeoutException {
      // Documented workaround for devices where the Play Services fused
      // provider never returns (Android 12, some Huawei builds): go around it
      // to the platform LocationManager.
      if (defaultTargetPlatform != TargetPlatform.android) rethrow;
      AppLogger.general(
        '   ⚠️  Fused one-shot timed out — retrying via LocationManager',
        level: AppLogger.error,
      );
      final p = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: geolocator.AndroidSettings(
          accuracy: geolocator.LocationAccuracy.high,
          forceLocationManager: true,
          timeLimit: _oneShotFallbackTimeout,
        ),
      );
      return _positionToFused(p);
    }
  }

  /// fused_location can go permanently silent (see _oneShotLocation), which
  /// would mean a shift that starts fine but never puts the driver on the
  /// manager's map. If no fix has arrived shortly after the stream starts,
  /// abandon the plugin and run the rest of the session on geolocator.
  void _armStreamWatchdog() {
    _streamWatchdog?.cancel();
    _streamWatchdog = Timer(_streamWatchdogDelay, () {
      if (!_isTracking || _usingGeolocatorStream) return;
      if (_lastLocation != null) return; // plugin is healthy — leave it alone
      AppLogger.general(
        '⚠️  No fused_location fix in ${_streamWatchdogDelay.inSeconds}s — '
        'compass gate suspected. Switching to the geolocator stream.',
        level: AppLogger.error,
      );
      _switchToGeolocatorStream();
    });
  }

  /// Run live tracking off geolocator instead of fused_location.
  ///
  /// Nothing is lost by this: _sendLocation already derives the published
  /// bearing from movement between successive fixes and explicitly distrusts
  /// the plugin's compass heading, so the orientation data the plugin blocks
  /// on was never actually used.
  void _switchToGeolocatorStream() {
    _usingGeolocatorStream = true;

    _locationSubscription?.cancel();
    _locationSubscription = null;
    _fusedLocation.stopLocationUpdates();

    _geoSubscription?.cancel();
    _geoSubscription = geolocator.Geolocator.getPositionStream(
      locationSettings: const geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen(
      (geolocator.Position p) {
        final location = _positionToFused(p);
        _lastLocation = location;
        _onLocationUpdate?.call(location);
        _sendLocation(location);
      },
      onError: (Object error) {
        AppLogger.general(
          '❌ geolocator stream error: $error',
          level: AppLogger.error,
        );
      },
    );

    AppLogger.general('✅ Live tracking now running on geolocator');
  }

  /// Resend the last cached GPS location immediately.
  ///
  /// Called when the Centrifugo connection (re)establishes, so the dashboard
  /// snaps to the driver's current position right away instead of waiting for
  /// the next ~1s GPS tick. No-op if no location has been captured yet (e.g.
  /// connected at login before a shift / tracking has started).
  Future<void> sendLastKnownLocation() async {
    final location = _lastLocation;
    if (location == null) {
      AppLogger.general(
        '📍 [LocationTracking] sendLastKnownLocation: no cached location yet — skipping',
      );
      return;
    }
    AppLogger.general(
      '📍 [LocationTracking] Resending last known location on (re)connect',
    );
    await _sendLocation(location);
  }

  /// Stop location tracking
  void stopTracking() {
    if (!_isTracking) return;

    AppLogger.general('🛑 Stopping location tracking');

    _locationSubscription?.cancel();
    _locationSubscription = null;
    _geoSubscription?.cancel();
    _geoSubscription = null;
    _streamWatchdog?.cancel();
    _streamWatchdog = null;
    _usingGeolocatorStream = false;
    _simulatorTimer?.cancel(); // Stop simulator timer if active
    _simulatorTimer = null;
    _fusedLocation.stopLocationUpdates();
    _currentShiftId = null;
    _isTracking = false;
    _lastLocation = null; // Clear cached location
    _lastPubLat = null; // Fresh dedup/bearing anchor for the next shift
    _lastPubLng = null;
    _lastPublishSentAt = null;
    _lastCourse = null;
    _onLocationUpdate = null; // Clear callback

    AppLogger.general('✅ Location tracking stopped');
  }

  /// Great-circle distance in meters (equirectangular approx — fine at the
  /// few-meters scale these checks operate on).
  static double _metersBetween(
      double lat1, double lng1, double lat2, double lng2) {
    const mPerDegLat = 110540.0;
    final mPerDegLng = 111320.0 * cos(lat1 * pi / 180);
    final dy = (lat2 - lat1) * mPerDegLat;
    final dx = (lng2 - lng1) * mPerDegLng;
    return sqrt(dx * dx + dy * dy);
  }

  /// Compass bearing (degrees clockwise from north) from point 1 to point 2.
  static double _bearingDegrees(
      double lat1, double lng1, double lat2, double lng2) {
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final y = sin(dLng) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLng);
    final deg = atan2(y, x) * 180 / pi;
    return (deg + 360) % 360;
  }

  /// Send location to Centrifugo via WebSocket publish
  /// Centrifugo publish proxy will intercept, process (save to Redis, snap to roads),
  /// and broadcast the modified location to all managers watching
  Future<void> _sendLocation(fused.FusedLocation location) async {
    // Note: _currentShiftId can be null for background tracking

    try {
      // Get Centrifugo service and user
      final centrifugoService = _ref.read(centrifugoServiceProvider);
      AppLogger.general('🔍 [LocationTracking] _sendLocation() - Centrifugo isConnected: ${centrifugoService.isConnected}');

      final user = _ref.read(authNotifierProvider).value;

      if (user == null) {
        AppLogger.general('⚠️  User not authenticated, skipping location update');
        return;
      }

      // Extract position data
      final lat = location.position.latitude;
      final lng = location.position.longitude;

      final speed = location.speed.magnitude ?? 0.0;
      final accuracy = location.position.accuracy ?? -1.0;

      // Suppress compass-event re-emissions: the plugin re-fires the SAME
      // fix whenever the phone's heading changes, so a stationary/slow phone
      // spammed byte-identical coordinates with fresh timestamps and a
      // creeping compass heading. Those polluted the manager's playback
      // clock (phantom "new fixes" at the same spot) and — being sourced
      // from the compass — pointed the truck off-road. Only publish when the
      // coordinate actually moved (or on the very first fix).
      final nowTs = DateTime.now();
      if (_lastPubLat != null && _lastPubLng != null) {
        final moved = _metersBetween(_lastPubLat!, _lastPubLng!, lat, lng);
        // Keepalive: a genuinely parked driver (loading/servicing a bin)
        // produces only compass re-emits, which we drop — but the backend
        // Redis key has a 10-min TTL, so if we NEVER publish while parked the
        // driver drops off the manager map. Let one identical publish through
        // every 4 min to refresh the TTL.
        final keepaliveDue = _lastPublishSentAt == null ||
            nowTs.difference(_lastPublishSentAt!) >= const Duration(minutes: 4);
        if (moved < 0.5 && !keepaliveDue) {
          return; // same position, recent publish — drop the compass re-emit
        }
      }

      // Marker orientation must be the direction of TRAVEL, not the compass
      // heading (which way the PHONE points — a backwards-mounted phone would
      // render the truck driving in reverse). Prefer a bearing computed from
      // real movement between successive published fixes (the probe proved
      // the device's own course/heading field was compass-like, ~110° off the
      // road); fall back to the plugin course, then the held course.
      double? movementBearing;
      if (_lastPubLat != null && _lastPubLng != null && speed >= 1.0) {
        final moved = _metersBetween(_lastPubLat!, _lastPubLng!, lat, lng);
        if (moved >= 4.0) {
          movementBearing = _bearingDegrees(_lastPubLat!, _lastPubLng!, lat, lng);
        }
      }
      final course = movementBearing ?? location.course.direction;
      if (course != null && speed >= 1.0) {
        _lastCourse = course;
      }
      final travelDirection =
          _lastCourse ?? course ?? location.heading.direction;

      // Past the dedup gate — this fix is being published; record it as the
      // anchor for the next movement-bearing + dedup + keepalive check.
      _lastPubLat = lat;
      _lastPubLng = lng;
      _lastPublishSentAt = nowTs;

      // Prepare location data. 'heading' carries the travel direction so
      // every consumer (manager map, dashboard, Redis) is fixed by this one
      // writer; the raw compass is kept alongside for diagnostics.
      final locationData = {
        'latitude': lat,
        'longitude': lng,
        'heading': travelDirection,
        'compass_heading': location.heading.direction,
        'speed': speed,
        'accuracy': accuracy,
        'shift_id': _currentShiftId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      AppLogger.general(
        '📍 [LocationTracking] Publishing location to Centrifugo: '
        'lat=${lat.toStringAsFixed(6)}, lng=${lng.toStringAsFixed(6)}, '
        'accuracy=${accuracy.toStringAsFixed(1)}m, shift_id=$_currentShiftId',
      );

      AppLogger.general(
        '📦 [LocationTracking] Full location data: $locationData',
      );

      AppLogger.general(
        '🔑 [LocationTracking] Publishing to channel: driver:location:${user.id}',
      );

      // Publish to Centrifugo channel via WebSocket
      // Channel format: driver:location:{userId}
      // Centrifugo publish proxy will:
      // 1. Save original GPS to Redis (fast cache)
      // 2. Snap to roads via OSRM (if accuracy > 15m)
      // 3. Broadcast SNAPPED GPS to all managers watching this driver

      // Fast path: publish over the Centrifugo WebSocket when connected.
      if (centrifugoService.isConnected) {
        try {
          await centrifugoService.publish(
            'driver:location:${user.id}',
            locationData,
          );
          AppLogger.general(
            '✅ [LocationTracking] Location published to Centrifugo successfully',
          );
          return;
        } catch (e) {
          AppLogger.general(
            '⚠️  [LocationTracking] Centrifugo publish failed — '
            'falling back to HTTP: $e',
          );
        }
      } else {
        AppLogger.general(
          '⚠️  [LocationTracking] Centrifugo not connected — '
          'sending location via HTTP fallback',
        );
      }

      // Fallback: POST to the backend, which saves to Redis + Postgres and
      // re-publishes to Centrifugo server-side, so the dashboard stays live
      // even while this device's WebSocket is down (e.g. a Railway restart).
      await _sendLocationViaHttp(locationData);
    } catch (e) {
      AppLogger.general(
        '❌ [LocationTracking] Failed to send location: $e',
        level: AppLogger.error,
      );
    }
  }

  /// HTTP fallback for sending a location when Centrifugo is unavailable.
  /// Hits POST /api/driver/location, the server-side equal of the publish proxy.
  Future<void> _sendLocationViaHttp(Map<String, dynamic> locationData) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.post(ApiConstants.driverLocationEndpoint, locationData);
      AppLogger.general(
        '✅ [LocationTracking] Location sent via HTTP fallback',
      );
    } catch (e) {
      AppLogger.general(
        '❌ [LocationTracking] HTTP fallback failed (point dropped): $e',
        level: AppLogger.error,
      );
    }
  }

  bool get isTracking => _isTracking;
  String? get currentShiftId => _currentShiftId;

  void dispose() {
    stopTracking();
  }
}

/// Provider for location tracking service
final locationTrackingServiceProvider = Provider<LocationTrackingService>(
  (ref) => LocationTrackingService(ref),
);
