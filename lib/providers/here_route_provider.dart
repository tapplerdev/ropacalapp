import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:ropacalapp/models/route_step.dart';

part 'here_route_provider.g.dart';

/// Provider to store HERE Maps route metadata including traffic-aware durations
@Riverpod(keepAlive: true)
class HereRouteMetadata extends _$HereRouteMetadata {
  @override
  HereRouteData? build() {
    AppLogger.routing(
      '🔔 DEBUG - HereRouteMetadata provider build() called (initializing to null)',
    );
    // Initially null, no HERE route data
    return null;
  }

  /// Store HERE Maps route response data
  void setRouteData({
    required List<double> legDurations,
    required List<double> legDistances,
    required double totalDuration,
    required double totalDistance,
    required List<latlong.LatLng> polyline,
    required List<RouteStep> steps,
  }) {
    AppLogger.routing(
      '🔔 DEBUG - setRouteData() called in HereRouteMetadata provider',
    );
    AppLogger.routing(
      '   Total duration: ${totalDuration}s (${(totalDuration / 60).toStringAsFixed(1)} min)',
    );
    AppLogger.routing(
      '   Total distance: ${totalDistance}m (${(totalDistance / 1000).toStringAsFixed(2)} km)',
    );
    AppLogger.routing('   Number of legs: ${legDurations.length}');
    AppLogger.routing('   Polyline points: ${polyline.length}');
    AppLogger.routing('   Turn instructions: ${steps.length}');

    state = HereRouteData(
      legDurations: legDurations,
      legDistances: legDistances,
      totalDuration: totalDuration,
      totalDistance: totalDistance,
      polyline: polyline,
      steps: steps,
    );

    AppLogger.routing('✅ DEBUG - state updated, listeners should be notified');
  }

  /// Clear route data
  void clearRouteData() {
    AppLogger.routing(
      '🔔 DEBUG - clearRouteData() called in HereRouteMetadata provider',
    );
    state = null;
    AppLogger.routing('✅ DEBUG - state cleared (set to null)');
  }
}

/// Data class to hold HERE Maps route metadata
class HereRouteData {
  final List<double> legDurations; // Duration for each leg in seconds
  final List<double> legDistances; // Distance for each leg in meters
  final double totalDuration; // Total duration in seconds
  final double totalDistance; // Total distance in meters
  final List<latlong.LatLng> polyline; // Route polyline coordinates
  final List<RouteStep> steps; // Turn-by-turn navigation instructions

  const HereRouteData({
    required this.legDurations,
    required this.legDistances,
    required this.totalDuration,
    required this.totalDistance,
    required this.polyline,
    required this.steps,
  });

  /// Get ETA to a specific bin index (in seconds)
  /// binIndex 0 = first bin, 1 = second bin, etc.
  double? getEtaToBin(int binIndex) {
    // AppLogger.routing('🔍 HereRouteData.getEtaToBin called:');
    // AppLogger.routing('   Requested binIndex: $binIndex');
    // AppLogger.routing('   Available legDurations: ${legDurations.length}');

    if (binIndex < 0 || binIndex >= legDurations.length) {
      // AppLogger.routing('   ❌ binIndex out of range, returning null');
      return null;
    }

    // Sum up durations from current location to target bin
    // binIndex 0 means we want duration of leg 0 (current location -> first bin)
    // binIndex 1 means we want legs 0 + 1 (current location -> first bin -> second bin)
    double totalDuration = 0.0;
    for (int i = 0; i <= binIndex; i++) {
      totalDuration += legDurations[i];
      // AppLogger.routing('   leg[$i] duration: ${legDurations[i]}s');
    }

    // AppLogger.routing('   ✅ Total duration to bin $binIndex: ${totalDuration}s (${(totalDuration / 60).toStringAsFixed(1)} min)');
    return totalDuration;
  }

  /// Get distance to a specific bin index (in meters)
  double? getDistanceToBin(int binIndex) {
    if (binIndex < 0 || binIndex >= legDistances.length) return null;

    // Sum up distances from current location to target bin
    double totalDistance = 0.0;
    for (int i = 0; i <= binIndex; i++) {
      totalDistance += legDistances[i];
    }

    return totalDistance;
  }
}
