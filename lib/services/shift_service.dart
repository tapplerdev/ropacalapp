import 'package:dio/dio.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/core/services/api_service.dart';

/// Service for shift management API calls
class ShiftService {
  final ApiService _apiService;

  ShiftService(this._apiService);

  /// Get current shift status
  Future<ShiftState?> getCurrentShift() async {
    try {
      print('📤 REQUEST: GET /api/driver/shift/current');
      print('   🔗 Backend URL: https://ropacal-backend-production.up.railway.app');

      final response = await _apiService.get('/api/driver/shift/current');

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Response Data: ${response.data}');
      print('   Success: ${response.data['success']}');

      if (response.data['success'] == true) {
        final shiftData = response.data['data'];

        print('   Shift Data from backend: $shiftData');

        // If data is null, no active shift
        if (shiftData == null) {
          print('   ❌ Backend returned NULL - No active shift found in PostgreSQL');
          print('   This means either:');
          print('     1. No shift was ever started for this driver');
          print('     2. The shift was ended (status=inactive)');
          print('     3. The shift expired');
          return null;
        }

        print('   ✅ Found active shift in database!');
        print('   Status: ${shiftData['status']}');
        print('   Route ID: ${shiftData['route_id']}');

        // Freezed handles parsing bins automatically
        final shiftState = ShiftState.fromJson(
          shiftData as Map<String, dynamic>,
        );

        print('   ✅ Current shift: ${shiftData['status']}');
        print('   Route: ${shiftData['route_id']}');
        print(
          '   Bins: ${shiftData['completed_bins']}/${shiftData['total_bins']} (${shiftState.routeBins.length} in route)',
        );

        return shiftState;
      }

      throw Exception('Failed to fetch current shift');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Start shift
  Future<ShiftState> startShift() async {
    try {
      print('📤 REQUEST: POST /api/driver/shift/start');

      final response = await _apiService.post('/api/driver/shift/start', {});

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        final shiftData = response.data['data'] as Map<String, dynamic>;
        print('   ✅ Shift started!');
        print('   Start time: ${shiftData['start_time']}');
        print('   Status: ${shiftData['status']}');
        return ShiftState.fromJson(shiftData);
      }

      throw Exception(response.data['error'] ?? 'Failed to start shift');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Pause shift
  Future<void> pauseShift() async {
    try {
      print('📤 REQUEST: POST /api/driver/shift/pause');

      final response = await _apiService.post('/api/driver/shift/pause', {});

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        print('   ✅ Shift paused!');
        return;
      }

      throw Exception(response.data['error'] ?? 'Failed to pause shift');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Resume shift
  Future<void> resumeShift() async {
    try {
      print('📤 REQUEST: POST /api/driver/shift/resume');

      final response = await _apiService.post('/api/driver/shift/resume', {});

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        print('   ✅ Shift resumed successfully');
        return;
      }

      throw Exception(response.data['error'] ?? 'Failed to resume shift');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// End shift
  Future<Map<String, dynamic>> endShift() async {
    try {
      print('📤 REQUEST: POST /api/driver/shift/end');

      final response = await _apiService.post('/api/driver/shift/end', {});

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        print('   ✅ Shift ended successfully');
        return data;
      }

      throw Exception(response.data['error'] ?? 'Failed to end shift');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Complete a bin
  Future<Map<String, dynamic>> completeBin(String binId) async {
    try {
      print('📤 REQUEST: POST /api/driver/shift/complete-bin');
      print('   Body: {"bin_id": "$binId"}');

      final response = await _apiService.post(
        '/api/driver/shift/complete-bin',
        {'bin_id': binId},
      );

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        print(
          '   ✅ Bin completed: ${data['completed_bins']}/${data['total_bins']}',
        );
        return data;
      }

      throw Exception(response.data['error'] ?? 'Failed to complete bin');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Register FCM token with backend
  Future<void> registerFCMToken(String token, String deviceType) async {
    try {
      print('📤 REQUEST: POST /api/driver/fcm-token');
      print(
        '   Body: {"token": "${token.substring(0, 20)}...", "device_type": "$deviceType"}',
      );

      final response = await _apiService.post('/api/driver/fcm-token', {
        'token': token,
        'device_type': deviceType,
      });

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        print('   ✅ FCM token registered successfully');
        return;
      }

      throw Exception(response.data['error'] ?? 'Failed to register FCM token');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Assign route to driver (manager only)
  Future<Map<String, dynamic>> assignRoute({
    required String driverID,
    required String routeID,
    required int totalBins,
  }) async {
    try {
      print('📤 REQUEST: POST /api/manager/assign-route');
      print('   Body: {');
      print('     "driver_id": "$driverID",');
      print('     "route_id": "$routeID",');
      print('     "total_bins": $totalBins');
      print('   }');

      final response = await _apiService.post('/api/manager/assign-route', {
        'driver_id': driverID,
        'route_id': routeID,
        'total_bins': totalBins,
      });

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        print('   ✅ Route assigned successfully!');
        print('   Driver: $driverID');
        print('   Route: $routeID');
        print('   Bins: $totalBins');
        return response.data['data'] as Map<String, dynamic>;
      }

      throw Exception(response.data['error'] ?? 'Failed to assign route');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }
}
