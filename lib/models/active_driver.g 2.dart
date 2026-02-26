// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_driver.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ActiveDriverImpl _$$ActiveDriverImplFromJson(Map<String, dynamic> json) =>
    _$ActiveDriverImpl(
      driverId: json['driver_id'] as String,
      driverName: json['driver_name'] as String? ?? 'Unknown Driver',
      shiftId: json['shift_id'] as String? ?? '',
      routeId: json['route_id'] as String?,
      status: $enumDecode(_$ShiftStatusEnumMap, json['status']),
      startTime: const UnixTimestampConverter().fromJson(
        (json['start_time'] as num?)?.toInt(),
      ),
      totalBins: (json['total_bins'] as num?)?.toInt() ?? 0,
      completedBins: (json['completed_bins'] as num?)?.toInt() ?? 0,
      currentLocation: json['current_location'] == null
          ? null
          : DriverLocation.fromJson(
              json['current_location'] as Map<String, dynamic>,
            ),
      updatedAt: (json['updated_at'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ActiveDriverImplToJson(_$ActiveDriverImpl instance) =>
    <String, dynamic>{
      'driver_id': instance.driverId,
      'driver_name': instance.driverName,
      'shift_id': instance.shiftId,
      'route_id': instance.routeId,
      'status': _$ShiftStatusEnumMap[instance.status]!,
      'start_time': const UnixTimestampConverter().toJson(instance.startTime),
      'total_bins': instance.totalBins,
      'completed_bins': instance.completedBins,
      'current_location': instance.currentLocation,
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
