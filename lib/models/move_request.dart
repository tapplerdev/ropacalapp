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
    @JsonKey(name: 'urgency') String? urgency,
    @JsonKey(name: 'requested_by') String? requestedBy,
    @JsonKey(name: 'scheduled_date') int? scheduledDate,
    @JsonKey(name: 'assigned_shift_id') String? assignedShiftId,
    @JsonKey(name: 'assignment_type') String? assignmentType,
    @JsonKey(name: 'move_type') String? moveType,

    // ORIGINAL LOCATION (where bin currently is)
    @JsonKey(name: 'original_latitude') required double originalLatitude,
    @JsonKey(name: 'original_longitude') required double originalLongitude,
    @JsonKey(name: 'original_address') required String originalAddress,

    // NEW LOCATION (where to move it - nullable for pickup-only)
    @JsonKey(name: 'new_latitude') double? newLatitude,
    @JsonKey(name: 'new_longitude') double? newLongitude,
    @JsonKey(name: 'new_address') String? newAddress,

    // TRACKING & METADATA
    @JsonKey(name: 'reason') String? reason,
    @JsonKey(name: 'notes') String? notes,
    @JsonKey(name: 'completed_at') int? completedAt,
    @JsonKey(name: 'created_at') required int createdAt,
    @JsonKey(name: 'updated_at') required int updatedAt,
  }) = _MoveRequest;

  // Private constructor required for custom getters
  const MoveRequest._();

  factory MoveRequest.fromJson(Map<String, dynamic> json) =>
      _$MoveRequestFromJson(json);

  // Computed properties for better semantics on frontend
  // Maps backend "original" (where bin is now) to "pickup" (where to pick it up from)
  // Maps backend "new" (where bin should go) to "dropoff" (where to drop it off)
  double get pickupLatitude => originalLatitude;
  double get pickupLongitude => originalLongitude;
  String get pickupAddress => originalAddress;

  double? get dropoffLatitude => newLatitude;
  double? get dropoffLongitude => newLongitude;
  String? get dropoffAddress => newAddress;
}
