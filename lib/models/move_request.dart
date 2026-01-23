import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ropacalapp/core/enums/move_request_status.dart';

part 'move_request.freezed.dart';
part 'move_request.g.dart';

@freezed
class MoveRequest with _$MoveRequest {
  const factory MoveRequest({
    required String id,
    @JsonKey(name: 'bin_id') required String binId,
    @JsonKey(name: 'bin_number') int? binNumber,
    required MoveRequestStatus status,
    @JsonKey(name: 'requested_at') required DateTime requestedAt,
    @JsonKey(name: 'assigned_shift_id') String? assignedShiftId,
    @JsonKey(name: 'insert_after_bin_id') String? insertAfterBinId,
    @JsonKey(name: 'insert_position') String? insertPosition,

    // PICKUP LOCATION (current bin location OR warehouse)
    @JsonKey(name: 'pickup_latitude') required double pickupLatitude,
    @JsonKey(name: 'pickup_longitude') required double pickupLongitude,
    @JsonKey(name: 'pickup_address') required String pickupAddress,
    @JsonKey(name: 'is_warehouse_pickup')
    @Default(false)
    bool isWarehousePickup,

    // DROP-OFF LOCATION (new placement)
    @JsonKey(name: 'dropoff_latitude') required double dropoffLatitude,
    @JsonKey(name: 'dropoff_longitude') required double dropoffLongitude,
    @JsonKey(name: 'dropoff_address') required String dropoffAddress,

    // TRACKING
    @JsonKey(name: 'picked_up_at') DateTime? pickedUpAt,
    @JsonKey(name: 'pickup_photo_url') String? pickupPhotoUrl,
    @JsonKey(name: 'placement_photo_url') String? placementPhotoUrl,
    @JsonKey(name: 'notes') String? notes,

    // DEPRECATED - kept for backward compatibility
    @JsonKey(name: 'new_location') String? newLocation,
    @JsonKey(name: 'warehouse_location') String? warehouseLocation,
    @JsonKey(name: 'resolved_at') DateTime? resolvedAt,
    @JsonKey(name: 'resolved_by') String? resolvedBy,
  }) = _MoveRequest;

  factory MoveRequest.fromJson(Map<String, dynamic> json) =>
      _$MoveRequestFromJson(json);
}
