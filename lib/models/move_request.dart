import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ropacalapp/core/enums/move_request_status.dart';

part 'move_request.freezed.dart';
part 'move_request.g.dart';

@freezed
class MoveRequest with _$MoveRequest {
  const factory MoveRequest({
    required String id,
    @JsonKey(name: 'bin_id') required String binId,
    required MoveRequestStatus status,
    @JsonKey(name: 'requested_at') required DateTime requestedAt,
    @JsonKey(name: 'assigned_shift_id') String? assignedShiftId,
    @JsonKey(name: 'insert_after_bin_id') String? insertAfterBinId,
    @JsonKey(name: 'insert_position') String? insertPosition,
    @JsonKey(name: 'new_location') String? newLocation,
    @JsonKey(name: 'warehouse_location') String? warehouseLocation,
    @JsonKey(name: 'resolved_at') DateTime? resolvedAt,
    @JsonKey(name: 'resolved_by') String? resolvedBy,
  }) = _MoveRequest;

  factory MoveRequest.fromJson(Map<String, dynamic> json) =>
      _$MoveRequestFromJson(json);
}
