import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

/// Service for converting GPS coordinates to address components
class GeocodingService {
  // HERE Maps API Key
  static final String _hereApiKey = dotenv.env['HERE_API_KEY'] ?? '';

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// HERE MAPS REVERSE GEOCODING (NEW - ACTIVE)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Convert GPS coordinates to address using HERE Maps Reverse Geocoding API
  ///
  /// Returns a map with keys: 'street', 'city', 'zip', 'state'
  /// Returns null if reverse geocoding fails or no results found
  static Future<Map<String, String>?> hereReverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.general('🗺️ HERE MAPS REVERSE GEOCODING');
      AppLogger.general('   Latitude: $latitude');
      AppLogger.general('   Longitude: $longitude');

      if (_hereApiKey.isEmpty) {
        AppLogger.general('   ❌ HERE_API_KEY not configured');
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return null;
      }

      // Build HERE Maps Revgeocode API URL
      final params = {
        'at': '$latitude,$longitude',
        'lang': 'en',
        'limit': '1',
        'apiKey': _hereApiKey,
      };

      final uri = Uri.https(
        'revgeocode.search.hereapi.com',
        '/v1/revgeocode',
        params,
      );

      AppLogger.general('   🌐 Calling HERE API...');
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        AppLogger.general('   ❌ API error: ${response.statusCode}');
        AppLogger.general('   Response: ${response.body}');
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return null;
      }

      final data = json.decode(response.body);

      if (data['items'] == null || (data['items'] as List).isEmpty) {
        AppLogger.general('   ❌ No results found');
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return null;
      }

      final address = data['items'][0]['address'];

      final street = '${address['houseNumber'] ?? ''} ${address['street'] ?? ''}'.trim();
      final city = address['city'] ?? '';
      final zip = address['postalCode'] ?? '';
      final state = address['stateCode'] ?? address['state'] ?? '';

      AppLogger.general('   📍 Address found:');
      AppLogger.general('      Street: $street');
      AppLogger.general('      City: $city');
      AppLogger.general('      ZIP: $zip');
      AppLogger.general('      State: $state');

      // Validate required fields
      if (street.isEmpty || city.isEmpty || zip.isEmpty) {
        AppLogger.general('   ⚠️  Missing required fields:');
        AppLogger.general('      Street: ${street.isEmpty ? "MISSING" : "OK"}');
        AppLogger.general('      City: ${city.isEmpty ? "MISSING" : "OK"}');
        AppLogger.general('      ZIP: ${zip.isEmpty ? "MISSING" : "OK"}');
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return null;
      }

      final result = <String, String>{
        'street': street,
        'city': city,
        'zip': zip,
        'state': state,
      };

      AppLogger.general('   ✅ Reverse geocoding successful');
      AppLogger.general('      Result: $result');
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return result;
    } catch (e, stack) {
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.general('❌ HERE MAPS REVERSE GEOCODING FAILED');
      AppLogger.general('   Error: $e');
      AppLogger.general('   Stack trace: $stack');
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return null;
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// HERE MAPS AUTOSUGGEST (NEW - ACTIVE)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Get autocomplete suggestions using HERE Maps Autosuggest API
  static Future<List<Map<String, dynamic>>> hereAutosuggest({
    required String query,
    double? userLat,
    double? userLng,
    int limit = 5,
  }) async {
    try {
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.general('🗺️ HERE MAPS AUTOSUGGEST');
      AppLogger.general('   Query: $query');

      if (_hereApiKey.isEmpty) {
        AppLogger.general('   ❌ HERE_API_KEY not configured');
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return [];
      }

      // Use provided location or default to US center (Kansas City, MO)
      final lat = userLat ?? 39.0997;
      final lng = userLng ?? -94.5786;

      final params = {
        'q': query,
        'at': '$lat,$lng',
        'limit': limit.toString(),
        'lang': 'en',
        'apiKey': _hereApiKey,
      };

      final uri = Uri.https(
        'autosuggest.search.hereapi.com',
        '/v1/autosuggest',
        params,
      );

      AppLogger.general('   🌐 Calling HERE API...');
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        AppLogger.general('   ❌ API error: ${response.statusCode}');
        AppLogger.general('   Response: ${response.body}');
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return [];
      }

      final data = json.decode(response.body);
      final items = data['items'] as List? ?? [];

      AppLogger.general('   ✅ Found ${items.length} suggestions');
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return items.map((item) {
        return {
          'id': item['id'] as String,
          'title': item['title'] as String,
          'address': item['address']?['label'] as String?,
        };
      }).toList();
    } catch (e, stack) {
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.general('❌ HERE MAPS AUTOSUGGEST FAILED');
      AppLogger.general('   Error: $e');
      AppLogger.general('   Stack trace: $stack');
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return [];
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// HERE MAPS LOOKUP (NEW - ACTIVE)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Get full place details using HERE Maps Lookup API
  static Future<Map<String, String>?> hereLookup({
    required String hereId,
  }) async {
    try {
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.general('🗺️ HERE MAPS LOOKUP');
      AppLogger.general('   HERE ID: $hereId');

      if (_hereApiKey.isEmpty) {
        AppLogger.general('   ❌ HERE_API_KEY not configured');
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return null;
      }

      final params = {
        'id': hereId,
        'apiKey': _hereApiKey,
      };

      final uri = Uri.https(
        'lookup.search.hereapi.com',
        '/v1/lookup',
        params,
      );

      AppLogger.general('   🌐 Calling HERE API...');
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        AppLogger.general('   ❌ API error: ${response.statusCode}');
        AppLogger.general('   Response: ${response.body}');
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return null;
      }

      final data = json.decode(response.body);
      final address = data['address'];
      final position = data['position'];

      final street = '${address['houseNumber'] ?? ''} ${address['street'] ?? ''}'.trim();
      final city = address['city'] ?? '';
      final zip = address['postalCode'] ?? '';
      final state = address['stateCode'] ?? address['state'] ?? '';
      final latitude = position?['lat'];
      final longitude = position?['lng'];

      AppLogger.general('   ✅ Place details found');
      AppLogger.general('      Street: $street');
      AppLogger.general('      City: $city');
      AppLogger.general('      ZIP: $zip');
      AppLogger.general('      Lat/Lng: $latitude, $longitude');
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return <String, String>{
        'street': street,
        'city': city,
        'zip': zip,
        'state': state,
        'latitude': latitude?.toString() ?? '',
        'longitude': longitude?.toString() ?? '',
        'formattedAddress': address['label'] ?? '',
      };
    } catch (e, stack) {
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.general('❌ HERE MAPS LOOKUP FAILED');
      AppLogger.general('   Error: $e');
      AppLogger.general('   Stack trace: $stack');
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return null;
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// GOOGLE REVERSE GEOCODING (DEPRECATED - KEPT FOR ROLLBACK)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  // /// Convert GPS coordinates to address components (street, city, zip)
  // ///
  // /// Returns a map with keys: 'street', 'city', 'zip', 'state'
  // /// Returns null if reverse geocoding fails or no results found
  // static Future<Map<String, String>?> reverseGeocode({
  //   required double latitude,
  //   required double longitude,
  // }) async {
  //   try {
  //     AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  //     AppLogger.general('🌍 REVERSE GEOCODING');
  //     AppLogger.general('   Latitude: $latitude');
  //     AppLogger.general('   Longitude: $longitude');
  //
  //     // Reverse geocode coordinates to placemarks
  //     final List<Placemark> placemarks = await placemarkFromCoordinates(
  //       latitude,
  //       longitude,
  //     );
  //
  //     if (placemarks.isEmpty) {
  //       AppLogger.general('   ❌ No placemarks found');
  //       AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  //       return null;
  //     }
  //
  //     final place = placemarks.first;
  //
  //     AppLogger.general('   📍 Placemark found:');
  //     AppLogger.general('      Street: ${place.street}');
  //     AppLogger.general('      Locality: ${place.locality}');
  //     AppLogger.general('      Postal Code: ${place.postalCode}');
  //     AppLogger.general('      Admin Area: ${place.administrativeArea}');
  //     AppLogger.general('      Sub Admin Area: ${place.subAdministrativeArea}');
  //     AppLogger.general('      Sublocality: ${place.subLocality}');
  //
  //     // Extract address components
  //     final street = place.street ?? '';
  //     final city = place.locality ?? place.subAdministrativeArea ?? '';
  //     final zip = place.postalCode ?? '';
  //     final state = place.administrativeArea ?? '';
  //
  //     // Validate required fields
  //     if (street.isEmpty || city.isEmpty || zip.isEmpty) {
  //       AppLogger.general(
  //         '   ⚠️  Missing required fields:',
  //       );
  //       AppLogger.general('      Street: ${street.isEmpty ? "MISSING" : "OK"}');
  //       AppLogger.general('      City: ${city.isEmpty ? "MISSING" : "OK"}');
  //       AppLogger.general('      ZIP: ${zip.isEmpty ? "MISSING" : "OK"}');
  //       AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  //       return null;
  //     }
  //
  //     final result = {
  //       'street': street,
  //       'city': city,
  //       'zip': zip,
  //       'state': state,
  //     };
  //
  //     AppLogger.general('   ✅ Reverse geocoding successful');
  //     AppLogger.general('      Result: $result');
  //     AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  //
  //     return result;
  //   } catch (e, stack) {
  //     AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  //     AppLogger.general('❌ REVERSE GEOCODING FAILED');
  //     AppLogger.general('   Error: $e');
  //     AppLogger.general('   Stack trace: $stack');
  //     AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  //     return null;
  //   }
  // }

  /// Check if geocoding service is available
  ///
  /// Note: This is a simple check - actual availability depends on
  /// device connectivity and platform configuration
  static bool isAvailable() {
    // The geocoding package doesn't provide a direct availability check
    // We'll return true and let the actual call handle errors
    return true;
  }
}
