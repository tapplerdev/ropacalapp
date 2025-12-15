// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'active_driver.dart';

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
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;

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
  $Res call({double latitude, double longitude});
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
  $Res call({Object? latitude = null, Object? longitude = null}) {
    return _then(
      _value.copyWith(
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
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
  $Res call({double latitude, double longitude});
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
  $Res call({Object? latitude = null, Object? longitude = null}) {
    return _then(
      _$DriverLocationImpl(
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DriverLocationImpl implements _DriverLocation {
  const _$DriverLocationImpl({required this.latitude, required this.longitude});

  factory _$DriverLocationImpl.fromJson(Map<String, dynamic> json) =>
      _$$DriverLocationImplFromJson(json);

  @override
  final double latitude;
  @override
  final double longitude;

  @override
  String toString() {
    return 'DriverLocation(latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DriverLocationImpl &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, latitude, longitude);

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
    required final double latitude,
    required final double longitude,
  }) = _$DriverLocationImpl;

  factory _DriverLocation.fromJson(Map<String, dynamic> json) =
      _$DriverLocationImpl.fromJson;

  @override
  double get latitude;
  @override
  double get longitude;

  /// Create a copy of DriverLocation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DriverLocationImplCopyWith<_$DriverLocationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ActiveDriver _$ActiveDriverFromJson(Map<String, dynamic> json) {
  return _ActiveDriver.fromJson(json);
}

/// @nodoc
mixin _$ActiveDriver {
  /// Driver ID
  @JsonKey(name: 'driver_id')
  String get driverId => throw _privateConstructorUsedError;

  /// Driver name
  @JsonKey(name: 'driver_name')
  String get driverName => throw _privateConstructorUsedError;

  /// Shift ID
  @JsonKey(name: 'shift_id')
  String get shiftId => throw _privateConstructorUsedError;

  /// Assigned route ID
  @JsonKey(name: 'route_id')
  String? get routeId => throw _privateConstructorUsedError;

  /// Shift status
  ShiftStatus get status => throw _privateConstructorUsedError;

  /// When the shift started
  @JsonKey(name: 'start_time')
  @UnixTimestampConverter()
  DateTime? get startTime => throw _privateConstructorUsedError;

  /// Total bins in route
  @JsonKey(name: 'total_bins')
  int get totalBins => throw _privateConstructorUsedError;

  /// Completed bins count
  @JsonKey(name: 'completed_bins')
  int get completedBins => throw _privateConstructorUsedError;

  /// Driver's current GPS location
  @JsonKey(name: 'current_location')
  DriverLocation? get currentLocation => throw _privateConstructorUsedError;

  /// Last updated timestamp
  @JsonKey(name: 'updated_at')
  int? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ActiveDriver to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ActiveDriver
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActiveDriverCopyWith<ActiveDriver> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActiveDriverCopyWith<$Res> {
  factory $ActiveDriverCopyWith(
    ActiveDriver value,
    $Res Function(ActiveDriver) then,
  ) = _$ActiveDriverCopyWithImpl<$Res, ActiveDriver>;
  @useResult
  $Res call({
    @JsonKey(name: 'driver_id') String driverId,
    @JsonKey(name: 'driver_name') String driverName,
    @JsonKey(name: 'shift_id') String shiftId,
    @JsonKey(name: 'route_id') String? routeId,
    ShiftStatus status,
    @JsonKey(name: 'start_time') @UnixTimestampConverter() DateTime? startTime,
    @JsonKey(name: 'total_bins') int totalBins,
    @JsonKey(name: 'completed_bins') int completedBins,
    @JsonKey(name: 'current_location') DriverLocation? currentLocation,
    @JsonKey(name: 'updated_at') int? updatedAt,
  });

  $DriverLocationCopyWith<$Res>? get currentLocation;
}

/// @nodoc
class _$ActiveDriverCopyWithImpl<$Res, $Val extends ActiveDriver>
    implements $ActiveDriverCopyWith<$Res> {
  _$ActiveDriverCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActiveDriver
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? driverId = null,
    Object? driverName = null,
    Object? shiftId = null,
    Object? routeId = freezed,
    Object? status = null,
    Object? startTime = freezed,
    Object? totalBins = null,
    Object? completedBins = null,
    Object? currentLocation = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            driverId: null == driverId
                ? _value.driverId
                : driverId // ignore: cast_nullable_to_non_nullable
                      as String,
            driverName: null == driverName
                ? _value.driverName
                : driverName // ignore: cast_nullable_to_non_nullable
                      as String,
            shiftId: null == shiftId
                ? _value.shiftId
                : shiftId // ignore: cast_nullable_to_non_nullable
                      as String,
            routeId: freezed == routeId
                ? _value.routeId
                : routeId // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ShiftStatus,
            startTime: freezed == startTime
                ? _value.startTime
                : startTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            totalBins: null == totalBins
                ? _value.totalBins
                : totalBins // ignore: cast_nullable_to_non_nullable
                      as int,
            completedBins: null == completedBins
                ? _value.completedBins
                : completedBins // ignore: cast_nullable_to_non_nullable
                      as int,
            currentLocation: freezed == currentLocation
                ? _value.currentLocation
                : currentLocation // ignore: cast_nullable_to_non_nullable
                      as DriverLocation?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }

  /// Create a copy of ActiveDriver
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DriverLocationCopyWith<$Res>? get currentLocation {
    if (_value.currentLocation == null) {
      return null;
    }

    return $DriverLocationCopyWith<$Res>(_value.currentLocation!, (value) {
      return _then(_value.copyWith(currentLocation: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ActiveDriverImplCopyWith<$Res>
    implements $ActiveDriverCopyWith<$Res> {
  factory _$$ActiveDriverImplCopyWith(
    _$ActiveDriverImpl value,
    $Res Function(_$ActiveDriverImpl) then,
  ) = __$$ActiveDriverImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'driver_id') String driverId,
    @JsonKey(name: 'driver_name') String driverName,
    @JsonKey(name: 'shift_id') String shiftId,
    @JsonKey(name: 'route_id') String? routeId,
    ShiftStatus status,
    @JsonKey(name: 'start_time') @UnixTimestampConverter() DateTime? startTime,
    @JsonKey(name: 'total_bins') int totalBins,
    @JsonKey(name: 'completed_bins') int completedBins,
    @JsonKey(name: 'current_location') DriverLocation? currentLocation,
    @JsonKey(name: 'updated_at') int? updatedAt,
  });

  @override
  $DriverLocationCopyWith<$Res>? get currentLocation;
}

/// @nodoc
class __$$ActiveDriverImplCopyWithImpl<$Res>
    extends _$ActiveDriverCopyWithImpl<$Res, _$ActiveDriverImpl>
    implements _$$ActiveDriverImplCopyWith<$Res> {
  __$$ActiveDriverImplCopyWithImpl(
    _$ActiveDriverImpl _value,
    $Res Function(_$ActiveDriverImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ActiveDriver
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? driverId = null,
    Object? driverName = null,
    Object? shiftId = null,
    Object? routeId = freezed,
    Object? status = null,
    Object? startTime = freezed,
    Object? totalBins = null,
    Object? completedBins = null,
    Object? currentLocation = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$ActiveDriverImpl(
        driverId: null == driverId
            ? _value.driverId
            : driverId // ignore: cast_nullable_to_non_nullable
                  as String,
        driverName: null == driverName
            ? _value.driverName
            : driverName // ignore: cast_nullable_to_non_nullable
                  as String,
        shiftId: null == shiftId
            ? _value.shiftId
            : shiftId // ignore: cast_nullable_to_non_nullable
                  as String,
        routeId: freezed == routeId
            ? _value.routeId
            : routeId // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ShiftStatus,
        startTime: freezed == startTime
            ? _value.startTime
            : startTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        totalBins: null == totalBins
            ? _value.totalBins
            : totalBins // ignore: cast_nullable_to_non_nullable
                  as int,
        completedBins: null == completedBins
            ? _value.completedBins
            : completedBins // ignore: cast_nullable_to_non_nullable
                  as int,
        currentLocation: freezed == currentLocation
            ? _value.currentLocation
            : currentLocation // ignore: cast_nullable_to_non_nullable
                  as DriverLocation?,
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
class _$ActiveDriverImpl extends _ActiveDriver {
  const _$ActiveDriverImpl({
    @JsonKey(name: 'driver_id') required this.driverId,
    @JsonKey(name: 'driver_name') required this.driverName,
    @JsonKey(name: 'shift_id') required this.shiftId,
    @JsonKey(name: 'route_id') this.routeId,
    required this.status,
    @JsonKey(name: 'start_time') @UnixTimestampConverter() this.startTime,
    @JsonKey(name: 'total_bins') this.totalBins = 0,
    @JsonKey(name: 'completed_bins') this.completedBins = 0,
    @JsonKey(name: 'current_location') this.currentLocation,
    @JsonKey(name: 'updated_at') this.updatedAt,
  }) : super._();

  factory _$ActiveDriverImpl.fromJson(Map<String, dynamic> json) =>
      _$$ActiveDriverImplFromJson(json);

  /// Driver ID
  @override
  @JsonKey(name: 'driver_id')
  final String driverId;

  /// Driver name
  @override
  @JsonKey(name: 'driver_name')
  final String driverName;

  /// Shift ID
  @override
  @JsonKey(name: 'shift_id')
  final String shiftId;

  /// Assigned route ID
  @override
  @JsonKey(name: 'route_id')
  final String? routeId;

  /// Shift status
  @override
  final ShiftStatus status;

  /// When the shift started
  @override
  @JsonKey(name: 'start_time')
  @UnixTimestampConverter()
  final DateTime? startTime;

  /// Total bins in route
  @override
  @JsonKey(name: 'total_bins')
  final int totalBins;

  /// Completed bins count
  @override
  @JsonKey(name: 'completed_bins')
  final int completedBins;

  /// Driver's current GPS location
  @override
  @JsonKey(name: 'current_location')
  final DriverLocation? currentLocation;

  /// Last updated timestamp
  @override
  @JsonKey(name: 'updated_at')
  final int? updatedAt;

  @override
  String toString() {
    return 'ActiveDriver(driverId: $driverId, driverName: $driverName, shiftId: $shiftId, routeId: $routeId, status: $status, startTime: $startTime, totalBins: $totalBins, completedBins: $completedBins, currentLocation: $currentLocation, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActiveDriverImpl &&
            (identical(other.driverId, driverId) ||
                other.driverId == driverId) &&
            (identical(other.driverName, driverName) ||
                other.driverName == driverName) &&
            (identical(other.shiftId, shiftId) || other.shiftId == shiftId) &&
            (identical(other.routeId, routeId) || other.routeId == routeId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.totalBins, totalBins) ||
                other.totalBins == totalBins) &&
            (identical(other.completedBins, completedBins) ||
                other.completedBins == completedBins) &&
            (identical(other.currentLocation, currentLocation) ||
                other.currentLocation == currentLocation) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    driverId,
    driverName,
    shiftId,
    routeId,
    status,
    startTime,
    totalBins,
    completedBins,
    currentLocation,
    updatedAt,
  );

  /// Create a copy of ActiveDriver
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActiveDriverImplCopyWith<_$ActiveDriverImpl> get copyWith =>
      __$$ActiveDriverImplCopyWithImpl<_$ActiveDriverImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ActiveDriverImplToJson(this);
  }
}

abstract class _ActiveDriver extends ActiveDriver {
  const factory _ActiveDriver({
    @JsonKey(name: 'driver_id') required final String driverId,
    @JsonKey(name: 'driver_name') required final String driverName,
    @JsonKey(name: 'shift_id') required final String shiftId,
    @JsonKey(name: 'route_id') final String? routeId,
    required final ShiftStatus status,
    @JsonKey(name: 'start_time')
    @UnixTimestampConverter()
    final DateTime? startTime,
    @JsonKey(name: 'total_bins') final int totalBins,
    @JsonKey(name: 'completed_bins') final int completedBins,
    @JsonKey(name: 'current_location') final DriverLocation? currentLocation,
    @JsonKey(name: 'updated_at') final int? updatedAt,
  }) = _$ActiveDriverImpl;
  const _ActiveDriver._() : super._();

  factory _ActiveDriver.fromJson(Map<String, dynamic> json) =
      _$ActiveDriverImpl.fromJson;

  /// Driver ID
  @override
  @JsonKey(name: 'driver_id')
  String get driverId;

  /// Driver name
  @override
  @JsonKey(name: 'driver_name')
  String get driverName;

  /// Shift ID
  @override
  @JsonKey(name: 'shift_id')
  String get shiftId;

  /// Assigned route ID
  @override
  @JsonKey(name: 'route_id')
  String? get routeId;

  /// Shift status
  @override
  ShiftStatus get status;

  /// When the shift started
  @override
  @JsonKey(name: 'start_time')
  @UnixTimestampConverter()
  DateTime? get startTime;

  /// Total bins in route
  @override
  @JsonKey(name: 'total_bins')
  int get totalBins;

  /// Completed bins count
  @override
  @JsonKey(name: 'completed_bins')
  int get completedBins;

  /// Driver's current GPS location
  @override
  @JsonKey(name: 'current_location')
  DriverLocation? get currentLocation;

  /// Last updated timestamp
  @override
  @JsonKey(name: 'updated_at')
  int? get updatedAt;

  /// Create a copy of ActiveDriver
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActiveDriverImplCopyWith<_$ActiveDriverImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
