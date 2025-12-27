// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'driver_location.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DriverLocation _$DriverLocationFromJson(Map<String, dynamic> json) {
  return _DriverLocation.fromJson(json);
}

/// @nodoc
mixin _$DriverLocation {
  @JsonKey(name: 'driver_id')
  String? get driverId => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  double? get heading =>
      throw _privateConstructorUsedError; // Direction of travel (0-360 degrees)
  double? get speed => throw _privateConstructorUsedError; // Speed in m/s
  double? get accuracy =>
      throw _privateConstructorUsedError; // GPS accuracy in meters
  @JsonKey(name: 'shift_id')
  String? get shiftId => throw _privateConstructorUsedError;
  int? get timestamp =>
      throw _privateConstructorUsedError; // Client-side timestamp (milliseconds)
  @JsonKey(name: 'is_connected')
  bool? get isConnected => throw _privateConstructorUsedError; // WebSocket connection status (null = connected for broadcasts)
  @JsonKey(name: 'updated_at')
  int? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this DriverLocation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DriverLocation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DriverLocationCopyWith<DriverLocation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DriverLocationCopyWith<$Res> {
  factory $DriverLocationCopyWith(
    DriverLocation value,
    $Res Function(DriverLocation) then,
  ) = _$DriverLocationCopyWithImpl<$Res, DriverLocation>;
  @useResult
  $Res call({
    @JsonKey(name: 'driver_id') String? driverId,
    double latitude,
    double longitude,
    double? heading,
    double? speed,
    double? accuracy,
    @JsonKey(name: 'shift_id') String? shiftId,
    int? timestamp,
    @JsonKey(name: 'is_connected') bool? isConnected,
    @JsonKey(name: 'updated_at') int? updatedAt,
  });
}

/// @nodoc
class _$DriverLocationCopyWithImpl<$Res, $Val extends DriverLocation>
    implements $DriverLocationCopyWith<$Res> {
  _$DriverLocationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DriverLocation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? driverId = freezed,
    Object? latitude = null,
    Object? longitude = null,
    Object? heading = freezed,
    Object? speed = freezed,
    Object? accuracy = freezed,
    Object? shiftId = freezed,
    Object? timestamp = freezed,
    Object? isConnected = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            driverId: freezed == driverId
                ? _value.driverId
                : driverId // ignore: cast_nullable_to_non_nullable
                      as String?,
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
            heading: freezed == heading
                ? _value.heading
                : heading // ignore: cast_nullable_to_non_nullable
                      as double?,
            speed: freezed == speed
                ? _value.speed
                : speed // ignore: cast_nullable_to_non_nullable
                      as double?,
            accuracy: freezed == accuracy
                ? _value.accuracy
                : accuracy // ignore: cast_nullable_to_non_nullable
                      as double?,
            shiftId: freezed == shiftId
                ? _value.shiftId
                : shiftId // ignore: cast_nullable_to_non_nullable
                      as String?,
            timestamp: freezed == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as int?,
            isConnected: freezed == isConnected
                ? _value.isConnected
                : isConnected // ignore: cast_nullable_to_non_nullable
                      as bool?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DriverLocationImplCopyWith<$Res>
    implements $DriverLocationCopyWith<$Res> {
  factory _$$DriverLocationImplCopyWith(
    _$DriverLocationImpl value,
    $Res Function(_$DriverLocationImpl) then,
  ) = __$$DriverLocationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'driver_id') String? driverId,
    double latitude,
    double longitude,
    double? heading,
    double? speed,
    double? accuracy,
    @JsonKey(name: 'shift_id') String? shiftId,
    int? timestamp,
    @JsonKey(name: 'is_connected') bool? isConnected,
    @JsonKey(name: 'updated_at') int? updatedAt,
  });
}

