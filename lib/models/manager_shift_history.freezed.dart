// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'manager_shift_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ManagerShiftHistory _$ManagerShiftHistoryFromJson(Map<String, dynamic> json) {
  return _ManagerShiftHistory.fromJson(json);
}

/// @nodoc
mixin _$ManagerShiftHistory {
  @JsonKey(name: 'id')
  String get shiftId => throw _privateConstructorUsedError;
  @JsonKey(name: 'driver_id')
  String get driverId => throw _privateConstructorUsedError;
  @JsonKey(name: 'driver_name')
  String get driverName => throw _privateConstructorUsedError;
  @JsonKey(name: 'driver_email')
  String get driverEmail => throw _privateConstructorUsedError;
  @JsonKey(name: 'route_id')
  String? get routeId => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_time')
  @UnixTimestampConverter()
  DateTime? get startTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'end_time')
  @UnixTimestampConverter()
  DateTime? get endTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  int? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'ended_at')
  int? get endedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_pause_seconds')
  int get totalPauseSeconds => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_bins')
  int get totalBins => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_bins')
  int get completedBins => throw _privateConstructorUsedError;
  @JsonKey(name: 'completion_rate')
  double get completionRate => throw _privateConstructorUsedError;
  @JsonKey(name: 'incidents_reported')
  int get incidentsReported => throw _privateConstructorUsedError;
  @JsonKey(name: 'field_observations')
  int get fieldObservations => throw _privateConstructorUsedError;
  @JsonKey(name: 'end_reason')
  String get endReason => throw _privateConstructorUsedError;
  @JsonKey(name: 'collections_completed')
  int get collectionsCompleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'collections_skipped')
  int get collectionsSkipped => throw _privateConstructorUsedError;
  @JsonKey(name: 'placements_completed')
  int get placementsCompleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'placements_skipped')
  int get placementsSkipped => throw _privateConstructorUsedError;
  @JsonKey(name: 'move_requests_completed')
  int get moveRequestsCompleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_skipped')
  int get totalSkipped => throw _privateConstructorUsedError;
  @JsonKey(name: 'warehouse_stops')
  int get warehouseStops => throw _privateConstructorUsedError;

  /// Serializes this ManagerShiftHistory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ManagerShiftHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ManagerShiftHistoryCopyWith<ManagerShiftHistory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ManagerShiftHistoryCopyWith<$Res> {
  factory $ManagerShiftHistoryCopyWith(
    ManagerShiftHistory value,
    $Res Function(ManagerShiftHistory) then,
  ) = _$ManagerShiftHistoryCopyWithImpl<$Res, ManagerShiftHistory>;
  @useResult
  $Res call({
    @JsonKey(name: 'id') String shiftId,
    @JsonKey(name: 'driver_id') String driverId,
    @JsonKey(name: 'driver_name') String driverName,
    @JsonKey(name: 'driver_email') String driverEmail,
    @JsonKey(name: 'route_id') String? routeId,
    @JsonKey(name: 'start_time') @UnixTimestampConverter() DateTime? startTime,
    @JsonKey(name: 'end_time') @UnixTimestampConverter() DateTime? endTime,
    @JsonKey(name: 'created_at') int? createdAt,
    @JsonKey(name: 'ended_at') int? endedAt,
    @JsonKey(name: 'total_pause_seconds') int totalPauseSeconds,
    @JsonKey(name: 'total_bins') int totalBins,
    @JsonKey(name: 'completed_bins') int completedBins,
    @JsonKey(name: 'completion_rate') double completionRate,
    @JsonKey(name: 'incidents_reported') int incidentsReported,
    @JsonKey(name: 'field_observations') int fieldObservations,
    @JsonKey(name: 'end_reason') String endReason,
    @JsonKey(name: 'collections_completed') int collectionsCompleted,
    @JsonKey(name: 'collections_skipped') int collectionsSkipped,
    @JsonKey(name: 'placements_completed') int placementsCompleted,
    @JsonKey(name: 'placements_skipped') int placementsSkipped,
    @JsonKey(name: 'move_requests_completed') int moveRequestsCompleted,
    @JsonKey(name: 'total_skipped') int totalSkipped,
    @JsonKey(name: 'warehouse_stops') int warehouseStops,
  });
}

