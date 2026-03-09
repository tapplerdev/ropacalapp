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

  /// Schedule a bin move (store, relocation, or redeployment)
  /// Returns the created move request data
  Future<Map<String, dynamic>> scheduleBinMove({
    required String binId,
    required String moveType, // 'store', 'relocation', or 'redeployment'
    int? scheduledDate, // Unix timestamp in seconds; defaults to now if null
    String? newStreet,
    String? newCity,
    String? newZip,
    double? newLatitude,
    double? newLongitude,
    String? reason,
    String? notes,
    String? reasonCategory,
    bool? createNoGoZone,
    String? sourcePotentialLocationId,
    String? shiftId, // Optional: Assign to specific shift immediately
  }) async {
    try {
      print('📤 REQUEST: POST /api/manager/bins/schedule-move');
      print('   Move Type: $moveType');
      print('   Bin ID: $binId');

      final effectiveDate = scheduledDate ??
          (DateTime.now().millisecondsSinceEpoch ~/ 1000);

      final requestBody = <String, dynamic>{
        'bin_id': binId,
        'scheduled_date': effectiveDate,
        'move_type': moveType,
      };

      // Add optional fields
      if (newStreet != null) requestBody['new_street'] = newStreet;
      if (newCity != null) requestBody['new_city'] = newCity;
      if (newZip != null) requestBody['new_zip'] = newZip;
      if (newLatitude != null) requestBody['new_latitude'] = newLatitude;
      if (newLongitude != null) requestBody['new_longitude'] = newLongitude;
      if (reason != null) requestBody['reason'] = reason;
      if (notes != null) requestBody['notes'] = notes;
      if (reasonCategory != null) requestBody['reason_category'] = reasonCategory;
      if (createNoGoZone != null) requestBody['create_no_go_zone'] = createNoGoZone;
      if (sourcePotentialLocationId != null) {
        requestBody['source_potential_location_id'] = sourcePotentialLocationId;
      }
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

  // ═══════════════════════════════════════════════════════════════
  // Shift Management
  // ═══════════════════════════════════════════════════════════════

  /// Cancel a shift (manager action)
  /// Backend handles: status→cancelled, move requests→pending,
  /// history recording, WebSocket notification to driver
  Future<void> cancelShift(String shiftId) async {
    try {
      print('📤 REQUEST: PUT /api/manager/shifts/$shiftId/cancel');

      final response = await _apiService.put(
        '/api/manager/shifts/$shiftId/cancel',
        {},
      );

      print('📥 RESPONSE: ${response.statusCode}');
      print('   ✅ Shift cancelled successfully');
    } catch (e) {
      print('   ❌ ERROR cancelling shift: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Routes & Shift Creation
  // ═══════════════════════════════════════════════════════════════

  /// Fetch all route templates
  Future<List<Map<String, dynamic>>> getRoutes() async {
    try {
      print('📤 REQUEST: GET /api/routes');
      final response = await _apiService.get('/api/routes');

      // Endpoint returns array directly (no success wrapper)
      final routes = List<Map<String, dynamic>>.from(response.data as List);
      print('   ✅ Found ${routes.length} route(s)');
      return routes;
    } catch (e) {
      print('   ❌ ERROR fetching routes: $e');
      rethrow;
    }
  }

  /// Fetch a single route with its bins
  Future<Map<String, dynamic>> getRouteWithBins(String routeId) async {
    try {
      print('📤 REQUEST: GET /api/routes/$routeId');
      final response = await _apiService.get('/api/routes/$routeId');

      // Endpoint returns RouteWithBins directly (no success wrapper)
      final route = response.data as Map<String, dynamic>;
      print('   ✅ Route "${route['name']}" with ${(route['bins'] as List?)?.length ?? 0} bins');
      return route;
    } catch (e) {
      print('   ❌ ERROR fetching route: $e');
      rethrow;
    }
  }

  /// Get road-following directions (polyline) between two points via OSRM
  /// Returns list of {latitude, longitude} points following actual roads
  Future<List<Map<String, dynamic>>> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/directions?origin_lat=$originLat&origin_lng=$originLng&dest_lat=$destLat&dest_lng=$destLng',
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['coordinates'] as List);
      }

      // Fallback: straight line
      return [
        {'latitude': originLat, 'longitude': originLng},
        {'latitude': destLat, 'longitude': destLng},
      ];
    } catch (e) {
      print('   ⚠️  Directions API failed: $e (using straight line)');
      return [
        {'latitude': originLat, 'longitude': originLng},
        {'latitude': destLat, 'longitude': destLng},
      ];
    }
  }

  /// Create a new shift with tasks
  Future<Map<String, dynamic>> createShiftWithTasks({
    required String driverId,
    required int truckBinCapacity,
    required double warehouseLatitude,
    required double warehouseLongitude,
    required String warehouseAddress,
    required bool lockRouteOrder,
    required List<Map<String, dynamic>> tasks,
  }) async {
    try {
      print('📤 REQUEST: POST /api/manager/shifts/create-with-tasks');
      print('   Driver: $driverId');
      print('   Tasks: ${tasks.length}');
      print('   Truck capacity: $truckBinCapacity');

      final response = await _apiService.post(
        '/api/manager/shifts/create-with-tasks',
        {
          'driver_id': driverId,
          'truck_bin_capacity': truckBinCapacity,
          'warehouse_latitude': warehouseLatitude,
          'warehouse_longitude': warehouseLongitude,
          'warehouse_address': warehouseAddress,
          'lock_route_order': lockRouteOrder,
          'tasks': tasks,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        print('   ✅ Shift created: ${data['shift_id']}');
        return data;
      }

      throw Exception(response.data['error'] ?? 'Failed to create shift');
    } catch (e) {
      print('   ❌ ERROR creating shift: $e');
      rethrow;
    }
  }

  /// Get a single shift's details (manager view)
  /// Returns shift data including id, driver_id, status, start_time, end_time, etc.
  Future<Map<String, dynamic>> getManagerShiftDetails(String shiftId) async {
    try {
      print('📤 REQUEST: GET /api/manager/shifts/$shiftId');

      final response = await _apiService.get('/api/manager/shifts/$shiftId');

      print('📥 RESPONSE: ${response.statusCode}');

      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }

      throw Exception(
          response.data['error'] ?? 'Failed to fetch shift details');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Get tasks for a specific shift (manager view, returns RouteTask format)
  Future<List<dynamic>> getManagerShiftTasks(String shiftId) async {
    try {
      print('📤 REQUEST: GET /api/shifts/$shiftId/tasks');

      final response = await _apiService.get('/api/shifts/$shiftId/tasks');

      print('📥 RESPONSE: ${response.statusCode}');

      if (response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      }

      throw Exception(
          response.data['error'] ?? 'Failed to fetch shift tasks');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Get shift history for all drivers (manager view)
  /// Returns paginated shift history with per-type task stats.
  Future<Map<String, dynamic>> getShiftHistory({
    String? driverId,
    int? startDate,
    int? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (driverId != null) queryParams['driver_id'] = driverId;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _apiService.get(
        '/api/manager/shifts/history',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }

      throw Exception(
          response.data['error'] ?? 'Failed to fetch shift history');
    } catch (e) {
      print('   ❌ ERROR fetching shift history: $e');
      rethrow;
    }
  }
}
