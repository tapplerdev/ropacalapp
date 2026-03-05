// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'navigation_page_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$NavigationPageState {
  /// Whether navigation system is ready (map loaded, listeners setup)
  bool get isNavigationReady => throw _privateConstructorUsedError;

  /// Whether navigation guidance is currently active
  bool get isNavigating => throw _privateConstructorUsedError;

  /// Current bin index in the route
  int get currentBinIndex => throw _privateConstructorUsedError;

  /// Map of marker IDs to RouteBin objects for tap handling
  Map<String, RouteBin> get markerToBinMap =>
      throw _privateConstructorUsedError;

  /// Current navigation step (turn-by-turn instruction)
  RouteStep? get currentStep => throw _privateConstructorUsedError;

  /// Distance to next maneuver in meters
  double get distanceToNextManeuver => throw _privateConstructorUsedError;

  /// Estimated time remaining to final destination
  Duration? get remainingTime => throw _privateConstructorUsedError;

  /// Total distance remaining to final destination in meters
  double? get totalDistanceRemaining => throw _privateConstructorUsedError;

  /// Current navigation location (road-snapped)
  LatLng? get navigationLocation => throw _privateConstructorUsedError;

  /// Geofence circles around bins (50m radius)
  List<CircleOptions> get geofenceCircles => throw _privateConstructorUsedError;

  /// Polyline showing completed route segments
  PolylineOptions? get completedRoutePolyline =>
      throw _privateConstructorUsedError;

  /// Whether we've received first NavInfo event
  bool get hasReceivedFirstNavInfo => throw _privateConstructorUsedError;

  /// Whether audio guidance is muted
  bool get isAudioMuted => throw _privateConstructorUsedError;

  /// Whether bottom panel is expanded (UI state - could use hooks instead)
  bool get isBottomPanelExpanded => throw _privateConstructorUsedError;

  /// Create a copy of NavigationPageState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NavigationPageStateCopyWith<NavigationPageState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NavigationPageStateCopyWith<$Res> {
  factory $NavigationPageStateCopyWith(
    NavigationPageState value,
    $Res Function(NavigationPageState) then,
  ) = _$NavigationPageStateCopyWithImpl<$Res, NavigationPageState>;
  @useResult
  $Res call({
    bool isNavigationReady,
    bool isNavigating,
    int currentBinIndex,
    Map<String, RouteBin> markerToBinMap,
    RouteStep? currentStep,
    double distanceToNextManeuver,
    Duration? remainingTime,
    double? totalDistanceRemaining,
    LatLng? navigationLocation,
    List<CircleOptions> geofenceCircles,
    PolylineOptions? completedRoutePolyline,
    bool hasReceivedFirstNavInfo,
    bool isAudioMuted,
    bool isBottomPanelExpanded,
  });

  $RouteStepCopyWith<$Res>? get currentStep;
}

