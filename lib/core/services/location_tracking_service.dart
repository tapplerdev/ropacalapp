import 'dart:async';
import 'dart:convert';
import 'package:fused_location/fused_location.dart';
import 'package:fused_location/fused_location_provider.dart';
import 'package:fused_location/fused_location_options.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/providers/auth_provider.dart';

/// Location tracking service for drivers using fused_location with native
/// FusedLocationProviderClient for maximum accuracy and update frequency.
///
/// Streams GPS updates and sends them via WebSocket.
/// Backend handles filtering logic (1m position delta + 2s time fallback).
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
  DateTime? _lastGpsUpdate;

  LocationTrackingService(this._ref);

  /// Start location tracking for a shift
  Future<void> startTracking(String shiftId) async {
    if (_isTracking && _currentShiftId == shiftId) {
      AppLogger.general('📍 Already tracking location for shift: $shiftId');
      return;
    }

    stopTracking();

    _currentShiftId = shiftId;
    _isTracking = true;

    AppLogger.general('📍 Starting location tracking for shift: $shiftId');

    try {
      // Configure fused_location with minimal distance filter
      // Native implementation uses:
      // - Android: 1000ms interval, 500ms minimum (PRIORITY_HIGH_ACCURACY)
      // - iOS: CoreLocation with kCLLocationAccuracyBestForNavigation
      const options = FusedLocationProviderOptions(
        distanceFilter: 0, // No distance filter - get all updates
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
          // Measure actual GPS update interval
          final now = DateTime.now();
          if (_lastGpsUpdate != null) {
            final interval = now.difference(_lastGpsUpdate!).inMilliseconds;
            AppLogger.general(
              '⏱️  GPS interval: ${interval}ms (${(interval / 1000).toStringAsFixed(1)}s)',
            );
          }
          _lastGpsUpdate = now;

          // Extract position data
          final lat = location.position.latitude;
          final lng = location.position.longitude;
          final accuracy = location.position.accuracy ?? -1.0;
          final speedMs = location.speed.magnitude ?? 0.0;
          final speedKmh = speedMs * 3.6;

          AppLogger.general(
            '📍 GPS: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)} '
            '(${speedKmh.toStringAsFixed(1)} km/h, '
            'accuracy: ${accuracy.toStringAsFixed(1)}m)',
          );

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

  /// Stop location tracking
  void stopTracking() {
    if (!_isTracking) return;

    AppLogger.general('🛑 Stopping location tracking');

    _locationSubscription?.cancel();
    _locationSubscription = null;
    _fusedLocation.stopLocationUpdates();
    _currentShiftId = null;
    _isTracking = false;
    _lastGpsUpdate = null;

    AppLogger.general('✅ Location tracking stopped');
  }

  /// Send position via WebSocket
  void _sendLocation(FusedLocation location) {
    if (!_isTracking || _currentShiftId == null) {
      AppLogger.general('⚠️  Skipping location send (not tracking)');
      return;
    }

    try {
      // Get WebSocket service
      final webSocket = _ref.read(webSocketManagerProvider);
      if (webSocket == null || !webSocket.isConnected) {
        AppLogger.general(
          '⚠️  WebSocket not connected, skipping location send',
        );
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

      AppLogger.general('🧭 Heading: ${heading.toStringAsFixed(1)}°');

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

      // Send via WebSocket
      final message = jsonEncode({
        'type': 'location_update',
        'data': locationData,
      });

      webSocket.sendMessage(message);

      AppLogger.general('📤 Location sent to backend');
    } catch (e) {
      AppLogger.general('❌ Failed to send location: $e');
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
