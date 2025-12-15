// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shift_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ShiftHistory _$ShiftHistoryFromJson(Map<String, dynamic> json) {
  return _ShiftHistory.fromJson(json);
}

/// @nodoc
mixin _$ShiftHistory {
  /// Shift ID
  @JsonKey(name: 'id')
  String get shiftId => throw _privateConstructorUsedError;

  /// Driver ID who completed this shift
  @JsonKey(name: 'driver_id')
  String get driverId => throw _privateConstructorUsedError;

  /// Route ID assigned to this shift
  @JsonKey(name: 'route_id')
  String? get routeId => throw _privateConstructorUsedError;

  /// Shift status
  ShiftStatus get status => throw _privateConstructorUsedError;

  /// When the shift started
  @JsonKey(name: 'start_time')
  @UnixTimestampConverter()
  DateTime? get startTime => throw _privateConstructorUsedError;

  /// When the shift ended
  @JsonKey(name: 'end_time')
  @UnixTimestampConverter()
  DateTime? get endTime => throw _privateConstructorUsedError;

  /// Total pause time in seconds
  @JsonKey(name: 'total_pause_seconds')
  int get totalPauseSeconds => throw _privateConstructorUsedError;

  /// Total bins in route
  @JsonKey(name: 'total_bins')
  int get totalBins => throw _privateConstructorUsedError;

  /// Completed bins count
  @JsonKey(name: 'completed_bins')
  int get completedBins => throw _privateConstructorUsedError;

  /// Created timestamp
  @JsonKey(name: 'created_at')
  int? get createdAt => throw _privateConstructorUsedError;

  /// Updated timestamp
  @JsonKey(name: 'updated_at')
  int? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ShiftHistory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShiftHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShiftHistoryCopyWith<ShiftHistory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShiftHistoryCopyWith<$Res> {
  factory $ShiftHistoryCopyWith(
    ShiftHistory value,
    $Res Function(ShiftHistory) then,
  ) = _$ShiftHistoryCopyWithImpl<$Res, ShiftHistory>;
  @useResult
  $Res call({
    @JsonKey(name: 'id') String shiftId,
    @JsonKey(name: 'driver_id') String driverId,
    @JsonKey(name: 'route_id') String? routeId,
    ShiftStatus status,
    @JsonKey(name: 'start_time') @UnixTimestampConverter() DateTime? startTime,
    @JsonKey(name: 'end_time') @UnixTimestampConverter() DateTime? endTime,
    @JsonKey(name: 'total_pause_seconds') int totalPauseSeconds,
    @JsonKey(name: 'total_bins') int totalBins,
    @JsonKey(name: 'completed_bins') int completedBins,
    @JsonKey(name: 'created_at') int? createdAt,
    @JsonKey(name: 'updated_at') int? updatedAt,
  });
}

/// @nodoc
class _$ShiftHistoryCopyWithImpl<$Res, $Val extends ShiftHistory>
    implements $ShiftHistoryCopyWith<$Res> {
  _$ShiftHistoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShiftHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shiftId = null,
    Object? driverId = null,
    Object? routeId = freezed,
    Object? status = null,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? totalPauseSeconds = null,
    Object? totalBins = null,
    Object? completedBins = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            shiftId: null == shiftId
                ? _value.shiftId
                : shiftId // ignore: cast_nullable_to_non_nullable
                      as String,
            driverId: null == driverId
                ? _value.driverId
                : driverId // ignore: cast_nullable_to_non_nullable
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
            endTime: freezed == endTime
                ? _value.endTime
                : endTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            totalPauseSeconds: null == totalPauseSeconds
                ? _value.totalPauseSeconds
                : totalPauseSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            totalBins: null == totalBins
                ? _value.totalBins
                : totalBins // ignore: cast_nullable_to_non_nullable
                      as int,
            completedBins: null == completedBins
                ? _value.completedBins
                : completedBins // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as int?,
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
abstract class _$$ShiftHistoryImplCopyWith<$Res>
    implements $ShiftHistoryCopyWith<$Res> {
  factory _$$ShiftHistoryImplCopyWith(
    _$ShiftHistoryImpl value,
    $Res Function(_$ShiftHistoryImpl) then,
  ) = __$$ShiftHistoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'id') String shiftId,
    @JsonKey(name: 'driver_id') String driverId,
    @JsonKey(name: 'route_id') String? routeId,
    ShiftStatus status,
    @JsonKey(name: 'start_time') @UnixTimestampConverter() DateTime? startTime,
    @JsonKey(name: 'end_time') @UnixTimestampConverter() DateTime? endTime,
    @JsonKey(name: 'total_pause_seconds') int totalPauseSeconds,
    @JsonKey(name: 'total_bins') int totalBins,
    @JsonKey(name: 'completed_bins') int completedBins,
    @JsonKey(name: 'created_at') int? createdAt,
    @JsonKey(name: 'updated_at') int? updatedAt,
  });
}

