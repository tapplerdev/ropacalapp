import 'package:riverpod/riverpod.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:ropacalapp/core/services/here_maps_service.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/providers/here_route_provider.dart';
import 'package:ropacalapp/core/enums/bin_status.dart';

/// Service for fetching and storing HERE Maps routes
/// Centralizes route fetching logic used across the app
class HereRouteFetcherService {
  final HEREMapsService hereService;
  final Ref ref;

  HereRouteFetcherService({required this.hereService, required this.ref});

  /// Fetch HERE Maps route and store in hereRouteMetadataProvider
  ///
  /// [currentLocation] - Driver's current GPS location
  /// [routeBins] - List of bins in the route (from shift data)
  /// [optimize] - Whether to use waypoint optimization (default: true)
  ///
  /// Returns true if successful, false if failed
  Future<bool> fetchAndStoreRoute({
    required latlong.LatLng currentLocation,
    required List<RouteBin> routeBins,
    bool optimize = true,
  }) async {
    try {
      AppLogger.routing('🚗 HereRouteFetcherService: Starting route fetch...');
      AppLogger.routing(
        '   Current location: ${currentLocation.latitude},${currentLocation.longitude}',
      );
      AppLogger.routing('   Route bins: ${routeBins.length}');
      AppLogger.routing('   Optimize: $optimize');

      // Step 1: Convert RouteBins to Bins
      final binList = _convertToBins(routeBins);

      // Step 2: Get optimized waypoint sequence (if enabled)
      List<Bin> orderedBins;
      if (optimize) {
        final optimizedIndices = await hereService.getOptimizedWaypointSequence(
          start: currentLocation,
          destinations: binList,
          departureTime: DateTime.now(),
          improveFor: 'time',
        );

        if (optimizedIndices != null && optimizedIndices.isNotEmpty) {
          orderedBins = optimizedIndices.map((idx) => binList[idx]).toList();
          AppLogger.routing(
            '🎯 Using optimized order: ${orderedBins.map((b) => b.binNumber ?? 0).toList()}',
          );

          // Log differences from backend order
          for (int i = 0; i < binList.length; i++) {
            final backendBin = binList[i].binNumber ?? 0;
            final hereBin = orderedBins[i].binNumber ?? 0;
            if (backendBin != hereBin) {
              AppLogger.routing(
                '   Position $i: Backend=#$backendBin → HERE=#$hereBin',
              );
            }
          }
        } else {
          // Optimization failed - use backend order
          AppLogger.routing(
            '⚠️  Optimization unavailable, using backend order',
          );
          orderedBins = binList;
        }
      } else {
        // Optimization disabled - use backend order
        orderedBins = binList;
      }

      // Step 3: Get route with traffic-aware durations
      final hereResponse = await hereService.getRoute(
        start: currentLocation,
        destinations: orderedBins,
        departureTime: DateTime.now(),
      );

      // Step 4: Extract route data
      final legDurations = hereService.getLegDurations(hereResponse);
      final legDistances = hereService.getLegDistances(hereResponse);
      final totalDuration = hereService.getTotalDuration(hereResponse);
      final totalDistance = hereService.getTotalDistance(hereResponse);
      final polyline = hereService.getRoutePolyline(hereResponse);
      final steps = hereService.parseRouteSteps(hereResponse);

      AppLogger.routing('📏 Route metrics:');
      AppLogger.routing('   Bins/waypoints: ${orderedBins.length}');
      AppLogger.routing('   Sections received: ${legDurations.length}');
      AppLogger.routing(
        '   Total duration: ${(totalDuration / 60).toStringAsFixed(1)} min',
      );
      AppLogger.routing(
        '   Total distance: ${(totalDistance / 1000).toStringAsFixed(2)} km',
      );
      AppLogger.routing('   Polyline points: ${polyline.length}');
      AppLogger.routing('   Turn instructions: ${steps.length}');

      // Verify section count matches waypoint count
      if (legDurations.length != orderedBins.length) {
        AppLogger.routing('⚠️  WARNING: Section count mismatch!');
        AppLogger.routing(
          '   Expected ${orderedBins.length} sections, got ${legDurations.length}',
        );
      }

      // Step 5: Store route metadata
      ref
          .read(hereRouteMetadataProvider.notifier)
          .setRouteData(
            legDurations: legDurations,
            legDistances: legDistances,
            totalDuration: totalDuration,
            totalDistance: totalDistance,
            polyline: polyline,
            steps: steps,
          );

      AppLogger.routing('✅ HERE Maps route fetched & stored successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.routing('❌ Error fetching HERE route: $e');
      AppLogger.routing(
        '   Stack trace: ${stackTrace.toString().split('\n').take(3).join('\n')}',
      );
      return false;
    }
  }

  /// Convert RouteBins to Bins for HERE Maps API
  List<Bin> _convertToBins(List<RouteBin> routeBins) {
    return routeBins.map((routeBin) {
      return Bin(
        id: routeBin.binId,
        binNumber: routeBin.binNumber,
        currentStreet: routeBin.currentStreet,
        city: routeBin.city,
        zip: routeBin.zip,
        latitude: routeBin.latitude,
        longitude: routeBin.longitude,
        fillPercentage: routeBin.fillPercentage,
        status: BinStatus.active,
        lastMoved: null,
        lastChecked: null,
        checked: false,
        moveRequested: false,
      );
    }).toList();
  }
}
