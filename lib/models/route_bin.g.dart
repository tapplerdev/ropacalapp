// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_bin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RouteBinImpl _$$RouteBinImplFromJson(Map<String, dynamic> json) =>
    _$RouteBinImpl(
      id: (json['id'] as num).toInt(),
      shiftId: json['shift_id'] as String,
      binId: json['bin_id'] as String,
      sequenceOrder: (json['sequence_order'] as num).toInt(),
      stopType:
          $enumDecodeNullable(_$StopTypeEnumMap, json['stop_type']) ??
          StopType.collection,
      moveRequestId: json['move_request_id'] as String?,
      originalAddress: json['original_address'] as String?,
      newAddress: json['new_address'] as String?,
      moveType: json['move_type'] as String?,
      isCompleted: (json['is_completed'] as num?)?.toInt() ?? 0,
      completedAt: (json['completed_at'] as num?)?.toInt(),
      updatedFillPercentage: (json['updated_fill_percentage'] as num?)?.toInt(),
      createdAt: (json['created_at'] as num).toInt(),
      binNumber: (json['bin_number'] as num).toInt(),
      currentStreet: json['current_street'] as String,
      city: json['city'] as String,
      zip: json['zip'] as String,
      fillPercentage: (json['fill_percentage'] as num).toInt(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$$RouteBinImplToJson(_$RouteBinImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shift_id': instance.shiftId,
      'bin_id': instance.binId,
      'sequence_order': instance.sequenceOrder,
      'stop_type': _$StopTypeEnumMap[instance.stopType]!,
      'move_request_id': instance.moveRequestId,
      'original_address': instance.originalAddress,
      'new_address': instance.newAddress,
      'move_type': instance.moveType,
      'is_completed': instance.isCompleted,
      'completed_at': instance.completedAt,
      'updated_fill_percentage': instance.updatedFillPercentage,
      'created_at': instance.createdAt,
      'bin_number': instance.binNumber,
      'current_street': instance.currentStreet,
      'city': instance.city,
      'zip': instance.zip,
      'fill_percentage': instance.fillPercentage,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

const _$StopTypeEnumMap = {
  StopType.collection: 'collection',
  StopType.pickup: 'pickup',
  StopType.dropoff: 'dropoff',
  StopType.placement: 'placement',
  StopType.warehouseStop: 'warehouse_stop',
};
