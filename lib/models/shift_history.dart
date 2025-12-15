import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ropacalapp/core/utils/unix_timestamp_converter.dart';
import 'package:ropacalapp/models/shift_state.dart';

part 'shift_history.freezed.dart';
part 'shift_history.g.dart';

/// Represents a completed shift in the driver's history
@freezed
class ShiftHistory with _$ShiftHistory {
  const factory ShiftHistory({
    /// Shift ID
    @JsonKey(name: 'id') required String shiftId,

    /// Driver ID who completed this shift
    @JsonKey(name: 'driver_id') required String driverId,

    /// Route ID assigned to this shift
    @JsonKey(name: 'route_id') String? routeId,

    /// Shift status
    required ShiftStatus status,

    /// When the shift started
    @JsonKey(name: 'start_time') @UnixTimestampConverter() DateTime? startTime,

    /// When the shift ended
    @JsonKey(name: 'end_time') @UnixTimestampConverter() DateTime? endTime,

    /// Total pause time in seconds
    @JsonKey(name: 'total_pause_seconds') @Default(0) int totalPauseSeconds,

    /// Total bins in route
    @JsonKey(name: 'total_bins') @Default(0) int totalBins,

    /// Completed bins count
    @JsonKey(name: 'completed_bins') @Default(0) int completedBins,

    /// Created timestamp
    @JsonKey(name: 'created_at') int? createdAt,

    /// Updated timestamp
    @JsonKey(name: 'updated_at') int? updatedAt,
  }) = _ShiftHistory;

  const ShiftHistory._();

  factory ShiftHistory.fromJson(Map<String, dynamic> json) =>
      _$ShiftHistoryFromJson(json);

  /// Get active shift duration (excluding pauses)
  Duration get activeDuration {
    if (startTime == null || endTime == null) {
      return Duration.zero;
    }

    final totalSeconds = endTime!.difference(startTime!).inSeconds;
    final activeSeconds = totalSeconds - totalPauseSeconds;
    return Duration(seconds: activeSeconds.clamp(0, totalSeconds));
  }

  /// Get total shift duration (including pauses)
  Duration get totalDuration {
    if (startTime == null || endTime == null) {
      return Duration.zero;
    }

    return endTime!.difference(startTime!);
  }

  /// Get completion percentage
  double get completionPercentage {
    if (totalBins == 0) return 0.0;
    return (completedBins / totalBins).clamp(0.0, 1.0);
  }

  /// Check if shift is fully complete
  bool get isComplete {
    return completedBins >= totalBins;
  }

  /// Get display name for the route
  String get routeDisplayName {
    if (routeId != null && routeId!.isNotEmpty) {
      return 'Route ${routeId!.substring(0, 8)}';
    }
    return 'Unknown Route';
  }
}
