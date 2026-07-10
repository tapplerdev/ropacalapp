import 'package:ropacalapp/models/route_task.dart';
import 'package:ropacalapp/core/services/geofence_service.dart';
import 'package:ropacalapp/core/enums/stop_type.dart';

/// Logical job kinds for driver-facing shift summaries. Move legs are grouped
/// by their move request + move_type — a redeployment is ONE job, not
/// "1 pickup + 1 dropoff" — matching how the work is actually assigned.
/// movePickup/moveDropoff remain only as a fallback for legs whose move_type
/// is unknown (older data), rendering exactly as before.
enum JobKind {
  collection,
  placement,
  redeployment,
  relocation,
  storageReturn,
  movePickup,
  moveDropoff,
  service,
  warehouse,
}

/// Data model for shift overview before starting
class ShiftOverview {
  final String shiftId;
  final DateTime startTime;
  final DateTime? estimatedEndTime;
  final int totalBins;
  final double? totalDistanceKm;
  final List<RouteTask> tasks; // New task-based system
  final String routeName;
  final bool isOptimized;

  const ShiftOverview({
    required this.shiftId,
    required this.startTime,
    this.estimatedEndTime,
    required this.totalBins,
    this.totalDistanceKm,
    required this.tasks,
    required this.routeName,
    this.isOptimized = false,
  });

  /// Check if this is a task-based shift (new system)
  bool get isTaskBased => tasks.isNotEmpty;

  /// Get task counts by type
  Map<StopType, int> get taskCounts {
    if (!isTaskBased) return {};

    final counts = <StopType, int>{};
    for (final task in tasks) {
      counts[task.taskType] = (counts[task.taskType] ?? 0) + 1;
    }
    return counts;
  }

  /// Logical JOB counts for summary badges. Unlike [taskCounts] (raw rows),
  /// paired move legs collapse into one job by move_type: a redeployment shows
  /// as "1 Redeployment", not "1 Pickup + 1 Dropoff". Legs without a known
  /// move_type fall back to raw pickup/dropoff counts (renders as before).
  Map<JobKind, int> get jobCounts {
    if (!isTaskBased) return {};

    final counts = <JobKind, int>{};
    final countedMoves = <String>{};
    void bump(JobKind k) => counts[k] = (counts[k] ?? 0) + 1;

    for (final task in tasks) {
      switch (task.taskType) {
        case StopType.collection:
          bump(JobKind.collection);
        case StopType.placement:
          bump(JobKind.placement);
        case StopType.warehouseStop:
          bump(JobKind.warehouse);
        case StopType.service:
          bump(JobKind.service);
        case StopType.pickup:
        case StopType.dropoff:
          final moveId = task.moveRequestId;
          final kind = switch (task.moveType) {
            'redeployment' => JobKind.redeployment,
            'relocation' => JobKind.relocation,
            'store' || 'pickup_only' => JobKind.storageReturn,
            _ => null,
          };
          if (kind != null && moveId != null) {
            // Count each move request once, whichever leg we see first.
            if (countedMoves.add(moveId)) bump(kind);
          } else {
            // Unknown move_type — keep the raw leg badge as a fallback.
            bump(task.taskType == StopType.pickup
                ? JobKind.movePickup
                : JobKind.moveDropoff);
          }
      }
    }
    return counts;
  }

  /// Calculate estimated duration in hours
  double get estimatedDurationHours {
    if (estimatedEndTime == null) return 0.0;
    final duration = estimatedEndTime!.difference(startTime);
    return duration.inMinutes / 60.0;
  }

  /// Format time range for display (e.g., "8:00 AM - 2:00 PM")
  String get timeRangeFormatted {
    if (estimatedEndTime == null) return 'Route Pending';
    final startFormatted = _formatTime(startTime);
    final endFormatted = _formatTime(estimatedEndTime!);
    return '$startFormatted - $endFormatted';
  }

  /// Format single time (e.g., "8:00 AM")
  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Format distance for display (imperial units)
  /// Delegates to GeofenceService for consistent formatting
  String get distanceFormatted {
    if (totalDistanceKm == null || !isOptimized) return 'Route Pending';
    // Convert km to meters and use GeofenceService formatting
    return GeofenceService.formatDistance(totalDistanceKm! * 1000);
  }

  /// Format duration for display (e.g., "5h 30m")
  String get durationFormatted {
    if (estimatedEndTime == null || !isOptimized) return 'Route Pending';
    final hours = estimatedDurationHours.floor();
    final minutes = ((estimatedDurationHours - hours) * 60).round();

    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// Get summary stats string (e.g., "24 bins • 28 mi • ~5h 30m")
  String get summaryStats {
    if (!isOptimized) {
      return '$totalBins bins • Route Pending';
    }
    return '$totalBins bins • $distanceFormatted • ~$durationFormatted';
  }
}
