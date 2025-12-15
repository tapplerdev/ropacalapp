import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/shift_history.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/providers/api_provider.dart';
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
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => fetchHistory());
    AppLogger.general('✅ Shift history refreshed');
  }
}

/// Provider for a single shift's detailed information
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

      final shiftService = ref.read(shiftServiceProvider);
      final data = await shiftService.getShiftDetails(shiftId);

      // Parse shift history from the response
      final shiftHistory = ShiftHistory.fromJson(data);

      // Parse bins array
      final bins = (data['bins'] as List)
          .map((json) => RouteBin.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.general('✅ Loaded shift with ${bins.length} bins');

      return ShiftDetailData(shift: shiftHistory, bins: bins);
    } catch (e, stack) {
      AppLogger.general(
        '❌ Error fetching shift details: $e',
        level: AppLogger.error,
      );
      AppLogger.general('Stack trace: $stack');
      rethrow;
    }
  }
}

/// Data class combining shift history with bins
class ShiftDetailData {
  final ShiftHistory shift;
  final List<RouteBin> bins;

  ShiftDetailData({required this.shift, required this.bins});
}
