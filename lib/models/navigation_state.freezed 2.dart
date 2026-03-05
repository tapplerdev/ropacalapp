// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'navigation_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$NavigationState {
  List<RouteStep> get routeSteps => throw _privateConstructorUsedError;
  int get currentStepIndex => throw _privateConstructorUsedError;
  LatLng get currentLocation => throw _privateConstructorUsedError;
  List<Bin> get destinationBins => throw _privateConstructorUsedError;
  int get currentBinIndex => throw _privateConstructorUsedError;
  double get totalDistance => throw _privateConstructorUsedError; // in meters
  double get remainingDistance =>
      throw _privateConstructorUsedError; // in meters
  double get distanceToNextManeuver =>
      throw _privateConstructorUsedError; // in meters
  DateTime get startTime => throw _privateConstructorUsedError;
  List<LatLng> get routePolyline =>
      throw _privateConstructorUsedError; // Full route geometry
  DateTime? get estimatedArrival => throw _privateConstructorUsedError;
  double? get currentSpeed => throw _privateConstructorUsedError; // in m/s
  double? get currentBearing =>
      throw _privateConstructorUsedError; // in degrees
  bool get isOffRoute => throw _privateConstructorUsedError;

  /// Create a copy of NavigationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NavigationStateCopyWith<NavigationState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NavigationStateCopyWith<$Res> {
  factory $NavigationStateCopyWith(
    NavigationState value,
    $Res Function(NavigationState) then,
  ) = _$NavigationStateCopyWithImpl<$Res, NavigationState>;
  @useResult
  $Res call({
    List<RouteStep> routeSteps,
    int currentStepIndex,
    LatLng currentLocation,
    List<Bin> destinationBins,
    int currentBinIndex,
    double totalDistance,
    double remainingDistance,
    double distanceToNextManeuver,
    DateTime startTime,
    List<LatLng> routePolyline,
    DateTime? estimatedArrival,
    double? currentSpeed,
    double? currentBearing,
    bool isOffRoute,
  });
}

