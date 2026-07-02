import 'package:ropacalapp/models/route_task.dart';
import 'package:ropacalapp/core/services/api_service.dart';

/// Service for route task management API calls
class RouteTaskService {
  final ApiService _apiService;

  RouteTaskService(this._apiService);

  /// Get all tasks for a specific shift
  Future<List<RouteTask>> getShiftTasks(String shiftId) async {
    try {
      print('📤 REQUEST: GET /api/shifts/$shiftId/tasks');

      final response = await _apiService.get('/api/shifts/$shiftId/tasks');

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        final tasksData = response.data['data'] as List?;

        if (tasksData == null || tasksData.isEmpty) {
          print('   ℹ️  No tasks found for shift $shiftId');
          return [];
        }

        final tasks = tasksData
            .map((taskJson) => RouteTask.fromJson(taskJson as Map<String, dynamic>))
            .toList();

        print('   ✅ Found ${tasks.length} tasks for shift');
        return tasks;
      }

      throw Exception(response.data['error'] ?? 'Failed to fetch shift tasks');
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Create a new shift with tasks
  Future<String> createShiftWithTasks({
    required String driverId,
    required int truckBinCapacity,
    required double warehouseLatitude,
    required double warehouseLongitude,
    required String warehouseAddress,
    required List<Map<String, dynamic>> tasks,
  }) async {
    try {
      print('📤 REQUEST: POST /api/manager/shifts/create-with-tasks');

      final requestData = {
        'driver_id': driverId,
        'truck_bin_capacity': truckBinCapacity,
        'warehouse_latitude': warehouseLatitude,
        'warehouse_longitude': warehouseLongitude,
        'warehouse_address': warehouseAddress,
        'tasks': tasks,
      };

      print('   Body: $requestData');

      final response = await _apiService.post(
        '/api/manager/shifts/create-with-tasks',
        requestData,
      );

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        final shiftId = response.data['data']['shift_id'] as String;
        final taskCount = response.data['data']['task_count'] as int;
        print('   ✅ Shift created successfully!');
        print('   Shift ID: $shiftId');
        print('   Tasks created: $taskCount');
        return shiftId;
      }

      throw Exception(
        response.data['error'] ?? 'Failed to create shift with tasks',
      );
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }

  /// Get detailed tasks with JOINed data (bins, potential locations, etc.)
  Future<List<Map<String, dynamic>>> getShiftTasksDetailed(
    String shiftId,
  ) async {
    try {
      print('📤 REQUEST: GET /api/shifts/$shiftId/tasks/detailed');

      final response = await _apiService.get(
        '/api/shifts/$shiftId/tasks/detailed',
      );

      print('📥 RESPONSE: ${response.statusCode}');
      print('   Data: ${response.data}');

      if (response.data['success'] == true) {
        final tasksData = response.data['data'] as List?;

        if (tasksData == null || tasksData.isEmpty) {
          print('   ℹ️  No detailed tasks found for shift $shiftId');
          return [];
        }

        final tasks = List<Map<String, dynamic>>.from(tasksData);
        print('   ✅ Found ${tasks.length} detailed tasks');
        return tasks;
      }

      throw Exception(
        response.data['error'] ?? 'Failed to fetch detailed tasks',
      );
    } catch (e) {
      print('   ❌ ERROR: $e');
      rethrow;
    }
  }
}
