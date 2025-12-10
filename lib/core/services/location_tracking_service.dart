import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/services/websocket_service.dart';

/// Simple location tracking service for drivers
///
/// Streams GPS updates and sends them via WebSocket.
/// Backend handles all filtering logic (20m position delta).
///
/// Lifecycle:
/// - START: When driver accepts shift
/// - STOP: When driver ends shift or takes break
class LocationTrackingService {
  final Ref _ref;
  StreamSubscription<Position>? _locationSubscription;
  String? _currentShiftId;
  bool _isTracking = false;
  Position? _previousPosition;  // For bearing calculation

  LocationTrackingService(this._ref);

  /// Start location tracking for a shift
  void startTracking(String shiftId) {
    if (_isTracking && _currentShiftId == shiftId) {
      AppLogger.general('📍 Already tracking location for shift: $shiftId');
      return;
    }

    stopTracking();

    _currentShiftId = shiftId;
    _isTracking = true;

    AppLogger.general('📍 Starting location tracking for shift: $shiftId');

    // Start GPS stream with simple settings
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 15,  // 15 meters - simple and battery efficient
    );

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        AppLogger.general(
          '📍 GPS: ${position.latitude.toStringAsFixed(6)}, '
          '${position.longitude.toStringAsFixed(6)} '
          '(${(position.speed * 3.6).toStringAsFixed(1)} km/h)',
        );
        _sendLocation(position);
      },
      onError: (error) {
        AppLogger.general('❌ GPS error: $error');
      },
    );

    AppLogger.general('✅ Location tracking started');
  }

  /// Stop location tracking
  void stopTracking() {
    if (!_isTracking) return;

    AppLogger.general('🛑 Stopping location tracking');

    _locationSubscription?.cancel();
    _locationSubscription = null;
    _currentShiftId = null;
    _isTracking = false;
    _previousPosition = null;

    AppLogger.general('✅ Location tracking stopped');
  }

  /// Send position via WebSocket
  void _sendLocation(Position position) {
    if (!_isTracking || _currentShiftId == null) {
      AppLogger.general('⚠️  Skipping location send (not tracking)');
      return;
    }

    try {
      // Get WebSocket service
      final webSocket = _ref.read(webSocketManagerProvider);
      if (webSocket == null || !webSocket.isConnected) {
        AppLogger.general('⚠️  WebSocket not connected, skipping location send');
        return;
      }

      // Calculate bearing if we have previous position
      double? calculatedHeading;
      if (_previousPosition != null) {
        calculatedHeading = _calculateBearing(_previousPosition!, position);
        AppLogger.general('🧭 Bearing: ${calculatedHeading.toStringAsFixed(1)}°');
      } else {
        calculatedHeading = position.heading >= 0 ? position.heading : null;
      }

      // Prepare location data
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'heading': calculatedHeading,
        'speed': position.speed >= 0 ? position.speed : null,
        'accuracy': position.accuracy,
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

      // Store for next bearing calculation
      _previousPosition = position;
    } catch (e) {
      AppLogger.general('❌ Failed to send location: $e');
    }
  }

  /// Calculate bearing between two positions using Haversine formula
  double _calculateBearing(Position start, Position end) {
    final startLat = _toRadians(start.latitude);
    final startLng = _toRadians(start.longitude);
    final endLat = _toRadians(end.latitude);
    final endLng = _toRadians(end.longitude);

    final deltaLng = endLng - startLng;

    final y = sin(deltaLng) * cos(endLat);
    final x = cos(startLat) * sin(endLat) -
        sin(startLat) * cos(endLat) * cos(deltaLng);

    final bearing = atan2(y, x);

    return (_toDegrees(bearing) + 360) % 360;
  }

  double _toRadians(double degrees) => degrees * (pi / 180.0);
  double _toDegrees(double radians) => radians * (180.0 / pi);

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
