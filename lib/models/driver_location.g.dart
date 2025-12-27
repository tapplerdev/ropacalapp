// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DriverLocationImpl _$$DriverLocationImplFromJson(Map<String, dynamic> json) =>
    _$DriverLocationImpl(
      driverId: json['driver_id'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      shiftId: json['shift_id'] as String?,
      timestamp: (json['timestamp'] as num?)?.toInt(),
      isConnected: json['is_connected'] as bool? ?? true,
      updatedAt: (json['updated_at'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$DriverLocationImplToJson(
  _$DriverLocationImpl instance,
) => <String, dynamic>{
  'driver_id': instance.driverId,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'heading': instance.heading,
  'speed': instance.speed,
  'accuracy': instance.accuracy,
  'shift_id': instance.shiftId,
  'timestamp': instance.timestamp,
  'is_connected': instance.isConnected,
  'updated_at': instance.updatedAt,
};
