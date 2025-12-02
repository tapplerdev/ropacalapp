import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:ropacalapp/core/utils/app_logger.dart';

/// Service for Google Routes API (Directions API v2)
/// https://developers.google.com/maps/documentation/routes
class GoogleRoutesService {
  final Dio _dio;
  static const String _apiKey = 'AIzaSyAH7PTzTVJrud5KqsDmWEw67mQkiA0Co4Y';
  static const String _baseUrl =
      'https://routes.googleapis.com/directions/v2:computeRoutes';

  GoogleRoutesService({Dio? dio}) : _dio = dio ?? Dio();

  /// Calculate route using Google Routes API
  Future<Map<String, dynamic>> calculateRoute({
    required latlong.LatLng origin,
    required List<latlong.LatLng> waypoints,
    required latlong.LatLng destination,
  }) async {
    try {
      AppLogger.routing('🗺️  GOOGLE ROUTES REQUEST');
      AppLogger.routing('   Origin: ${origin.latitude}, ${origin.longitude}');
      AppLogger.routing('   Waypoints: ${waypoints.length}');
      AppLogger.routing(
        '   Destination: ${destination.latitude}, ${destination.longitude}',
      );

      // Build request body
      final requestBody = {
        'origin': {
          'location': {
            'latLng': {
              'latitude': origin.latitude,
              'longitude': origin.longitude,
            },
          },
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': destination.latitude,
              'longitude': destination.longitude,
            },
          },
        },
        'intermediates': waypoints
            .map(
              (point) => {
                'location': {
                  'latLng': {
                    'latitude': point.latitude,
                    'longitude': point.longitude,
                  },
                },
              },
            )
            .toList(),
        'travelMode': 'DRIVE',
        'routingPreference': 'TRAFFIC_AWARE',
        'computeAlternativeRoutes': false,
        'routeModifiers': {
          'avoidTolls': false,
          'avoidHighways': false,
          'avoidFerries': false,
        },
        'languageCode': 'en-US',
        'units': 'METRIC',
      };

      AppLogger.routing('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await _dio.post(
        _baseUrl,
        data: requestBody,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask':
                'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs',
          },
        ),
      );

      AppLogger.routing('✅ GOOGLE ROUTES RESPONSE: ${response.statusCode}');
      AppLogger.routing('📦 Response data: ${jsonEncode(response.data)}');

      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.routing(
        '❌ Error calculating Google route: $e',
        level: AppLogger.error,
      );
      rethrow;
    }
  }

  /// Extract polyline from Google Routes response
  List<LatLng> getRoutePolyline(Map<String, dynamic> googleResponse) {
    try {
      AppLogger.routing(
        '🔍 Extracting polyline from Google Routes response...',
      );

      final routes = googleResponse['routes'] as List;
      if (routes.isEmpty) {
        AppLogger.routing(
          '❌ No routes found in response',
          level: AppLogger.warning,
        );
        return [];
      }

      final route = routes.first as Map<String, dynamic>;
      final polyline = route['polyline'] as Map<String, dynamic>;
      final encodedPolyline = polyline['encodedPolyline'] as String;

      AppLogger.routing(
        '   Encoded polyline length: ${encodedPolyline.length}',
      );

      // Decode polyline
      final points = _decodePolyline(encodedPolyline);

      AppLogger.routing('✅ Extracted ${points.length} polyline points');
      if (points.isNotEmpty) {
        AppLogger.routing('   First point: ${points.first}');
        AppLogger.routing('   Last point: ${points.last}');
      }

      return points;
    } catch (e) {
      AppLogger.routing(
        '❌ Error extracting route polyline: $e',
        level: AppLogger.error,
      );
      return [];
    }
  }

  /// Decode Google's encoded polyline format
  /// https://developers.google.com/maps/documentation/utilities/polylinealgorithm
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double latitude = lat / 1E5;
      double longitude = lng / 1E5;

      points.add(LatLng(latitude: latitude, longitude: longitude));
    }

    return points;
  }

  /// Get route statistics from Google Routes response
  Map<String, dynamic> getRouteStats(Map<String, dynamic> googleResponse) {
    try {
      final routes = googleResponse['routes'] as List;
      if (routes.isEmpty) {
        return {'distance': 0.0, 'duration': 0.0};
      }

      final route = routes.first as Map<String, dynamic>;
      final distanceMeters = route['distanceMeters'] as int;
      final duration = route['duration'] as String;

      // Parse duration (format: "1234s")
      final durationSeconds = int.parse(duration.replaceAll('s', ''));

      AppLogger.routing('📊 Google Route statistics:');
      AppLogger.routing(
        '   Distance: ${(distanceMeters / 1000).toStringAsFixed(2)} km',
      );
      AppLogger.routing(
        '   Duration: ${(durationSeconds / 60).toStringAsFixed(1)} min',
      );

      return {
        'distance': distanceMeters / 1000.0, // km
        'duration': durationSeconds / 60.0, // minutes
      };
    } catch (e) {
      AppLogger.routing(
        '❌ Error extracting route stats: $e',
        level: AppLogger.error,
      );
      return {'distance': 0.0, 'duration': 0.0};
    }
  }
}
