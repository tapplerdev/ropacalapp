// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RouteTemplateImpl _$$RouteTemplateImplFromJson(Map<String, dynamic> json) =>
    _$RouteTemplateImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      geographicArea: json['geographic_area'] as String? ?? '',
      binCount: (json['bin_count'] as num?)?.toInt() ?? 0,
      estimatedDurationHours: (json['estimated_duration_hours'] as num?)
          ?.toDouble(),
      createdAt: (json['created_at'] as num).toInt(),
      updatedAt: (json['updated_at'] as num).toInt(),
      bins:
          (json['bins'] as List<dynamic>?)
              ?.map((e) => RouteBin.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$RouteTemplateImplToJson(_$RouteTemplateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'geographic_area': instance.geographicArea,
      'bin_count': instance.binCount,
      'estimated_duration_hours': instance.estimatedDurationHours,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'bins': instance.bins,
    };

_$RouteBinImpl _$$RouteBinImplFromJson(Map<String, dynamic> json) =>
    _$RouteBinImpl(
      id: json['id'] as String,
      binNumber: (json['bin_number'] as num).toInt(),
      currentStreet: json['current_street'] as String? ?? '',
      city: json['city'] as String? ?? '',
      zip: json['zip'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      fillPercentage: (json['fill_percentage'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'active',
      sequenceOrder: (json['sequence_order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$RouteBinImplToJson(_$RouteBinImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bin_number': instance.binNumber,
      'current_street': instance.currentStreet,
      'city': instance.city,
      'zip': instance.zip,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'fill_percentage': instance.fillPercentage,
      'status': instance.status,
      'sequence_order': instance.sequenceOrder,
    };
