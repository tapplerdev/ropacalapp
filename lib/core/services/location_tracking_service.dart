import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/services/websocket_service.dart';
import 'package:ropacalapp/providers/auth_provider.dart';

/// LocationTrackingService with intelligent motion detection
///
/// Uses accelerometer to detect device movement and intelligently manages GPS:
/// - MOVING: GPS stream active, sending real-time updates
/// - STATIONARY: GPS stream stopped to save battery
///
/// This approach mimics flutter_background_geolocation's battery-efficient design
/// while using free, open-source packages.
///
/// Lifecycle:
/// - START: When driver accepts shift → Start accelerometer monitoring
/// - PAUSE: When driver takes break → Stop all tracking
/// - RESUME: When driver returns from break → Resume accelerometer monitoring
/// - STOP: When shift ends → Stop all tracking
///
/// Motion Detection:
/// - Accelerometer samples at ~100Hz to detect real movement
/// - Threshold: magnitude > 10.5 m/s² indicates motion
/// - GPS auto-starts when motion detected
/// - GPS auto-stops after 30 seconds of no motion
///
/// Location Updates:
/// - distanceFilter: 5 meters (industry standard for real-time tracking)
/// - accuracy: bestForNavigation (highest precision)
/// - Updates sent via WebSocket when device is actually moving
///
/// Bearing Calculation:
/// - Uses Haversine formula to calculate accurate direction of travel
/// - Calculates bearing between consecutive GPS points
/// - More accurate than GPS-provided heading, especially at low speeds
/// - Ensures driver markers always point in the direction of movement
class LocationTrackingService {
  final Ref _ref;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  String? _currentShiftId;
  bool _isTracking = false;
  bool _isDeviceMoving = false;
  DateTime? _lastMotionTime;
  Timer? _motionCheckTimer;
  Position? _previousPosition;  // Store previous position for bearing calculation
  Position? _lastSentPosition;  // Store last sent position for distance filtering

  // Motion detection configuration
  static const double _motionThreshold = 10.5;  // m/s² - indicates device movement
  static const Duration _motionTimeout = Duration(seconds: 30);  // Stop GPS after this

  // Distance filtering configuration (Uber/DoorDash-style optimization)
  static const double _minDistanceMeters = 10.0;  // Only send if moved > 10 meters
  static const double _minSpeedMps = 0.5;  // 0.5 m/s = 1.8 km/h (walking speed)

  LocationTrackingService(this._ref);

  /// Start motion-aware location tracking
  ///
  /// Call this when:
  /// - Driver accepts shift (startShift)
  /// - Driver resumes from pause (resumeShift)
  void startTracking(String shiftId) {
    if (_isTracking && _currentShiftId == shiftId) {
      AppLogger.general('📍 Already tracking location for shift: $shiftId');
      return;
    }

    // Stop any existing tracker
    stopTracking();

    _currentShiftId = shiftId;
    _isTracking = true;

    AppLogger.general(
      '🔋 Starting SMART location tracking for shift: $shiftId',
    );
    AppLogger.general('   ⚡ Motion detection: ON (accelerometer-based)');
    AppLogger.general('   🔋 Battery optimization: ENABLED');

    // Start accelerometer monitoring (this manages GPS)
    _startMotionDetection();
  }

