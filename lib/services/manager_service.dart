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

  /// Schedule a bin move (relocation or pickup)
  /// Returns the created move request data
  Future<Map<String, dynamic>> scheduleBinMove({
    required String binId,
    required String moveType, // 'relocation' or 'pickup_only'
    String? disposalAction, // 'retire' or 'store' (required for pickup_only)
    String? newStreet,
    String? newCity,
    String? newZip,
    double? newLatitude,
    double? newLongitude,
    String? reason,
    String? notes,
    String? shiftId, // Optional: Assign to specific shift immediately
  }) async {
    try {
      print('📤 REQUEST: POST /api/manager/bins/schedule-move');
      print('   Move Type: $moveType');
      print('   Bin ID: $binId');

      final now = DateTime.now();
      final scheduledDate = now.millisecondsSinceEpoch ~/ 1000;

      final requestBody = <String, dynamic>{
        'bin_id': binId,
        'scheduled_date': scheduledDate,
        'move_type': moveType,
      };

      // Add optional fields
      if (disposalAction != null) {
        requestBody['disposal_action'] = disposalAction;
      }
      if (newStreet != null) requestBody['new_street'] = newStreet;
      if (newCity != null) requestBody['new_city'] = newCity;
      if (newZip != null) requestBody['new_zip'] = newZip;
      if (newLatitude != null) requestBody['new_latitude'] = newLatitude;
      if (newLongitude != null) requestBody['new_longitude'] = newLongitude;
      if (reason != null) requestBody['reason'] = reason;
      if (notes != null) requestBody['notes'] = notes;
      if (shiftId != null) requestBody['shift_id'] = shiftId;

      print('   Request Body: $requestBody');

      final response = await _apiService.post(
        '/api/manager/bins/schedule-move',
        requestBody,
      );

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      // The endpoint returns the move request directly (no success wrapper)
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Get move history for a specific bin
  Future<List<Map<String, dynamic>>> getBinMoveHistory(String binId) async {
    try {
      print('📤 REQUEST: GET /api/bins/$binId/moves');

      final response = await _apiService.get('/api/bins/$binId/moves');

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      // The endpoint returns an array directly (no success wrapper)
      final moves = List<Map<String, dynamic>>.from(response.data as List);
      print('   ✅ Found ${moves.length} move(s)');
      return moves;
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Get all move requests for a specific bin (pending, assigned, completed, cancelled)
  Future<List<Map<String, dynamic>>> getBinMoveRequests(
    String binId, {
    String? status,
  }) async {
    try {
      print('📤 REQUEST: GET /api/bins/$binId/move-requests');

      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final response = await _apiService.get(
        '/api/bins/$binId/move-requests',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      // The endpoint returns an array directly (no success wrapper)
      final moveRequests = List<Map<String, dynamic>>.from(response.data as List);
      print('   ✅ Found ${moveRequests.length} move request(s) for bin $binId');
      return moveRequests;
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Get check history for a specific bin
  Future<List<Map<String, dynamic>>> getBinCheckHistory(String binId) async {
    try {
      print('📤 REQUEST: GET /api/bins/$binId/checks');

      final response = await _apiService.get('/api/bins/$binId/checks');

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      // The endpoint returns an array directly (no success wrapper)
      final checks = List<Map<String, dynamic>>.from(response.data as List);
      print('   ✅ Found ${checks.length} check(s)');
      return checks;
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Assign a move request to a specific user for manual completion
  Future<void> assignMoveToUser(String moveRequestId, String userId) async {
    try {
      print('📤 REQUEST: PUT /api/manager/bins/move-requests/$moveRequestId/assign-to-user');
      print('   User ID: $userId');

      final response = await _apiService.put(
        '/api/manager/bins/move-requests/$moveRequestId/assign-to-user',
        {'user_id': userId},
      );

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');
      print('   ✅ Move assigned to user successfully');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Manually complete a move request
  Future<void> manuallyCompleteMoveRequest(String moveRequestId) async {
    try {
      print('📤 REQUEST: PUT /api/manager/bins/move-requests/$moveRequestId/complete-manually');

      final response = await _apiService.put(
        '/api/manager/bins/move-requests/$moveRequestId/complete-manually',
        {},
      );

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');
      print('   ✅ Move completed manually');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Get all users (drivers, managers, admins)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      print('📤 REQUEST: GET /api/users');

      final response = await _apiService.get('/api/users');

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        final users = List<Map<String, dynamic>>.from(
          response.data['users'] as List,
        );
        print('   ✅ Found ${users.length} user(s)');
        return users;
      }

      return [];
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Get all move requests (pending, assigned, completed)
  /// Optionally filter by status and/or urgency
  Future<List<Map<String, dynamic>>> getAllMoveRequests({
    String? status,
    String? urgency,
  }) async {
    try {
      print('📤 REQUEST: GET /api/manager/bins/move-requests');

      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (urgency != null) queryParams['urgency'] = urgency;

      final response = await _apiService.get(
        '/api/manager/bins/move-requests',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      // The endpoint returns an array directly (no success wrapper)
      final moveRequests = List<Map<String, dynamic>>.from(response.data as List);
      print('   ✅ Found ${moveRequests.length} move request(s)');
      return moveRequests;
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Cancel a move request
  Future<void> cancelMoveRequest(String moveRequestId) async {
    try {
      print('📤 REQUEST: PUT /api/manager/bins/move-requests/$moveRequestId/cancel');

      final response = await _apiService.put(
        '/api/manager/bins/move-requests/$moveRequestId/cancel',
        {},
      );

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');
      print('   ✅ Move request cancelled successfully');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }
}