/// @nodoc
class __$$DriverLocationImplCopyWithImpl<$Res>
    extends _$DriverLocationCopyWithImpl<$Res, _$DriverLocationImpl>
    implements _$$DriverLocationImplCopyWith<$Res> {
  __$$DriverLocationImplCopyWithImpl(
    _$DriverLocationImpl _value,
    $Res Function(_$DriverLocationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DriverLocation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? driverId = freezed,
    Object? latitude = null,
    Object? longitude = null,
    Object? heading = freezed,
    Object? speed = freezed,
    Object? accuracy = freezed,
    Object? shiftId = freezed,
    Object? timestamp = freezed,
    Object? isConnected = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$DriverLocationImpl(
        driverId: freezed == driverId
            ? _value.driverId
            : driverId // ignore: cast_nullable_to_non_nullable
                  as String?,
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
        heading: freezed == heading
            ? _value.heading
            : heading // ignore: cast_nullable_to_non_nullable
                  as double?,
        speed: freezed == speed
            ? _value.speed
            : speed // ignore: cast_nullable_to_non_nullable
                  as double?,
        accuracy: freezed == accuracy
            ? _value.accuracy
            : accuracy // ignore: cast_nullable_to_non_nullable
                  as double?,
        shiftId: freezed == shiftId
            ? _value.shiftId
            : shiftId // ignore: cast_nullable_to_non_nullable
                  as String?,
        timestamp: freezed == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as int?,
        isConnected: freezed == isConnected
            ? _value.isConnected
            : isConnected // ignore: cast_nullable_to_non_nullable
                  as bool?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DriverLocationImpl implements _DriverLocation {
  const _$DriverLocationImpl({
    @JsonKey(name: 'driver_id') this.driverId,
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    this.accuracy,
    @JsonKey(name: 'shift_id') this.shiftId,
    this.timestamp,
    @JsonKey(name: 'is_connected') this.isConnected = true,
    @JsonKey(name: 'updated_at') this.updatedAt,
  });

  factory _$DriverLocationImpl.fromJson(Map<String, dynamic> json) =>
      _$$DriverLocationImplFromJson(json);

  @override
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final double? heading;
  // Direction of travel (0-360 degrees)
  @override
  final double? speed;
  // Speed in m/s
  @override
  final double? accuracy;
  // GPS accuracy in meters
  @override
  @JsonKey(name: 'shift_id')
  final String? shiftId;
  @override
  final int? timestamp;
  // Client-side timestamp (milliseconds)
  @override
  @JsonKey(name: 'is_connected')
  final bool? isConnected;
  // WebSocket connection status (null = connected for broadcasts)
  @override
  @JsonKey(name: 'updated_at')
  final int? updatedAt;

  @override
  String toString() {
    return 'DriverLocation(driverId: $driverId, latitude: $latitude, longitude: $longitude, heading: $heading, speed: $speed, accuracy: $accuracy, shiftId: $shiftId, timestamp: $timestamp, isConnected: $isConnected, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DriverLocationImpl &&
            (identical(other.driverId, driverId) ||
                other.driverId == driverId) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.heading, heading) || other.heading == heading) &&
            (identical(other.speed, speed) || other.speed == speed) &&
            (identical(other.accuracy, accuracy) ||
                other.accuracy == accuracy) &&
            (identical(other.shiftId, shiftId) || other.shiftId == shiftId) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.isConnected, isConnected) ||
                other.isConnected == isConnected) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    driverId,
    latitude,
    longitude,
    heading,
    speed,
    accuracy,
    shiftId,
    timestamp,
    isConnected,
    updatedAt,
  );

  /// Create a copy of DriverLocation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DriverLocationImplCopyWith<_$DriverLocationImpl> get copyWith =>
      __$$DriverLocationImplCopyWithImpl<_$DriverLocationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DriverLocationImplToJson(this);
  }
}

abstract class _DriverLocation implements DriverLocation {
  const factory _DriverLocation({
    @JsonKey(name: 'driver_id') final String? driverId,
    required final double latitude,
    required final double longitude,
    final double? heading,
    final double? speed,
    final double? accuracy,
    @JsonKey(name: 'shift_id') final String? shiftId,
    final int? timestamp,
    @JsonKey(name: 'is_connected') final bool? isConnected,
    @JsonKey(name: 'updated_at') final int? updatedAt,
  }) = _$DriverLocationImpl;

  factory _DriverLocation.fromJson(Map<String, dynamic> json) =
      _$DriverLocationImpl.fromJson;

  @override
  @JsonKey(name: 'driver_id')
  String? get driverId;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  double? get heading; // Direction of travel (0-360 degrees)
  @override
  double? get speed; // Speed in m/s
  @override
  double? get accuracy; // GPS accuracy in meters
  @override
  @JsonKey(name: 'shift_id')
  String? get shiftId;
  @override
  int? get timestamp; // Client-side timestamp (milliseconds)
  @override
  @JsonKey(name: 'is_connected')
  bool? get isConnected; // WebSocket connection status (null = connected for broadcasts)
  @override
  @JsonKey(name: 'updated_at')
  int? get updatedAt;

  /// Create a copy of DriverLocation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DriverLocationImplCopyWith<_$DriverLocationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
