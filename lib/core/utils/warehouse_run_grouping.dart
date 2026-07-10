import 'package:ropacalapp/models/route_task.dart';

/// One display group in a task list: either a single task, or a run of
/// consecutive warehouse-load tasks collapsed into one physical stop.
///
/// The optimizer persists ONE `warehouse_stop` row per bin loaded, so a
/// placement route renders as a wall of identical "Warehouse" cards
/// (an 11-placement capacity-8 shift has 12 warehouse rows). Physically the
/// driver makes one stop per reload run — group the rows so lists read
/// "Load 5 bins → place ×3 → Load 6 bins → place ×8 → Return".
class TaskDisplayGroup {
  const TaskDisplayGroup.single(RouteTask this.task)
      : run = null,
        isReturn = false;

  const TaskDisplayGroup.warehouseRun(
    List<RouteTask> this.run, {
    required this.isReturn,
  }) : task = null;

  /// The task, when this group is a single non-warehouse task.
  final RouteTask? task;

  /// The consecutive warehouse-load tasks, when this group is a run.
  final List<RouteTask>? run;

  /// True when this run is the end-of-route return (a lone trailing
  /// warehouse stop), not a load run.
  final bool isReturn;

  bool get isWarehouseRun => run != null;
}

/// Collapses each run of consecutive `warehouse_stop` tasks into a single
/// [TaskDisplayGroup]. Input order is preserved; a lone trailing warehouse
/// stop is marked as the return leg.
List<TaskDisplayGroup> groupWarehouseRuns(List<RouteTask> tasks) {
  final groups = <TaskDisplayGroup>[];
  var i = 0;
  while (i < tasks.length) {
    if (tasks[i].isWarehouseStop) {
      final run = <RouteTask>[];
      while (i < tasks.length && tasks[i].isWarehouseStop) {
        run.add(tasks[i]);
        i++;
      }
      final isReturn = i == tasks.length && run.length == 1;
      groups.add(TaskDisplayGroup.warehouseRun(run, isReturn: isReturn));
    } else {
      groups.add(TaskDisplayGroup.single(tasks[i]));
      i++;
    }
  }
  return groups;
}

/// The "bins" progress semantic: real deliverables only. Warehouse loads and
/// service stops are logistics, not work items — mirrors the backend's
/// completed_bins/total_bins definition (itinerary.CountStops).
List<RouteTask> binSemanticTasks(List<RouteTask> tasks) =>
    tasks.where((t) => !t.isWarehouseStop && !t.isService).toList();
