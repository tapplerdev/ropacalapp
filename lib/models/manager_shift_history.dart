import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:ropacalapp/core/utils/unix_timestamp_converter.dart';

part 'manager_shift_history.freezed.dart';
part 'manager_shift_history.g.dart';

/// Represents a completed shift from the manager's history view.
/// Maps to GET /api/manager/shifts/history response.
@freezed
class ManagerShiftHistory with _$ManagerShiftHistory {
  const factory ManagerShiftHistory({
    @JsonKey(name: 'id') required String shiftId,
    @JsonKey(name: 'driver_id') required String driverId,
    @JsonKey(name: 'driver_name') @Default('Unknown') String driverName,
    @JsonKey(name: 'driver_email') @Default('') String driverEmail,
    @JsonKey(name: 'route_id') String? routeId,
    @JsonKey(name: 'start_time') @UnixTimestampConverter() DateTime? startTime,
    @JsonKey(name: 'end_time') @UnixTimestampConverter() DateTime? endTime,
    @JsonKey(name: 'created_at') int? createdAt,
    @JsonKey(name: 'ended_at') int? endedAt,
    @JsonKey(name: 'total_pause_seconds') @Default(0) int totalPauseSeconds,
    @JsonKey(name: 'total_bins') @Default(0) int totalBins,
    @JsonKey(name: 'completed_bins') @Default(0) int completedBins,
    @JsonKey(name: 'completion_rate') @Default(0.0) double completionRate,
    @JsonKey(name: 'incidents_reported') @Default(0) int incidentsReported,
    @JsonKey(name: 'field_observations') @Default(0) int fieldObservations,
    @JsonKey(name: 'end_reason') @Default('completed') String endReason,
    @JsonKey(name: 'collections_completed') @Default(0) int collectionsCompleted,
    @JsonKey(name: 'collections_skipped') @Default(0) int collectionsSkipped,
    @JsonKey(name: 'placements_completed') @Default(0) int placementsCompleted,
    @JsonKey(name: 'placements_skipped') @Default(0) int placementsSkipped,
    @JsonKey(name: 'move_requests_completed') @Default(0) int moveRequestsCompleted,
    @JsonKey(name: 'total_skipped') @Default(0) int totalSkipped,
    @JsonKey(name: 'warehouse_stops') @Default(0) int warehouseStops,
  }) = _ManagerShiftHistory;

  const ManagerShiftHistory._();

  factory ManagerShiftHistory.fromJson(Map<String, dynamic> json) =>
      _$ManagerShiftHistoryFromJson(json);

  /// Active duration (total - pauses)
  Duration get activeDuration {
    if (startTime == null || endTime == null) return Duration.zero;
    final totalSeconds = endTime!.difference(startTime!).inSeconds;
    final activeSeconds = totalSeconds - totalPauseSeconds;
    return Duration(seconds: activeSeconds.clamp(0, totalSeconds));
  }

  /// Total wall-clock duration
  Duration get totalDuration {
    if (startTime == null || endTime == null) return Duration.zero;
    return endTime!.difference(startTime!);
  }

  /// Completion percentage 0.0 - 1.0
  double get completionPercentage {
    if (totalBins == 0) return 0.0;
    return (completedBins / totalBins).clamp(0.0, 1.0);
  }

  /// Formatted date when the shift ended
  String get endedDateFormatted {
    if (endedAt == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(endedAt! * 1000);
    return DateFormat('MMM d, y').format(dt);
  }

  /// Formatted active duration string
  String get durationFormatted {
    final d = activeDuration;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  /// Route display name
  String get routeDisplayName {
    if (routeId != null && routeId!.isNotEmpty) {
      final displayId =
          routeId!.length > 8 ? routeId!.substring(0, 8) : routeId!;
      return 'Route $displayId';
    }
    return 'Custom Shift';
  }
}
