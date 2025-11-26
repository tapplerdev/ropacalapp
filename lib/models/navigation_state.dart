import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';
import 'package:ropacalapp/models/route_step.dart';
import 'package:ropacalapp/models/bin.dart';

part 'navigation_state.freezed.dart';

@freezed
class NavigationState with _$NavigationState {
  const factory NavigationState({
    required List<RouteStep> routeSteps,
    required int currentStepIndex,
    required LatLng currentLocation,
    required List<Bin> destinationBins,
    required int currentBinIndex,
    required double totalDistance, // in meters
    required double remainingDistance, // in meters
    required double distanceToNextManeuver, // in meters
    required DateTime startTime,
    required List<LatLng> routePolyline, // Full route geometry
    DateTime? estimatedArrival,
    double? currentSpeed, // in m/s
    double? currentBearing, // in degrees
    @Default(false) bool isOffRoute,
  }) = _NavigationState;

  const NavigationState._();

  RouteStep? get currentStep => currentStepIndex < routeSteps.length
      ? routeSteps[currentStepIndex]
      : null;

  RouteStep? get nextStep => currentStepIndex + 1 < routeSteps.length
      ? routeSteps[currentStepIndex + 1]
      : null;

  Bin? get currentDestination => currentBinIndex < destinationBins.length
      ? destinationBins[currentBinIndex]
      : null;

  double get progress => totalDistance > 0
      ? ((totalDistance - remainingDistance) / totalDistance).clamp(0.0, 1.0)
      : 0.0;

  bool get isComplete =>
      currentBinIndex >= destinationBins.length &&
      currentStepIndex >= routeSteps.length;
}
