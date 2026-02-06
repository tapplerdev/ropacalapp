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

  LocationTrackingService(this._ref);

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
  /// Gets location from the data stream's first value
  Future<void> sendCurrentLocation() async {
    try {
      final startTime = DateTime.now();
      AppLogger.general('📍 Getting current location for pre-shift update...');
      AppLogger.general('   ⏱️  Start time: ${startTime.toIso8601String()}');

      FusedLocation? location;

      try {
        // Start location updates temporarily to get current position
        const options = FusedLocationProviderOptions(distanceFilter: 0);
        await _fusedLocation.startLocationUpdates(options: options);
        AppLogger.general('   ✅ Location updates started');

        // Get the first location from the stream with timeout
        AppLogger.general('   ⏳ Waiting for GPS location (5 second timeout)...');
        location = await _fusedLocation.dataStream
            .first
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => throw Exception('Location timeout'),
            );

        final gotLocationTime = DateTime.now();
        final gpsDuration = gotLocationTime.difference(startTime).inMilliseconds;
        AppLogger.general('   ✅ Got GPS location in ${gpsDuration}ms');

        // Stop the temporary location updates
        await _fusedLocation.stopLocationUpdates();
      } catch (e) {
        AppLogger.general('   ❌ GPS timeout - could not get location');
        AppLogger.general('   ⚠️  Using simulator fallback coordinates');
        // iOS simulator fallback
        location = FusedLocation(
          position: const Position(
            latitude: 11.18656,
            longitude: -74.23346,
            accuracy: 10.0,
          ),
          elevation: const Elevation(),
          course: const Course(),
          speed: const Speed(),
          heading: const Heading(direction: 0.0, accuracy: 0.0),
          timestamp: DateTime.now(),
        );
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
      AppLogger.general('   ⚠️  Shift will start WITHOUT location in Redis!');
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
