import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/models/route_task.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';

/// Tasks for a single shift (manager view), keyed by shiftId. Works for
/// ended/cancelled shifts too — GET /api/shifts/{id}/tasks returns the full
/// archived task list. Powers the read-only historical shift detail page.
final managerShiftTasksProvider =
    FutureProvider.family<List<RouteTask>, String>((ref, shiftId) async {
  final managerService = ref.read(managerServiceProvider);
  final raw = await managerService.getManagerShiftTasks(shiftId);
  final tasks = raw
      .map((json) => RouteTask.fromJson(json as Map<String, dynamic>))
      .toList();
  // Present in route order — the archived rows may not arrive pre-sorted.
  tasks.sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));
  return tasks;
});
