import 'package:dio/dio.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/models/route_task.dart';
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

        // Log first 3 tasks to see raw coordinate data types from backend
        final tasks = shiftData['tasks'] as List?;
        if (tasks != null && tasks.isNotEmpty) {
          print('[DIAGNOSTIC] 🔍 RAW TASK DATA FROM BACKEND (first 3 tasks):');
          for (int i = 0; i < tasks.length && i < 3; i++) {
            final task = tasks[i];
            print('[DIAGNOSTIC]    Task #$i: task_type=${task['task_type']}, lat=${task['latitude']} (${task['latitude'].runtimeType}), lng=${task['longitude']} (${task['longitude'].runtimeType}), addr=${task['address']}');
          }
        }

        // Freezed handles parsing bins automatically
        final shiftState = ShiftState.fromJson(
          shiftData as Map<String, dynamic>,
        );

        // Log parsed coordinates after Flutter JSON parsing
        if (shiftState.tasks.isNotEmpty) {
          print('[DIAGNOSTIC] 🔍 PARSED TASK DATA AFTER FLUTTER (first 3 tasks):');
          for (int i = 0; i < shiftState.tasks.length && i < 3; i++) {
            final task = shiftState.tasks[i];
            print('[DIAGNOSTIC]    Task #$i: taskType=${task.taskType}, lat=${task.latitude} (${task.latitude.runtimeType}), lng=${task.longitude} (${task.longitude.runtimeType}), addr=${task.address}');
          }
        }

        print('   ✅ Current shift: ${shiftData['status']}');
        print('   Route: ${shiftData['route_id']}');
        print(
          '   Bins: ${shiftData['completed_bins']}/${shiftData['total_bins']} (${shiftState.tasks.length} in route)',
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
  /// [binsPreloaded] - whether bins are already loaded on the truck (optional)
  /// If true, route optimization will skip warehouse as first stop
  /// If false or null, route will include warehouse pickup
  Future<ShiftState> startShift({bool? binsPreloaded}) async {
    try {
      print('📤 REQUEST: POST /api/driver/shift/start');

      final requestData = <String, dynamic>{};
      if (binsPreloaded != null) {
        requestData['bins_preloaded'] = binsPreloaded;
        print('   🚚 Bins preloaded: $binsPreloaded');
      }

      final response = await _apiService.post(
        '/api/driver/shift/start',
        requestData,
      );

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

  /// Preflight check - validates GPS readiness before starting shift
  Future<Map<String, dynamic>> preflightCheck() async {
    try {
      print('📤 REQUEST: POST /api/driver/shift/preflight');

      final response = await _apiService.post('/api/driver/shift/preflight', {});

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        final data = response.data as Map<String, dynamic>;
        final ready = data['ready'] as bool? ?? false;
        final message = data['message'] as String? ?? '';
        final retryAfter = data['retry_after'] as int? ?? 2;
        final needsWarehouseBinsPrompt = data['needs_warehouse_bins_prompt'] as bool? ?? false;
        final placementCount = data['placement_count'] as int? ?? 0;
        final redeploymentCount = data['redeployment_count'] as int? ?? 0;

        print('   Ready: $ready');
        print('   Message: $message');
        if (!ready) {
          print('   Retry after: ${retryAfter}s');
        }
        if (needsWarehouseBinsPrompt) {
          print('   🏭 Needs warehouse bins prompt: $placementCount placements + $redeploymentCount redeployments');
        }

        return data;
      }

      throw Exception(response.data['error'] ?? 'Preflight check failed');
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

  /// Complete a task (bin collection, placement, warehouse stop, etc.)
  Future<Map<String, dynamic>> completeTask(
    String taskId, // ID of route_tasks record (route task UUID)
    String binId, // DEPRECATED: kept for reference only
    int? updatedFillPercentage, { // Now nullable for incidents
    String? photoUrl,
    int? newBinNumber, // REQUIRED for placement tasks
    bool hasIncident = false,
    String? incidentType,
    String? incidentPhotoUrl,
    String? incidentDescription,
    String? moveRequestId, // Links check to move request for pickup/dropoff
  }) async {
    try {
      print('📤 REQUEST: POST /api/driver/shift/complete-task');

      final requestData = {
        'task_id': taskId, // NEW: Properly identifies specific waypoint
        'bin_id': binId, // DEPRECATED: Kept for backward compatibility
        if (updatedFillPercentage != null) 'updated_fill_percentage': updatedFillPercentage,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (newBinNumber != null) 'new_bin_number': newBinNumber, // Driver-provided bin number
        if (hasIncident) 'has_incident': hasIncident,
        if (incidentType != null) 'incident_type': incidentType,
        if (incidentPhotoUrl != null) 'incident_photo_url': incidentPhotoUrl,
        if (incidentDescription != null) 'incident_description': incidentDescription,
        if (moveRequestId != null) 'move_request_id': moveRequestId,
      };

      print('   Body: $requestData');

      final response = await _apiService.post(
        '/api/driver/shift/complete-task',
        requestData,
      );

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        if (hasIncident) {
          print(
            '   🚨 Incident reported: ${data['completed_bins']}/${data['total_bins']} (type: $incidentType)',
          );
        } else {
          print(
            '   ✅ Bin completed: ${data['completed_bins']}/${data['total_bins']} (fill: $updatedFillPercentage%)${photoUrl != null ? ' with photo' : ''}',
          );
        }
        return data;
      }

      throw Exception(response.data['error'] ?? 'Failed to complete bin');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Skip a task with a required reason
  Future<Map<String, dynamic>> skipTask(
    String taskId,
    String reason,
  ) async {
    try {
      print('📤 REQUEST: POST /api/driver/shift/skip-task');

      final requestData = {
        'task_id': taskId,
        'reason': reason,
      };

      print('   Body: $requestData');

      final response = await _apiService.post(
        '/api/driver/shift/skip-task',
        requestData,
      );

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        final data = response.data;
        print('   ✅ Task(s) skipped: ${data['tasks_skipped']}');
        return data;
      }

      throw Exception(response.data['error'] ?? 'Failed to skip task');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Get shift history for the authenticated driver
  Future<List<Map<String, dynamic>>> getShiftHistory() async {
    try {
      print('📤 REQUEST: GET /api/driver/shift-history');

      final response = await _apiService.get('/api/driver/shift-history');

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        // Handle null data (no shift history exists)
        final data = response.data['data'];
        if (data == null) {
          print('   ℹ️  No shift history found (data is null)');
          return [];
        }

        final shifts =
            List<Map<String, dynamic>>.from(data as List);
        print('   ✅ Found ${shifts.length} shifts in history');
        return shifts;
      }

      throw Exception(response.data['error'] ?? 'Failed to fetch shift history');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Get detailed information about a specific shift
  Future<Map<String, dynamic>> getShiftDetails(String shiftId) async {
    try {
      print('📤 REQUEST: GET /api/driver/shift-details?shift_id=$shiftId');

      final response = await _apiService.get(
        '/api/driver/shift-details',
        queryParameters: {'shift_id': shiftId},
      );

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        final shiftDetails = response.data['data'] as Map<String, dynamic>;
        final binsCount = (shiftDetails['bins'] as List).length;
        print('   ✅ Shift details loaded with $binsCount bins');
        return shiftDetails;
      }

      throw Exception(
        response.data['error'] ?? 'Failed to fetch shift details',
      );
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
