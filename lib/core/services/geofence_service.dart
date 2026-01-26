import 'package:geolocator/geolocator.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

/// Service for geofence-based proximity detection
///
/// Used to detect when driver is within range of pickup/dropoff locations
/// for move requests, or within range of bin collection stops.
///
/// All distance displays use imperial units (feet/miles) for US operations.
class GeofenceService {
  /// Default geofence radius in meters (100m = ~328 feet)
  /// TEMPORARILY DISABLED FOR TESTING - Set to 1000km to allow testing anywhere
  static const double defaultGeofenceRadiusMeters = 1000000.0;

  /// Conversion constants
  static const double metersToFeet = 3.28084;
  static const double metersToMiles = 0.000621371;
  static const double feetPerMile = 5280.0;

  /// Check if driver is within geofence of a location
  ///
  /// Returns true if [currentLocation] is within [radiusMeters] of [targetLocation]
  static bool isWithinGeofence({
    required LatLng currentLocation,
    required LatLng targetLocation,
    double radiusMeters = defaultGeofenceRadiusMeters,
  }) {
    final distance = getDistanceToTargetInMeters(
      currentLocation: currentLocation,
      targetLocation: targetLocation,
    );

    return distance <= radiusMeters;
  }

  /// Get distance to target in meters (for internal calculations)
  ///
  /// Uses Haversine formula to calculate distance between two coordinates
  static double getDistanceToTargetInMeters({
    required LatLng currentLocation,
    required LatLng targetLocation,
  }) {
    return Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      targetLocation.latitude,
      targetLocation.longitude,
    );
  }

  /// Get distance to target in feet (for US display)
  static double getDistanceToTargetInFeet({
    required LatLng currentLocation,
    required LatLng targetLocation,
  }) {
    final meters = getDistanceToTargetInMeters(
      currentLocation: currentLocation,
      targetLocation: targetLocation,
    );
    return meters * metersToFeet;
  }

  /// Get distance to target in miles (for US display)
  static double getDistanceToTargetInMiles({
    required LatLng currentLocation,
    required LatLng targetLocation,
  }) {
    final meters = getDistanceToTargetInMeters(
      currentLocation: currentLocation,
      targetLocation: targetLocation,
    );
    return meters * metersToMiles;
  }

  /// Convert meters to feet
  static double convertMetersToFeet(double meters) {
    return meters * metersToFeet;
  }

  /// Convert meters to miles
  static double convertMetersToMiles(double meters) {
    return meters * metersToMiles;
  }

  /// Format distance for display (imperial units)
  ///
  /// Returns formatted string: "150 ft" or "1.2 mi"
  /// Uses feet for distances under 0.1 miles (~528 feet)
  static String formatDistance(double distanceMeters) {
    final distanceMiles = distanceMeters * metersToMiles;

    if (distanceMiles < 0.1) {
      // Show in feet for short distances
      final distanceFeet = distanceMeters * metersToFeet;
      return '${distanceFeet.round()} ft';
    } else {
      // Show in miles for longer distances
      return '${distanceMiles.toStringAsFixed(1)} mi';
    }
  }

  /// Format distance for display with more precision
  ///
  /// Returns formatted string: "328 ft" or "1.25 mi"
  static String formatDistanceDetailed(double distanceMeters) {
    final distanceMiles = distanceMeters * metersToMiles;

    if (distanceMiles < 0.1) {
      final distanceFeet = distanceMeters * metersToFeet;
      return '${distanceFeet.round()} ft';
    } else {
      return '${distanceMiles.toStringAsFixed(2)} mi';
    }
  }

  /// Check if driver has entered geofence (state transition)
  ///
  /// Returns true if driver was outside geofence and is now inside
  static bool hasEnteredGeofence({
    required bool wasInsideGeofence,
    required LatLng currentLocation,
    required LatLng targetLocation,
    double radiusMeters = defaultGeofenceRadiusMeters,
  }) {
    final isNowInside = isWithinGeofence(
      currentLocation: currentLocation,
      targetLocation: targetLocation,
      radiusMeters: radiusMeters,
    );

    return !wasInsideGeofence && isNowInside;
  }

  /// Check if driver has exited geofence (state transition)
  ///
  /// Returns true if driver was inside geofence and is now outside
  static bool hasExitedGeofence({
    required bool wasInsideGeofence,
    required LatLng currentLocation,
    required LatLng targetLocation,
    double radiusMeters = defaultGeofenceRadiusMeters,
  }) {
    final isNowInside = isWithinGeofence(
      currentLocation: currentLocation,
      targetLocation: targetLocation,
      radiusMeters: radiusMeters,
    );

    return wasInsideGeofence && !isNowInside;
  }
}
