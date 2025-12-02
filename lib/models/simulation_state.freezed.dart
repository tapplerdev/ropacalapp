// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'simulation_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SimulationState {
  /// Whether simulation is currently running
  bool get isSimulating => throw _privateConstructorUsedError;

  /// Current simulated position (Google Maps LatLng for rendering)
  LatLng? get simulatedPosition => throw _privateConstructorUsedError;

  /// Current bearing/heading in degrees (0-360)
  double get bearing => throw _privateConstructorUsedError;

  /// Current segment index in route polyline
  int get currentSegmentIndex => throw _privateConstructorUsedError;

  /// Progress within current segment (0.0 to 1.0)
  double get segmentProgress => throw _privateConstructorUsedError;

  /// Overall route progress (0.0 to 1.0)
  double get routeProgress => throw _privateConstructorUsedError;

  /// Whether in 3D navigation mode (tilted camera)
  bool get isNavigationMode => throw _privateConstructorUsedError;

  /// Whether camera is following current position (vs free roam)
  bool get isFollowing => throw _privateConstructorUsedError;

  /// Smoothed bearing to reduce jitter
  double? get smoothedBearing => throw _privateConstructorUsedError;

  /// Full route polyline for map rendering (detailed road path)
  List<LatLng> get routePolyline => throw _privateConstructorUsedError;

  /// Create a copy of SimulationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SimulationStateCopyWith<SimulationState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SimulationStateCopyWith<$Res> {
  factory $SimulationStateCopyWith(
    SimulationState value,
    $Res Function(SimulationState) then,
  ) = _$SimulationStateCopyWithImpl<$Res, SimulationState>;
  @useResult
  $Res call({
    bool isSimulating,
    LatLng? simulatedPosition,
    double bearing,
    int currentSegmentIndex,
    double segmentProgress,
    double routeProgress,
    bool isNavigationMode,
    bool isFollowing,
    double? smoothedBearing,
    List<LatLng> routePolyline,
  });
}

