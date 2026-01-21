import 'package:geocoding/geocoding.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

/// Service for converting GPS coordinates to address components
class GeocodingService {
  /// Convert GPS coordinates to address components (street, city, zip)
  ///
  /// Returns a map with keys: 'street', 'city', 'zip', 'state'
  /// Returns null if reverse geocoding fails or no results found
  static Future<Map<String, String>?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.general('🌍 REVERSE GEOCODING');
      AppLogger.general('   Latitude: $latitude');
      AppLogger.general('   Longitude: $longitude');

      // Reverse geocode coordinates to placemarks
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        AppLogger.general('   ❌ No placemarks found');
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return null;
      }

      final place = placemarks.first;

      AppLogger.general('   📍 Placemark found:');
      AppLogger.general('      Street: ${place.street}');
      AppLogger.general('      Locality: ${place.locality}');
      AppLogger.general('      Postal Code: ${place.postalCode}');
      AppLogger.general('      Admin Area: ${place.administrativeArea}');
      AppLogger.general('      Sub Admin Area: ${place.subAdministrativeArea}');
      AppLogger.general('      Sublocality: ${place.subLocality}');

      // Extract address components
      final street = place.street ?? '';
      final city = place.locality ?? place.subAdministrativeArea ?? '';
      final zip = place.postalCode ?? '';
      final state = place.administrativeArea ?? '';

      // Validate required fields
      if (street.isEmpty || city.isEmpty || zip.isEmpty) {
        AppLogger.general(
          '   ⚠️  Missing required fields:',
        );
        AppLogger.general('      Street: ${street.isEmpty ? "MISSING" : "OK"}');
        AppLogger.general('      City: ${city.isEmpty ? "MISSING" : "OK"}');
        AppLogger.general('      ZIP: ${zip.isEmpty ? "MISSING" : "OK"}');
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return null;
      }

      final result = {
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
      AppLogger.general('❌ REVERSE GEOCODING FAILED');
      AppLogger.general('   Error: $e');
      AppLogger.general('   Stack trace: $stack');
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return null;
    }
  }

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
