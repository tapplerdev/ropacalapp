// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ShiftStateImpl _$$ShiftStateImplFromJson(Map<String, dynamic> json) =>
    _$ShiftStateImpl(
      status: $enumDecode(_$ShiftStatusEnumMap, json['status']),
      startTime: const UnixTimestampConverter().fromJson(
        (json['start_time'] as num?)?.toInt(),
      ),
      totalPauseSeconds: (json['total_pause_seconds'] as num?)?.toInt() ?? 0,
      pauseStartTime: const UnixTimestampConverter().fromJson(
        (json['pause_start_time'] as num?)?.toInt(),
      ),
      assignedRouteId: json['route_id'] as String?,
      totalBins: (json['total_bins'] as num?)?.toInt() ?? 0,
      completedBins: (json['completed_bins'] as num?)?.toInt() ?? 0,
      routeBins:
          (json['bins'] as List<dynamic>?)
              ?.map((e) => RouteBin.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ShiftStateImplToJson(_$ShiftStateImpl instance) =>
    <String, dynamic>{
      'status': _$ShiftStatusEnumMap[instance.status]!,
      'start_time': const UnixTimestampConverter().toJson(instance.startTime),
      'total_pause_seconds': instance.totalPauseSeconds,
      'pause_start_time': const UnixTimestampConverter().toJson(
        instance.pauseStartTime,
      ),
      'route_id': instance.assignedRouteId,
      'total_bins': instance.totalBins,
      'completed_bins': instance.completedBins,
      'bins': instance.routeBins,
    };

const _$ShiftStatusEnumMap = {
  ShiftStatus.inactive: 'inactive',
  ShiftStatus.ready: 'ready',
  ShiftStatus.active: 'active',
  ShiftStatus.paused: 'paused',
  ShiftStatus.ended: 'ended',
  ShiftStatus.cancelled: 'cancelled',
};
