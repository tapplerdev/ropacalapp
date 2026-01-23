import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/services/location_service.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

part 'location_provider.g.dart';

@riverpod
LocationService locationService(LocationServiceRef ref) {
  return LocationService();
}

/// Location provider with background tracking capability
/// Call startBackgroundTracking() to enable continuous updates
/// Call stopBackgroundTracking() to save battery
@Riverpod(keepAlive: true)
class CurrentLocation extends _$CurrentLocation {
  StreamSubscription<Position>? _locationSubscription;
  bool _isTracking = false;

  @override
  Future<Position?> build() async {
    // Clean up on dispose
    ref.onDispose(() {
      stopBackgroundTracking();
    });

    // Get initial location
    final locationService = ref.read(locationServiceProvider);
    return await locationService.getCurrentLocation();
  }

  /// Start continuous background tracking (call when shift assigned)
  void startBackgroundTracking() {
    if (_isTracking) {
      AppLogger.location('📍 Background tracking already active');
      return;
    }

    AppLogger.location('📍 Starting background location tracking');
    _isTracking = true;

    final locationService = ref.read(locationServiceProvider);
    _locationSubscription = locationService.getPositionStream().listen(
      (position) {
        // AppLogger.location('📍 Location updated: ${position.latitude}, ${position.longitude}');
        state = AsyncValue.data(position);
      },
      onError: (error) {
        AppLogger.location('❌ Location stream error: $error');
      },
    );
  }

  /// Stop background tracking (call when shift ends)
  void stopBackgroundTracking() {
    if (!_isTracking) return;

    AppLogger.location('📍 Stopping background location tracking');
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isTracking = false;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final locationService = ref.read(locationServiceProvider);
      return await locationService.getCurrentLocation();
    });
  }

  // Manually set location (for simulation)
  void setSimulatedLocation({
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
  }) {
    final simulatedPosition = Position(
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
}

@riverpod
Stream<Position> locationStream(LocationStreamRef ref) {
  final locationService = ref.read(locationServiceProvider);
  return locationService.getPositionStream();
}
