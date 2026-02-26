// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_step.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RouteStep _$RouteStepFromJson(Map<String, dynamic> json) {
  return _RouteStep.fromJson(json);
}

/// @nodoc
mixin _$RouteStep {
  String get instruction => throw _privateConstructorUsedError;
  double get distance => throw _privateConstructorUsedError; // in meters
  double get duration => throw _privateConstructorUsedError; // in seconds
  String get maneuverType =>
      throw _privateConstructorUsedError; // "turn-left", "turn-right", "straight", etc.
  LatLng get location => throw _privateConstructorUsedError;
  String? get modifier =>
      throw _privateConstructorUsedError; // "left", "right", "slight left", etc.
  String? get name => throw _privateConstructorUsedError;

  /// Serializes this RouteStep to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RouteStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RouteStepCopyWith<RouteStep> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RouteStepCopyWith<$Res> {
  factory $RouteStepCopyWith(RouteStep value, $Res Function(RouteStep) then) =
      _$RouteStepCopyWithImpl<$Res, RouteStep>;
  @useResult
  $Res call({
    String instruction,
    double distance,
    double duration,
    String maneuverType,
    LatLng location,
    String? modifier,
    String? name,
  });
}

/// @nodoc
class _$RouteStepCopyWithImpl<$Res, $Val extends RouteStep>
    implements $RouteStepCopyWith<$Res> {
  _$RouteStepCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RouteStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? instruction = null,
    Object? distance = null,
    Object? duration = null,
    Object? maneuverType = null,
    Object? location = null,
    Object? modifier = freezed,
    Object? name = freezed,
  }) {
    return _then(
      _value.copyWith(
            instruction: null == instruction
                ? _value.instruction
                : instruction // ignore: cast_nullable_to_non_nullable
                      as String,
            distance: null == distance
                ? _value.distance
                : distance // ignore: cast_nullable_to_non_nullable
                      as double,
            duration: null == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as double,
            maneuverType: null == maneuverType
                ? _value.maneuverType
                : maneuverType // ignore: cast_nullable_to_non_nullable
                      as String,
            location: null == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as LatLng,
            modifier: freezed == modifier
                ? _value.modifier
                : modifier // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RouteStepImplCopyWith<$Res>
    implements $RouteStepCopyWith<$Res> {
  factory _$$RouteStepImplCopyWith(
    _$RouteStepImpl value,
    $Res Function(_$RouteStepImpl) then,
  ) = __$$RouteStepImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String instruction,
    double distance,
    double duration,
    String maneuverType,
    LatLng location,
    String? modifier,
    String? name,
  });
}

/// @nodoc
class __$$RouteStepImplCopyWithImpl<$Res>
    extends _$RouteStepCopyWithImpl<$Res, _$RouteStepImpl>
    implements _$$RouteStepImplCopyWith<$Res> {
  __$$RouteStepImplCopyWithImpl(
    _$RouteStepImpl _value,
    $Res Function(_$RouteStepImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RouteStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? instruction = null,
    Object? distance = null,
    Object? duration = null,
    Object? maneuverType = null,
    Object? location = null,
    Object? modifier = freezed,
    Object? name = freezed,
  }) {
    return _then(
      _$RouteStepImpl(
        instruction: null == instruction
            ? _value.instruction
            : instruction // ignore: cast_nullable_to_non_nullable
                  as String,
        distance: null == distance
            ? _value.distance
            : distance // ignore: cast_nullable_to_non_nullable
                  as double,
        duration: null == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as double,
        maneuverType: null == maneuverType
            ? _value.maneuverType
            : maneuverType // ignore: cast_nullable_to_non_nullable
                  as String,
        location: null == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as LatLng,
        modifier: freezed == modifier
            ? _value.modifier
            : modifier // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RouteStepImpl implements _RouteStep {
  const _$RouteStepImpl({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.maneuverType,
    required this.location,
    this.modifier,
    this.name,
  });

  factory _$RouteStepImpl.fromJson(Map<String, dynamic> json) =>
      _$$RouteStepImplFromJson(json);

  @override
  final String instruction;
  @override
  final double distance;
  // in meters
  @override
  final double duration;
  // in seconds
  @override
  final String maneuverType;
  // "turn-left", "turn-right", "straight", etc.
  @override
  final LatLng location;
  @override
  final String? modifier;
  // "left", "right", "slight left", etc.
  @override
  final String? name;

  @override
  String toString() {
    return 'RouteStep(instruction: $instruction, distance: $distance, duration: $duration, maneuverType: $maneuverType, location: $location, modifier: $modifier, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RouteStepImpl &&
            (identical(other.instruction, instruction) ||
                other.instruction == instruction) &&
            (identical(other.distance, distance) ||
                other.distance == distance) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.maneuverType, maneuverType) ||
                other.maneuverType == maneuverType) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.modifier, modifier) ||
                other.modifier == modifier) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    instruction,
    distance,
    duration,
    maneuverType,
    location,
    modifier,
    name,
  );

  /// Create a copy of RouteStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RouteStepImplCopyWith<_$RouteStepImpl> get copyWith =>
      __$$RouteStepImplCopyWithImpl<_$RouteStepImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RouteStepImplToJson(this);
  }
}

abstract class _RouteStep implements RouteStep {
  const factory _RouteStep({
    required final String instruction,
    required final double distance,
    required final double duration,
    required final String maneuverType,
    required final LatLng location,
    final String? modifier,
    final String? name,
  }) = _$RouteStepImpl;

  factory _RouteStep.fromJson(Map<String, dynamic> json) =
      _$RouteStepImpl.fromJson;

  @override
  String get instruction;
  @override
  double get distance; // in meters
  @override
  double get duration; // in seconds
  @override
  String get maneuverType; // "turn-left", "turn-right", "straight", etc.
  @override
  LatLng get location;
  @override
  String? get modifier; // "left", "right", "slight left", etc.
  @override
  String? get name;

  /// Create a copy of RouteStep
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RouteStepImplCopyWith<_$RouteStepImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
