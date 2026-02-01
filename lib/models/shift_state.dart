import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/models/route_task.dart';
import 'package:ropacalapp/core/utils/unix_timestamp_converter.dart';
import 'package:ropacalapp/core/enums/stop_type.dart';

part 'shift_state.freezed.dart';
part 'shift_state.g.dart';

/// Represents the driver's current shift status
@freezed
class ShiftState with _$ShiftState {
  const factory ShiftState({
    /// Current shift status
    required ShiftStatus status,

    /// Shift ID (unique identifier for this shift instance)
    @JsonKey(name: 'id') String? shiftId,

    /// When the shift started (clock in time)
    @JsonKey(name: 'start_time') @UnixTimestampConverter() DateTime? startTime,

    /// Total pause time in seconds
    @JsonKey(name: 'total_pause_seconds') @Default(0) int totalPauseSeconds,

    /// Current pause start time (null if not paused)
    @JsonKey(name: 'pause_start_time')
    @UnixTimestampConverter()
    DateTime? pauseStartTime,

    /// Assigned route ID
    @JsonKey(name: 'route_id') String? assignedRouteId,

    /// Total bins in assigned route
    @JsonKey(name: 'total_bins') @Default(0) int totalBins,

    /// Completed bins count
    @JsonKey(name: 'completed_bins') @Default(0) int completedBins,

    /// List of bins in the route with their details (legacy)
    @JsonKey(name: 'bins') @Default([]) List<RouteBin> routeBins,

    /// List of tasks in the route (new task-based system)
    @JsonKey(name: 'tasks') @Default([]) List<RouteTask> tasks,
  }) = _ShiftState;

  const ShiftState._();

  factory ShiftState.fromJson(Map<String, dynamic> json) =>
      _$ShiftStateFromJson(json);

  /// Check if this shift uses the new task-based system
  bool get usesTasks => tasks.isNotEmpty;

  /// Get only incomplete bins for active navigation (legacy)
  List<RouteBin> get remainingBins {
    return routeBins.where((bin) => bin.isCompleted == 0).toList();
  }

  /// Get only incomplete tasks for active navigation (new system)
  List<RouteTask> get remainingTasks {
    return tasks.where((task) => task.isCompleted == 0).toList();
  }

  /// Get logical bin count (count pickup+dropoff pairs as 1)
  /// This treats a move request (pickup + dropoff) as a single action
  int get logicalTotalBins {
    final moveRequestIds = <String>{};
    int count = 0;

    for (final bin in routeBins) {
      if (bin.stopType == StopType.pickup && bin.moveRequestId != null) {
        // Only count pickup once per move request
        if (!moveRequestIds.contains(bin.moveRequestId)) {
          moveRequestIds.add(bin.moveRequestId!);
          count++;
        }
      } else if (bin.stopType == StopType.dropoff &&
          bin.moveRequestId != null) {
        // Skip dropoff in count (already counted with pickup)
        continue;
      } else {
        // Regular collection bin
        count++;
      }
    }

    return count;
  }

  /// Get logical completed bin count
  /// Move requests are only counted as complete when BOTH pickup AND dropoff
  /// are finished
  int get logicalCompletedBins {
    final completedMoveRequests = <String>{};
    int count = 0;

    for (final bin in routeBins) {
      if (bin.stopType == StopType.pickup && bin.moveRequestId != null) {
        // Check if corresponding dropoff is also completed
        final dropoff = routeBins.firstWhere(
          (b) =>
              b.stopType == StopType.dropoff &&
              b.moveRequestId == bin.moveRequestId,
          orElse: () => bin,
        );

        // Only count if BOTH pickup and dropoff are completed
        if (bin.isCompleted == 1 &&
            dropoff.isCompleted == 1 &&
            !completedMoveRequests.contains(bin.moveRequestId)) {
          completedMoveRequests.add(bin.moveRequestId!);
          count++;
        }
      } else if (bin.stopType == StopType.dropoff &&
          bin.moveRequestId != null) {
        // Skip dropoff - already handled in pickup branch
        continue;
      } else if (bin.stopType == StopType.collection &&
          bin.isCompleted == 1) {
        // Regular completed bin
        count++;
      }
    }

    return count;
  }
}

/// Shift status enum
enum ShiftStatus {
  /// No route assigned, cannot start shift (deprecated - use ended/cancelled)
  @JsonValue('inactive')
  inactive,

  /// Route assigned, ready to start shift
  @JsonValue('ready')
  ready,

  /// Shift in progress, timer running
  @JsonValue('active')
  active,

  /// Shift paused (break time)
  @JsonValue('paused')
  paused,

  /// Shift completed or manually ended by driver
  @JsonValue('ended')
  ended,

  /// Shift cancelled by manager
  @JsonValue('cancelled')
  cancelled,
}
