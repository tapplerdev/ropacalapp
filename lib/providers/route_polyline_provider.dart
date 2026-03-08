import 'dart:math' as math;
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/route_task.dart';
import 'package:ropacalapp/providers/driver_live_position_provider.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';

part 'route_polyline_provider.g.dart';

/// State for the live route polyline drawn from a followed/focused driver
/// to their current task destination.
class RoutePolylineState {
  final List<LatLng> fullRoute;
  final List<LatLng> visibleRoute;
  final LatLng? destination;
  final String? activeTaskId;
  final RouteTask? currentTask;
  final int totalTasks;
  final int completedTasks;
  final LatLng? lastFetchOrigin;
  final bool isLoading;
  final int lastTrimIndex;

  const RoutePolylineState({
    this.fullRoute = const [],
    this.visibleRoute = const [],
    this.destination,
    this.activeTaskId,
    this.currentTask,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.lastFetchOrigin,
    this.isLoading = false,
    this.lastTrimIndex = 0,
  });

  RoutePolylineState copyWith({
    List<LatLng>? fullRoute,
    List<LatLng>? visibleRoute,
    LatLng? destination,
    String? activeTaskId,
    RouteTask? currentTask,
    int? totalTasks,
    int? completedTasks,
    LatLng? lastFetchOrigin,
    bool? isLoading,
    int? lastTrimIndex,
  }) {
    return RoutePolylineState(
      fullRoute: fullRoute ?? this.fullRoute,
      visibleRoute: visibleRoute ?? this.visibleRoute,
      destination: destination ?? this.destination,
      activeTaskId: activeTaskId ?? this.activeTaskId,
      currentTask: currentTask ?? this.currentTask,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      lastFetchOrigin: lastFetchOrigin ?? this.lastFetchOrigin,
      isLoading: isLoading ?? this.isLoading,
      lastTrimIndex: lastTrimIndex ?? this.lastTrimIndex,
    );
  }

  bool get hasRoute => visibleRoute.length >= 2;
  bool get isEmpty => fullRoute.isEmpty;
}

@Riverpod(keepAlive: true)
class RoutePolyline extends _$RoutePolyline {
  /// Distance thresholds (meters)
  static const _snapThreshold = 25.0; // Prepend driverPos only when this close

  @override
  RoutePolylineState build() => const RoutePolylineState();