/// @nodoc
class _$NavigationStateCopyWithImpl<$Res, $Val extends NavigationState>
    implements $NavigationStateCopyWith<$Res> {
  _$NavigationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NavigationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? routeSteps = null,
    Object? currentStepIndex = null,
    Object? currentLocation = null,
    Object? destinationBins = null,
    Object? currentBinIndex = null,
    Object? totalDistance = null,
    Object? remainingDistance = null,
    Object? distanceToNextManeuver = null,
    Object? startTime = null,
    Object? routePolyline = null,
    Object? estimatedArrival = freezed,
    Object? currentSpeed = freezed,
    Object? currentBearing = freezed,
    Object? isOffRoute = null,
  }) {
    return _then(
      _value.copyWith(
            routeSteps: null == routeSteps
                ? _value.routeSteps
                : routeSteps // ignore: cast_nullable_to_non_nullable
                      as List<RouteStep>,
            currentStepIndex: null == currentStepIndex
                ? _value.currentStepIndex
                : currentStepIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            currentLocation: null == currentLocation
                ? _value.currentLocation
                : currentLocation // ignore: cast_nullable_to_non_nullable
                      as LatLng,
            destinationBins: null == destinationBins
                ? _value.destinationBins
                : destinationBins // ignore: cast_nullable_to_non_nullable
                      as List<Bin>,
            currentBinIndex: null == currentBinIndex
                ? _value.currentBinIndex
                : currentBinIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            totalDistance: null == totalDistance
                ? _value.totalDistance
                : totalDistance // ignore: cast_nullable_to_non_nullable
                      as double,
            remainingDistance: null == remainingDistance
                ? _value.remainingDistance
                : remainingDistance // ignore: cast_nullable_to_non_nullable
                      as double,
            distanceToNextManeuver: null == distanceToNextManeuver
                ? _value.distanceToNextManeuver
                : distanceToNextManeuver // ignore: cast_nullable_to_non_nullable
                      as double,
            startTime: null == startTime
                ? _value.startTime
                : startTime // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            routePolyline: null == routePolyline
                ? _value.routePolyline
                : routePolyline // ignore: cast_nullable_to_non_nullable
                      as List<LatLng>,
            estimatedArrival: freezed == estimatedArrival
                ? _value.estimatedArrival
                : estimatedArrival // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            currentSpeed: freezed == currentSpeed
                ? _value.currentSpeed
                : currentSpeed // ignore: cast_nullable_to_non_nullable
                      as double?,
            currentBearing: freezed == currentBearing
                ? _value.currentBearing
                : currentBearing // ignore: cast_nullable_to_non_nullable
                      as double?,
            isOffRoute: null == isOffRoute
                ? _value.isOffRoute
                : isOffRoute // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NavigationStateImplCopyWith<$Res>
    implements $NavigationStateCopyWith<$Res> {
  factory _$$NavigationStateImplCopyWith(
    _$NavigationStateImpl value,
    $Res Function(_$NavigationStateImpl) then,
  ) = __$$NavigationStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<RouteStep> routeSteps,
    int currentStepIndex,
    LatLng currentLocation,
    List<Bin> destinationBins,
    int currentBinIndex,
    double totalDistance,
    double remainingDistance,
    double distanceToNextManeuver,
    DateTime startTime,
    List<LatLng> routePolyline,
    DateTime? estimatedArrival,
    double? currentSpeed,
    double? currentBearing,
    bool isOffRoute,
  });
}

/// @nodoc
class __$$NavigationStateImplCopyWithImpl<$Res>
    extends _$NavigationStateCopyWithImpl<$Res, _$NavigationStateImpl>
    implements _$$NavigationStateImplCopyWith<$Res> {
  __$$NavigationStateImplCopyWithImpl(
    _$NavigationStateImpl _value,
    $Res Function(_$NavigationStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NavigationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? routeSteps = null,
    Object? currentStepIndex = null,
    Object? currentLocation = null,
    Object? destinationBins = null,
    Object? currentBinIndex = null,
    Object? totalDistance = null,
    Object? remainingDistance = null,
    Object? distanceToNextManeuver = null,
    Object? startTime = null,
    Object? routePolyline = null,
    Object? estimatedArrival = freezed,
    Object? currentSpeed = freezed,
    Object? currentBearing = freezed,
    Object? isOffRoute = null,
  }) {
    return _then(
      _$NavigationStateImpl(
        routeSteps: null == routeSteps
            ? _value._routeSteps
            : routeSteps // ignore: cast_nullable_to_non_nullable
                  as List<RouteStep>,
        currentStepIndex: null == currentStepIndex
            ? _value.currentStepIndex
            : currentStepIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        currentLocation: null == currentLocation
            ? _value.currentLocation
            : currentLocation // ignore: cast_nullable_to_non_nullable
                  as LatLng,
        destinationBins: null == destinationBins
            ? _value._destinationBins
            : destinationBins // ignore: cast_nullable_to_non_nullable
                  as List<Bin>,
        currentBinIndex: null == currentBinIndex
            ? _value.currentBinIndex
            : currentBinIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        totalDistance: null == totalDistance
            ? _value.totalDistance
            : totalDistance // ignore: cast_nullable_to_non_nullable
                  as double,
        remainingDistance: null == remainingDistance
            ? _value.remainingDistance
            : remainingDistance // ignore: cast_nullable_to_non_nullable
                  as double,
        distanceToNextManeuver: null == distanceToNextManeuver
            ? _value.distanceToNextManeuver
            : distanceToNextManeuver // ignore: cast_nullable_to_non_nullable
                  as double,
        startTime: null == startTime
            ? _value.startTime
            : startTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        routePolyline: null == routePolyline
            ? _value._routePolyline
            : routePolyline // ignore: cast_nullable_to_non_nullable
                  as List<LatLng>,
        estimatedArrival: freezed == estimatedArrival
            ? _value.estimatedArrival
            : estimatedArrival // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        currentSpeed: freezed == currentSpeed
            ? _value.currentSpeed
            : currentSpeed // ignore: cast_nullable_to_non_nullable
                  as double?,
        currentBearing: freezed == currentBearing
            ? _value.currentBearing
            : currentBearing // ignore: cast_nullable_to_non_nullable
                  as double?,
        isOffRoute: null == isOffRoute
            ? _value.isOffRoute
            : isOffRoute // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$NavigationStateImpl extends _NavigationState {
  const _$NavigationStateImpl({
    required final List<RouteStep> routeSteps,
    required this.currentStepIndex,
    required this.currentLocation,
    required final List<Bin> destinationBins,
    required this.currentBinIndex,
    required this.totalDistance,
    required this.remainingDistance,
    required this.distanceToNextManeuver,
    required this.startTime,
    required final List<LatLng> routePolyline,
    this.estimatedArrival,
    this.currentSpeed,
    this.currentBearing,
    this.isOffRoute = false,
  }) : _routeSteps = routeSteps,
       _destinationBins = destinationBins,
       _routePolyline = routePolyline,
       super._();

  final List<RouteStep> _routeSteps;
  @override
  List<RouteStep> get routeSteps {
    if (_routeSteps is EqualUnmodifiableListView) return _routeSteps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_routeSteps);
  }

  @override
  final int currentStepIndex;
  @override
  final LatLng currentLocation;
  final List<Bin> _destinationBins;
  @override
  List<Bin> get destinationBins {
    if (_destinationBins is EqualUnmodifiableListView) return _destinationBins;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_destinationBins);
  }

  @override
  final int currentBinIndex;
  @override
  final double totalDistance;
  // in meters
  @override
  final double remainingDistance;
  // in meters
  @override
  final double distanceToNextManeuver;
  // in meters
  @override
  final DateTime startTime;
  final List<LatLng> _routePolyline;
  @override
  List<LatLng> get routePolyline {
    if (_routePolyline is EqualUnmodifiableListView) return _routePolyline;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_routePolyline);
  }

  // Full route geometry
  @override
  final DateTime? estimatedArrival;
  @override
  final double? currentSpeed;
  // in m/s
  @override
  final double? currentBearing;
  // in degrees
  @override
  @JsonKey()
  final bool isOffRoute;

  @override
  String toString() {
    return 'NavigationState(routeSteps: $routeSteps, currentStepIndex: $currentStepIndex, currentLocation: $currentLocation, destinationBins: $destinationBins, currentBinIndex: $currentBinIndex, totalDistance: $totalDistance, remainingDistance: $remainingDistance, distanceToNextManeuver: $distanceToNextManeuver, startTime: $startTime, routePolyline: $routePolyline, estimatedArrival: $estimatedArrival, currentSpeed: $currentSpeed, currentBearing: $currentBearing, isOffRoute: $isOffRoute)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NavigationStateImpl &&
            const DeepCollectionEquality().equals(
              other._routeSteps,
              _routeSteps,
            ) &&
            (identical(other.currentStepIndex, currentStepIndex) ||
                other.currentStepIndex == currentStepIndex) &&
            (identical(other.currentLocation, currentLocation) ||
                other.currentLocation == currentLocation) &&
            const DeepCollectionEquality().equals(
              other._destinationBins,
              _destinationBins,
            ) &&
            (identical(other.currentBinIndex, currentBinIndex) ||
                other.currentBinIndex == currentBinIndex) &&
            (identical(other.totalDistance, totalDistance) ||
                other.totalDistance == totalDistance) &&
            (identical(other.remainingDistance, remainingDistance) ||
                other.remainingDistance == remainingDistance) &&
            (identical(other.distanceToNextManeuver, distanceToNextManeuver) ||
                other.distanceToNextManeuver == distanceToNextManeuver) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            const DeepCollectionEquality().equals(
              other._routePolyline,
              _routePolyline,
            ) &&
            (identical(other.estimatedArrival, estimatedArrival) ||
                other.estimatedArrival == estimatedArrival) &&
            (identical(other.currentSpeed, currentSpeed) ||
                other.currentSpeed == currentSpeed) &&
            (identical(other.currentBearing, currentBearing) ||
                other.currentBearing == currentBearing) &&
            (identical(other.isOffRoute, isOffRoute) ||
                other.isOffRoute == isOffRoute));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_routeSteps),
    currentStepIndex,
    currentLocation,
    const DeepCollectionEquality().hash(_destinationBins),
    currentBinIndex,
    totalDistance,
    remainingDistance,
    distanceToNextManeuver,
    startTime,
    const DeepCollectionEquality().hash(_routePolyline),
    estimatedArrival,
    currentSpeed,
    currentBearing,
    isOffRoute,
  );

  /// Create a copy of NavigationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NavigationStateImplCopyWith<_$NavigationStateImpl> get copyWith =>
      __$$NavigationStateImplCopyWithImpl<_$NavigationStateImpl>(
        this,
        _$identity,
      );
}

