import 'package:ropacalapp/core/enums/stop_type.dart';
import 'package:ropacalapp/models/route_task.dart';

/// Utility class for calculating and inserting warehouse stops
/// into a list of route tasks based on truck capacity constraints
class WarehouseStopCalculator {
  /// Insert warehouse stops into tasks based on truck capacity
  ///
  /// Algorithm:
  /// 1. Placements consume truck capacity -> insert load stops before batches
  /// 2. Collections generate waste -> insert unload stops when full
  /// 3. Move requests don't consume capacity (1 bin in, 1 bin out)
  ///
  /// [tasks] - Original list of tasks (without warehouse stops)
  /// [truckBinCapacity] - Max number of new bins truck can carry
  /// [warehouseLocation] - Latitude/longitude of warehouse
  /// [shiftId] - ID of the shift
  static List<RouteTask> insertWarehouseStops({
    required List<RouteTask> tasks,
    required int truckBinCapacity,
    required WarehouseLocation warehouseLocation,
    required String shiftId,
  }) {
    final result = <RouteTask>[];
    int binsInTruck = 0;
    int wasteInTruck = 0;
    int sequenceOrder = 1;
    int warehouseStopCount = 0;

    for (final task in tasks) {
      // Handle placement tasks
      if (task.taskType == StopType.placement) {
        // If truck is empty, insert load stop first
        if (binsInTruck == 0) {
          result.add(
            _createWarehouseStop(
              shiftId: shiftId,
              sequenceOrder: sequenceOrder++,
              location: warehouseLocation,
              action: 'load',
              binsToLoad: truckBinCapacity,
              stopCount: ++warehouseStopCount,
            ),
          );
          binsInTruck = truckBinCapacity;
        }

        // Add the placement task
        result.add(task.copyWith(sequenceOrder: sequenceOrder++));
        binsInTruck--;

        // Note: No warehouse stop inserted here - will continue placing
        // until truck is empty
      }
      // Handle collection tasks
      else if (task.taskType == StopType.collection) {
        result.add(task.copyWith(sequenceOrder: sequenceOrder++));
        wasteInTruck++;

        // If waste is at capacity, insert unload stop
        if (wasteInTruck >= truckBinCapacity) {
          result.add(
            _createWarehouseStop(
              shiftId: shiftId,
              sequenceOrder: sequenceOrder++,
              location: warehouseLocation,
              action: 'unload',
              binsToLoad: 0,
              stopCount: ++warehouseStopCount,
            ),
          );
          wasteInTruck = 0;
        }
      }
      // Handle move request tasks (pickup/dropoff)
      else if (task.taskType == StopType.pickup ||
          task.taskType == StopType.dropoff) {
        // Move requests don't affect capacity - just relocating 1 bin
        result.add(task.copyWith(sequenceOrder: sequenceOrder++));
      }
      // Handle manually inserted warehouse stops
      else if (task.taskType == StopType.warehouseStop) {
        // Manager manually inserted a warehouse stop
        // Reset counters based on action
        if (task.warehouseAction == 'load') {
          binsInTruck = task.binsToLoad ?? truckBinCapacity;
        } else if (task.warehouseAction == 'unload') {
          wasteInTruck = 0;
        } else {
          // Both
          binsInTruck = task.binsToLoad ?? truckBinCapacity;
          wasteInTruck = 0;
        }
        result.add(task.copyWith(sequenceOrder: sequenceOrder++));
        warehouseStopCount++;
      }
    }

    // Final warehouse stop if waste remaining
    if (wasteInTruck > 0) {
      result.add(
        _createWarehouseStop(
          shiftId: shiftId,
          sequenceOrder: sequenceOrder,
          location: warehouseLocation,
          action: 'unload',
          binsToLoad: 0,
          stopCount: ++warehouseStopCount,
        ),
      );
    }

    return result;
  }

