import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ropacalapp/core/enums/stop_type.dart';

part 'route_bin.freezed.dart';
part 'route_bin.g.dart';

/// Represents a bin in a driver's assigned route
@freezed
class RouteBin with _$RouteBin {
  const factory RouteBin({
    /// Route bin ID
    required int id,

    /// Associated shift ID
    @JsonKey(name: 'shift_id') required String shiftId,

    /// Bin ID
    @JsonKey(name: 'bin_id') required String binId,

    /// Order in the route sequence
    @JsonKey(name: 'sequence_order') required int sequenceOrder,

    /// Type of stop (collection, pickup, dropoff)
    @JsonKey(name: 'stop_type') @Default(StopType.collection) StopType stopType,

    /// Move request ID (for pickup/dropoff stops)
    @JsonKey(name: 'move_request_id') String? moveRequestId,

    /// Whether this bin has been completed
    @JsonKey(name: 'is_completed') @Default(0) int isCompleted,

    /// Timestamp when completed (Unix timestamp)
    @JsonKey(name: 'completed_at') int? completedAt,

    /// Updated fill percentage after driver check-in (0-100)
    @JsonKey(name: 'updated_fill_percentage') int? updatedFillPercentage,

    /// Created timestamp (Unix timestamp)
    @JsonKey(name: 'created_at') required int createdAt,

    /// Bin number
    @JsonKey(name: 'bin_number') required int binNumber,

    /// Street address
    @JsonKey(name: 'current_street') required String currentStreet,

    /// City
    required String city,

    /// Zip code
    required String zip,

    /// Fill percentage (0-100)
    @JsonKey(name: 'fill_percentage') required int fillPercentage,

    /// Latitude coordinate
    required double latitude,

    /// Longitude coordinate
    required double longitude,
  }) = _RouteBin;

  factory RouteBin.fromJson(Map<String, dynamic> json) =>
      _$RouteBinFromJson(json);
}