/// @nodoc
class _$ManagerShiftHistoryCopyWithImpl<$Res, $Val extends ManagerShiftHistory>
    implements $ManagerShiftHistoryCopyWith<$Res> {
  _$ManagerShiftHistoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ManagerShiftHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shiftId = null,
    Object? driverId = null,
    Object? driverName = null,
    Object? driverEmail = null,
    Object? routeId = freezed,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? createdAt = freezed,
    Object? endedAt = freezed,
    Object? totalPauseSeconds = null,
    Object? totalBins = null,
    Object? completedBins = null,
    Object? completionRate = null,
    Object? incidentsReported = null,
    Object? fieldObservations = null,
    Object? endReason = null,
    Object? collectionsCompleted = null,
    Object? collectionsSkipped = null,
    Object? placementsCompleted = null,
    Object? placementsSkipped = null,
    Object? moveRequestsCompleted = null,
    Object? totalSkipped = null,
    Object? warehouseStops = null,
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
            driverName: null == driverName
                ? _value.driverName
                : driverName // ignore: cast_nullable_to_non_nullable
                      as String,
            driverEmail: null == driverEmail
                ? _value.driverEmail
                : driverEmail // ignore: cast_nullable_to_non_nullable
                      as String,
            routeId: freezed == routeId
                ? _value.routeId
                : routeId // ignore: cast_nullable_to_non_nullable
                      as String?,
            startTime: freezed == startTime
                ? _value.startTime
                : startTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            endTime: freezed == endTime
                ? _value.endTime
                : endTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as int?,
            endedAt: freezed == endedAt
                ? _value.endedAt
                : endedAt // ignore: cast_nullable_to_non_nullable
                      as int?,
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
            completionRate: null == completionRate
                ? _value.completionRate
                : completionRate // ignore: cast_nullable_to_non_nullable
                      as double,
            incidentsReported: null == incidentsReported
                ? _value.incidentsReported
                : incidentsReported // ignore: cast_nullable_to_non_nullable
                      as int,
            fieldObservations: null == fieldObservations
                ? _value.fieldObservations
                : fieldObservations // ignore: cast_nullable_to_non_nullable
                      as int,
            endReason: null == endReason
                ? _value.endReason
                : endReason // ignore: cast_nullable_to_non_nullable
                      as String,
            collectionsCompleted: null == collectionsCompleted
                ? _value.collectionsCompleted
                : collectionsCompleted // ignore: cast_nullable_to_non_nullable
                      as int,
            collectionsSkipped: null == collectionsSkipped
                ? _value.collectionsSkipped
                : collectionsSkipped // ignore: cast_nullable_to_non_nullable
                      as int,
            placementsCompleted: null == placementsCompleted
                ? _value.placementsCompleted
                : placementsCompleted // ignore: cast_nullable_to_non_nullable
                      as int,
            placementsSkipped: null == placementsSkipped
                ? _value.placementsSkipped
                : placementsSkipped // ignore: cast_nullable_to_non_nullable
                      as int,
            moveRequestsCompleted: null == moveRequestsCompleted
                ? _value.moveRequestsCompleted
                : moveRequestsCompleted // ignore: cast_nullable_to_non_nullable
                      as int,
            totalSkipped: null == totalSkipped
                ? _value.totalSkipped
                : totalSkipped // ignore: cast_nullable_to_non_nullable
                      as int,
            warehouseStops: null == warehouseStops
                ? _value.warehouseStops
                : warehouseStops // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ManagerShiftHistoryImplCopyWith<$Res>
    implements $ManagerShiftHistoryCopyWith<$Res> {
  factory _$$ManagerShiftHistoryImplCopyWith(
    _$ManagerShiftHistoryImpl value,
    $Res Function(_$ManagerShiftHistoryImpl) then,
  ) = __$$ManagerShiftHistoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'id') String shiftId,
    @JsonKey(name: 'driver_id') String driverId,
    @JsonKey(name: 'driver_name') String driverName,
    @JsonKey(name: 'driver_email') String driverEmail,
    @JsonKey(name: 'route_id') String? routeId,
    @JsonKey(name: 'start_time') @UnixTimestampConverter() DateTime? startTime,
    @JsonKey(name: 'end_time') @UnixTimestampConverter() DateTime? endTime,
    @JsonKey(name: 'created_at') int? createdAt,
    @JsonKey(name: 'ended_at') int? endedAt,
    @JsonKey(name: 'total_pause_seconds') int totalPauseSeconds,
    @JsonKey(name: 'total_bins') int totalBins,
    @JsonKey(name: 'completed_bins') int completedBins,
    @JsonKey(name: 'completion_rate') double completionRate,
    @JsonKey(name: 'incidents_reported') int incidentsReported,
    @JsonKey(name: 'field_observations') int fieldObservations,
    @JsonKey(name: 'end_reason') String endReason,
    @JsonKey(name: 'collections_completed') int collectionsCompleted,
    @JsonKey(name: 'collections_skipped') int collectionsSkipped,
    @JsonKey(name: 'placements_completed') int placementsCompleted,
    @JsonKey(name: 'placements_skipped') int placementsSkipped,
    @JsonKey(name: 'move_requests_completed') int moveRequestsCompleted,
    @JsonKey(name: 'total_skipped') int totalSkipped,
    @JsonKey(name: 'warehouse_stops') int warehouseStops,
  });
}

