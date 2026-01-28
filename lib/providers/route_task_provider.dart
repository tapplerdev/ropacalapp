import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/models/route_task.dart';
import 'package:ropacalapp/services/route_task_service.dart';
import 'package:ropacalapp/providers/api_provider.dart';

part 'route_task_provider.g.dart';

/// Provider for RouteTaskService
@riverpod
RouteTaskService routeTaskService(RouteTaskServiceRef ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RouteTaskService(apiService);
}

/// Provider for fetching tasks for a specific shift
@riverpod
Future<List<RouteTask>> shiftTasks(
  ShiftTasksRef ref,
  String shiftId,
) async {
  final service = ref.watch(routeTaskServiceProvider);
  return service.getShiftTasks(shiftId);
}

/// Provider for fetching detailed tasks with JOINed data
@riverpod
Future<List<Map<String, dynamic>>> shiftTasksDetailed(
  ShiftTasksDetailedRef ref,
  String shiftId,
) async {
  final service = ref.watch(routeTaskServiceProvider);
  return service.getShiftTasksDetailed(shiftId);
}
