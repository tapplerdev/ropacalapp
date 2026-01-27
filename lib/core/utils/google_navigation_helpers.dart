import 'dart:math';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/core/services/geofence_service.dart';

/// Helper utilities for Google Navigation functionality
/// Contains formatting, conversion, and calculation methods
class GoogleNavigationHelpers {
  GoogleNavigationHelpers._(); // Private constructor - utility class

  /// Convert Google Navigation Maneuver enum to string representation
  static String convertManeuverType(Maneuver? maneuver) {
    if (maneuver == null) return 'UNKNOWN';

    switch (maneuver) {
      case Maneuver.destination:
        return 'DESTINATION';
      case Maneuver.depart:
        return 'DEPART';
      case Maneuver.destinationLeft:
        return 'DESTINATION_LEFT';
      case Maneuver.destinationRight:
        return 'DESTINATION_RIGHT';
      case Maneuver.ferryBoat:
        return 'FERRY_BOAT';
      case Maneuver.ferryTrain:
        return 'FERRY_TRAIN';
      case Maneuver.forkLeft:
        return 'FORK_LEFT';
      case Maneuver.forkRight:
        return 'FORK_RIGHT';
      case Maneuver.mergeLeft:
        return 'MERGE_LEFT';
      case Maneuver.mergeRight:
        return 'MERGE_RIGHT';
      case Maneuver.mergeUnspecified:
        return 'MERGE_UNSPECIFIED';
      case Maneuver.nameChange:
        return 'NAME_CHANGE';
      case Maneuver.offRampUnspecified:
        return 'OFF_RAMP_UNSPECIFIED';
      case Maneuver.offRampKeepLeft:
        return 'OFF_RAMP_KEEP_LEFT';
      case Maneuver.offRampKeepRight:
        return 'OFF_RAMP_KEEP_RIGHT';
      case Maneuver.offRampLeft:
        return 'OFF_RAMP_LEFT';
      case Maneuver.offRampRight:
        return 'OFF_RAMP_RIGHT';
      case Maneuver.offRampSharpLeft:
        return 'OFF_RAMP_SHARP_LEFT';
      case Maneuver.offRampSharpRight:
        return 'OFF_RAMP_SHARP_RIGHT';
      case Maneuver.offRampSlightLeft:
        return 'OFF_RAMP_SLIGHT_LEFT';
      case Maneuver.offRampSlightRight:
        return 'OFF_RAMP_SLIGHT_RIGHT';
      case Maneuver.offRampUTurnClockwise:
        return 'OFF_RAMP_U_TURN_CLOCKWISE';
      case Maneuver.offRampUTurnCounterclockwise:
        return 'OFF_RAMP_U_TURN_COUNTERCLOCKWISE';
      case Maneuver.onRampUnspecified:
        return 'ON_RAMP_UNSPECIFIED';
      case Maneuver.onRampKeepLeft:
        return 'ON_RAMP_KEEP_LEFT';
      case Maneuver.onRampKeepRight:
        return 'ON_RAMP_KEEP_RIGHT';
      case Maneuver.onRampLeft:
        return 'ON_RAMP_LEFT';
      case Maneuver.onRampRight:
        return 'ON_RAMP_RIGHT';
      case Maneuver.onRampSharpLeft:
        return 'ON_RAMP_SHARP_LEFT';
      case Maneuver.onRampSharpRight:
        return 'ON_RAMP_SHARP_RIGHT';
      case Maneuver.onRampSlightLeft:
        return 'ON_RAMP_SLIGHT_LEFT';
      case Maneuver.onRampSlightRight:
        return 'ON_RAMP_SLIGHT_RIGHT';
      case Maneuver.onRampUTurnClockwise:
        return 'ON_RAMP_U_TURN_CLOCKWISE';
      case Maneuver.onRampUTurnCounterclockwise:
        return 'ON_RAMP_U_TURN_COUNTERCLOCKWISE';
      case Maneuver.roundaboutClockwise:
        return 'ROUNDABOUT_CLOCKWISE';
      case Maneuver.roundaboutCounterclockwise:
        return 'ROUNDABOUT_COUNTERCLOCKWISE';
      case Maneuver.roundaboutExitClockwise:
        return 'ROUNDABOUT_EXIT_CLOCKWISE';
      case Maneuver.roundaboutExitCounterclockwise:
        return 'ROUNDABOUT_EXIT_COUNTERCLOCKWISE';
      case Maneuver.roundaboutLeftClockwise:
        return 'ROUNDABOUT_LEFT_CLOCKWISE';
      case Maneuver.roundaboutLeftCounterclockwise:
        return 'ROUNDABOUT_LEFT_COUNTERCLOCKWISE';
      case Maneuver.roundaboutRightClockwise:
        return 'ROUNDABOUT_RIGHT_CLOCKWISE';
      case Maneuver.roundaboutRightCounterclockwise:
        return 'ROUNDABOUT_RIGHT_COUNTERCLOCKWISE';
      case Maneuver.roundaboutSharpLeftClockwise:
        return 'ROUNDABOUT_SHARP_LEFT_CLOCKWISE';
      case Maneuver.roundaboutSharpLeftCounterclockwise:
        return 'ROUNDABOUT_SHARP_LEFT_COUNTERCLOCKWISE';
      case Maneuver.roundaboutSharpRightClockwise:
        return 'ROUNDABOUT_SHARP_RIGHT_CLOCKWISE';
      case Maneuver.roundaboutSharpRightCounterclockwise:
        return 'ROUNDABOUT_SHARP_RIGHT_COUNTERCLOCKWISE';
      case Maneuver.roundaboutSlightLeftClockwise:
        return 'ROUNDABOUT_SLIGHT_LEFT_CLOCKWISE';
      case Maneuver.roundaboutSlightLeftCounterclockwise:
        return 'ROUNDABOUT_SLIGHT_LEFT_COUNTERCLOCKWISE';
      case Maneuver.roundaboutSlightRightClockwise:
        return 'ROUNDABOUT_SLIGHT_RIGHT_CLOCKWISE';
      case Maneuver.roundaboutSlightRightCounterclockwise:
        return 'ROUNDABOUT_SLIGHT_RIGHT_COUNTERCLOCKWISE';
      case Maneuver.roundaboutStraightClockwise:
        return 'ROUNDABOUT_STRAIGHT_CLOCKWISE';
      case Maneuver.roundaboutStraightCounterclockwise:
        return 'ROUNDABOUT_STRAIGHT_COUNTERCLOCKWISE';
      case Maneuver.roundaboutUTurnClockwise:
        return 'ROUNDABOUT_U_TURN_CLOCKWISE';
      case Maneuver.roundaboutUTurnCounterclockwise:
        return 'ROUNDABOUT_U_TURN_COUNTERCLOCKWISE';
      case Maneuver.straight:
        return 'STRAIGHT';
      case Maneuver.turnKeepLeft:
        return 'TURN_KEEP_LEFT';
      case Maneuver.turnKeepRight:
        return 'TURN_KEEP_RIGHT';
      case Maneuver.turnLeft:
        return 'TURN_LEFT';
      case Maneuver.turnRight:
        return 'TURN_RIGHT';
      case Maneuver.turnSharpLeft:
        return 'TURN_SHARP_LEFT';
      case Maneuver.turnSharpRight:
        return 'TURN_SHARP_RIGHT';
      case Maneuver.turnSlightLeft:
        return 'TURN_SLIGHT_LEFT';
      case Maneuver.turnSlightRight:
        return 'TURN_SLIGHT_RIGHT';
      case Maneuver.turnUTurnClockwise:
        return 'TURN_U_TURN_CLOCKWISE';
      case Maneuver.turnUTurnCounterclockwise:
        return 'TURN_U_TURN_COUNTERCLOCKWISE';
      case Maneuver.unknown:
        return 'UNKNOWN';
    }
  }