/// @nodoc
class __$$ManagerShiftHistoryImplCopyWithImpl<$Res>
    extends _$ManagerShiftHistoryCopyWithImpl<$Res, _$ManagerShiftHistoryImpl>
    implements _$$ManagerShiftHistoryImplCopyWith<$Res> {
  __$$ManagerShiftHistoryImplCopyWithImpl(
    _$ManagerShiftHistoryImpl _value,
    $Res Function(_$ManagerShiftHistoryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ManagerShiftHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shiftId = null,
    Object? driverId = null,
    Object? driverName = null,
    Object? driverEmail = null,
    Object? routeId = freezed,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? createdAt = freezed,
    Object? endedAt = freezed,
    Object? totalPauseSeconds = null,
    Object? totalBins = null,
    Object? completedBins = null,
    Object? completionRate = null,
    Object? incidentsReported = null,
    Object? fieldObservations = null,
    Object? endReason = null,
    Object? collectionsCompleted = null,
    Object? collectionsSkipped = null,
    Object? placementsCompleted = null,
    Object? placementsSkipped = null,
    Object? moveRequestsCompleted = null,
    Object? totalSkipped = null,
    Object? warehouseStops = null,
  }) {
    return _then(
      _$ManagerShiftHistoryImpl(
        shiftId: null == shiftId
            ? _value.shiftId
            : shiftId // ignore: cast_nullable_to_non_nullable
                  as String,
        driverId: null == driverId
            ? _value.driverId
            : driverId // ignore: cast_nullable_to_non_nullable
                  as String,
        driverName: null == driverName
            ? _value.driverName
            : driverName // ignore: cast_nullable_to_non_nullable
                  as String,
        driverEmail: null == driverEmail
            ? _value.driverEmail
            : driverEmail // ignore: cast_nullable_to_non_nullable
                  as String,
        routeId: freezed == routeId
            ? _value.routeId
            : routeId // ignore: cast_nullable_to_non_nullable
                  as String?,
        startTime: freezed == startTime
            ? _value.startTime
            : startTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        endTime: freezed == endTime
            ? _value.endTime
            : endTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as int?,
        endedAt: freezed == endedAt
            ? _value.endedAt
            : endedAt // ignore: cast_nullable_to_non_nullable
                  as int?,
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
        completionRate: null == completionRate
            ? _value.completionRate
            : completionRate // ignore: cast_nullable_to_non_nullable
                  as double,
        incidentsReported: null == incidentsReported
            ? _value.incidentsReported
            : incidentsReported // ignore: cast_nullable_to_non_nullable
                  as int,
        fieldObservations: null == fieldObservations
            ? _value.fieldObservations
            : fieldObservations // ignore: cast_nullable_to_non_nullable
                  as int,
        endReason: null == endReason
            ? _value.endReason
            : endReason // ignore: cast_nullable_to_non_nullable
                  as String,
        collectionsCompleted: null == collectionsCompleted
            ? _value.collectionsCompleted
            : collectionsCompleted // ignore: cast_nullable_to_non_nullable
                  as int,
        collectionsSkipped: null == collectionsSkipped
            ? _value.collectionsSkipped
            : collectionsSkipped // ignore: cast_nullable_to_non_nullable
                  as int,
        placementsCompleted: null == placementsCompleted
            ? _value.placementsCompleted
            : placementsCompleted // ignore: cast_nullable_to_non_nullable
                  as int,
        placementsSkipped: null == placementsSkipped
            ? _value.placementsSkipped
            : placementsSkipped // ignore: cast_nullable_to_non_nullable
                  as int,
        moveRequestsCompleted: null == moveRequestsCompleted
            ? _value.moveRequestsCompleted
            : moveRequestsCompleted // ignore: cast_nullable_to_non_nullable
                  as int,
        totalSkipped: null == totalSkipped
            ? _value.totalSkipped
            : totalSkipped // ignore: cast_nullable_to_non_nullable
                  as int,
        warehouseStops: null == warehouseStops
            ? _value.warehouseStops
            : warehouseStops // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ManagerShiftHistoryImpl extends _ManagerShiftHistory {
  const _$ManagerShiftHistoryImpl({
    @JsonKey(name: 'id') required this.shiftId,
    @JsonKey(name: 'driver_id') required this.driverId,
    @JsonKey(name: 'driver_name') this.driverName = 'Unknown',
    @JsonKey(name: 'driver_email') this.driverEmail = '',
    @JsonKey(name: 'route_id') this.routeId,
    @JsonKey(name: 'start_time') @UnixTimestampConverter() this.startTime,
    @JsonKey(name: 'end_time') @UnixTimestampConverter() this.endTime,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'ended_at') this.endedAt,
    @JsonKey(name: 'total_pause_seconds') this.totalPauseSeconds = 0,
    @JsonKey(name: 'total_bins') this.totalBins = 0,
    @JsonKey(name: 'completed_bins') this.completedBins = 0,
    @JsonKey(name: 'completion_rate') this.completionRate = 0.0,
    @JsonKey(name: 'incidents_reported') this.incidentsReported = 0,
    @JsonKey(name: 'field_observations') this.fieldObservations = 0,
    @JsonKey(name: 'end_reason') this.endReason = 'completed',
    @JsonKey(name: 'collections_completed') this.collectionsCompleted = 0,
    @JsonKey(name: 'collections_skipped') this.collectionsSkipped = 0,
    @JsonKey(name: 'placements_completed') this.placementsCompleted = 0,
    @JsonKey(name: 'placements_skipped') this.placementsSkipped = 0,
    @JsonKey(name: 'move_requests_completed') this.moveRequestsCompleted = 0,
    @JsonKey(name: 'total_skipped') this.totalSkipped = 0,
    @JsonKey(name: 'warehouse_stops') this.warehouseStops = 0,
  }) : super._();

  factory _$ManagerShiftHistoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ManagerShiftHistoryImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String shiftId;
  @override
  @JsonKey(name: 'driver_id')
  final String driverId;
  @override
  @JsonKey(name: 'driver_name')
  final String driverName;
  @override
  @JsonKey(name: 'driver_email')
  final String driverEmail;
  @override
  @JsonKey(name: 'route_id')
  final String? routeId;
  @override
  @JsonKey(name: 'start_time')
  @UnixTimestampConverter()
  final DateTime? startTime;
  @override
  @JsonKey(name: 'end_time')
  @UnixTimestampConverter()
  final DateTime? endTime;
  @override
  @JsonKey(name: 'created_at')
  final int? createdAt;
  @override
  @JsonKey(name: 'ended_at')
  final int? endedAt;
  @override
  @JsonKey(name: 'total_pause_seconds')
  final int totalPauseSeconds;
  @override
  @JsonKey(name: 'total_bins')
  final int totalBins;
  @override
  @JsonKey(name: 'completed_bins')
  final int completedBins;
  @override
  @JsonKey(name: 'completion_rate')
  final double completionRate;
  @override
  @JsonKey(name: 'incidents_reported')
  final int incidentsReported;
  @override
  @JsonKey(name: 'field_observations')
  final int fieldObservations;
  @override
  @JsonKey(name: 'end_reason')
  final String endReason;
  @override
  @JsonKey(name: 'collections_completed')
  final int collectionsCompleted;
  @override
  @JsonKey(name: 'collections_skipped')
  final int collectionsSkipped;
  @override
  @JsonKey(name: 'placements_completed')
  final int placementsCompleted;
  @override
  @JsonKey(name: 'placements_skipped')
  final int placementsSkipped;
  @override
  @JsonKey(name: 'move_requests_completed')
  final int moveRequestsCompleted;
  @override
  @JsonKey(name: 'total_skipped')
  final int totalSkipped;
  @override
  @JsonKey(name: 'warehouse_stops')
  final int warehouseStops;

  @override
  String toString() {
    return 'ManagerShiftHistory(shiftId: $shiftId, driverId: $driverId, driverName: $driverName, driverEmail: $driverEmail, routeId: $routeId, startTime: $startTime, endTime: $endTime, createdAt: $createdAt, endedAt: $endedAt, totalPauseSeconds: $totalPauseSeconds, totalBins: $totalBins, completedBins: $completedBins, completionRate: $completionRate, incidentsReported: $incidentsReported, fieldObservations: $fieldObservations, endReason: $endReason, collectionsCompleted: $collectionsCompleted, collectionsSkipped: $collectionsSkipped, placementsCompleted: $placementsCompleted, placementsSkipped: $placementsSkipped, moveRequestsCompleted: $moveRequestsCompleted, totalSkipped: $totalSkipped, warehouseStops: $warehouseStops)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ManagerShiftHistoryImpl &&
            (identical(other.shiftId, shiftId) || other.shiftId == shiftId) &&
            (identical(other.driverId, driverId) ||
                other.driverId == driverId) &&
            (identical(other.driverName, driverName) ||
                other.driverName == driverName) &&
            (identical(other.driverEmail, driverEmail) ||
                other.driverEmail == driverEmail) &&
            (identical(other.routeId, routeId) || other.routeId == routeId) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.totalPauseSeconds, totalPauseSeconds) ||
                other.totalPauseSeconds == totalPauseSeconds) &&
            (identical(other.totalBins, totalBins) ||
                other.totalBins == totalBins) &&
            (identical(other.completedBins, completedBins) ||
                other.completedBins == completedBins) &&
            (identical(other.completionRate, completionRate) ||
                other.completionRate == completionRate) &&
            (identical(other.incidentsReported, incidentsReported) ||
                other.incidentsReported == incidentsReported) &&
            (identical(other.fieldObservations, fieldObservations) ||
                other.fieldObservations == fieldObservations) &&
            (identical(other.endReason, endReason) ||
                other.endReason == endReason) &&
            (identical(other.collectionsCompleted, collectionsCompleted) ||
                other.collectionsCompleted == collectionsCompleted) &&
            (identical(other.collectionsSkipped, collectionsSkipped) ||
                other.collectionsSkipped == collectionsSkipped) &&
            (identical(other.placementsCompleted, placementsCompleted) ||
                other.placementsCompleted == placementsCompleted) &&
            (identical(other.placementsSkipped, placementsSkipped) ||
                other.placementsSkipped == placementsSkipped) &&
            (identical(other.moveRequestsCompleted, moveRequestsCompleted) ||
                other.moveRequestsCompleted == moveRequestsCompleted) &&
            (identical(other.totalSkipped, totalSkipped) ||
                other.totalSkipped == totalSkipped) &&
            (identical(other.warehouseStops, warehouseStops) ||
                other.warehouseStops == warehouseStops));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    shiftId,
    driverId,
    driverName,
    driverEmail,
    routeId,
    startTime,
    endTime,
    createdAt,
    endedAt,
    totalPauseSeconds,
    totalBins,
    completedBins,
    completionRate,
    incidentsReported,
    fieldObservations,
    endReason,
    collectionsCompleted,
    collectionsSkipped,
    placementsCompleted,
    placementsSkipped,
    moveRequestsCompleted,
    totalSkipped,
    warehouseStops,
  ]);

  /// Create a copy of ManagerShiftHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ManagerShiftHistoryImplCopyWith<_$ManagerShiftHistoryImpl> get copyWith =>
      __$$ManagerShiftHistoryImplCopyWithImpl<_$ManagerShiftHistoryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ManagerShiftHistoryImplToJson(this);
  }
}

