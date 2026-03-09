// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manager_shift_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ManagerShiftHistoryImpl _$$ManagerShiftHistoryImplFromJson(
  Map<String, dynamic> json,
) => _$ManagerShiftHistoryImpl(
  shiftId: json['id'] as String,
  driverId: json['driver_id'] as String,
  driverName: json['driver_name'] as String? ?? 'Unknown',
  driverEmail: json['driver_email'] as String? ?? '',
  routeId: json['route_id'] as String?,
  startTime: const UnixTimestampConverter().fromJson(
    (json['start_time'] as num?)?.toInt(),
  ),
  endTime: const UnixTimestampConverter().fromJson(
    (json['end_time'] as num?)?.toInt(),
  ),
  createdAt: (json['created_at'] as num?)?.toInt(),
  endedAt: (json['ended_at'] as num?)?.toInt(),
  totalPauseSeconds: (json['total_pause_seconds'] as num?)?.toInt() ?? 0,
  totalBins: (json['total_bins'] as num?)?.toInt() ?? 0,
  completedBins: (json['completed_bins'] as num?)?.toInt() ?? 0,
  completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
  incidentsReported: (json['incidents_reported'] as num?)?.toInt() ?? 0,
  fieldObservations: (json['field_observations'] as num?)?.toInt() ?? 0,
  endReason: json['end_reason'] as String? ?? 'completed',
  collectionsCompleted: (json['collections_completed'] as num?)?.toInt() ?? 0,
  collectionsSkipped: (json['collections_skipped'] as num?)?.toInt() ?? 0,
  placementsCompleted: (json['placements_completed'] as num?)?.toInt() ?? 0,
  placementsSkipped: (json['placements_skipped'] as num?)?.toInt() ?? 0,
  moveRequestsCompleted:
      (json['move_requests_completed'] as num?)?.toInt() ?? 0,
  totalSkipped: (json['total_skipped'] as num?)?.toInt() ?? 0,
  warehouseStops: (json['warehouse_stops'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$ManagerShiftHistoryImplToJson(
  _$ManagerShiftHistoryImpl instance,
) => <String, dynamic>{
  'id': instance.shiftId,
  'driver_id': instance.driverId,
  'driver_name': instance.driverName,
  'driver_email': instance.driverEmail,
  'route_id': instance.routeId,
  'start_time': const UnixTimestampConverter().toJson(instance.startTime),
  'end_time': const UnixTimestampConverter().toJson(instance.endTime),
  'created_at': instance.createdAt,
  'ended_at': instance.endedAt,
  'total_pause_seconds': instance.totalPauseSeconds,
  'total_bins': instance.totalBins,
  'completed_bins': instance.completedBins,
  'completion_rate': instance.completionRate,
  'incidents_reported': instance.incidentsReported,
  'field_observations': instance.fieldObservations,
  'end_reason': instance.endReason,
  'collections_completed': instance.collectionsCompleted,
  'collections_skipped': instance.collectionsSkipped,
  'placements_completed': instance.placementsCompleted,
  'placements_skipped': instance.placementsSkipped,
  'move_requests_completed': instance.moveRequestsCompleted,
  'total_skipped': instance.totalSkipped,
  'warehouse_stops': instance.warehouseStops,
};
