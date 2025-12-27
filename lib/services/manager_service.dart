import 'package:ropacalapp/core/services/api_service.dart';

/// Service for manager-specific API operations
class ManagerService {
  final ApiService _apiService;

  ManagerService(this._apiService);

  /// Get all drivers regardless of shift status
  /// Returns drivers with status: 'active', 'paused', 'ready', or 'idle'
  Future<List<Map<String, dynamic>>> getAllDrivers() async {
    try {
      print('📤 REQUEST: GET /api/manager/drivers');

      final response = await _apiService.get('/api/manager/drivers');

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        // Handle null data (no drivers)
        final data = response.data['data'];
        if (data == null) {
          print('   ℹ️  No drivers found (data is null)');
          return [];
        }

        final drivers =
            List<Map<String, dynamic>>.from(data as List);
        print('   ✅ Found ${drivers.length} driver(s)');
        return drivers;
      }

      throw Exception(response.data['error'] ?? 'Failed to fetch drivers');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Get all active drivers with their current shifts
  Future<List<Map<String, dynamic>>> getActiveDrivers() async {
    try {
      print('📤 REQUEST: GET /api/manager/active-drivers');

      final response = await _apiService.get('/api/manager/active-drivers');

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        // Handle null data (no active drivers)
        final data = response.data['data'];
        if (data == null) {
          print('   ℹ️  No active drivers found (data is null)');
          return [];
        }

        final drivers =
            List<Map<String, dynamic>>.from(data as List);
        print('   ✅ Found ${drivers.length} active driver(s)');
        return drivers;
      }

      throw Exception(response.data['error'] ?? 'Failed to fetch active drivers');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Get detailed shift information for a specific driver
  /// Returns null if the shift has ended (404 - no active shift)
  Future<Map<String, dynamic>?> getDriverShiftDetails(String driverId) async {
    try {
      print('📤 REQUEST: GET /api/manager/driver-shift-details?driver_id=$driverId');

      final response = await _apiService.get(
        '/api/manager/driver-shift-details',
        queryParameters: {'driver_id': driverId},
      );

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data == null) {
          throw Exception('No shift details found');
        }
        return data as Map<String, dynamic>;
      }

      throw Exception(response.data['error'] ?? 'Failed to fetch driver shift details');
    } catch (e) {
      // If 404 with "No active shift found", the shift has ended - return null
      if (e.toString().contains('404') ||
          e.toString().contains('No active shift found') ||
          e.toString().contains('Resource not found')) {
        print('   ℹ️  Shift has ended or is no longer active for driver: $driverId');
        return null;
      }

      print('   ❌ ERROR: $e');
      rethrow;
    }
  }
}