abstract class _NavigationState extends NavigationState {
  const factory _NavigationState({
    required final List<RouteStep> routeSteps,
    required final int currentStepIndex,
    required final LatLng currentLocation,
    required final List<Bin> destinationBins,
    required final int currentBinIndex,
    required final double totalDistance,
    required final double remainingDistance,
    required final double distanceToNextManeuver,
    required final DateTime startTime,
    required final List<LatLng> routePolyline,
    final DateTime? estimatedArrival,
    final double? currentSpeed,
    final double? currentBearing,
    final bool isOffRoute,
  }) = _$NavigationStateImpl;
  const _NavigationState._() : super._();

  @override
  List<RouteStep> get routeSteps;
  @override
  int get currentStepIndex;
  @override
  LatLng get currentLocation;
  @override
  List<Bin> get destinationBins;
  @override
  int get currentBinIndex;
  @override
  double get totalDistance; // in meters
  @override
  double get remainingDistance; // in meters
  @override
  double get distanceToNextManeuver; // in meters
  @override
  DateTime get startTime;
  @override
  List<LatLng> get routePolyline; // Full route geometry
  @override
  DateTime? get estimatedArrival;
  @override
  double? get currentSpeed; // in m/s
  @override
  double? get currentBearing; // in degrees
  @override
  bool get isOffRoute;

  /// Create a copy of NavigationState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NavigationStateImplCopyWith<_$NavigationStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
