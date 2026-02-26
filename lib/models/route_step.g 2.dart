// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_step.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RouteStepImpl _$$RouteStepImplFromJson(Map<String, dynamic> json) =>
    _$RouteStepImpl(
      instruction: json['instruction'] as String,
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      maneuverType: json['maneuverType'] as String,
      location: LatLng.fromJson(json['location'] as Map<String, dynamic>),
      modifier: json['modifier'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$$RouteStepImplToJson(_$RouteStepImpl instance) =>
    <String, dynamic>{
      'instruction': instance.instruction,
      'distance': instance.distance,
      'duration': instance.duration,
      'maneuverType': instance.maneuverType,
      'location': instance.location,
      'modifier': instance.modifier,
      'name': instance.name,
    };
