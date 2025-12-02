import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/models/route_step.dart';

part 'navigation_page_state.freezed.dart';

/// State for the navigation page
/// Contains all navigation-related state that was previously in ValueNotifiers
@freezed
class NavigationPageState with _$NavigationPageState {
  const factory NavigationPageState({
    /// Whether navigation system is ready (map loaded, listeners setup)
    @Default(false) bool isNavigationReady,

    /// Whether navigation guidance is currently active
    @Default(false) bool isNavigating,

    /// Current bin index in the route
    @Default(0) int currentBinIndex,

    /// Map of marker IDs to RouteBin objects for tap handling
    @Default({}) Map<String, RouteBin> markerToBinMap,

    /// Current navigation step (turn-by-turn instruction)
    RouteStep? currentStep,

    /// Distance to next maneuver in meters
    @Default(0.0) double distanceToNextManeuver,

    /// Estimated time remaining to final destination
    Duration? remainingTime,

    /// Total distance remaining to final destination in meters
    double? totalDistanceRemaining,

    /// Current navigation location (road-snapped)
    LatLng? navigationLocation,

    /// Geofence circles around bins (50m radius)
    @Default([]) List<CircleOptions> geofenceCircles,

    /// Polyline showing completed route segments
    PolylineOptions? completedRoutePolyline,

    /// Whether we've received first NavInfo event
    @Default(false) bool hasReceivedFirstNavInfo,

    /// Whether audio guidance is muted
    @Default(false) bool isAudioMuted,

    /// Whether bottom panel is expanded (UI state - could use hooks instead)
    @Default(false) bool isBottomPanelExpanded,
  }) = _NavigationPageState;
}
