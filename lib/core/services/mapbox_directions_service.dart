// Temporary stub - will be replaced with Google Navigation implementation
import 'package:latlong2/latlong.dart';

class MapboxDirectionsService {
  MapboxDirectionsService({required String accessToken});

  Future<dynamic> getRoute({
    required LatLng start,
    required List<dynamic> destinations,
  }) async {
    return null; // Stub implementation - route fetching disabled during migration
  }

  List<LatLng> getRoutePolyline(dynamic routeResponse) {
    return []; // Stub implementation - returns empty list during migration
  }
}
