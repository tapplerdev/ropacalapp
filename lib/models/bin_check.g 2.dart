// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bin_check.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BinCheckImpl _$$BinCheckImplFromJson(Map<String, dynamic> json) =>
    _$BinCheckImpl(
      id: (json['id'] as num).toInt(),
      binId: json['bin_id'] as String,
      checkedFrom: json['checked_from'] as String,
      fillPercentage: (json['fill_percentage'] as num).toInt(),
      checkedOn: DateTime.parse(json['checked_on'] as String),
    );

Map<String, dynamic> _$$BinCheckImplToJson(_$BinCheckImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bin_id': instance.binId,
      'checked_from': instance.checkedFrom,
      'fill_percentage': instance.fillPercentage,
      'checked_on': instance.checkedOn.toIso8601String(),
    };
