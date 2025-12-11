import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/services/websocket_service.dart';

/// Location tracking service for drivers using geolocator with optimized
/// platform-specific settings.
///
/// Streams GPS updates and sends them via WebSocket.
/// Backend handles filtering logic (5m position delta).
///
/// Platform-specific optimizations:
/// - iOS: ~1 second updates (hardware maximum)
/// - Android: 1 second intervals with high accuracy
///
/// Lifecycle:
/// - START: When driver accepts shift
/// - STOP: When driver ends shift or takes break
class LocationTrackingService {
  final Ref _ref;
  StreamSubscription<Position>? _locationSubscription;
  String? _currentShiftId;
  bool _isTracking = false;
  Position? _previousLocation;
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

    // Check and request permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.general('❌ Location service not enabled');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        AppLogger.general('❌ Location permission denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      AppLogger.general('❌ Location permission permanently denied');
      return;
    }

    // Configure platform-specific location settings for maximum accuracy
    // OPTIMIZATION: Using bestForNavigation + FusedLocationProvider + 800ms intervals
    late LocationSettings locationSettings;

    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation, // CHANGED: Maximum accuracy mode
        distanceFilter: 0, // No distance filter - send all updates
        forceLocationManager: false, // CHANGED: Use FusedLocationProvider (sensor fusion)
        intervalDuration: const Duration(milliseconds: 800), // CHANGED: Match animation duration
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
              'Ropacal is tracking your location during your shift',
          notificationTitle: 'Location Tracking Active',
          notificationChannelName: 'Location Tracking',
        ),
      );
      AppLogger.general(
        '✅ Android: bestForNavigation mode, FusedLocationProvider, 800ms intervals',
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation, // CHANGED: Maximum accuracy mode
        activityType: ActivityType.automotiveNavigation, // NEW: Optimized for driving
        distanceFilter: 0, // No distance filter - send all updates
        pauseLocationUpdatesAutomatically: false, // CRITICAL: Keep updates flowing
        showBackgroundLocationIndicator: false,
      );
      AppLogger.general(
        '✅ iOS: bestForNavigation mode, automotive navigation profile',
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
      AppLogger.general('✅ Default location settings configured');
    }

    // Subscribe to location updates
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        // Measure actual GPS update interval
        final now = DateTime.now();
        if (_lastGpsUpdate != null) {
          final interval = now.difference(_lastGpsUpdate!).inMilliseconds;
          AppLogger.general(
            '⏱️  GPS interval: ${interval}ms (${(interval / 1000).toStringAsFixed(1)}s)',
          );
        }
        _lastGpsUpdate = now;

        AppLogger.general(
          '📍 GPS: ${position.latitude.toStringAsFixed(6)}, '
          '${position.longitude.toStringAsFixed(6)} '
          '(${(position.speed * 3.6).toStringAsFixed(1)} km/h, '
          'accuracy: ${position.accuracy.toStringAsFixed(1)}m)',
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
    _previousLocation = null;
    _lastGpsUpdate = null;

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

      // Calculate bearing if we have previous location
      double calculatedHeading;
      if (_previousLocation != null) {
        calculatedHeading = Geolocator.bearingBetween(
          _previousLocation!.latitude,
          _previousLocation!.longitude,
          position.latitude,
          position.longitude,
        );
        AppLogger.general('🧭 Bearing: ${calculatedHeading.toStringAsFixed(1)}°');
      } else {
        calculatedHeading = position.heading;
      }

      // Prepare location data
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'heading': calculatedHeading,
        'speed': position.speed,
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
      _previousLocation = position;
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