abstract class _ManagerShiftHistory extends ManagerShiftHistory {
  const factory _ManagerShiftHistory({
    @JsonKey(name: 'id') required final String shiftId,
    @JsonKey(name: 'driver_id') required final String driverId,
    @JsonKey(name: 'driver_name') final String driverName,
    @JsonKey(name: 'driver_email') final String driverEmail,
    @JsonKey(name: 'route_id') final String? routeId,
    @JsonKey(name: 'start_time')
    @UnixTimestampConverter()
    final DateTime? startTime,
    @JsonKey(name: 'end_time')
    @UnixTimestampConverter()
    final DateTime? endTime,
    @JsonKey(name: 'created_at') final int? createdAt,
    @JsonKey(name: 'ended_at') final int? endedAt,
    @JsonKey(name: 'total_pause_seconds') final int totalPauseSeconds,
    @JsonKey(name: 'total_bins') final int totalBins,
    @JsonKey(name: 'completed_bins') final int completedBins,
    @JsonKey(name: 'completion_rate') final double completionRate,
    @JsonKey(name: 'incidents_reported') final int incidentsReported,
    @JsonKey(name: 'field_observations') final int fieldObservations,
    @JsonKey(name: 'end_reason') final String endReason,
    @JsonKey(name: 'collections_completed') final int collectionsCompleted,
    @JsonKey(name: 'collections_skipped') final int collectionsSkipped,
    @JsonKey(name: 'placements_completed') final int placementsCompleted,
    @JsonKey(name: 'placements_skipped') final int placementsSkipped,
    @JsonKey(name: 'move_requests_completed') final int moveRequestsCompleted,
    @JsonKey(name: 'total_skipped') final int totalSkipped,
    @JsonKey(name: 'warehouse_stops') final int warehouseStops,
  }) = _$ManagerShiftHistoryImpl;
  const _ManagerShiftHistory._() : super._();

