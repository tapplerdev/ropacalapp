// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'move_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MoveRequestImpl _$$MoveRequestImplFromJson(Map<String, dynamic> json) =>
    _$MoveRequestImpl(
      id: json['id'] as String,
      binId: json['bin_id'] as String,
      status: $enumDecode(_$MoveRequestStatusEnumMap, json['status']),
      requestedAt: DateTime.parse(json['requested_at'] as String),
      assignedShiftId: json['assigned_shift_id'] as String?,
      insertAfterBinId: json['insert_after_bin_id'] as String?,
      insertPosition: json['insert_position'] as String?,
      newLocation: json['new_location'] as String?,
      warehouseLocation: json['warehouse_location'] as String?,
      resolvedAt: json['resolved_at'] == null
          ? null
          : DateTime.parse(json['resolved_at'] as String),
      resolvedBy: json['resolved_by'] as String?,
    );

Map<String, dynamic> _$$MoveRequestImplToJson(_$MoveRequestImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bin_id': instance.binId,
      'status': _$MoveRequestStatusEnumMap[instance.status]!,
      'requested_at': instance.requestedAt.toIso8601String(),
      'assigned_shift_id': instance.assignedShiftId,
      'insert_after_bin_id': instance.insertAfterBinId,
      'insert_position': instance.insertPosition,
      'new_location': instance.newLocation,
      'warehouse_location': instance.warehouseLocation,
      'resolved_at': instance.resolvedAt?.toIso8601String(),
      'resolved_by': instance.resolvedBy,
    };

const _$MoveRequestStatusEnumMap = {
  MoveRequestStatus.pendingMove: 'pending_move',
  MoveRequestStatus.relocate: 'relocate',
  MoveRequestStatus.retire: 'retire',
  MoveRequestStatus.warehouseStorage: 'warehouse_storage',
};