  /// Start accelerometer monitoring to detect device motion
  void _startMotionDetection() {
    AppLogger.general('📡 Starting accelerometer motion detection...');

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      // Calculate magnitude of acceleration vector
      final magnitude = sqrt(
        event.x * event.x +
        event.y * event.y +
        event.z * event.z,
      );

      final wasMoving = _isDeviceMoving;
      _isDeviceMoving = magnitude > _motionThreshold;

      if (_isDeviceMoving) {
        _lastMotionTime = DateTime.now();

        // Device started moving - start GPS if not already running
        if (!wasMoving) {
          AppLogger.general('🚶 MOTION DETECTED (magnitude: ${magnitude.toStringAsFixed(2)} m/s²)');
          _startGPSStream();
        }
      } else if (wasMoving) {
        // Device stopped moving - schedule GPS stop
        AppLogger.general('🛑 Motion stopped - GPS will stop in ${_motionTimeout.inSeconds}s if no movement');
      }
    });

    // Check periodically if we should stop GPS due to inactivity
    _motionCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isDeviceMoving &&
          _lastMotionTime != null &&
          DateTime.now().difference(_lastMotionTime!) > _motionTimeout) {
        _stopGPSStream();
      }
    });

    AppLogger.general('✅ Accelerometer monitoring active');
  }

  /// Start GPS position stream (called when motion detected)
  void _startGPSStream() {
    if (_locationSubscription != null) {
      return;  // Already running
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,  // Highest precision
      distanceFilter: 5,  // Standard 5-10m (research-backed optimal value)
    );

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        AppLogger.general('🎯 GPS UPDATE: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}');
        AppLogger.general('   Speed: ${(position.speed * 3.6).toStringAsFixed(1)} km/h');
        _sendLocation(position);
      },
      onError: (error) {
        AppLogger.general('❌ GPS stream error: $error');
      },
    );

    AppLogger.general('📍 GPS STREAM STARTED (motion detected, sending updates)');
  }

  /// Stop GPS position stream (called when device stationary)
  void _stopGPSStream() {
    if (_locationSubscription == null) {
      return;  // Already stopped
    }

    _locationSubscription?.cancel();
    _locationSubscription = null;

    AppLogger.general('🔋 GPS STREAM STOPPED (device stationary, saving battery)');
  }

  /// Stop all tracking (accelerometer + GPS)
  ///
  /// Call this when:
  /// - Driver pauses shift (pauseShift)
  /// - Driver ends shift (endShift)
  void stopTracking() {
    if (!_isTracking) return;

    AppLogger.general('🛑 Stopping all location tracking');

    // Stop accelerometer
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;

    // Stop GPS
    _stopGPSStream();

    // Stop motion check timer
    _motionCheckTimer?.cancel();
    _motionCheckTimer = null;

    _currentShiftId = null;
    _isTracking = false;
    _isDeviceMoving = false;
    _lastMotionTime = null;
    _previousPosition = null;  // Reset bearing calculation
    _lastSentPosition = null;  // Reset distance filtering

    AppLogger.general('✅ All tracking stopped');
  }

  /// Internal method to send position via WebSocket
  void _sendLocation(Position position) {
    if (!_isTracking || _currentShiftId == null) {
      AppLogger.general('⚠️ Skipping location send (not tracking)');
      return;
    }

    // ===== DISTANCE FILTERING (Uber/DoorDash-style optimization) =====
    // Only send updates if driver has actually moved significantly
    // This eliminates jittery markers when stationary and saves bandwidth
    if (_lastSentPosition != null) {
      final distanceMoved = _calculateDistance(_lastSentPosition!, position);
      final speed = position.speed >= 0 ? position.speed : 0.0;

      // Skip update if:
      // 1. Moved less than 10 meters AND
      // 2. Speed is below walking pace (< 0.5 m/s = 1.8 km/h)
      if (distanceMoved < _minDistanceMeters && speed < _minSpeedMps) {
        AppLogger.general(
          '🔇 Skipping update (distance: ${distanceMoved.toStringAsFixed(1)}m, '
          'speed: ${(speed * 3.6).toStringAsFixed(1)} km/h) - device likely stationary',
        );
        return;  // Don't send update
      }

      AppLogger.general(
        '✅ Significant movement detected (distance: ${distanceMoved.toStringAsFixed(1)}m, '
        'speed: ${(speed * 3.6).toStringAsFixed(1)} km/h)',
      );
    } else {
      AppLogger.general('📍 First position - sending immediately');
    }

    try {
      // Get WebSocket service
      final webSocket = _ref.read(webSocketManagerProvider);
      if (webSocket == null || !webSocket.isConnected) {
        AppLogger.general('⚠️ WebSocket not connected, skipping location send');
        return;
      }

      // Calculate accurate bearing if we have previous position
      double? calculatedHeading;
      if (_previousPosition != null) {
        calculatedHeading = _calculateBearing(_previousPosition!, position);
        AppLogger.general(
          '🧭 Calculated bearing: ${calculatedHeading.toStringAsFixed(1)}° (GPS heading: ${position.heading.toStringAsFixed(1)}°)',
        );
      } else {
        // Use GPS heading for first position
        calculatedHeading = position.heading >= 0 ? position.heading : null;
        AppLogger.general('🧭 Using GPS heading for first position');
      }

      // Prepare location data
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'heading': calculatedHeading,  // Use calculated bearing
        'speed': position.speed >= 0 ? position.speed : null,
        'accuracy': position.accuracy,
        'shift_id': _currentShiftId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Send via WebSocket (type: location_update)
      final message = jsonEncode({
        'type': 'location_update',
        'data': locationData,
      });

      webSocket.sendMessage(message);

      AppLogger.general(
        '📤 Location sent via WebSocket (accuracy: ${position.accuracy.toStringAsFixed(1)}m)',
      );

      // Store current position for next bearing calculation
      _previousPosition = position;

      // Store last sent position for distance filtering
      _lastSentPosition = position;
    } catch (e) {
      // Network error, WebSocket error, etc.
      AppLogger.general('❌ Failed to send location: $e');
      // Stream will continue - no need to stop
    }
  }

  /// Calculate bearing (direction) between two GPS positions
  ///
  /// Uses Haversine formula to calculate the direction of travel
  /// Returns bearing in degrees (0-360, where 0 = North, 90 = East, etc.)
  double _calculateBearing(Position start, Position end) {
    final startLat = _toRadians(start.latitude);
    final startLng = _toRadians(start.longitude);
    final endLat = _toRadians(end.latitude);
    final endLng = _toRadians(end.longitude);

    final deltaLng = endLng - startLng;

    // Haversine formula for bearing calculation
    final y = sin(deltaLng) * cos(endLat);
    final x = cos(startLat) * sin(endLat) -
        sin(startLat) * cos(endLat) * cos(deltaLng);

    final bearing = atan2(y, x);

    // Convert to degrees and normalize to 0-360
    return (_toDegrees(bearing) + 360) % 360;
  }

  /// Calculate distance between two GPS positions in meters
  ///
  /// Uses Haversine formula to calculate the great-circle distance
  /// between two points on Earth's surface
  double _calculateDistance(Position start, Position end) {
    const earthRadius = 6371000.0;  // Earth's radius in meters

    final lat1 = _toRadians(start.latitude);
    final lat2 = _toRadians(end.latitude);
    final deltaLat = _toRadians(end.latitude - start.latitude);
    final deltaLng = _toRadians(end.longitude - start.longitude);

    // Haversine formula
    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;  // Distance in meters
  }

  /// Convert degrees to radians
  double _toRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  /// Convert radians to degrees
  double _toDegrees(double radians) {
    return radians * (180.0 / pi);
  }

  /// Check if currently tracking
  bool get isTracking => _isTracking;

  /// Check if device is currently moving (based on accelerometer)
  bool get isDeviceMoving => _isDeviceMoving;

  /// Check if GPS stream is currently active
  bool get isGPSActive => _locationSubscription != null;

  /// Get current shift ID being tracked
  String? get currentShiftId => _currentShiftId;

  /// Clean up resources
  void dispose() {
    stopTracking();
  }
}

/// Provider for location tracking service
final locationTrackingServiceProvider = Provider<LocationTrackingService>(
  (ref) => LocationTrackingService(ref),
);

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
