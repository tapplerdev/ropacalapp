// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BinImpl _$$BinImplFromJson(Map<String, dynamic> json) => _$BinImpl(
  id: json['id'] as String,
  binNumber: (json['bin_number'] as num).toInt(),
  currentStreet: json['current_street'] as String,
  city: json['city'] as String,
  zip: json['zip'] as String,
  lastMoved: json['last_moved'] == null
      ? null
      : DateTime.parse(json['last_moved'] as String),
  lastChecked: json['last_checked'] == null
      ? null
      : DateTime.parse(json['last_checked'] as String),
  status: $enumDecode(_$BinStatusEnumMap, json['status']),
  fillPercentage: (json['fill_percentage'] as num?)?.toInt(),
  checked: json['checked'] as bool? ?? false,
  moveRequested: json['move_requested'] as bool? ?? false,
  moveRequestId: json['move_request_id'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$$BinImplToJson(_$BinImpl instance) => <String, dynamic>{
  'id': instance.id,
  'bin_number': instance.binNumber,
  'current_street': instance.currentStreet,
  'city': instance.city,
  'zip': instance.zip,
  'last_moved': instance.lastMoved?.toIso8601String(),
  'last_checked': instance.lastChecked?.toIso8601String(),
  'status': _$BinStatusEnumMap[instance.status]!,
  'fill_percentage': instance.fillPercentage,
  'checked': instance.checked,
  'move_requested': instance.moveRequested,
  'move_request_id': instance.moveRequestId,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};

const _$BinStatusEnumMap = {
  BinStatus.active: 'active',
  BinStatus.missing: 'missing',
  BinStatus.pendingMove: 'pending_move',
  BinStatus.relocate: 'relocate',
  BinStatus.retire: 'retire',
  BinStatus.warehouseStorage: 'warehouse_storage',
};
