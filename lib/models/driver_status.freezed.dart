// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'driver_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DriverStatus _$DriverStatusFromJson(Map<String, dynamic> json) {
  return _DriverStatus.fromJson(json);
}

/// @nodoc
mixin _$DriverStatus {
  @JsonKey(name: 'driver_id')
  String get driverId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  ShiftStatus get status =>
      throw _privateConstructorUsedError; // active, paused, ready, etc.
  @JsonKey(name: 'shift_id')
  String? get shiftId => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_bin')
  int? get currentBin => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_bins')
  int? get totalBins => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_location')
  DriverLocation? get lastLocation => throw _privateConstructorUsedError;

  /// Serializes this DriverStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DriverStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DriverStatusCopyWith<DriverStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DriverStatusCopyWith<$Res> {
  factory $DriverStatusCopyWith(
    DriverStatus value,
    $Res Function(DriverStatus) then,
  ) = _$DriverStatusCopyWithImpl<$Res, DriverStatus>;
  @useResult
  $Res call({
    @JsonKey(name: 'driver_id') String driverId,
    String name,
    ShiftStatus status,
    @JsonKey(name: 'shift_id') String? shiftId,
    @JsonKey(name: 'current_bin') int? currentBin,
    @JsonKey(name: 'total_bins') int? totalBins,
    @JsonKey(name: 'last_location') DriverLocation? lastLocation,
  });

  $DriverLocationCopyWith<$Res>? get lastLocation;
}

