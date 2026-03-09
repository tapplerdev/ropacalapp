import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/models/manager_shift_history.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';

part 'manager_shift_history_provider.g.dart';

/// Provider for manager shift history with date filtering.
/// Fetches from GET /api/manager/shifts/history.
@riverpod
class ManagerShiftHistoryNotifier extends _$ManagerShiftHistoryNotifier {
  @override
  Future<List<ManagerShiftHistory>> build({int daysBack = 7}) async {
    return _fetch(daysBack);
  }

  Future<List<ManagerShiftHistory>> _fetch(int daysBack) async {
    final managerService = ref.read(managerServiceProvider);

    int? startDate;
    if (daysBack > 0) {
      startDate = DateTime.now()
              .subtract(Duration(days: daysBack))
              .millisecondsSinceEpoch ~/
          1000;
    }

    final data = await managerService.getShiftHistory(
      startDate: startDate,
      limit: 50,
    );

    final shiftsJson = data['shifts'] as List<dynamic>? ?? [];
    return shiftsJson
        .map((json) =>
            ManagerShiftHistory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(daysBack));
  }
}
