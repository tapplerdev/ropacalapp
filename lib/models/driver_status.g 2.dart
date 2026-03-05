// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DriverStatusImpl _$$DriverStatusImplFromJson(Map<String, dynamic> json) =>
    _$DriverStatusImpl(
      driverId: json['driver_id'] as String,
      name: json['driver_name'] as String? ?? 'Unknown Driver',
      status: $enumDecode(_$ShiftStatusEnumMap, json['status']),
      shiftId: json['shift_id'] as String?,
      currentBin: (json['current_bin'] as num?)?.toInt() ?? 0,
      totalBins: (json['total_bins'] as num?)?.toInt() ?? 0,
      lastLocation: json['last_location'] == null
          ? null
          : DriverLocation.fromJson(
              json['last_location'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$$DriverStatusImplToJson(_$DriverStatusImpl instance) =>
    <String, dynamic>{
      'driver_id': instance.driverId,
      'driver_name': instance.name,
      'status': _$ShiftStatusEnumMap[instance.status]!,
      'shift_id': instance.shiftId,
      'current_bin': instance.currentBin,
      'total_bins': instance.totalBins,
      'last_location': instance.lastLocation,
    };

const _$ShiftStatusEnumMap = {
  ShiftStatus.inactive: 'inactive',
  ShiftStatus.ready: 'ready',
  ShiftStatus.active: 'active',
  ShiftStatus.paused: 'paused',
  ShiftStatus.ended: 'ended',
  ShiftStatus.cancelled: 'cancelled',
};