/// @nodoc
class _$DriverStatusCopyWithImpl<$Res, $Val extends DriverStatus>
    implements $DriverStatusCopyWith<$Res> {
  _$DriverStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DriverStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? driverId = null,
    Object? name = null,
    Object? status = null,
    Object? shiftId = freezed,
    Object? currentBin = freezed,
    Object? totalBins = freezed,
    Object? lastLocation = freezed,
  }) {
    return _then(
      _value.copyWith(
            driverId: null == driverId
                ? _value.driverId
                : driverId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ShiftStatus,
            shiftId: freezed == shiftId
                ? _value.shiftId
                : shiftId // ignore: cast_nullable_to_non_nullable
                      as String?,
            currentBin: freezed == currentBin
                ? _value.currentBin
                : currentBin // ignore: cast_nullable_to_non_nullable
                      as int?,
            totalBins: freezed == totalBins
                ? _value.totalBins
                : totalBins // ignore: cast_nullable_to_non_nullable
                      as int?,
            lastLocation: freezed == lastLocation
                ? _value.lastLocation
                : lastLocation // ignore: cast_nullable_to_non_nullable
                      as DriverLocation?,
          )
          as $Val,
    );
  }

  /// Create a copy of DriverStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DriverLocationCopyWith<$Res>? get lastLocation {
    if (_value.lastLocation == null) {
      return null;
    }

    return $DriverLocationCopyWith<$Res>(_value.lastLocation!, (value) {
      return _then(_value.copyWith(lastLocation: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DriverStatusImplCopyWith<$Res>
    implements $DriverStatusCopyWith<$Res> {
  factory _$$DriverStatusImplCopyWith(
    _$DriverStatusImpl value,
    $Res Function(_$DriverStatusImpl) then,
  ) = __$$DriverStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'driver_id') String driverId,
    String name,
    ShiftStatus status,
    @JsonKey(name: 'shift_id') String? shiftId,
    @JsonKey(name: 'current_bin') int? currentBin,
    @JsonKey(name: 'total_bins') int? totalBins,
    @JsonKey(name: 'last_location') DriverLocation? lastLocation,
  });

  @override
  $DriverLocationCopyWith<$Res>? get lastLocation;
}

/// @nodoc
class __$$DriverStatusImplCopyWithImpl<$Res>
    extends _$DriverStatusCopyWithImpl<$Res, _$DriverStatusImpl>
    implements _$$DriverStatusImplCopyWith<$Res> {
  __$$DriverStatusImplCopyWithImpl(
    _$DriverStatusImpl _value,
    $Res Function(_$DriverStatusImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DriverStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? driverId = null,
    Object? name = null,
    Object? status = null,
    Object? shiftId = freezed,
    Object? currentBin = freezed,
    Object? totalBins = freezed,
    Object? lastLocation = freezed,
  }) {
    return _then(
      _$DriverStatusImpl(
        driverId: null == driverId
            ? _value.driverId
            : driverId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ShiftStatus,
        shiftId: freezed == shiftId
            ? _value.shiftId
            : shiftId // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentBin: freezed == currentBin
            ? _value.currentBin
            : currentBin // ignore: cast_nullable_to_non_nullable
                  as int?,
        totalBins: freezed == totalBins
            ? _value.totalBins
            : totalBins // ignore: cast_nullable_to_non_nullable
                  as int?,
        lastLocation: freezed == lastLocation
            ? _value.lastLocation
            : lastLocation // ignore: cast_nullable_to_non_nullable
                  as DriverLocation?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DriverStatusImpl implements _DriverStatus {
  const _$DriverStatusImpl({
    @JsonKey(name: 'driver_id') required this.driverId,
    required this.name,
    required this.status,
    @JsonKey(name: 'shift_id') this.shiftId,
    @JsonKey(name: 'current_bin') this.currentBin = 0,
    @JsonKey(name: 'total_bins') this.totalBins = 0,
    @JsonKey(name: 'last_location') this.lastLocation,
  });

  factory _$DriverStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$DriverStatusImplFromJson(json);

  @override
  @JsonKey(name: 'driver_id')
  final String driverId;
  @override
  final String name;
  @override
  final ShiftStatus status;
  // active, paused, ready, etc.
  @override
  @JsonKey(name: 'shift_id')
  final String? shiftId;
  @override
  @JsonKey(name: 'current_bin')
  final int? currentBin;
  @override
  @JsonKey(name: 'total_bins')
  final int? totalBins;
  @override
  @JsonKey(name: 'last_location')
  final DriverLocation? lastLocation;

  @override
  String toString() {
    return 'DriverStatus(driverId: $driverId, name: $name, status: $status, shiftId: $shiftId, currentBin: $currentBin, totalBins: $totalBins, lastLocation: $lastLocation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DriverStatusImpl &&
            (identical(other.driverId, driverId) ||
                other.driverId == driverId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.shiftId, shiftId) || other.shiftId == shiftId) &&
            (identical(other.currentBin, currentBin) ||
                other.currentBin == currentBin) &&
            (identical(other.totalBins, totalBins) ||
                other.totalBins == totalBins) &&
            (identical(other.lastLocation, lastLocation) ||
                other.lastLocation == lastLocation));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    driverId,
    name,
    status,
    shiftId,
    currentBin,
    totalBins,
    lastLocation,
  );

  /// Create a copy of DriverStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DriverStatusImplCopyWith<_$DriverStatusImpl> get copyWith =>
      __$$DriverStatusImplCopyWithImpl<_$DriverStatusImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DriverStatusImplToJson(this);
  }
}

abstract class _DriverStatus implements DriverStatus {
  const factory _DriverStatus({
    @JsonKey(name: 'driver_id') required final String driverId,
    required final String name,
    required final ShiftStatus status,
    @JsonKey(name: 'shift_id') final String? shiftId,
    @JsonKey(name: 'current_bin') final int? currentBin,
    @JsonKey(name: 'total_bins') final int? totalBins,
    @JsonKey(name: 'last_location') final DriverLocation? lastLocation,
  }) = _$DriverStatusImpl;

  factory _DriverStatus.fromJson(Map<String, dynamic> json) =
      _$DriverStatusImpl.fromJson;

  @override
  @JsonKey(name: 'driver_id')
  String get driverId;
  @override
  String get name;
  @override
  ShiftStatus get status; // active, paused, ready, etc.
  @override
  @JsonKey(name: 'shift_id')
  String? get shiftId;
  @override
  @JsonKey(name: 'current_bin')
  int? get currentBin;
  @override
  @JsonKey(name: 'total_bins')
  int? get totalBins;
  @override
  @JsonKey(name: 'last_location')
  DriverLocation? get lastLocation;

  /// Create a copy of DriverStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DriverStatusImplCopyWith<_$DriverStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
