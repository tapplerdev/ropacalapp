// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'move_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MoveRequestImpl _$$MoveRequestImplFromJson(Map<String, dynamic> json) =>
    _$MoveRequestImpl(
      id: json['id'] as String,
      binId: json['bin_id'] as String,
      binNumber: (json['bin_number'] as num?)?.toInt(),
      status: $enumDecode(_$MoveRequestStatusEnumMap, json['status']),
      urgency: json['urgency'] as String?,
      requestedBy: json['requested_by'] as String?,
      scheduledDate: (json['scheduled_date'] as num?)?.toInt(),
      assignedShiftId: json['assigned_shift_id'] as String?,
      assignmentType: json['assignment_type'] as String?,
      moveType: json['move_type'] as String?,
      originalLatitude: (json['original_latitude'] as num).toDouble(),
      originalLongitude: (json['original_longitude'] as num).toDouble(),
      originalAddress: json['original_address'] as String,
      newLatitude: (json['new_latitude'] as num?)?.toDouble(),
      newLongitude: (json['new_longitude'] as num?)?.toDouble(),
      newAddress: json['new_address'] as String?,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      completedAt: (json['completed_at'] as num?)?.toInt(),
      createdAt: (json['created_at'] as num).toInt(),
      updatedAt: (json['updated_at'] as num).toInt(),
    );

Map<String, dynamic> _$$MoveRequestImplToJson(_$MoveRequestImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bin_id': instance.binId,
      'bin_number': instance.binNumber,
      'status': _$MoveRequestStatusEnumMap[instance.status]!,
      'urgency': instance.urgency,
      'requested_by': instance.requestedBy,
      'scheduled_date': instance.scheduledDate,
      'assigned_shift_id': instance.assignedShiftId,
      'assignment_type': instance.assignmentType,
      'move_type': instance.moveType,
      'original_latitude': instance.originalLatitude,
      'original_longitude': instance.originalLongitude,
      'original_address': instance.originalAddress,
      'new_latitude': instance.newLatitude,
      'new_longitude': instance.newLongitude,
      'new_address': instance.newAddress,
      'reason': instance.reason,
      'notes': instance.notes,
      'completed_at': instance.completedAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

const _$MoveRequestStatusEnumMap = {
  MoveRequestStatus.pendingMove: 'pending_move',
  MoveRequestStatus.relocate: 'relocate',
  MoveRequestStatus.retire: 'retire',
  MoveRequestStatus.warehouseStorage: 'warehouse_storage',
  MoveRequestStatus.assigned: 'assigned',
  MoveRequestStatus.inProgress: 'in_progress',
  MoveRequestStatus.pending: 'pending',
  MoveRequestStatus.pickedUp: 'picked_up',
  MoveRequestStatus.completed: 'completed',
  MoveRequestStatus.cancelled: 'cancelled',
};