  /// Extract modifier (left/right/slight/sharp) from instruction text
  static String extractModifier(String instruction) {
    final lowerInstruction = instruction.toLowerCase();

    if (lowerInstruction.contains('sharp left')) return 'sharp left';
    if (lowerInstruction.contains('sharp right')) return 'sharp right';
    if (lowerInstruction.contains('slight left')) return 'slight left';
    if (lowerInstruction.contains('slight right')) return 'slight right';
    if (lowerInstruction.contains('left')) return 'left';
    if (lowerInstruction.contains('right')) return 'right';
    if (lowerInstruction.contains('straight')) return 'straight';
    if (lowerInstruction.contains('u-turn')) return 'u-turn';

    return '';
  }

  /// Calculate distance between two coordinates using Haversine formula
  static double calculateDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371000.0; // meters

    final lat1 = degreesToRadians(point1.latitude);
    final lat2 = degreesToRadians(point2.latitude);
    final deltaLat = degreesToRadians(point2.latitude - point1.latitude);
    final deltaLon = degreesToRadians(point2.longitude - point1.longitude);

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Format distance in meters to human-readable string (imperial units)
  /// Delegates to GeofenceService for consistent formatting throughout the app
  static String formatDistance(double meters) {
    return GeofenceService.formatDistance(meters);
  }

  /// Format ETA duration to human-readable string
  static String formatETA(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Calculate estimated finish time from remaining duration
  static String calculateEstimatedFinishTime(Duration remainingTime) {
    final now = DateTime.now();
    final estimatedFinish = now.add(remainingTime);

    final hour = estimatedFinish.hour;
    final minute = estimatedFinish.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Get upcoming bins (next 2-3 bins after current index)
  static List<RouteBin> getUpcomingBins(List<RouteBin> allBins, int currentIndex) {
    if (currentIndex >= allBins.length - 1) {
      return [];
    }

    final upcoming = <RouteBin>[];
    for (int i = currentIndex + 1; i < allBins.length && upcoming.length < 3; i++) {
      upcoming.add(allBins[i]);
    }
    return upcoming;
  }
}