  /// Create a warehouse stop task
  static RouteTask _createWarehouseStop({
    required String shiftId,
    required int sequenceOrder,
    required WarehouseLocation location,
    required String action,
    required int binsToLoad,
    required int stopCount,
  }) {
    return RouteTask(
      id: "-${1000000 + stopCount}", // Negative ID for temporary warehouse tasks
      shiftId: shiftId,
      sequenceOrder: sequenceOrder,
      taskType: StopType.warehouseStop,
      latitude: location.latitude,
      longitude: location.longitude,
      address: location.address,
      warehouseAction: action,
      binsToLoad: binsToLoad,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Analyze tasks and provide warehouse stop statistics
  static WarehouseStopAnalysis analyzeWarehouseStops({
    required List<RouteTask> tasks,
    required int truckBinCapacity,
  }) {
    int placementCount = 0;
    int collectionCount = 0;
    int moveRequestCount = 0;
    int manualWarehouseStops = 0;

    for (final task in tasks) {
      switch (task.taskType) {
        case StopType.placement:
          placementCount++;
          break;
        case StopType.collection:
          collectionCount++;
          break;
        case StopType.pickup:
          moveRequestCount++;
          break;
        case StopType.warehouseStop:
          manualWarehouseStops++;
          break;
        default:
          break;
      }
    }

    // Calculate auto warehouse stops
    final placementBatches =
        placementCount > 0 ? (placementCount / truckBinCapacity).ceil() : 0;
    final collectionBatches =
        collectionCount > 0 ? (collectionCount / truckBinCapacity).ceil() : 0;

    // Placement batches = load stops
    // Collection batches = unload stops (if waste needs to be dropped off)
    final autoLoadStops = placementBatches;
    final autoUnloadStops = collectionCount > 0 ? 1 : 0;

    return WarehouseStopAnalysis(
      placementCount: placementCount,
      collectionCount: collectionCount,
      moveRequestCount: moveRequestCount,
      manualWarehouseStops: manualWarehouseStops,
      autoLoadStops: autoLoadStops,
      autoUnloadStops: autoUnloadStops,
      totalWarehouseStops: autoLoadStops + autoUnloadStops + manualWarehouseStops,
      binsToLoad: placementCount,
    );
  }

  /// Remove all auto-inserted warehouse stops from task list
  /// Keeps only manually inserted ones
  static List<RouteTask> removeAutoWarehouseStops(List<RouteTask> tasks) {
    return tasks
        .where(
          (task) =>
              task.taskType != StopType.warehouseStop ||
              task.taskData?['manual'] == true,
        )
        .toList();
  }

  /// Check if tasks list needs warehouse stops recalculation
  static bool needsRecalculation(List<RouteTask> tasks) {
    // Check if there are placements or collections without proper warehouse stops
    int placementsSinceLoad = 0;
    int collectionsSinceUnload = 0;

    for (final task in tasks) {
      if (task.taskType == StopType.placement) {
        placementsSinceLoad++;
      } else if (task.taskType == StopType.collection) {
        collectionsSinceUnload++;
      } else if (task.taskType == StopType.warehouseStop) {
        if (task.warehouseAction == 'load') {
          placementsSinceLoad = 0;
        } else if (task.warehouseAction == 'unload') {
          collectionsSinceUnload = 0;
        }
      }
    }

    // Needs recalculation if there are orphaned placements/collections
    return placementsSinceLoad > 0 || collectionsSinceUnload > 0;
  }
}

/// Warehouse location data class
class WarehouseLocation {
  final double latitude;
  final double longitude;
  final String address;

  const WarehouseLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

/// Warehouse stop analysis result
class WarehouseStopAnalysis {
  final int placementCount;
  final int collectionCount;
  final int moveRequestCount;
  final int manualWarehouseStops;
  final int autoLoadStops;
  final int autoUnloadStops;
  final int totalWarehouseStops;
  final int binsToLoad;

  const WarehouseStopAnalysis({
    required this.placementCount,
    required this.collectionCount,
    required this.moveRequestCount,
    required this.manualWarehouseStops,
    required this.autoLoadStops,
    required this.autoUnloadStops,
    required this.totalWarehouseStops,
    required this.binsToLoad,
  });

  /// Get human-readable summary
  String get summary {
    final parts = <String>[];

    if (placementCount > 0) {
      parts.add('$placementCount placements');
    }
    if (collectionCount > 0) {
      parts.add('$collectionCount collections');
    }
    if (moveRequestCount > 0) {
      parts.add('$moveRequestCount moves');
    }
    if (totalWarehouseStops > 0) {
      parts.add('$totalWarehouseStops warehouse stops');
    }

    return parts.join(', ');
  }
}
