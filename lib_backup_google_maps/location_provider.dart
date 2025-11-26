import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/services/location_service.dart';

part 'location_provider.g.dart';

@riverpod
LocationService locationService(LocationServiceRef ref) {
  return LocationService();
}

@riverpod
class CurrentLocation extends _$CurrentLocation {
  @override
  Future<Position?> build() async {
    final locationService = ref.read(locationServiceProvider);
    return await locationService.getCurrentLocation();
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