  /// Initialize polyline for a focused/followed driver.
  /// Fetches their shift details, finds the current task, then fetches
  /// OSRM directions from the driver's position to the task destination.
  Future<void> initializeForDriver(String driverId) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    try {
      // 1. Fetch shift details to get task list
      final shiftData = await ref.read(
        driverShiftDetailProvider(driverId).future,
      );

      final tasks = shiftData.bins;
      final totalTasks = tasks.length;
      final completedTasks = tasks.where((t) => t.isCompleted == 1).length;

      // 2. Find first incomplete task
      final currentTask = tasks
          .where((t) => t.isCompleted == 0 && !t.skipped)
          .firstOrNull;

      if (currentTask == null) {
        // No active task — clear polyline
        state = RoutePolylineState(
          totalTasks: totalTasks,
          completedTasks: completedTasks,
        );
        return;
      }

      final dest = LatLng(
        latitude: currentTask.latitude,
        longitude: currentTask.longitude,
      );

      // 3. Get driver's current GPS position
      final livePositions = ref.read(driverLivePositionsProvider);
      final driverLoc = livePositions[driverId];

      if (driverLoc == null) {
        // No GPS position yet — store task info but no route
        state = RoutePolylineState(
          destination: dest,
          activeTaskId: currentTask.id,
          currentTask: currentTask,
          totalTasks: totalTasks,
          completedTasks: completedTasks,
        );
        return;
      }

      final origin = LatLng(
        latitude: driverLoc.latitude,
        longitude: driverLoc.longitude,
      );

      // 4. Fetch OSRM directions
      await _fetchRoute(origin, dest);

      // 5. Update with task info
      state = state.copyWith(
        destination: dest,
        activeTaskId: currentTask.id,
        currentTask: currentTask,
        totalTasks: totalTasks,
        completedTasks: completedTasks,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.general('❌ Failed to initialize polyline for $driverId: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Local trim — adjusts the visible polyline based on the driver's
  /// current position. Fast, no API calls.
  ///
  /// Only prepends the driver position when ≤25m from the route to avoid
  /// straight lines cutting through buildings.
  void updateDriverPosition(LatLng driverPos) {
    if (state.fullRoute.isEmpty || state.destination == null) return;

    // Find nearest vertex (search forward from last trim to avoid jitter)
    final nearestIdx = _findNearestVertexIndex(
      state.fullRoute,
      driverPos,
      startFrom: state.lastTrimIndex,
    );

    final distFromRoute = _haversineDistance(
      driverPos,
      state.fullRoute[nearestIdx],
    );

    // Trim: slice from nearestIdx forward
    final remaining = state.fullRoute.sublist(nearestIdx);

    // Only prepend driver position when very close to the route.
    // When further away, omit to avoid straight line through buildings.
    // The periodic OSRM refresh (every 10s) will correct the route.
    final visible = distFromRoute <= _snapThreshold
        ? [driverPos, ...remaining]
        : remaining;

    state = state.copyWith(
      visibleRoute: visible,
      lastTrimIndex: nearestIdx,
    );
  }

  /// Periodic OSRM refresh — re-fetches the full route from the driver's
  /// current position to the destination. Guarantees the polyline is always
  /// road-snapped. Called every ~10s by the map page timer.
  Future<void> refreshRoute(LatLng driverPos) async {
    if (state.destination == null || state.isLoading) return;

    await _fetchRoute(driverPos, state.destination!);
  }

  /// Periodically check if the driver's active task has changed.
  /// If so, re-fetch the route to the new destination.
  Future<void> checkForTaskChange(String driverId) async {
    if (state.isLoading) return;

    try {
      // Force-invalidate to get fresh data
      ref.invalidate(driverShiftDetailProvider(driverId));
      final shiftData = await ref.read(
        driverShiftDetailProvider(driverId).future,
      );

      final tasks = shiftData.bins;
      final totalTasks = tasks.length;
      final completedTasks = tasks.where((t) => t.isCompleted == 1).length;

      final currentTask = tasks
          .where((t) => t.isCompleted == 0 && !t.skipped)
          .firstOrNull;

      if (currentTask == null) {
        // All tasks done
        state = RoutePolylineState(
          totalTasks: totalTasks,
          completedTasks: completedTasks,
        );
        return;
      }

      // Update progress regardless
      state = state.copyWith(
        totalTasks: totalTasks,
        completedTasks: completedTasks,
        currentTask: currentTask,
      );

      // If task changed, re-fetch route
      if (currentTask.id != state.activeTaskId) {
        AppLogger.general(
          '🔄 Task changed: ${state.activeTaskId} → ${currentTask.id}',
        );

        final dest = LatLng(
          latitude: currentTask.latitude,
          longitude: currentTask.longitude,
        );

        final livePositions = ref.read(driverLivePositionsProvider);
        final driverLoc = livePositions[driverId];
        if (driverLoc == null) return;

        final origin = LatLng(
          latitude: driverLoc.latitude,
          longitude: driverLoc.longitude,
        );

        state = state.copyWith(
          activeTaskId: currentTask.id,
          destination: dest,
        );

        await _fetchRoute(origin, dest);
      }
    } catch (e) {
      AppLogger.general('⚠️ Task change check failed: $e');
    }
  }

  /// Clear all polyline state (when focus/follow mode ends).
  void clear() {
    state = const RoutePolylineState();
  }

  // ─── Internal ──────────────────────────────────────────────────────

  /// Fetch OSRM route and update state.
  Future<void> _fetchRoute(LatLng origin, LatLng destination) async {
    state = state.copyWith(isLoading: true);

    try {
      final managerService = ref.read(managerServiceProvider);
      final coords = await managerService.getDirections(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destLat: destination.latitude,
        destLng: destination.longitude,
      );

      final route = coords
          .map((c) => LatLng(
                latitude: (c['latitude'] as num).toDouble(),
                longitude: (c['longitude'] as num).toDouble(),
              ))
          .toList();

      state = state.copyWith(
        fullRoute: route,
        visibleRoute: route,
        lastFetchOrigin: origin,
        lastTrimIndex: 0,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.general('⚠️ OSRM fetch failed: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Find the index of the nearest vertex in [route] to [point],
  /// searching forward from [startFrom] to prevent GPS jitter from
  /// making the polyline grow backwards.
  int _findNearestVertexIndex(
    List<LatLng> route,
    LatLng point, {
    int startFrom = 0,
  }) {
    double minDist = double.infinity;
    int nearestIdx = startFrom;

    // Search forward from startFrom, but also check a small window behind
    // in case the GPS jumped slightly back
    final searchStart = math.max(0, startFrom - 2);

    for (int i = searchStart; i < route.length; i++) {
      final dist = _haversineDistance(point, route[i]);
      if (dist < minDist) {
        minDist = dist;
        nearestIdx = i;
      }
    }

    // Ensure we don't go backwards beyond a small tolerance
    if (nearestIdx < startFrom - 2) {
      nearestIdx = startFrom;
    }

    return nearestIdx;
  }

  /// Haversine distance between two LatLng points, in meters.
  static double _haversineDistance(LatLng a, LatLng b) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);
    final h = sinDLat * sinDLat +
        math.cos(_toRadians(a.latitude)) *
            math.cos(_toRadians(b.latitude)) *
            sinDLng *
            sinDLng;
    return 2 * earthRadius * math.asin(math.sqrt(h));
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
