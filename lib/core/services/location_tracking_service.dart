import 'dart:async';
import 'package:fused_location/fused_location.dart';
import 'package:fused_location/fused_location_provider.dart';
import 'package:fused_location/fused_location_options.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/services/centrifugo_service.dart';
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
  final Ref _ref;
  final FusedLocationProvider _fusedLocation = FusedLocationProvider();
  StreamSubscription<FusedLocation>? _locationSubscription;
  String? _currentShiftId;
  bool _isTracking = false;
  FusedLocation? _lastLocation; // Cache last received location

  // Callback for location updates (for UI integration)
  void Function(FusedLocation)? _onLocationUpdate;

  LocationTrackingService(this._ref);

  /// Get the last cached location (null if not tracking or no location yet)
  FusedLocation? get lastLocation => _lastLocation;

  /// Set callback for location updates (for UI integration)
  /// This allows other parts of the app to react to location changes
  void setLocationUpdateCallback(void Function(FusedLocation)? callback) {
    _onLocationUpdate = callback;
    // If we already have a location, notify immediately
    if (callback != null && _lastLocation != null) {
      callback(_lastLocation!);
    }
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

    try {
      // Configure fused_location with 3-second interval
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
        (FusedLocation location) {
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

      FusedLocation? location;

      // OPTION 1: Use cached location from already-running stream (INSTANT!)
      if (_isTracking && _lastLocation != null) {
        AppLogger.general('   ⚡ Using cached location from active stream (INSTANT!)');

        location = _lastLocation!;

        final gotLocationTime = DateTime.now();
        final gpsDuration = gotLocationTime.difference(startTime).inMilliseconds;
        AppLogger.general('   ✅ Got cached location in ${gpsDuration}ms');

        // Note: FusedLocation.Position doesn't have timestamp, so we can't calculate age
        AppLogger.general('   📅 Using cached location from active stream');
      }
      // OPTION 2: Start new stream (FALLBACK - slower on emulator)
      else {
        AppLogger.general('   🆕 No cached location - starting new GPS stream');

        // Start location updates temporarily to get current position
        const options = FusedLocationProviderOptions(distanceFilter: 0);
        await _fusedLocation.startLocationUpdates(options: options);
        AppLogger.general('   ✅ Location updates started');

        // Get the first location from the stream with 10s timeout (increased for emulator)
        AppLogger.general('   ⏳ Waiting for GPS location (10 second timeout)...');
        location = await _fusedLocation.dataStream
            .first
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw Exception('GPS_TIMEOUT_NEW_STREAM'),
            );

        final gotLocationTime = DateTime.now();
        final gpsDuration = gotLocationTime.difference(startTime).inMilliseconds;
        AppLogger.general('   ✅ Got GPS location from new stream in ${gpsDuration}ms');

        // Stop the temporary location updates
        await _fusedLocation.stopLocationUpdates();
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

  /// Stop location tracking
  void stopTracking() {
    if (!_isTracking) return;

    AppLogger.general('🛑 Stopping location tracking');

    _locationSubscription?.cancel();
    _locationSubscription = null;
    _fusedLocation.stopLocationUpdates();
    _currentShiftId = null;
    _isTracking = false;
    _lastLocation = null; // Clear cached location
    _onLocationUpdate = null; // Clear callback

    AppLogger.general('✅ Location tracking stopped');
  }

  /// Send location to Centrifugo via WebSocket publish
  /// Centrifugo publish proxy will intercept, process (save to Redis, snap to roads),
  /// and broadcast the modified location to all managers watching
  Future<void> _sendLocation(FusedLocation location) async {
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

      // Use heading from fused_location (combines GPS + device sensors)
      // This is more accurate than manual bearing calculation
      final heading = location.heading.direction;
      final speed = location.speed.magnitude ?? 0.0;
      final accuracy = location.position.accuracy ?? -1.0;

      // Prepare location data
      final locationData = {
        'latitude': lat,
        'longitude': lng,
        'heading': heading,
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
      await centrifugoService.publish(
        'driver:location:${user.id}',
        locationData,
      );

      AppLogger.general(
        '✅ [LocationTracking] Location published to Centrifugo successfully',
      );
    } catch (e) {
      AppLogger.general(
        '❌ [LocationTracking] Failed to publish location: $e',
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
