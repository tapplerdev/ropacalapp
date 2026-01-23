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
      requestedAt: DateTime.parse(json['requested_at'] as String),
      assignedShiftId: json['assigned_shift_id'] as String?,
      insertAfterBinId: json['insert_after_bin_id'] as String?,
      insertPosition: json['insert_position'] as String?,
      pickupLatitude: (json['pickup_latitude'] as num).toDouble(),
      pickupLongitude: (json['pickup_longitude'] as num).toDouble(),
      pickupAddress: json['pickup_address'] as String,
      isWarehousePickup: json['is_warehouse_pickup'] as bool? ?? false,
      dropoffLatitude: (json['dropoff_latitude'] as num).toDouble(),
      dropoffLongitude: (json['dropoff_longitude'] as num).toDouble(),
      dropoffAddress: json['dropoff_address'] as String,
      pickedUpAt: json['picked_up_at'] == null
          ? null
          : DateTime.parse(json['picked_up_at'] as String),
      pickupPhotoUrl: json['pickup_photo_url'] as String?,
      placementPhotoUrl: json['placement_photo_url'] as String?,
      notes: json['notes'] as String?,
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
      'bin_number': instance.binNumber,
      'status': _$MoveRequestStatusEnumMap[instance.status]!,
      'requested_at': instance.requestedAt.toIso8601String(),
      'assigned_shift_id': instance.assignedShiftId,
      'insert_after_bin_id': instance.insertAfterBinId,
      'insert_position': instance.insertPosition,
      'pickup_latitude': instance.pickupLatitude,
      'pickup_longitude': instance.pickupLongitude,
      'pickup_address': instance.pickupAddress,
      'is_warehouse_pickup': instance.isWarehousePickup,
      'dropoff_latitude': instance.dropoffLatitude,
      'dropoff_longitude': instance.dropoffLongitude,
      'dropoff_address': instance.dropoffAddress,
      'picked_up_at': instance.pickedUpAt?.toIso8601String(),
      'pickup_photo_url': instance.pickupPhotoUrl,
      'placement_photo_url': instance.placementPhotoUrl,
      'notes': instance.notes,
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
  MoveRequestStatus.pending: 'pending',
  MoveRequestStatus.pickedUp: 'picked_up',
  MoveRequestStatus.completed: 'completed',
  MoveRequestStatus.cancelled: 'cancelled',
};
