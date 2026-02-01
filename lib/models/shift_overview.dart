import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/core/services/geofence_service.dart';

/// Data model for shift overview before starting
class ShiftOverview {
  final String shiftId;
  final DateTime startTime;
  final DateTime? estimatedEndTime;
  final int totalBins;
  final double? totalDistanceKm;
  final List<RouteBin> routeBins;
  final String routeName;
  final bool isOptimized;

  const ShiftOverview({
    required this.shiftId,
    required this.startTime,
    this.estimatedEndTime,
    required this.totalBins,
    this.totalDistanceKm,
    required this.routeBins,
    required this.routeName,
    this.isOptimized = false,
  });

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
