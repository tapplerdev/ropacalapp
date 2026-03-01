import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/models/navigation_page_state.dart';
import 'package:ropacalapp/models/route_task.dart';
import 'package:ropacalapp/models/route_step.dart';

part 'navigation_page_provider.g.dart';

/// Provider for navigation page state
/// Manages all navigation-related state for the google_navigation_page
///
/// This follows the same pattern as SimulationNotifier and ShiftNotifier:
/// - Synchronous state initialization
/// - Mutable state via state = state.copyWith()
/// - Auto-dispose (will reset when page is disposed)
@riverpod
class NavigationPageNotifier extends _$NavigationPageNotifier {
  @override
  NavigationPageState build() {
    // Return clean initial state
    return const NavigationPageState();
  }

  // ==================== Navigation Status ====================

  void setNavigationReady(bool ready) {
    state = state.copyWith(isNavigationReady: ready);
  }

  void setNavigating(bool navigating) {
    state = state.copyWith(isNavigating: navigating);
  }

  void setHasReceivedFirstNavInfo(bool received) {
    state = state.copyWith(hasReceivedFirstNavInfo: received);
  }

  // ==================== Current Bin ====================

  void setCurrentBinIndex(int index) {
    state = state.copyWith(currentBinIndex: index);
  }

  void incrementBinIndex() {
    state = state.copyWith(currentBinIndex: state.currentBinIndex + 1);
  }

  // ==================== Task ID Tracking ====================

  /// Get the current task ID being tracked
  String? getCurrentTaskId() {
    return state.currentTaskId;
  }

  /// Set the current task ID from a task index
  /// This should be called whenever currentBinIndex changes
  void setCurrentTaskIdFromIndex(List<RouteTask> tasks, int index) {
    if (index >= 0 && index < tasks.length) {
      state = state.copyWith(currentTaskId: tasks[index].id);
    } else {
      state = state.copyWith(currentTaskId: null);
    }
  }

  /// Recalculate currentBinIndex based on the tracked task ID
  /// Call this after route reoptimization to sync the index with the new task order
  void recalculateIndexFromTaskId(List<RouteTask> remainingTasks) {
    final taskId = state.currentTaskId;
    if (taskId == null) {
      // No task ID tracked, reset to 0
      setCurrentBinIndex(0);
      if (remainingTasks.isNotEmpty) {
        setCurrentTaskIdFromIndex(remainingTasks, 0);
      }
      return;
    }

    // Find the task's new position in the updated array
    final newIndex = remainingTasks.indexWhere((task) => task.id == taskId);

    if (newIndex != -1) {
      // Task found at new position
      setCurrentBinIndex(newIndex);
    } else {
      // Task not found (likely completed or removed), reset to first task
      setCurrentBinIndex(0);
      if (remainingTasks.isNotEmpty) {
        setCurrentTaskIdFromIndex(remainingTasks, 0);
      } else {
        state = state.copyWith(currentTaskId: null);
      }
    }
  }

  // ==================== Navigation Step ====================

  void updateCurrentStep(RouteStep? step) {
    state = state.copyWith(currentStep: step);
  }

  void updateDistanceToNextManeuver(double distance) {
    state = state.copyWith(distanceToNextManeuver: distance);
  }

  // ==================== Route Progress ====================

  void updateRemainingTime(Duration? time) {
    state = state.copyWith(remainingTime: time);
  }

  void updateTotalDistanceRemaining(double? distance) {
    state = state.copyWith(totalDistanceRemaining: distance);
  }

  // ==================== Location ====================

  void updateNavigationLocation(LatLng? location) {
    state = state.copyWith(navigationLocation: location);
  }

  // ==================== Markers & Overlays ====================

  void updateMarkerToTaskMap(Map<String, RouteTask> markerMap) {
    state = state.copyWith(markerToTaskMap: markerMap);
  }

  void clearMarkerToTaskMap() {
    state = state.copyWith(markerToTaskMap: {});
  }

  void updateGeofenceCircles(List<CircleOptions> circles) {
    state = state.copyWith(geofenceCircles: circles);
  }

  void updateCompletedRoutePolyline(PolylineOptions? polyline) {
    state = state.copyWith(completedRoutePolyline: polyline);
  }

  // ==================== Audio ====================

  void toggleAudio() {
    state = state.copyWith(isAudioMuted: !state.isAudioMuted);
  }

  void setAudioMuted(bool muted) {
    state = state.copyWith(isAudioMuted: muted);
  }

  // ==================== UI State ====================

  void toggleBottomPanel() {
    state = state.copyWith(isBottomPanelExpanded: !state.isBottomPanelExpanded);
  }

  void setBottomPanelExpanded(bool expanded) {
    state = state.copyWith(isBottomPanelExpanded: expanded);
  }

  // ==================== Reset ====================

  void reset() {
    state = const NavigationPageState();
  }
}
