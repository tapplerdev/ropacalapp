// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bin_move.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BinMoveImpl _$$BinMoveImplFromJson(Map<String, dynamic> json) =>
    _$BinMoveImpl(
      id: (json['id'] as num).toInt(),
      binId: json['bin_id'] as String,
      movedFrom: json['moved_from'] as String,
      movedTo: json['moved_to'] as String,
      movedOn: DateTime.parse(json['moved_on'] as String),
    );

Map<String, dynamic> _$$BinMoveImplToJson(_$BinMoveImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bin_id': instance.binId,
      'moved_from': instance.movedFrom,
      'moved_to': instance.movedTo,
      'moved_on': instance.movedOn.toIso8601String(),
    };
