import 'package:latlong2/latlong.dart';
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/services/geofence_service.dart';

/// Helper utilities for location-based calculations and proximity checks
class LocationHelpers {
  // Prevent instantiation
  LocationHelpers._();

  /// Check if user is within required proximity of a bin location
  ///
  /// Returns true if the user is within [requiredProximityMeters] of the bin.
  /// Returns false if user location is null or outside the required range.
  ///
  /// Example:
  /// ```dart
  /// final isNearby = LocationHelpers.isWithinProximity(
  ///   userLocation: currentLocation,
  ///   binLatitude: 37.7749,
  ///   binLongitude: -122.4194,
  /// );
  /// ```
  static bool isWithinProximity({
    required LatLng? userLocation,
    required double binLatitude,
    required double binLongitude,
    double requiredProximityMeters = BinConstants.binCompletionProximity,
  }) {
    if (userLocation == null) return false;

    final distance = Distance();
    final binLocation = LatLng(binLatitude, binLongitude);

    final distanceMeters = distance.as(
      LengthUnit.Meter,
      userLocation,
      binLocation,
    );

    return distanceMeters <= requiredProximityMeters;
  }

  /// Get distance to a bin location in meters
  ///
  /// Returns the distance in meters, or null if user location is unavailable.
  ///
  /// Example:
  /// ```dart
  /// final distance = LocationHelpers.getDistanceToBin(
  ///   userLocation: currentLocation,
  ///   binLatitude: 37.7749,
  ///   binLongitude: -122.4194,
  /// );
  /// print('Distance: ${distance?.round()}m');
  /// ```
  static double? getDistanceToBin({
    required LatLng? userLocation,
    required double binLatitude,
    required double binLongitude,
  }) {
    if (userLocation == null) return null;

    final distance = Distance();
    final binLocation = LatLng(binLatitude, binLongitude);

    return distance.as(LengthUnit.Meter, userLocation, binLocation);
  }

  /// Format distance for display with appropriate units (imperial)
  ///
  /// Returns a human-readable string with feet or miles.
  /// Delegates to GeofenceService for consistent formatting throughout the app.
  ///
  /// Example:
  /// ```dart
  /// final formatted = LocationHelpers.formatDistance(1500.0);
  /// print(formatted); // "0.9 mi"
  /// ```
  static String formatDistance(double? distanceMeters) {
    if (distanceMeters == null) return 'Calculating...';
    return GeofenceService.formatDistance(distanceMeters);
  }
}
