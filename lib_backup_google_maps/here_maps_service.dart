import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:flexible_polyline_dart/flutter_flexible_polyline.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/route_step.dart';
import 'package:ropacalapp/models/bin.dart';

class HEREMapsService {
  final Dio _dio;
  final String apiKey;
  static const String _baseUrl = 'https://router.hereapi.com/v8';

  HEREMapsService({required this.apiKey, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              listFormat: ListFormat
                  .multi, // Enable repeated query params (via=a&via=b)
            ),
          ) {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.routing('🗺️  HERE Maps REQUEST:');
          AppLogger.routing('   Method: ${options.method}');
          AppLogger.routing('   URL: ${options.uri}');
          AppLogger.routing('   Query Params: ${options.queryParameters}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.routing('✅ HERE Maps RESPONSE:');
          AppLogger.routing('   Status: ${response.statusCode}');
          AppLogger.routing(
            '   Body preview: ${response.data.toString().substring(0, response.data.toString().length > 200 ? 200 : response.data.toString().length)}...',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          AppLogger.routing('❌ HERE Maps ERROR:');
          AppLogger.routing('   Type: ${error.type}');
          AppLogger.routing('   Message: ${error.message}');

          // Log response details if available
          if (error.response != null) {
            AppLogger.routing('   Status Code: ${error.response?.statusCode}');
            AppLogger.routing(
              '   Status Message: ${error.response?.statusMessage}',
            );
            AppLogger.routing(
              '   Response Headers: ${error.response?.headers}',
            );
            AppLogger.routing('   Response Body: ${error.response?.data}');
          }

          // Log request details
          if (error.requestOptions != null) {
            AppLogger.routing('   Request URL: ${error.requestOptions.uri}');
            AppLogger.routing(
              '   Request Method: ${error.requestOptions.method}',
            );
            AppLogger.routing(
              '   Request Params: ${error.requestOptions.queryParameters}',
            );
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// Get route with turn-by-turn instructions and real-time traffic
  ///
  /// Uses HERE Routing API v8 to calculate routes with:
  /// - Real-time traffic data
  /// - Turn-by-turn instructions
  /// - Accurate travel time and distance
  ///
  /// [start] - Starting location (driver's current position)
  /// [destinations] - List of bins to visit in order
  /// [departureTime] - Optional departure time for traffic-aware routing
  ///
  /// Returns route data including polyline, sections, and travel metrics
  Future<Map<String, dynamic>> getRoute({
    required LatLng start,
    required List<Bin> destinations,
    DateTime? departureTime,
  }) async {
    try {
      // Log route endpoints for debugging
      AppLogger.routing('📍 Route start: ${start.latitude},${start.longitude}');
      AppLogger.routing(
        '📍 Route end: ${destinations.last.latitude},${destinations.last.longitude}',
      );

      // Build query parameters following HERE v8 API specifications
      final queryParams = <String, dynamic>{
        'apiKey': apiKey,
        'transportMode': 'car',
        'return': 'polyline,summary,actions,instructions',
        'spans': 'length,duration,speedLimit',
        'origin': '${start.latitude},${start.longitude}',
        'destination':
            '${destinations.last.latitude},${destinations.last.longitude}',
      };

      // Add via waypoints (intermediate stops) using repeated 'via' parameter
      // Format: via=lat,lng!stopDuration=0 for passthrough points
      // Dio with ListFormat.multi converts list to repeated params: via=...&via=...
      if (destinations.length > 1) {
        final viaPoints = <String>[];
        for (var i = 0; i < destinations.length - 1; i++) {
          final bin = destinations[i];
          // stopDuration=0 means passthrough (no actual stop)
          viaPoints.add('${bin.latitude},${bin.longitude}!stopDuration=0');
        }

        // Pass as list - Dio will convert to repeated 'via' parameters
        queryParams['via'] = viaPoints;

        AppLogger.routing('📍 Added ${viaPoints.length} via waypoints');
        AppLogger.routing('   Format: ${viaPoints.join(" & ")}');
      }

      // Add departure time for traffic-aware routing
      final effectiveDepartureTime = departureTime ?? DateTime.now();
      queryParams['departureTime'] = _formatHereMapsDateTime(
        effectiveDepartureTime,
      );
      AppLogger.routing(
        '🕐 Departure time: ${effectiveDepartureTime.toIso8601String()}',
      );

      // HERE Routing API v8
      final response = await _dio.get('/routes', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get route: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.routing('❌ Error fetching HERE route: $e');
      rethrow;
    }
  }

  /// Parse HERE Maps response into RouteStep objects
  List<RouteStep> parseRouteSteps(Map<String, dynamic> hereResponse) {
    final steps = <RouteStep>[];

    try {
      final routes = hereResponse['routes'] as List;
      if (routes.isEmpty) return steps;

      final route = routes.first as Map<String, dynamic>;
      final sections = route['sections'] as List;

      for (var section in sections) {
        final actions = section['actions'] as List?;
        if (actions == null) continue;

        for (var action in actions) {
          final actionType = action['action'] as String? ?? '';
          final instruction = action['instruction'] as String? ?? '';
          final duration = (action['duration'] as num?)?.toDouble() ?? 0.0;
          final length = (action['length'] as num?)?.toDouble() ?? 0.0;

          // Extract location from offset in polyline
          LatLng? location;
          if (action['offset'] != null) {
            final offset = action['offset'] as int;
            location = _getLocationFromPolyline(section, offset);
          }

          steps.add(
            RouteStep(
              instruction: instruction,
              distance: length,
              duration: duration,
              maneuverType: _mapActionType(actionType),
              location: location ?? const LatLng(0, 0),
              modifier: null,
              name: action['nextRoadName'] as String? ?? '',
            ),
          );
        }
      }

      AppLogger.routing('📍 Parsed ${steps.length} HERE route steps');
      return steps;
    } catch (e) {
      AppLogger.routing('❌ Error parsing HERE route steps: $e');
      return steps;
    }
  }

  /// Map HERE action types to OSRM-like maneuver types
  String _mapActionType(String actionType) {
    switch (actionType) {
      case 'depart':
        return 'depart';
      case 'arrive':
        return 'arrive';
      case 'turn':
        return 'turn';
      case 'continue':
        return 'continue';
      case 'merge':
        return 'merge';
      case 'fork':
        return 'fork';
      case 'roundaboutEnter':
        return 'roundabout';
      default:
        return 'continue';
    }
  }

  /// Extract location from polyline at specific offset
  LatLng? _getLocationFromPolyline(Map<String, dynamic> section, int offset) {
    try {
      final polyline = section['polyline'] as String?;
      if (polyline == null) return null;

      // Decode HERE flexible polyline
      final coordinates = _decodeFlexiblePolyline(polyline);
      if (offset < coordinates.length) {
        return coordinates[offset];
      }
    } catch (e) {
      AppLogger.routing('❌ Error extracting location: $e');
    }
    return null;
  }

  /// Calculate total distance from route response (meters)
  double getTotalDistance(Map<String, dynamic> hereResponse) {
    try {
      final routes = hereResponse['routes'] as List;
      if (routes.isEmpty) return 0.0;

      final route = routes.first as Map<String, dynamic>;
      final sections = route['sections'] as List;

      double totalDistance = 0.0;
      for (var section in sections) {
        final summary = section['summary'] as Map<String, dynamic>?;
        if (summary != null) {
          totalDistance += (summary['length'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return totalDistance;
    } catch (e) {
      AppLogger.routing('❌ Error getting total distance: $e');
      return 0.0;
    }
  }

  /// Calculate total duration from route response (seconds)
  /// Includes real-time traffic if departureTime was provided
  double getTotalDuration(Map<String, dynamic> hereResponse) {
    try {
      final routes = hereResponse['routes'] as List;
      if (routes.isEmpty) return 0.0;

      final route = routes.first as Map<String, dynamic>;
      final sections = route['sections'] as List;

      double totalDuration = 0.0;
      for (var section in sections) {
        final summary = section['summary'] as Map<String, dynamic>?;
        if (summary != null) {
          totalDuration += (summary['duration'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return totalDuration;
    } catch (e) {
      AppLogger.routing('❌ Error getting total duration: $e');
      return 0.0;
    }
  }

  /// Extract route polyline coordinates from HERE response
  List<LatLng> getRoutePolyline(Map<String, dynamic> hereResponse) {
    final polyline = <LatLng>[];

    try {
      AppLogger.routing('🔍 Extracting polyline from HERE response...');
      final routes = hereResponse['routes'] as List;
      AppLogger.routing('   Routes count: ${routes.length}');

      if (routes.isEmpty) {
        AppLogger.routing('❌ No routes in response');
        return polyline;
      }

      final route = routes.first as Map<String, dynamic>;
      final sections = route['sections'] as List;
      AppLogger.routing('   Sections count: ${sections.length}');

      // Decode polyline from each section
      for (var section in sections) {
        final encodedPolyline = section['polyline'] as String?;
        if (encodedPolyline != null) {
          final sectionPoints = _decodeFlexiblePolyline(encodedPolyline);
          polyline.addAll(sectionPoints);
        }
      }

      AppLogger.routing('✅ Extracted ${polyline.length} polyline points');
      if (polyline.isNotEmpty) {
        AppLogger.routing('   First point: ${polyline.first}');
        AppLogger.routing('   Last point: ${polyline.last}');
      }

      return polyline;
    } catch (e) {
      AppLogger.routing('❌ Error extracting route polyline: $e');
      return polyline;
    }
  }

  /// Get duration for each leg (waypoint to waypoint) in seconds
  /// Each section represents one leg of the journey
  /// Returns list of durations where index 0 is origin->first bin,
  /// index 1 is first bin->second bin, etc.
  List<double> getLegDurations(Map<String, dynamic> hereResponse) {
    final legDurations = <double>[];

    try {
      final routes = hereResponse['routes'] as List;
      if (routes.isEmpty) return legDurations;

      final route = routes.first as Map<String, dynamic>;
      final sections = route['sections'] as List;

      for (var section in sections) {
        final summary = section['summary'] as Map<String, dynamic>?;
        if (summary != null) {
          final duration = (summary['duration'] as num?)?.toDouble() ?? 0.0;
          legDurations.add(duration);
        }
      }

      AppLogger.routing('📊 Extracted ${legDurations.length} leg durations');
      return legDurations;
    } catch (e) {
      AppLogger.routing('❌ Error getting leg durations: $e');
      return legDurations;
    }
  }

  /// Get distance for each leg (waypoint to waypoint) in meters
  /// Each section represents one leg of the journey
  List<double> getLegDistances(Map<String, dynamic> hereResponse) {
    final legDistances = <double>[];

    try {
      final routes = hereResponse['routes'] as List;
      if (routes.isEmpty) return legDistances;

      final route = routes.first as Map<String, dynamic>;
      final sections = route['sections'] as List;

      for (var section in sections) {
        final summary = section['summary'] as Map<String, dynamic>?;
        if (summary != null) {
          final distance = (summary['length'] as num?)?.toDouble() ?? 0.0;
          legDistances.add(distance);
        }
      }

      AppLogger.routing('📊 Extracted ${legDistances.length} leg distances');
      return legDistances;
    } catch (e) {
      AppLogger.routing('❌ Error getting leg distances: $e');
      return legDistances;
    }
  }

  /// Optimize waypoint order using HERE Waypoints Sequence API v8
  ///
  /// The Routing API v8 does NOT support waypoint optimization.
  /// For that, we need the separate Waypoints Sequence API which:
  /// - Finds optimal order of waypoints based on time or distance
  /// - Takes traffic conditions into account
  /// - Returns optimized sequence indices
  ///
  /// [start] - Starting location
  /// [destinations] - List of bins to optimize
  /// [departureTime] - Optional departure time for traffic-aware optimization
  /// [improveFor] - Optimization goal: 'time' (default) or 'distance'
  ///
  /// Returns list of optimized indices, or null if optimization fails
  /// Example: [0, 2, 1] means visit destination 0, then 2, then 1
  Future<List<int>?> getOptimizedWaypointSequence({
    required LatLng start,
    required List<Bin> destinations,
    DateTime? departureTime,
    String improveFor = 'time',
  }) async {
    try {
      AppLogger.routing(
        '🔀 Requesting waypoint optimization from Sequence API...',
      );
      AppLogger.routing('   Start: ${start.latitude},${start.longitude}');
      AppLogger.routing('   Destinations: ${destinations.length}');
      AppLogger.routing('   Optimize for: $improveFor');

      // Build query parameters for Waypoint Sequence API v8
      final queryParams = <String, dynamic>{
        'apiKey': apiKey,
        'mode': 'fastest;car;traffic:enabled',
        'start': '${start.latitude},${start.longitude}',
        'end': '${destinations.last.latitude},${destinations.last.longitude}',
      };

      // Add intermediate destinations as destination1, destination2, etc.
      // Note: Last destination becomes 'end', so we only add destinations[0..length-2]
      for (var i = 0; i < destinations.length - 1; i++) {
        final bin = destinations[i];
        final destNum = i + 1;
        queryParams['destination$destNum'] = '${bin.latitude},${bin.longitude}';
        AppLogger.routing(
          '   destination$destNum: ${bin.latitude},${bin.longitude}',
        );
      }

      // Add departure time if specified (ISO 8601 format)
      if (departureTime != null) {
        queryParams['departure'] = _formatHereMapsDateTime(departureTime);
      }

      // Create separate Dio instance for waypoint sequence API (different base URL)
      final sequenceDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          listFormat:
              ListFormat.multi, // Enable repeated query params if needed
        ),
      );

      final response = await sequenceDio.get(
        'https://wps.hereapi.com/v8/findsequence2',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        AppLogger.routing('📊 Sequence API response received');

        // Extract optimized sequence from response
        // Response format: {"results": [{"waypoints": [{"id": 0, "sequence": 0}, ...]}]}
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final firstResult = results.first as Map<String, dynamic>;
          final waypoints = firstResult['waypoints'] as List?;

          if (waypoints != null && waypoints.isNotEmpty) {
            // Create a list of (id, sequence) pairs for sorting
            final waypointData = <Map<String, int>>[];

            for (final waypoint in waypoints) {
              final wp = waypoint as Map<String, dynamic>;

              // Handle both int and String types from API response
              final idValue = wp['id'];
              final seqValue = wp['sequence'];

              // Parse id - could be int or String
              final int? id = idValue is int
                  ? idValue
                  : (idValue is String ? int.tryParse(idValue) : null);

              // Parse sequence - could be int or String
              final int? seqNum = seqValue is int
                  ? seqValue
                  : (seqValue is String ? int.tryParse(seqValue) : null);

              if (id != null && seqNum != null) {
                waypointData.add({'id': id, 'sequence': seqNum});
                AppLogger.routing('   Waypoint id=$id, sequence=$seqNum');
              } else {
                AppLogger.routing(
                  '   ⚠️  Skipping waypoint - id=$idValue, sequence=$seqValue (failed to parse)',
                );
              }
            }

            // Sort by sequence number to get optimal order
            waypointData.sort(
              (a, b) => a['sequence']!.compareTo(b['sequence']!),
            );

            // Build final sequence list (excluding start=0 and end, only intermediate destinations)
            final sequence = <int>[];
            for (final wp in waypointData) {
              final id = wp['id']!;
              // Skip start (id=0) and end (last id)
              // Intermediate destinations have ids 1 to n-1, map to indices 0 to n-2
              if (id > 0 && id < waypointData.length) {
                sequence.add(id - 1); // Map id to destination index
              }
            }

            AppLogger.routing(
              '✅ Optimized sequence (destination indices): $sequence',
            );
            return sequence;
          }
        }
      }

      AppLogger.routing('⚠️  Sequence API returned unexpected response');
      return null;
    } catch (e) {
      AppLogger.routing('❌ Error getting optimized sequence: $e');
      return null;
    }
  }

  /// Decode HERE flexible polyline format using official package
  ///
  /// HERE Maps v8 uses a proprietary "Flexible Polyline" encoding format
  /// which differs from Google's polyline encoding. It supports:
  /// - URL-safe characters
  /// - Configurable precision
  /// - Optional 3rd dimension (elevation)
  ///
  /// We use the official flexible_polyline_dart package for decoding.
  List<LatLng> _decodeFlexiblePolyline(String encoded) {
    try {
      // Decode using HERE's flexible polyline format
      final decoded = FlexiblePolyline.decode(encoded);

      // Convert LatLngZ (from package) to LatLng (latlong2 package)
      final coordinates = decoded
          .map((point) => LatLng(point.lat, point.lng))
          .toList();

      AppLogger.routing('✅ Decoded ${coordinates.length} polyline points');
      return coordinates;
    } catch (e) {
      AppLogger.routing('❌ Error decoding flexible polyline: $e');
      AppLogger.routing('   Encoded string length: ${encoded.length}');
      AppLogger.routing(
        '   First 50 chars: ${encoded.substring(0, encoded.length > 50 ? 50 : encoded.length)}',
      );
      return [];
    }
  }

  /// Format DateTime for HERE Maps API
  /// HERE expects ISO 8601 in UTC WITHOUT microseconds
  /// Example: 2025-11-17T21:15:01Z (not 2025-11-17T16:15:01.833354)
  String _formatHereMapsDateTime(DateTime dateTime) {
    // Convert to UTC
    final utc = dateTime.toUtc();

    // Remove microseconds: split at '.' and add 'Z'
    final formatted = utc.toIso8601String().split('.').first + 'Z';

    return formatted;
  }
}