/// @nodoc
class __$$ShiftHistoryImplCopyWithImpl<$Res>
    extends _$ShiftHistoryCopyWithImpl<$Res, _$ShiftHistoryImpl>
    implements _$$ShiftHistoryImplCopyWith<$Res> {
  __$$ShiftHistoryImplCopyWithImpl(
    _$ShiftHistoryImpl _value,
    $Res Function(_$ShiftHistoryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ShiftHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shiftId = null,
    Object? driverId = null,
    Object? routeId = freezed,
    Object? status = null,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? totalPauseSeconds = null,
    Object? totalBins = null,
    Object? completedBins = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$ShiftHistoryImpl(
        shiftId: null == shiftId
            ? _value.shiftId
            : shiftId // ignore: cast_nullable_to_non_nullable
                  as String,
        driverId: null == driverId
            ? _value.driverId
            : driverId // ignore: cast_nullable_to_non_nullable
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
        endTime: freezed == endTime
            ? _value.endTime
            : endTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        totalPauseSeconds: null == totalPauseSeconds
            ? _value.totalPauseSeconds
            : totalPauseSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        totalBins: null == totalBins
            ? _value.totalBins
            : totalBins // ignore: cast_nullable_to_non_nullable
                  as int,
        completedBins: null == completedBins
            ? _value.completedBins
            : completedBins // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as int?,
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
class _$ShiftHistoryImpl extends _ShiftHistory {
  const _$ShiftHistoryImpl({
    @JsonKey(name: 'id') required this.shiftId,
    @JsonKey(name: 'driver_id') required this.driverId,
    @JsonKey(name: 'route_id') this.routeId,
    required this.status,
    @JsonKey(name: 'start_time') @UnixTimestampConverter() this.startTime,
    @JsonKey(name: 'end_time') @UnixTimestampConverter() this.endTime,
    @JsonKey(name: 'total_pause_seconds') this.totalPauseSeconds = 0,
    @JsonKey(name: 'total_bins') this.totalBins = 0,
    @JsonKey(name: 'completed_bins') this.completedBins = 0,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  }) : super._();

  factory _$ShiftHistoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShiftHistoryImplFromJson(json);

  /// Shift ID
  @override
  @JsonKey(name: 'id')
  final String shiftId;

  /// Driver ID who completed this shift
  @override
  @JsonKey(name: 'driver_id')
  final String driverId;

  /// Route ID assigned to this shift
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

  /// When the shift ended
  @override
  @JsonKey(name: 'end_time')
  @UnixTimestampConverter()
  final DateTime? endTime;

  /// Total pause time in seconds
  @override
  @JsonKey(name: 'total_pause_seconds')
  final int totalPauseSeconds;

  /// Total bins in route
  @override
  @JsonKey(name: 'total_bins')
  final int totalBins;

  /// Completed bins count
  @override
  @JsonKey(name: 'completed_bins')
  final int completedBins;

  /// Created timestamp
  @override
  @JsonKey(name: 'created_at')
  final int? createdAt;

  /// Updated timestamp
  @override
  @JsonKey(name: 'updated_at')
  final int? updatedAt;

  @override
  String toString() {
    return 'ShiftHistory(shiftId: $shiftId, driverId: $driverId, routeId: $routeId, status: $status, startTime: $startTime, endTime: $endTime, totalPauseSeconds: $totalPauseSeconds, totalBins: $totalBins, completedBins: $completedBins, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShiftHistoryImpl &&
            (identical(other.shiftId, shiftId) || other.shiftId == shiftId) &&
            (identical(other.driverId, driverId) ||
                other.driverId == driverId) &&
            (identical(other.routeId, routeId) || other.routeId == routeId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.totalPauseSeconds, totalPauseSeconds) ||
                other.totalPauseSeconds == totalPauseSeconds) &&
            (identical(other.totalBins, totalBins) ||
                other.totalBins == totalBins) &&
            (identical(other.completedBins, completedBins) ||
                other.completedBins == completedBins) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    shiftId,
    driverId,
    routeId,
    status,
    startTime,
    endTime,
    totalPauseSeconds,
    totalBins,
    completedBins,
    createdAt,
    updatedAt,
  );

  /// Create a copy of ShiftHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShiftHistoryImplCopyWith<_$ShiftHistoryImpl> get copyWith =>
      __$$ShiftHistoryImplCopyWithImpl<_$ShiftHistoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShiftHistoryImplToJson(this);
  }
}

abstract class _ShiftHistory extends ShiftHistory {
  const factory _ShiftHistory({
    @JsonKey(name: 'id') required final String shiftId,
    @JsonKey(name: 'driver_id') required final String driverId,
    @JsonKey(name: 'route_id') final String? routeId,
    required final ShiftStatus status,
    @JsonKey(name: 'start_time')
    @UnixTimestampConverter()
    final DateTime? startTime,
    @JsonKey(name: 'end_time')
    @UnixTimestampConverter()
    final DateTime? endTime,
    @JsonKey(name: 'total_pause_seconds') final int totalPauseSeconds,
    @JsonKey(name: 'total_bins') final int totalBins,
    @JsonKey(name: 'completed_bins') final int completedBins,
    @JsonKey(name: 'created_at') final int? createdAt,
    @JsonKey(name: 'updated_at') final int? updatedAt,
  }) = _$ShiftHistoryImpl;
  const _ShiftHistory._() : super._();

  factory _ShiftHistory.fromJson(Map<String, dynamic> json) =
      _$ShiftHistoryImpl.fromJson;

  /// Shift ID
  @override
  @JsonKey(name: 'id')
  String get shiftId;

  /// Driver ID who completed this shift
  @override
  @JsonKey(name: 'driver_id')
  String get driverId;

  /// Route ID assigned to this shift
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

  /// When the shift ended
  @override
  @JsonKey(name: 'end_time')
  @UnixTimestampConverter()
  DateTime? get endTime;

  /// Total pause time in seconds
  @override
  @JsonKey(name: 'total_pause_seconds')
  int get totalPauseSeconds;

  /// Total bins in route
  @override
  @JsonKey(name: 'total_bins')
  int get totalBins;

  /// Completed bins count
  @override
  @JsonKey(name: 'completed_bins')
  int get completedBins;

  /// Created timestamp
  @override
  @JsonKey(name: 'created_at')
  int? get createdAt;

  /// Updated timestamp
  @override
  @JsonKey(name: 'updated_at')
  int? get updatedAt;

  /// Create a copy of ShiftHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShiftHistoryImplCopyWith<_$ShiftHistoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
