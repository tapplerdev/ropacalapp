import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ropacalapp/core/enums/stop_type.dart';

part 'route_task.freezed.dart';
part 'route_task.g.dart';

/// Represents a single task in a driver's shift route
/// This model supports all task types: collections, placements,
/// move requests, and warehouse stops in an agnostic way
@freezed
class RouteTask with _$RouteTask {
  const factory RouteTask({
    /// Unique task ID (UUID from route_tasks table)
    required String id,

    /// Associated shift ID
    @JsonKey(name: 'shift_id') required String shiftId,

    /// Order in the route sequence (determines navigation order)
    @JsonKey(name: 'sequence_order') required int sequenceOrder,

    /// Type of task (collection, placement, pickup, dropoff, warehouse_stop)
    @JsonKey(name: 'task_type') required StopType taskType,

    /// Task location latitude
    required double latitude,

    /// Task location longitude
    required double longitude,

    /// Task location address
    String? address,

    // ========== COLLECTION TASK FIELDS ==========
    /// Bin ID (for collection and move request tasks)
    @JsonKey(name: 'bin_id') String? binId,

    /// Bin number (for display)
    @JsonKey(name: 'bin_number') int? binNumber,

    /// Current fill percentage before collection (0-100)
    @JsonKey(name: 'fill_percentage') int? fillPercentage,

    // ========== PLACEMENT TASK FIELDS ==========
    /// Potential location ID (for placement tasks)
    @JsonKey(name: 'potential_location_id') String? potentialLocationId,

    /// New bin number to place (for placement tasks)
    @JsonKey(name: 'new_bin_number') String? newBinNumber,

    // ========== MOVE REQUEST TASK FIELDS ==========
    /// Move request ID (for pickup/dropoff tasks)
    @JsonKey(name: 'move_request_id') String? moveRequestId,

    /// Destination latitude (for pickup tasks - where to drop off)
    @JsonKey(name: 'destination_latitude') double? destinationLatitude,

    /// Destination longitude (for pickup tasks - where to drop off)
    @JsonKey(name: 'destination_longitude') double? destinationLongitude,

    /// Destination address (for pickup tasks)
    @JsonKey(name: 'destination_address') String? destinationAddress,

    /// Move request type (relocation, store, etc.)
    @JsonKey(name: 'move_type') String? moveType,

    // ========== WAREHOUSE STOP FIELDS ==========
    /// Warehouse stop action type (load, unload, both)
    @JsonKey(name: 'warehouse_action') String? warehouseAction,

    /// Number of bins to load at warehouse
    @JsonKey(name: 'bins_to_load') int? binsToLoad,

    // ========== ROUTE TRACKING FIELDS ==========
    /// Route ID this task was imported from (if applicable)
    @JsonKey(name: 'route_id') String? routeId,

    // ========== COMPLETION TRACKING ==========
    /// Whether this task has been completed
    @JsonKey(name: 'is_completed') @Default(0) int isCompleted,

    /// When the task was completed (Unix timestamp)
    @JsonKey(name: 'completed_at') int? completedAt,

    /// Whether this task was skipped
    @Default(false) bool skipped,

    /// Updated fill percentage after collection (0-100)
    @JsonKey(name: 'updated_fill_percentage') int? updatedFillPercentage,

    // ========== METADATA ==========
    /// Flexible JSON data for task-specific information
    @JsonKey(name: 'task_data') Map<String, dynamic>? taskData,

    /// Created timestamp (Unix timestamp)
    @JsonKey(name: 'created_at') required int createdAt,
  }) = _RouteTask;

  const RouteTask._();

  factory RouteTask.fromJson(Map<String, dynamic> json) =>
      _$RouteTaskFromJson(json);

  /// Check if this is a collection task
  bool get isCollection => taskType == StopType.collection;

  /// Check if this is a placement task
  bool get isPlacement => taskType == StopType.placement;

  /// Check if this is a warehouse stop
  bool get isWarehouseStop => taskType == StopType.warehouseStop;

  /// Check if this is a move request (pickup or dropoff)
  bool get isMoveRequest =>
      taskType == StopType.pickup || taskType == StopType.dropoff;

  /// Check if this is a pickup task
  bool get isPickup => taskType == StopType.pickup;

  /// Check if this is a dropoff task
  bool get isDropoff => taskType == StopType.dropoff;

  /// Get display title for this task
  String get displayTitle {
    switch (taskType) {
      case StopType.collection:
        return binNumber != null ? 'Bin #$binNumber' : 'Collection';
      case StopType.placement:
        return newBinNumber != null ? 'Place Bin #$newBinNumber' : 'Place New Bin';
      case StopType.pickup:
        return binNumber != null ? 'Pickup Bin #$binNumber' : 'Pickup Bin';
      case StopType.dropoff:
        return destinationAddress != null
            ? 'Dropoff to ${_truncateAddress(destinationAddress!)}'
            : 'Dropoff';
      case StopType.warehouseStop:
        final action = warehouseAction == 'both' ? 'Load/Unload' :
                       warehouseAction == 'load' ? 'Load' :
                       warehouseAction == 'unload' ? 'Unload' : 'Stop';
        final bins = binsToLoad != null ? ' $binsToLoad bins' : '';
        return 'Warehouse - $action$bins';
    }
  }

  /// Helper to truncate long addresses
  String _truncateAddress(String address, [int maxLength = 25]) {
    if (address.length <= maxLength) return address;
    return '${address.substring(0, maxLength)}...';
  }

  /// Get display subtitle for this task
  String get displaySubtitle {
    switch (taskType) {
      case StopType.collection:
      case StopType.pickup:
      case StopType.placement:
        return address ?? 'No address';
      case StopType.dropoff:
        return destinationAddress ?? 'No address';
      case StopType.warehouseStop:
        return address ?? 'Warehouse Location';
    }
  }

  /// Get icon name for this task type
  String get iconName {
    switch (taskType) {
      case StopType.collection:
        return 'delete_outline';
      case StopType.placement:
        return 'add_location';
      case StopType.pickup:
        return 'upload';
      case StopType.dropoff:
        return 'download';
      case StopType.warehouseStop:
        return 'warehouse';
    }
  }
}
