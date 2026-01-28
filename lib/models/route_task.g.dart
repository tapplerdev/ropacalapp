// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RouteTaskImpl _$$RouteTaskImplFromJson(Map<String, dynamic> json) =>
    _$RouteTaskImpl(
      id: json['id'] as String,
      shiftId: json['shift_id'] as String,
      sequenceOrder: (json['sequence_order'] as num).toInt(),
      taskType: $enumDecode(_$StopTypeEnumMap, json['task_type']),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      binId: json['bin_id'] as String?,
      binNumber: (json['bin_number'] as num?)?.toInt(),
      fillPercentage: (json['fill_percentage'] as num?)?.toInt(),
      potentialLocationId: json['potential_location_id'] as String?,
      newBinNumber: json['new_bin_number'] as String?,
      moveRequestId: json['move_request_id'] as String?,
      destinationLatitude: (json['destination_latitude'] as num?)?.toDouble(),
      destinationLongitude: (json['destination_longitude'] as num?)?.toDouble(),
      destinationAddress: json['destination_address'] as String?,
      moveType: json['move_type'] as String?,
      warehouseAction: json['warehouse_action'] as String?,
      binsToLoad: (json['bins_to_load'] as num?)?.toInt(),
      routeId: json['route_id'] as String?,
      isCompleted: (json['is_completed'] as num?)?.toInt() ?? 0,
      completedAt: (json['completed_at'] as num?)?.toInt(),
      skipped: json['skipped'] as bool? ?? false,
      updatedFillPercentage: (json['updated_fill_percentage'] as num?)?.toInt(),
      taskData: json['task_data'] as Map<String, dynamic>?,
      createdAt: (json['created_at'] as num).toInt(),
    );

Map<String, dynamic> _$$RouteTaskImplToJson(_$RouteTaskImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shift_id': instance.shiftId,
      'sequence_order': instance.sequenceOrder,
      'task_type': _$StopTypeEnumMap[instance.taskType]!,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'address': instance.address,
      'bin_id': instance.binId,
      'bin_number': instance.binNumber,
      'fill_percentage': instance.fillPercentage,
      'potential_location_id': instance.potentialLocationId,
      'new_bin_number': instance.newBinNumber,
      'move_request_id': instance.moveRequestId,
      'destination_latitude': instance.destinationLatitude,
      'destination_longitude': instance.destinationLongitude,
      'destination_address': instance.destinationAddress,
      'move_type': instance.moveType,
      'warehouse_action': instance.warehouseAction,
      'bins_to_load': instance.binsToLoad,
      'route_id': instance.routeId,
      'is_completed': instance.isCompleted,
      'completed_at': instance.completedAt,
      'skipped': instance.skipped,
      'updated_fill_percentage': instance.updatedFillPercentage,
      'task_data': instance.taskData,
      'created_at': instance.createdAt,
    };

const _$StopTypeEnumMap = {
  StopType.collection: 'collection',
  StopType.pickup: 'pickup',
  StopType.dropoff: 'dropoff',
  StopType.placement: 'placement',
  StopType.warehouseStop: 'warehouse_stop',
};
