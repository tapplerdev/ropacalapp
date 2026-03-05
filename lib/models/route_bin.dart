import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ropacalapp/core/enums/stop_type.dart';

part 'route_bin.freezed.dart';
part 'route_bin.g.dart';

/// Represents a bin in a driver's assigned route
@freezed
class RouteBin with _$RouteBin {
  const factory RouteBin({
    /// Route bin ID (route_task UUID)
    required String id,

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

    /// Original address for move request (pickup location)
    @JsonKey(name: 'original_address') String? originalAddress,

    /// New address for move request (dropoff location)
    @JsonKey(name: 'new_address') String? newAddress,

    /// Move request type (relocation, store, etc.)
    @JsonKey(name: 'move_type') String? moveType,

    /// Potential location ID (for placement tasks)
    @JsonKey(name: 'potential_location_id') String? potentialLocationId,

    /// New bin number being placed (for placement tasks)
    @JsonKey(name: 'new_bin_number') int? newBinNumber,

    /// Warehouse action type (load, unload, both)
    @JsonKey(name: 'warehouse_action') String? warehouseAction,

    /// Number of bins to load at warehouse
    @JsonKey(name: 'bins_to_load') int? binsToLoad,

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

  const RouteBin._();

  factory RouteBin.fromJson(Map<String, dynamic> json) =>
      _$RouteBinFromJson(json);

  /// Get task label based on task type
  String getTaskLabel() {
    switch (stopType) {
      case StopType.collection:
        return 'Bin #$binNumber';

      case StopType.placement:
        return newBinNumber != null
            ? 'Place New Bin #$newBinNumber'
            : 'Place New Bin';

      case StopType.pickup:
        return 'Pickup Bin #$binNumber';

      case StopType.dropoff:
        final dest = newAddress ?? 'New Location';
        return 'Dropoff to $dest';

      case StopType.warehouseStop:
        final action = warehouseAction == 'both'
            ? 'Load/Unload'
            : warehouseAction == 'load'
                ? 'Load'
                : warehouseAction == 'unload'
                    ? 'Unload'
                    : 'Stop';
        final binsText = binsToLoad != null ? ' $binsToLoad bins' : '';
        return 'Warehouse - $action$binsText';

      default:
        return 'Bin #$binNumber';
    }
  }

  /// Get task type icon
  String getTaskIcon() {
    switch (stopType) {
      case StopType.collection:
        return 'trash';
      case StopType.placement:
        return 'map_pin';
      case StopType.pickup:
        return 'arrow_up';
      case StopType.dropoff:
        return 'arrow_down';
      case StopType.warehouseStop:
        return 'warehouse';
      default:
        return 'circle';
    }
  }
}
