// Temporary stub - will be replaced with Google Navigation implementation
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class MapboxRouteFetcherService {
  MapboxRouteFetcherService({
    required dynamic mapboxService,
    required dynamic ref,
  });

  Future<bool> fetchRouteForSequence(List<LatLng> waypoints) async {
    return false; // Stub implementation
  }

  Future<bool> fetchAndStoreRoute({
    required LatLng currentLocation,
    required List<dynamic> routeBins,
    bool optimize = false,
  }) async {
    return false; // Stub implementation - route fetching disabled during migration
  }
}