/// @nodoc
class _$NavigationPageStateCopyWithImpl<$Res, $Val extends NavigationPageState>
    implements $NavigationPageStateCopyWith<$Res> {
  _$NavigationPageStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NavigationPageState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isNavigationReady = null,
    Object? isNavigating = null,
    Object? currentBinIndex = null,
    Object? markerToBinMap = null,
    Object? currentStep = freezed,
    Object? distanceToNextManeuver = null,
    Object? remainingTime = freezed,
    Object? totalDistanceRemaining = freezed,
    Object? navigationLocation = freezed,
    Object? geofenceCircles = null,
    Object? completedRoutePolyline = freezed,
    Object? hasReceivedFirstNavInfo = null,
    Object? isAudioMuted = null,
    Object? isBottomPanelExpanded = null,
  }) {
    return _then(
      _value.copyWith(
            isNavigationReady: null == isNavigationReady
                ? _value.isNavigationReady
                : isNavigationReady // ignore: cast_nullable_to_non_nullable
                      as bool,
            isNavigating: null == isNavigating
                ? _value.isNavigating
                : isNavigating // ignore: cast_nullable_to_non_nullable
                      as bool,
            currentBinIndex: null == currentBinIndex
                ? _value.currentBinIndex
                : currentBinIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            markerToBinMap: null == markerToBinMap
                ? _value.markerToBinMap
                : markerToBinMap // ignore: cast_nullable_to_non_nullable
                      as Map<String, RouteBin>,
            currentStep: freezed == currentStep
                ? _value.currentStep
                : currentStep // ignore: cast_nullable_to_non_nullable
                      as RouteStep?,
            distanceToNextManeuver: null == distanceToNextManeuver
                ? _value.distanceToNextManeuver
                : distanceToNextManeuver // ignore: cast_nullable_to_non_nullable
                      as double,
            remainingTime: freezed == remainingTime
                ? _value.remainingTime
                : remainingTime // ignore: cast_nullable_to_non_nullable
                      as Duration?,
            totalDistanceRemaining: freezed == totalDistanceRemaining
                ? _value.totalDistanceRemaining
                : totalDistanceRemaining // ignore: cast_nullable_to_non_nullable
                      as double?,
            navigationLocation: freezed == navigationLocation
                ? _value.navigationLocation
                : navigationLocation // ignore: cast_nullable_to_non_nullable
                      as LatLng?,
            geofenceCircles: null == geofenceCircles
                ? _value.geofenceCircles
                : geofenceCircles // ignore: cast_nullable_to_non_nullable
                      as List<CircleOptions>,
            completedRoutePolyline: freezed == completedRoutePolyline
                ? _value.completedRoutePolyline
                : completedRoutePolyline // ignore: cast_nullable_to_non_nullable
                      as PolylineOptions?,
            hasReceivedFirstNavInfo: null == hasReceivedFirstNavInfo
                ? _value.hasReceivedFirstNavInfo
                : hasReceivedFirstNavInfo // ignore: cast_nullable_to_non_nullable
                      as bool,
            isAudioMuted: null == isAudioMuted
                ? _value.isAudioMuted
                : isAudioMuted // ignore: cast_nullable_to_non_nullable
                      as bool,
            isBottomPanelExpanded: null == isBottomPanelExpanded
                ? _value.isBottomPanelExpanded
                : isBottomPanelExpanded // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of NavigationPageState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RouteStepCopyWith<$Res>? get currentStep {
    if (_value.currentStep == null) {
      return null;
    }

    return $RouteStepCopyWith<$Res>(_value.currentStep!, (value) {
      return _then(_value.copyWith(currentStep: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$NavigationPageStateImplCopyWith<$Res>
    implements $NavigationPageStateCopyWith<$Res> {
  factory _$$NavigationPageStateImplCopyWith(
    _$NavigationPageStateImpl value,
    $Res Function(_$NavigationPageStateImpl) then,
  ) = __$$NavigationPageStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isNavigationReady,
    bool isNavigating,
    int currentBinIndex,
    Map<String, RouteBin> markerToBinMap,
    RouteStep? currentStep,
    double distanceToNextManeuver,
    Duration? remainingTime,
    double? totalDistanceRemaining,
    LatLng? navigationLocation,
    List<CircleOptions> geofenceCircles,
    PolylineOptions? completedRoutePolyline,
    bool hasReceivedFirstNavInfo,
    bool isAudioMuted,
    bool isBottomPanelExpanded,
  });

  @override
  $RouteStepCopyWith<$Res>? get currentStep;
}

/// @nodoc
class __$$NavigationPageStateImplCopyWithImpl<$Res>
    extends _$NavigationPageStateCopyWithImpl<$Res, _$NavigationPageStateImpl>
    implements _$$NavigationPageStateImplCopyWith<$Res> {
  __$$NavigationPageStateImplCopyWithImpl(
    _$NavigationPageStateImpl _value,
    $Res Function(_$NavigationPageStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NavigationPageState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isNavigationReady = null,
    Object? isNavigating = null,
    Object? currentBinIndex = null,
    Object? markerToBinMap = null,
    Object? currentStep = freezed,
    Object? distanceToNextManeuver = null,
    Object? remainingTime = freezed,
    Object? totalDistanceRemaining = freezed,
    Object? navigationLocation = freezed,
    Object? geofenceCircles = null,
    Object? completedRoutePolyline = freezed,
    Object? hasReceivedFirstNavInfo = null,
    Object? isAudioMuted = null,
    Object? isBottomPanelExpanded = null,
  }) {
    return _then(
      _$NavigationPageStateImpl(
        isNavigationReady: null == isNavigationReady
            ? _value.isNavigationReady
            : isNavigationReady // ignore: cast_nullable_to_non_nullable
                  as bool,
        isNavigating: null == isNavigating
            ? _value.isNavigating
            : isNavigating // ignore: cast_nullable_to_non_nullable
                  as bool,
        currentBinIndex: null == currentBinIndex
            ? _value.currentBinIndex
            : currentBinIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        markerToBinMap: null == markerToBinMap
            ? _value._markerToBinMap
            : markerToBinMap // ignore: cast_nullable_to_non_nullable
                  as Map<String, RouteBin>,
        currentStep: freezed == currentStep
            ? _value.currentStep
            : currentStep // ignore: cast_nullable_to_non_nullable
                  as RouteStep?,
        distanceToNextManeuver: null == distanceToNextManeuver
            ? _value.distanceToNextManeuver
            : distanceToNextManeuver // ignore: cast_nullable_to_non_nullable
                  as double,
        remainingTime: freezed == remainingTime
            ? _value.remainingTime
            : remainingTime // ignore: cast_nullable_to_non_nullable
                  as Duration?,
        totalDistanceRemaining: freezed == totalDistanceRemaining
            ? _value.totalDistanceRemaining
            : totalDistanceRemaining // ignore: cast_nullable_to_non_nullable
                  as double?,
        navigationLocation: freezed == navigationLocation
            ? _value.navigationLocation
            : navigationLocation // ignore: cast_nullable_to_non_nullable
                  as LatLng?,
        geofenceCircles: null == geofenceCircles
            ? _value._geofenceCircles
            : geofenceCircles // ignore: cast_nullable_to_non_nullable
                  as List<CircleOptions>,
        completedRoutePolyline: freezed == completedRoutePolyline
            ? _value.completedRoutePolyline
            : completedRoutePolyline // ignore: cast_nullable_to_non_nullable
                  as PolylineOptions?,
        hasReceivedFirstNavInfo: null == hasReceivedFirstNavInfo
            ? _value.hasReceivedFirstNavInfo
            : hasReceivedFirstNavInfo // ignore: cast_nullable_to_non_nullable
                  as bool,
        isAudioMuted: null == isAudioMuted
            ? _value.isAudioMuted
            : isAudioMuted // ignore: cast_nullable_to_non_nullable
                  as bool,
        isBottomPanelExpanded: null == isBottomPanelExpanded
            ? _value.isBottomPanelExpanded
            : isBottomPanelExpanded // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$NavigationPageStateImpl implements _NavigationPageState {
  const _$NavigationPageStateImpl({
    this.isNavigationReady = false,
    this.isNavigating = false,
    this.currentBinIndex = 0,
    final Map<String, RouteBin> markerToBinMap = const {},
    this.currentStep,
    this.distanceToNextManeuver = 0.0,
    this.remainingTime,
    this.totalDistanceRemaining,
    this.navigationLocation,
    final List<CircleOptions> geofenceCircles = const [],
    this.completedRoutePolyline,
    this.hasReceivedFirstNavInfo = false,
    this.isAudioMuted = false,
    this.isBottomPanelExpanded = false,
  }) : _markerToBinMap = markerToBinMap,
       _geofenceCircles = geofenceCircles;

  /// Whether navigation system is ready (map loaded, listeners setup)
  @override
  @JsonKey()
  final bool isNavigationReady;

  /// Whether navigation guidance is currently active
  @override
  @JsonKey()
  final bool isNavigating;

  /// Current bin index in the route
  @override
  @JsonKey()
  final int currentBinIndex;

  /// Map of marker IDs to RouteBin objects for tap handling
  final Map<String, RouteBin> _markerToBinMap;

  /// Map of marker IDs to RouteBin objects for tap handling
  @override
  @JsonKey()
  Map<String, RouteBin> get markerToBinMap {
    if (_markerToBinMap is EqualUnmodifiableMapView) return _markerToBinMap;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_markerToBinMap);
  }

  /// Current navigation step (turn-by-turn instruction)
  @override
  final RouteStep? currentStep;

  /// Distance to next maneuver in meters
  @override
  @JsonKey()
  final double distanceToNextManeuver;

  /// Estimated time remaining to final destination
  @override
  final Duration? remainingTime;

  /// Total distance remaining to final destination in meters
  @override
  final double? totalDistanceRemaining;

  /// Current navigation location (road-snapped)
  @override
  final LatLng? navigationLocation;

  /// Geofence circles around bins (50m radius)
  final List<CircleOptions> _geofenceCircles;

  /// Geofence circles around bins (50m radius)
  @override
  @JsonKey()
  List<CircleOptions> get geofenceCircles {
    if (_geofenceCircles is EqualUnmodifiableListView) return _geofenceCircles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_geofenceCircles);
  }

  /// Polyline showing completed route segments
  @override
  final PolylineOptions? completedRoutePolyline;

  /// Whether we've received first NavInfo event
  @override
  @JsonKey()
  final bool hasReceivedFirstNavInfo;

  /// Whether audio guidance is muted
  @override
  @JsonKey()
  final bool isAudioMuted;

  /// Whether bottom panel is expanded (UI state - could use hooks instead)
  @override
  @JsonKey()
  final bool isBottomPanelExpanded;

  @override
  String toString() {
    return 'NavigationPageState(isNavigationReady: $isNavigationReady, isNavigating: $isNavigating, currentBinIndex: $currentBinIndex, markerToBinMap: $markerToBinMap, currentStep: $currentStep, distanceToNextManeuver: $distanceToNextManeuver, remainingTime: $remainingTime, totalDistanceRemaining: $totalDistanceRemaining, navigationLocation: $navigationLocation, geofenceCircles: $geofenceCircles, completedRoutePolyline: $completedRoutePolyline, hasReceivedFirstNavInfo: $hasReceivedFirstNavInfo, isAudioMuted: $isAudioMuted, isBottomPanelExpanded: $isBottomPanelExpanded)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NavigationPageStateImpl &&
            (identical(other.isNavigationReady, isNavigationReady) ||
                other.isNavigationReady == isNavigationReady) &&
            (identical(other.isNavigating, isNavigating) ||
                other.isNavigating == isNavigating) &&
            (identical(other.currentBinIndex, currentBinIndex) ||
                other.currentBinIndex == currentBinIndex) &&
            const DeepCollectionEquality().equals(
              other._markerToBinMap,
              _markerToBinMap,
            ) &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep) &&
            (identical(other.distanceToNextManeuver, distanceToNextManeuver) ||
                other.distanceToNextManeuver == distanceToNextManeuver) &&
            (identical(other.remainingTime, remainingTime) ||
                other.remainingTime == remainingTime) &&
            (identical(other.totalDistanceRemaining, totalDistanceRemaining) ||
                other.totalDistanceRemaining == totalDistanceRemaining) &&
            (identical(other.navigationLocation, navigationLocation) ||
                other.navigationLocation == navigationLocation) &&
            const DeepCollectionEquality().equals(
              other._geofenceCircles,
              _geofenceCircles,
            ) &&
            (identical(other.completedRoutePolyline, completedRoutePolyline) ||
                other.completedRoutePolyline == completedRoutePolyline) &&
            (identical(
                  other.hasReceivedFirstNavInfo,
                  hasReceivedFirstNavInfo,
                ) ||
                other.hasReceivedFirstNavInfo == hasReceivedFirstNavInfo) &&
            (identical(other.isAudioMuted, isAudioMuted) ||
                other.isAudioMuted == isAudioMuted) &&
            (identical(other.isBottomPanelExpanded, isBottomPanelExpanded) ||
                other.isBottomPanelExpanded == isBottomPanelExpanded));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isNavigationReady,
    isNavigating,
    currentBinIndex,
    const DeepCollectionEquality().hash(_markerToBinMap),
    currentStep,
    distanceToNextManeuver,
    remainingTime,
    totalDistanceRemaining,
    navigationLocation,
    const DeepCollectionEquality().hash(_geofenceCircles),
    completedRoutePolyline,
    hasReceivedFirstNavInfo,
    isAudioMuted,
    isBottomPanelExpanded,
  );

  /// Create a copy of NavigationPageState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NavigationPageStateImplCopyWith<_$NavigationPageStateImpl> get copyWith =>
      __$$NavigationPageStateImplCopyWithImpl<_$NavigationPageStateImpl>(
        this,
        _$identity,
      );
}

abstract class _NavigationPageState implements NavigationPageState {
  const factory _NavigationPageState({
    final bool isNavigationReady,
    final bool isNavigating,
    final int currentBinIndex,
    final Map<String, RouteBin> markerToBinMap,
    final RouteStep? currentStep,
    final double distanceToNextManeuver,
    final Duration? remainingTime,
    final double? totalDistanceRemaining,
    final LatLng? navigationLocation,
    final List<CircleOptions> geofenceCircles,
    final PolylineOptions? completedRoutePolyline,
    final bool hasReceivedFirstNavInfo,
    final bool isAudioMuted,
    final bool isBottomPanelExpanded,
  }) = _$NavigationPageStateImpl;

  /// Whether navigation system is ready (map loaded, listeners setup)
  @override
  bool get isNavigationReady;

  /// Whether navigation guidance is currently active
  @override
  bool get isNavigating;

  /// Current bin index in the route
  @override
  int get currentBinIndex;

  /// Map of marker IDs to RouteBin objects for tap handling
  @override
  Map<String, RouteBin> get markerToBinMap;

  /// Current navigation step (turn-by-turn instruction)
  @override
  RouteStep? get currentStep;

  /// Distance to next maneuver in meters
  @override
  double get distanceToNextManeuver;

  /// Estimated time remaining to final destination
  @override
  Duration? get remainingTime;

  /// Total distance remaining to final destination in meters
  @override
  double? get totalDistanceRemaining;

  /// Current navigation location (road-snapped)
  @override
  LatLng? get navigationLocation;

  /// Geofence circles around bins (50m radius)
  @override
  List<CircleOptions> get geofenceCircles;

  /// Polyline showing completed route segments
  @override
  PolylineOptions? get completedRoutePolyline;

  /// Whether we've received first NavInfo event
  @override
  bool get hasReceivedFirstNavInfo;

  /// Whether audio guidance is muted
  @override
  bool get isAudioMuted;

  /// Whether bottom panel is expanded (UI state - could use hooks instead)
  @override
  bool get isBottomPanelExpanded;

  /// Create a copy of NavigationPageState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NavigationPageStateImplCopyWith<_$NavigationPageStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
