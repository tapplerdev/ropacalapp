import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/enums/user_role.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/shift_history.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/models/route_task.dart';
import 'package:ropacalapp/providers/api_provider.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/services/shift_service.dart';
import 'package:ropacalapp/providers/shift_provider.dart';

part 'route_history_provider.g.dart';

/// Provider for shift history data
@riverpod
class RouteHistory extends _$RouteHistory {
  @override
  Future<List<ShiftHistory>> build() async {
    return fetchHistory();
  }

  /// Fetch shift history from backend
  Future<List<ShiftHistory>> fetchHistory() async {
    try {
      AppLogger.general('📜 Fetching shift history...');

      final shiftService = ref.read(shiftServiceProvider);
      final data = await shiftService.getShiftHistory();

      final shifts = data
          .map((json) => ShiftHistory.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.general('✅ Loaded ${shifts.length} shifts from history');

      return shifts;
    } catch (e, stack) {
      AppLogger.general(
        '❌ Error fetching shift history: $e',
        level: AppLogger.error,
      );
      AppLogger.general('Stack trace: $stack');
      rethrow;
    }
  }

  /// Manually refresh shift history
  Future<void> refresh() async {
    AppLogger.general('🔄 Refreshing shift history...');
    // Use AsyncValue.guard without setting loading state first
    // This preserves the current data while fetching new data
    state = await AsyncValue.guard(() => fetchHistory());
    AppLogger.general('✅ Shift history refreshed');
  }
}

/// Provider for a single shift's detailed information.
/// Automatically uses the correct endpoint based on user role:
/// - Driver: GET /api/driver/shift-details?shift_id=...
/// - Manager: GET /api/manager/shifts/{shiftId} + GET /api/shifts/{shiftId}/tasks
@riverpod
class ShiftDetail extends _$ShiftDetail {
  @override
  Future<ShiftDetailData> build(String shiftId) async {
    return fetchShiftDetail(shiftId);
  }

  /// Fetch detailed shift information with bins
  Future<ShiftDetailData> fetchShiftDetail(String shiftId) async {
    try {
      AppLogger.general('📋 Fetching shift details for: $shiftId');

      final user = ref.read(authNotifierProvider).valueOrNull;
      final isManager = user?.role == UserRole.admin;

      if (isManager) {
        return _fetchAsManager(shiftId);
      } else {
        return _fetchAsDriver(shiftId);
      }
    } catch (e, stack) {
      AppLogger.general(
        '❌ Error fetching shift details: $e',
        level: AppLogger.error,
      );
      AppLogger.general('Stack trace: $stack');
      rethrow;
    }
  }

  Future<ShiftDetailData> _fetchAsDriver(String shiftId) async {
    final shiftService = ref.read(shiftServiceProvider);
    final data = await shiftService.getShiftDetails(shiftId);

    final shiftHistory = ShiftHistory.fromJson(data);
    final bins = (data['tasks'] as List)
        .map((json) => RouteTask.fromJson(json as Map<String, dynamic>))
        .toList();

    AppLogger.general('✅ [Driver] Loaded shift with ${bins.length} tasks');
    return ShiftDetailData(shift: shiftHistory, bins: bins);
  }

  Future<ShiftDetailData> _fetchAsManager(String shiftId) async {
    final managerService = ref.read(managerServiceProvider);

    // Fetch shift summary and tasks in parallel
    final results = await Future.wait([
      managerService.getManagerShiftDetails(shiftId),
      managerService.getManagerShiftTasks(shiftId),
    ]);

    final shiftData = results[0] as Map<String, dynamic>;
    final tasksData = results[1] as List<dynamic>;

    final shiftHistory = ShiftHistory.fromJson(shiftData);
    final bins = tasksData
        .map((json) => RouteTask.fromJson(json as Map<String, dynamic>))
        .toList();

    AppLogger.general('✅ [Manager] Loaded shift with ${bins.length} tasks');
    return ShiftDetailData(shift: shiftHistory, bins: bins);
  }
}

/// Data class combining shift history with bins
class ShiftDetailData {
  final ShiftHistory shift;
  final List<RouteTask> bins;

  ShiftDetailData({required this.shift, required this.bins});
}
