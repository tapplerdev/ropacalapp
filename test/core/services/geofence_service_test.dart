import 'package:flutter_test/flutter_test.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:ropacalapp/core/services/geofence_service.dart';

void main() {
  group('GeofenceService - Imperial Units Conversion', () {
    test('formatDistance - shows feet for short distances', () {
      // 50 meters = ~164 feet
      expect(GeofenceService.formatDistance(50), '164 ft');

      // 100 meters = ~328 feet
      expect(GeofenceService.formatDistance(100), '328 ft');

      // 150 meters = ~492 feet
      expect(GeofenceService.formatDistance(150), '492 ft');
    });

    test('formatDistance - shows miles for long distances', () {
      // 1000 meters = ~0.6 miles
      expect(GeofenceService.formatDistance(1000), '0.6 mi');

      // 1600 meters = ~1.0 mile
      expect(GeofenceService.formatDistance(1600), '1.0 mi');

      // 5000 meters = ~3.1 miles
      expect(GeofenceService.formatDistance(5000), '3.1 mi');

      // 10000 meters = ~6.2 miles
      expect(GeofenceService.formatDistance(10000), '6.2 mi');
    });

    test('formatDistance - threshold at 0.1 miles (~161 meters)', () {
      // Just below threshold - should show feet
      expect(GeofenceService.formatDistance(160), '525 ft');

      // Just above threshold - should show miles
      expect(GeofenceService.formatDistance(162), '0.1 mi');
    });

    test('convertMetersToFeet - accurate conversion', () {
      expect(GeofenceService.convertMetersToFeet(100), closeTo(328.084, 0.01));
      expect(GeofenceService.convertMetersToFeet(500), closeTo(1640.42, 0.01));
    });

    test('convertMetersToMiles - accurate conversion', () {
      expect(GeofenceService.convertMetersToMiles(1609.34), closeTo(1.0, 0.01));
      expect(GeofenceService.convertMetersToMiles(8046.72), closeTo(5.0, 0.01));
    });

    test('getDistanceToTargetInFeet - calculates correctly', () {
      // San Francisco City Hall to Ferry Building (~2.9 km = ~1.8 miles = ~9,465 feet)
      final cityHall = LatLng(latitude: 37.7794, longitude: -122.4194);
      final ferryBuilding = LatLng(latitude: 37.7955, longitude: -122.3937);

      final distanceFeet = GeofenceService.getDistanceToTargetInFeet(
        currentLocation: cityHall,
        targetLocation: ferryBuilding,
      );

      // Should be approximately 9,400-9,600 feet
      expect(distanceFeet, greaterThan(9400));
      expect(distanceFeet, lessThan(9600));
    });

    test('getDistanceToTargetInMiles - calculates correctly', () {
      // Same locations
      final cityHall = LatLng(latitude: 37.7794, longitude: -122.4194);
      final ferryBuilding = LatLng(latitude: 37.7955, longitude: -122.3937);

      final distanceMiles = GeofenceService.getDistanceToTargetInMiles(
        currentLocation: cityHall,
        targetLocation: ferryBuilding,
      );

      // Should be approximately 1.75-1.85 miles
      expect(distanceMiles, greaterThan(1.75));
      expect(distanceMiles, lessThan(1.85));
    });
  });

  group('GeofenceService - Geofence Detection', () {
    test('isWithinGeofence - detects when inside 100m radius', () {
      final center = LatLng(latitude: 37.7749, longitude: -122.4194);

      // 50 meters away (inside)
      final nearby = LatLng(latitude: 37.7753, longitude: -122.4194);

      expect(
        GeofenceService.isWithinGeofence(
          currentLocation: nearby,
          targetLocation: center,
        ),
        true,
      );
    });

    test('isWithinGeofence - detects when outside 100m radius', () {
      final center = LatLng(latitude: 37.7749, longitude: -122.4194);

      // 500 meters away (outside)
      final farAway = LatLng(latitude: 37.7794, longitude: -122.4194);

      expect(
        GeofenceService.isWithinGeofence(
          currentLocation: farAway,
          targetLocation: center,
        ),
        false,
      );
    });

    test('isWithinGeofence - custom radius works', () {
      final center = LatLng(latitude: 37.7749, longitude: -122.4194);
      final location = LatLng(latitude: 37.7753, longitude: -122.4194);

      // Should be inside 100m but outside 10m
      expect(
        GeofenceService.isWithinGeofence(
          currentLocation: location,
          targetLocation: center,
          radiusMeters: 100,
        ),
        true,
      );

      expect(
        GeofenceService.isWithinGeofence(
          currentLocation: location,
          targetLocation: center,
          radiusMeters: 10,
        ),
        false,
      );
    });

    test('hasEnteredGeofence - detects transition into geofence', () {
      final center = LatLng(latitude: 37.7749, longitude: -122.4194);
      final insideLocation = LatLng(latitude: 37.7753, longitude: -122.4194);

      // Was outside, now inside
      expect(
        GeofenceService.hasEnteredGeofence(
          wasInsideGeofence: false,
          currentLocation: insideLocation,
          targetLocation: center,
        ),
        true,
      );

      // Was inside, still inside (no transition)
      expect(
        GeofenceService.hasEnteredGeofence(
          wasInsideGeofence: true,
          currentLocation: insideLocation,
          targetLocation: center,
        ),
        false,
      );
    });

    test('hasExitedGeofence - detects transition out of geofence', () {
      final center = LatLng(latitude: 37.7749, longitude: -122.4194);
      final outsideLocation = LatLng(latitude: 37.7794, longitude: -122.4194);

      // Was inside, now outside
      expect(
        GeofenceService.hasExitedGeofence(
          wasInsideGeofence: true,
          currentLocation: outsideLocation,
          targetLocation: center,
        ),
        true,
      );

      // Was outside, still outside (no transition)
      expect(
        GeofenceService.hasExitedGeofence(
          wasInsideGeofence: false,
          currentLocation: outsideLocation,
          targetLocation: center,
        ),
        false,
      );
    });
  });

  group('GeofenceService - Edge Cases', () {
    test('formatDistance - handles zero distance', () {
      expect(GeofenceService.formatDistance(0), '0 ft');
    });

    test('formatDistance - handles very small distances', () {
      expect(GeofenceService.formatDistance(0.5), '2 ft');
    });

    test('formatDistance - handles very large distances', () {
      // 100 km = ~62 miles
      expect(GeofenceService.formatDistance(100000), '62.1 mi');
    });

    test('getDistanceToTarget - same location returns 0', () {
      final location = LatLng(latitude: 37.7749, longitude: -122.4194);

      final distance = GeofenceService.getDistanceToTargetInMeters(
        currentLocation: location,
        targetLocation: location,
      );

      expect(distance, 0);
    });
  });
}
