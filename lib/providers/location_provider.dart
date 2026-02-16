import 'dart:async';
import 'package:fused_location/fused_location.dart' as fused;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/services/location_service.dart';
import 'package:ropacalapp/core/services/location_tracking_service.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

part 'location_provider.g.dart';

@riverpod
LocationService locationService(LocationServiceRef ref) {
  return LocationService();
}

/// ⚠️ DEPRECATED: Legacy location provider for backwards compatibility
///
/// This provider is now a WRAPPER around locationTrackingServiceProvider.
/// It no longer starts its own GPS stream - instead it reads from the
/// modern FusedLocation-based tracking service.
///
/// MIGRATION PATH:
/// - For location tracking: Use locationTrackingServiceProvider directly
/// - For UI location display: Continue using this provider (it proxies to service)
/// - For new features: Use locationTrackingServiceProvider
///
/// This wrapper exists only for backwards compatibility with existing UI code.
/// It will be removed in a future release once all code is migrated.
@Deprecated(
  'Use locationTrackingServiceProvider directly. '
  'This provider is kept only for backwards compatibility and will be removed in a future release.',
)
@Riverpod(keepAlive: true)
class CurrentLocation extends _$CurrentLocation {
  bool _isWrapperActive = false;

  @override
  Future<geolocator.Position?> build() async {
    // Clean up on dispose
    ref.onDispose(() {
      stopBackgroundTracking();
    });

    // Try to get initial location from tracking service
    final trackingService = ref.read(locationTrackingServiceProvider);
    final fusedLocation = trackingService.lastLocation;

    if (fusedLocation != null) {
      return _fusedLocationToPosition(fusedLocation);
    }

    // Fallback: Get initial location using legacy method
    final locationService = ref.read(locationServiceProvider);
    return await locationService.getCurrentLocation();
  }

  /// ⚠️ DEPRECATED: Start continuous background tracking
  ///
  /// This method now DELEGATES to locationTrackingServiceProvider instead
  /// of starting its own GPS stream. This prevents duplicate GPS streams.
  ///
  /// What it does now:
  /// 1. Calls locationTrackingServiceProvider.startBackgroundTracking()
  /// 2. Registers a callback to update this provider's state
  /// 3. Converts FusedLocation → Position for backwards compatibility
  ///
  /// MIGRATION: Use locationTrackingServiceProvider.startBackgroundTracking() directly
  @Deprecated('Use locationTrackingServiceProvider.startBackgroundTracking()')
  void startBackgroundTracking() {
    if (_isWrapperActive) {
      AppLogger.location(
        '⚠️  [DEPRECATED] currentLocationProvider: Already wrapping location service',
      );
      return;
    }

    AppLogger.location(
      '⚠️  [DEPRECATED] currentLocationProvider.startBackgroundTracking() called',
    );
    AppLogger.location(
      '   → Delegating to locationTrackingServiceProvider (no duplicate GPS stream)',
    );

    final trackingService = ref.read(locationTrackingServiceProvider);

    // Register callback to convert FusedLocation → geolocator.Position and update state
    trackingService.setLocationUpdateCallback((fused.FusedLocation fusedLocation) {
      final position = _fusedLocationToPosition(fusedLocation);
      state = AsyncValue.data(position);
    });

    // Start the actual tracking service (if not already started)
    trackingService.startBackgroundTracking();

    _isWrapperActive = true;

    AppLogger.location('✅ currentLocationProvider wrapper active');
  }

  /// ⚠️ DEPRECATED: Stop background tracking
  ///
  /// WARNING: This method now does NOT stop the underlying locationTrackingService,
  /// because other parts of the app might be using it. It only unregisters this
  /// provider's callback.
  ///
  /// To fully stop tracking: Use locationTrackingServiceProvider.stopTracking()
  ///
  /// MIGRATION: Use locationTrackingServiceProvider.stopTracking() if you need to stop GPS
  @Deprecated('Use locationTrackingServiceProvider.stopTracking()')
  void stopBackgroundTracking() {
    if (!_isWrapperActive) return;

    AppLogger.location(
      '⚠️  [DEPRECATED] currentLocationProvider.stopBackgroundTracking() called',
    );
    AppLogger.location(
      '   → Unregistering callback only (NOT stopping actual GPS service)',
    );

    final trackingService = ref.read(locationTrackingServiceProvider);
    trackingService.setLocationUpdateCallback(null);

    _isWrapperActive = false;

    AppLogger.location('✅ currentLocationProvider wrapper deactivated');
  }

  /// Refresh location from tracking service
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final trackingService = ref.read(locationTrackingServiceProvider);
      final fusedLocation = trackingService.lastLocation;

      if (fusedLocation != null) {
        return _fusedLocationToPosition(fusedLocation);
      }

      // Fallback: Use legacy location service
      final locationService = ref.read(locationServiceProvider);
      return await locationService.getCurrentLocation();
    });
  }

  /// Manually set location (for simulation/testing)
  /// This still works for testing purposes
  void setSimulatedLocation({
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
  }) {
    AppLogger.location(
      '🧪 Setting simulated location: $latitude, $longitude',
    );

    final simulatedPosition = geolocator.Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: heading ?? 0.0,
      headingAccuracy: 0.0,
      speed: speed ?? 0.0,
      speedAccuracy: 0.0,
    );

    state = AsyncValue.data(simulatedPosition);
  }

  /// Convert FusedLocation (fused_location package) to geolocator.Position
  /// for backwards compatibility with existing UI code
  geolocator.Position _fusedLocationToPosition(fused.FusedLocation fusedLocation) {
    return geolocator.Position(
      latitude: fusedLocation.position.latitude,
      longitude: fusedLocation.position.longitude,
      timestamp: DateTime.now(), // FusedLocation.Position doesn't have timestamp
      accuracy: fusedLocation.position.accuracy ?? 0.0,
      altitude: 0.0, // FusedLocation.Position doesn't have altitude
      altitudeAccuracy: 0.0, // Not provided by FusedLocation
      heading: fusedLocation.heading.direction, // direction is non-nullable
      headingAccuracy: 0.0, // Not provided by FusedLocation
      speed: fusedLocation.speed.magnitude ?? 0.0,
      speedAccuracy: 0.0, // Not provided by FusedLocation
    );
  }
}

/// ⚠️ DEPRECATED: Location stream provider
///
/// This is kept for backwards compatibility but now uses locationTrackingService
///
/// MIGRATION: Access location through locationTrackingServiceProvider instead
@Deprecated('Use locationTrackingServiceProvider for location access')
@riverpod
Stream<geolocator.Position> locationStream(LocationStreamRef ref) {
  final locationService = ref.read(locationServiceProvider);
  return locationService.getPositionStream();
}
