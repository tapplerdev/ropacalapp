import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;

part 'simulation_state.freezed.dart';

/// State for route simulation
@freezed
class SimulationState with _$SimulationState {
  const factory SimulationState({
    /// Whether simulation is currently running
    @Default(false) bool isSimulating,

    /// Current simulated position (Google Maps LatLng for rendering)
    LatLng? simulatedPosition,

    /// Current bearing/heading in degrees (0-360)
    @Default(0.0) double bearing,

    /// Current segment index in route polyline
    @Default(0) int currentSegmentIndex,

    /// Progress within current segment (0.0 to 1.0)
    @Default(0.0) double segmentProgress,

    /// Overall route progress (0.0 to 1.0)
    @Default(0.0) double routeProgress,

    /// Whether in 3D navigation mode (tilted camera)
    @Default(true) bool isNavigationMode,

    /// Whether camera is following current position (vs free roam)
    @Default(true) bool isFollowing,

    /// Smoothed bearing to reduce jitter
    double? smoothedBearing,

    /// Full route polyline for map rendering (detailed road path)
    @Default([]) List<LatLng> routePolyline,
  }) = _SimulationState;
}