/// @nodoc
class _$SimulationStateCopyWithImpl<$Res, $Val extends SimulationState>
    implements $SimulationStateCopyWith<$Res> {
  _$SimulationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SimulationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isSimulating = null,
    Object? simulatedPosition = freezed,
    Object? bearing = null,
    Object? currentSegmentIndex = null,
    Object? segmentProgress = null,
    Object? routeProgress = null,
    Object? isNavigationMode = null,
    Object? isFollowing = null,
    Object? smoothedBearing = freezed,
    Object? routePolyline = null,
  }) {
    return _then(
      _value.copyWith(
            isSimulating: null == isSimulating
                ? _value.isSimulating
                : isSimulating // ignore: cast_nullable_to_non_nullable
                      as bool,
            simulatedPosition: freezed == simulatedPosition
                ? _value.simulatedPosition
                : simulatedPosition // ignore: cast_nullable_to_non_nullable
                      as LatLng?,
            bearing: null == bearing
                ? _value.bearing
                : bearing // ignore: cast_nullable_to_non_nullable
                      as double,
            currentSegmentIndex: null == currentSegmentIndex
                ? _value.currentSegmentIndex
                : currentSegmentIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            segmentProgress: null == segmentProgress
                ? _value.segmentProgress
                : segmentProgress // ignore: cast_nullable_to_non_nullable
                      as double,
            routeProgress: null == routeProgress
                ? _value.routeProgress
                : routeProgress // ignore: cast_nullable_to_non_nullable
                      as double,
            isNavigationMode: null == isNavigationMode
                ? _value.isNavigationMode
                : isNavigationMode // ignore: cast_nullable_to_non_nullable
                      as bool,
            isFollowing: null == isFollowing
                ? _value.isFollowing
                : isFollowing // ignore: cast_nullable_to_non_nullable
                      as bool,
            smoothedBearing: freezed == smoothedBearing
                ? _value.smoothedBearing
                : smoothedBearing // ignore: cast_nullable_to_non_nullable
                      as double?,
            routePolyline: null == routePolyline
                ? _value.routePolyline
                : routePolyline // ignore: cast_nullable_to_non_nullable
                      as List<LatLng>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SimulationStateImplCopyWith<$Res>
    implements $SimulationStateCopyWith<$Res> {
  factory _$$SimulationStateImplCopyWith(
    _$SimulationStateImpl value,
    $Res Function(_$SimulationStateImpl) then,
  ) = __$$SimulationStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isSimulating,
    LatLng? simulatedPosition,
    double bearing,
    int currentSegmentIndex,
    double segmentProgress,
    double routeProgress,
    bool isNavigationMode,
    bool isFollowing,
    double? smoothedBearing,
    List<LatLng> routePolyline,
  });
}

/// @nodoc
class __$$SimulationStateImplCopyWithImpl<$Res>
    extends _$SimulationStateCopyWithImpl<$Res, _$SimulationStateImpl>
    implements _$$SimulationStateImplCopyWith<$Res> {
  __$$SimulationStateImplCopyWithImpl(
    _$SimulationStateImpl _value,
    $Res Function(_$SimulationStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SimulationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isSimulating = null,
    Object? simulatedPosition = freezed,
    Object? bearing = null,
    Object? currentSegmentIndex = null,
    Object? segmentProgress = null,
    Object? routeProgress = null,
    Object? isNavigationMode = null,
    Object? isFollowing = null,
    Object? smoothedBearing = freezed,
    Object? routePolyline = null,
  }) {
    return _then(
      _$SimulationStateImpl(
        isSimulating: null == isSimulating
            ? _value.isSimulating
            : isSimulating // ignore: cast_nullable_to_non_nullable
                  as bool,
        simulatedPosition: freezed == simulatedPosition
            ? _value.simulatedPosition
            : simulatedPosition // ignore: cast_nullable_to_non_nullable
                  as LatLng?,
        bearing: null == bearing
            ? _value.bearing
            : bearing // ignore: cast_nullable_to_non_nullable
                  as double,
        currentSegmentIndex: null == currentSegmentIndex
            ? _value.currentSegmentIndex
            : currentSegmentIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        segmentProgress: null == segmentProgress
            ? _value.segmentProgress
            : segmentProgress // ignore: cast_nullable_to_non_nullable
                  as double,
        routeProgress: null == routeProgress
            ? _value.routeProgress
            : routeProgress // ignore: cast_nullable_to_non_nullable
                  as double,
        isNavigationMode: null == isNavigationMode
            ? _value.isNavigationMode
            : isNavigationMode // ignore: cast_nullable_to_non_nullable
                  as bool,
        isFollowing: null == isFollowing
            ? _value.isFollowing
            : isFollowing // ignore: cast_nullable_to_non_nullable
                  as bool,
        smoothedBearing: freezed == smoothedBearing
            ? _value.smoothedBearing
            : smoothedBearing // ignore: cast_nullable_to_non_nullable
                  as double?,
        routePolyline: null == routePolyline
            ? _value._routePolyline
            : routePolyline // ignore: cast_nullable_to_non_nullable
                  as List<LatLng>,
      ),
    );
  }
}

/// @nodoc

class _$SimulationStateImpl implements _SimulationState {
  const _$SimulationStateImpl({
    this.isSimulating = false,
    this.simulatedPosition,
    this.bearing = 0.0,
    this.currentSegmentIndex = 0,
    this.segmentProgress = 0.0,
    this.routeProgress = 0.0,
    this.isNavigationMode = true,
    this.isFollowing = true,
    this.smoothedBearing,
    final List<LatLng> routePolyline = const [],
  }) : _routePolyline = routePolyline;

  /// Whether simulation is currently running
  @override
  @JsonKey()
  final bool isSimulating;

  /// Current simulated position (Google Maps LatLng for rendering)
  @override
  final LatLng? simulatedPosition;

  /// Current bearing/heading in degrees (0-360)
  @override
  @JsonKey()
  final double bearing;

  /// Current segment index in route polyline
  @override
  @JsonKey()
  final int currentSegmentIndex;

  /// Progress within current segment (0.0 to 1.0)
  @override
  @JsonKey()
  final double segmentProgress;

  /// Overall route progress (0.0 to 1.0)
  @override
  @JsonKey()
  final double routeProgress;

  /// Whether in 3D navigation mode (tilted camera)
  @override
  @JsonKey()
  final bool isNavigationMode;

  /// Whether camera is following current position (vs free roam)
  @override
  @JsonKey()
  final bool isFollowing;

  /// Smoothed bearing to reduce jitter
  @override
  final double? smoothedBearing;

  /// Full route polyline for map rendering (detailed road path)
  final List<LatLng> _routePolyline;

  /// Full route polyline for map rendering (detailed road path)
  @override
  @JsonKey()
  List<LatLng> get routePolyline {
    if (_routePolyline is EqualUnmodifiableListView) return _routePolyline;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_routePolyline);
  }

  @override
  String toString() {
    return 'SimulationState(isSimulating: $isSimulating, simulatedPosition: $simulatedPosition, bearing: $bearing, currentSegmentIndex: $currentSegmentIndex, segmentProgress: $segmentProgress, routeProgress: $routeProgress, isNavigationMode: $isNavigationMode, isFollowing: $isFollowing, smoothedBearing: $smoothedBearing, routePolyline: $routePolyline)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SimulationStateImpl &&
            (identical(other.isSimulating, isSimulating) ||
                other.isSimulating == isSimulating) &&
            (identical(other.simulatedPosition, simulatedPosition) ||
                other.simulatedPosition == simulatedPosition) &&
            (identical(other.bearing, bearing) || other.bearing == bearing) &&
            (identical(other.currentSegmentIndex, currentSegmentIndex) ||
                other.currentSegmentIndex == currentSegmentIndex) &&
            (identical(other.segmentProgress, segmentProgress) ||
                other.segmentProgress == segmentProgress) &&
            (identical(other.routeProgress, routeProgress) ||
                other.routeProgress == routeProgress) &&
            (identical(other.isNavigationMode, isNavigationMode) ||
                other.isNavigationMode == isNavigationMode) &&
            (identical(other.isFollowing, isFollowing) ||
                other.isFollowing == isFollowing) &&
            (identical(other.smoothedBearing, smoothedBearing) ||
                other.smoothedBearing == smoothedBearing) &&
            const DeepCollectionEquality().equals(
              other._routePolyline,
              _routePolyline,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isSimulating,
    simulatedPosition,
    bearing,
    currentSegmentIndex,
    segmentProgress,
    routeProgress,
    isNavigationMode,
    isFollowing,
    smoothedBearing,
    const DeepCollectionEquality().hash(_routePolyline),
  );

  /// Create a copy of SimulationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SimulationStateImplCopyWith<_$SimulationStateImpl> get copyWith =>
      __$$SimulationStateImplCopyWithImpl<_$SimulationStateImpl>(
        this,
        _$identity,
      );
}

abstract class _SimulationState implements SimulationState {
  const factory _SimulationState({
    final bool isSimulating,
    final LatLng? simulatedPosition,
    final double bearing,
    final int currentSegmentIndex,
    final double segmentProgress,
    final double routeProgress,
    final bool isNavigationMode,
    final bool isFollowing,
    final double? smoothedBearing,
    final List<LatLng> routePolyline,
  }) = _$SimulationStateImpl;

  /// Whether simulation is currently running
  @override
  bool get isSimulating;

  /// Current simulated position (Google Maps LatLng for rendering)
  @override
  LatLng? get simulatedPosition;

  /// Current bearing/heading in degrees (0-360)
  @override
  double get bearing;

  /// Current segment index in route polyline
  @override
  int get currentSegmentIndex;

  /// Progress within current segment (0.0 to 1.0)
  @override
  double get segmentProgress;

  /// Overall route progress (0.0 to 1.0)
  @override
  double get routeProgress;

  /// Whether in 3D navigation mode (tilted camera)
  @override
  bool get isNavigationMode;

  /// Whether camera is following current position (vs free roam)
  @override
  bool get isFollowing;

  /// Smoothed bearing to reduce jitter
  @override
  double? get smoothedBearing;

  /// Full route polyline for map rendering (detailed road path)
  @override
  List<LatLng> get routePolyline;

  /// Create a copy of SimulationState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SimulationStateImplCopyWith<_$SimulationStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
