// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ShiftHistoryImpl _$$ShiftHistoryImplFromJson(Map<String, dynamic> json) =>
    _$ShiftHistoryImpl(
      shiftId: json['id'] as String,
      driverId: json['driver_id'] as String,
      routeId: json['route_id'] as String?,
      status: $enumDecode(_$ShiftStatusEnumMap, json['status']),
      startTime: const UnixTimestampConverter().fromJson(
        (json['start_time'] as num?)?.toInt(),
      ),
      endTime: const UnixTimestampConverter().fromJson(
        (json['end_time'] as num?)?.toInt(),
      ),
      totalPauseSeconds: (json['total_pause_seconds'] as num?)?.toInt() ?? 0,
      totalBins: (json['total_bins'] as num?)?.toInt() ?? 0,
      completedBins: (json['completed_bins'] as num?)?.toInt() ?? 0,
      createdAt: (json['created_at'] as num?)?.toInt(),
      updatedAt: (json['updated_at'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ShiftHistoryImplToJson(_$ShiftHistoryImpl instance) =>
    <String, dynamic>{
      'id': instance.shiftId,
      'driver_id': instance.driverId,
      'route_id': instance.routeId,
      'status': _$ShiftStatusEnumMap[instance.status]!,
      'start_time': const UnixTimestampConverter().toJson(instance.startTime),
      'end_time': const UnixTimestampConverter().toJson(instance.endTime),
      'total_pause_seconds': instance.totalPauseSeconds,
      'total_bins': instance.totalBins,
      'completed_bins': instance.completedBins,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

const _$ShiftStatusEnumMap = {
  ShiftStatus.inactive: 'inactive',
  ShiftStatus.ready: 'ready',
  ShiftStatus.active: 'active',
  ShiftStatus.paused: 'paused',
  ShiftStatus.ended: 'ended',
  ShiftStatus.cancelled: 'cancelled',
};
