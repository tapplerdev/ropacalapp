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
      isCompleted: (json['is_completed'] as num?)?.toInt() ?? 0,
      completedAt: (json['completed_at'] as num?)?.toInt(),
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
      'is_completed': instance.isCompleted,
      'completed_at': instance.completedAt,
      'created_at': instance.createdAt,
      'bin_number': instance.binNumber,
      'current_street': instance.currentStreet,
      'city': instance.city,
      'zip': instance.zip,
      'fill_percentage': instance.fillPercentage,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