  factory _ManagerShiftHistory.fromJson(Map<String, dynamic> json) =
      _$ManagerShiftHistoryImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get shiftId;
  @override
  @JsonKey(name: 'driver_id')
  String get driverId;
  @override
  @JsonKey(name: 'driver_name')
  String get driverName;
  @override
  @JsonKey(name: 'driver_email')
  String get driverEmail;
  @override
  @JsonKey(name: 'route_id')
  String? get routeId;
  @override
  @JsonKey(name: 'start_time')
  @UnixTimestampConverter()
  DateTime? get startTime;
  @override
  @JsonKey(name: 'end_time')
  @UnixTimestampConverter()
  DateTime? get endTime;
  @override
  @JsonKey(name: 'created_at')
  int? get createdAt;
  @override
  @JsonKey(name: 'ended_at')
  int? get endedAt;
  @override
  @JsonKey(name: 'total_pause_seconds')
  int get totalPauseSeconds;
  @override
  @JsonKey(name: 'total_bins')
  int get totalBins;
  @override
  @JsonKey(name: 'completed_bins')
  int get completedBins;
  @override
  @JsonKey(name: 'completion_rate')
  double get completionRate;
  @override
  @JsonKey(name: 'incidents_reported')
  int get incidentsReported;
  @override
  @JsonKey(name: 'field_observations')
  int get fieldObservations;
  @override
  @JsonKey(name: 'end_reason')
  String get endReason;
  @override
  @JsonKey(name: 'collections_completed')
  int get collectionsCompleted;
  @override
  @JsonKey(name: 'collections_skipped')
  int get collectionsSkipped;
  @override
  @JsonKey(name: 'placements_completed')
  int get placementsCompleted;
  @override
  @JsonKey(name: 'placements_skipped')
  int get placementsSkipped;
  @override
  @JsonKey(name: 'move_requests_completed')
  int get moveRequestsCompleted;
  @override
  @JsonKey(name: 'total_skipped')
  int get totalSkipped;
  @override
  @JsonKey(name: 'warehouse_stops')
  int get warehouseStops;

  /// Create a copy of ManagerShiftHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ManagerShiftHistoryImplCopyWith<_$ManagerShiftHistoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
