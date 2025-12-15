import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/services/shift_service.dart';
import 'package:ropacalapp/providers/api_provider.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/core/services/location_tracking_service.dart';

part 'shift_provider.g.dart';

/// Provider for ShiftService
@riverpod
ShiftService shiftService(ShiftServiceRef ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ShiftService(apiService);
}

@Riverpod(keepAlive: true)
class ShiftNotifier extends _$ShiftNotifier {
  @override
  ShiftState build() {
    // Don't fetch on initialization - will be called after login
    return const ShiftState(status: ShiftStatus.inactive);
  }

  /// Fetch current shift from backend (called after login and on app startup)
  Future<void> fetchCurrentShift() async {
    try {
      AppLogger.general('🔍 fetchCurrentShift: Starting...');
      AppLogger.general('🔍 fetchCurrentShift: Calling backend API GET /api/driver/shift/current');
      final shiftService = ref.read(shiftServiceProvider);
      final currentShift = await shiftService.getCurrentShift();

      AppLogger.general(
        '🔍 fetchCurrentShift: Got response from backend, isNull=${currentShift == null}',
      );

      if (currentShift != null) {
        AppLogger.general(
          '🔍 _fetchCurrentShift: routeBins.length=${currentShift.routeBins.length}',
        );
        state = currentShift;
        AppLogger.general('📥 Current shift loaded: ${currentShift.status}');

        // Start background tracking if shift is ready/active
        if (currentShift.status == ShiftStatus.ready ||
            currentShift.status == ShiftStatus.active ||
            currentShift.status == ShiftStatus.paused) {
          ref.read(currentLocationProvider.notifier).startBackgroundTracking();
        }
      } else {
        // No shift found - reset to inactive
        state = const ShiftState(status: ShiftStatus.inactive);
        AppLogger.general('📥 No active shift - state reset to inactive');

        // Downgrade to background tracking (no shift_id)
        // This allows managers to see driver location and assign routes
        AppLogger.general('📍 Downgrading to background tracking (no shift)');
        await ref.read(locationTrackingServiceProvider).startBackgroundTracking();
      }
    } catch (e, stack) {
      AppLogger.general(
        '⚠️ Error fetching shift: $e',
        level: AppLogger.warning,
      );
      AppLogger.general('Stack trace: $stack');
      // On error, reset to inactive to be safe
      state = const ShiftState(status: ShiftStatus.inactive);

      // On error, downgrade to background tracking (defensive)
      AppLogger.general('📍 Error fetching shift - downgrading to background tracking');
      await ref.read(locationTrackingServiceProvider).startBackgroundTracking();
    }
  }

  /// Manually refresh shift from backend
  Future<void> refreshShift() async {
    AppLogger.general('🔄 refreshShift() called');
    await fetchCurrentShift();
    AppLogger.general('✅ refreshShift() complete');
  }

  /// Pre-load shift and location data
  /// Returns true if data was successfully loaded, false otherwise
  /// Note: Google Navigation SDK handles route calculation internally
  Future<bool> preloadRoute() async {
    try {
      AppLogger.general('🚀 preloadRoute: Starting...');

      // Step 1: Fetch shift
      AppLogger.general('📥 preloadRoute: Step 1/2 - Fetching shift...');
      await fetchCurrentShift();

      // Check if we have bins
      if (state.routeBins.isEmpty) {
        AppLogger.general('ℹ️  preloadRoute: No route bins');
        return false;
      }

      AppLogger.general(
        '✅ preloadRoute: Shift loaded with ${state.routeBins.length} bins',
      );

      // Step 2: Wait for location (with timeout)
      AppLogger.general('📍 preloadRoute: Step 2/2 - Waiting for location...');
      final locationState = ref.read(currentLocationProvider);

      if (!locationState.hasValue || locationState.value == null) {
        // Location not ready yet, wait for it
        try {
          await ref
              .read(currentLocationProvider.future)
              .timeout(
                const Duration(seconds: 3),
                onTimeout: () {
                  AppLogger.general('⏱️  preloadRoute: Location timeout');
                  return null;
                },
              );
        } catch (e) {
          AppLogger.general('⚠️  preloadRoute: Location error: $e');
          return false;
        }
      }

      final location = ref.read(currentLocationProvider).value;
      if (location == null) {
        AppLogger.general('⚠️  preloadRoute: No location available');
        return false;
      }

      AppLogger.general('✅ preloadRoute: Complete! Shift and location ready');
      return true;
    } catch (e, stack) {
      AppLogger.general('❌ preloadRoute: Error - $e');
      AppLogger.general('Stack trace: $stack');
      return false;
    }
  }

  /// Called when manager assigns a route to the driver
  void assignRoute({required String routeId, required int totalBins}) {
    state = state.copyWith(
      status: ShiftStatus.ready,
      assignedRouteId: routeId,
      totalBins: totalBins,
      completedBins: 0,
    );

    AppLogger.general('📋 Route assigned: $routeId with $totalBins bins');
    AppLogger.general('✅ Shift ready to start');

    // Start background location tracking when shift is assigned
    ref.read(currentLocationProvider.notifier).startBackgroundTracking();
  }

  /// Start the shift (slide to confirm)
  Future<void> startShift() async {
    if (state.status != ShiftStatus.ready) {
      AppLogger.general('⚠️ Cannot start shift - status: ${state.status}');
      return;
    }

    try {
      final shiftService = ref.read(shiftServiceProvider);
      final updatedShift = await shiftService.startShift();

      state = updatedShift;
      AppLogger.general('🚀 Shift started at ${state.startTime}');

      // Start location tracking (sends GPS every 10 seconds)
      if (state.shiftId != null) {
        AppLogger.general('📍 Starting location tracking for shift: ${state.shiftId}');
        ref.read(locationTrackingServiceProvider).startTracking(
          state.shiftId!,
        );
      } else {
        AppLogger.general('⚠️ Cannot start location tracking - shiftId is null');
      }
    } catch (e) {
      AppLogger.general('❌ Error starting shift: $e', level: AppLogger.error);
      rethrow;
    }
  }

  /// Pause the shift (break time)
  Future<void> pauseShift() async {
    if (state.status != ShiftStatus.active) {
      AppLogger.general('⚠️ Cannot pause - not active');
      return;
    }

    try {
      final shiftService = ref.read(shiftServiceProvider);
      await shiftService.pauseShift();

      state = state.copyWith(
        status: ShiftStatus.paused,
        pauseStartTime: DateTime.now(),
      );

      AppLogger.general('⏸️ Shift paused at ${state.pauseStartTime}');

      // Stop location tracking during break (saves battery)
      ref.read(locationTrackingServiceProvider).stopTracking();
    } catch (e) {
      AppLogger.general('❌ Error pausing shift: $e', level: AppLogger.error);
      rethrow;
    }
  }

  /// Resume shift from pause
  Future<void> resumeShift() async {
    if (state.status != ShiftStatus.paused) {
      AppLogger.general('⚠️ Cannot resume - not paused');
      return;
    }

    try {
      final shiftService = ref.read(shiftServiceProvider);
      await shiftService.resumeShift();

      // Calculate pause duration and add to total
      if (state.pauseStartTime != null) {
        final pauseDuration = DateTime.now()
            .difference(state.pauseStartTime!)
            .inSeconds;
        final newTotalPause = state.totalPauseSeconds + pauseDuration;

        state = state.copyWith(
          status: ShiftStatus.active,
          totalPauseSeconds: newTotalPause,
          pauseStartTime: null,
        );

        AppLogger.general('▶️ Shift resumed - total pause: ${newTotalPause}s');

        // Resume location tracking after break
        if (state.shiftId != null) {
          AppLogger.general('📍 Resuming location tracking for shift: ${state.shiftId}');
          ref.read(locationTrackingServiceProvider).startTracking(
            state.shiftId!,
          );
        } else {
          AppLogger.general('⚠️ Cannot resume location tracking - shiftId is null');
        }
      }
    } catch (e) {
      AppLogger.general('❌ Error resuming shift: $e', level: AppLogger.error);
      rethrow;
    }
  }

  /// End the shift
  Future<void> endShift() async {
    final duration = getActiveShiftDuration();

    try {
      final shiftService = ref.read(shiftServiceProvider);
      await shiftService.endShift();

      AppLogger.general('🏁 Shift ended');
      AppLogger.general('   Duration: ${duration.inMinutes} minutes');
      AppLogger.general(
        '   Completed: ${state.completedBins}/${state.totalBins} bins',
      );

      // Note: Backend will send WebSocket update with full shift data
      // For now, set to ended status (will be replaced by WebSocket update)
      state = state.copyWith(status: ShiftStatus.ended);

      // Downgrade to background tracking (driver may get assigned another shift)
      AppLogger.general('📍 Downgrading to background tracking after shift ended');
      await ref.read(locationTrackingServiceProvider).startBackgroundTracking();
    } catch (e) {
      AppLogger.general('❌ Error ending shift: $e', level: AppLogger.error);
      rethrow;
    }
  }

  /// Mark a bin as completed
  Future<void> completeBin(String binId) async {
    if (state.status != ShiftStatus.active) {
      AppLogger.general('⚠️ Cannot complete bin - shift not active');
      return;
    }

    try {
      final shiftService = ref.read(shiftServiceProvider);
      await shiftService.completeBin(binId);

      AppLogger.general('✅ Bin completed via API, waiting for WebSocket update...');

      // Note: WebSocket will receive shift_update and call updateFromWebSocket()
      // No need to manually refresh - this avoids read-after-write consistency issues
    } catch (e) {
      AppLogger.general('❌ Error completing bin: $e', level: AppLogger.error);
      rethrow;
    }
  }

  /// Update shift state from WebSocket data (called by WebSocket listener)
  /// This is more efficient and reliable than calling refreshShift()
  void updateFromWebSocket(Map<String, dynamic> data) {
    try {
      AppLogger.general('📡 WebSocket: Updating shift state from WebSocket data');
      AppLogger.general('   Data: $data');

      // Parse the data into ShiftState
      final updatedShift = ShiftState.fromJson(data);

      AppLogger.general(
        '✅ WebSocket: Shift updated - ${updatedShift.completedBins}/${updatedShift.totalBins} (${updatedShift.remainingBins.length} remaining)',
      );
      AppLogger.general('   Status: ${updatedShift.status}');
      AppLogger.general('   Bins array length: ${updatedShift.routeBins.length}');
      AppLogger.general('   Route ID: ${updatedShift.assignedRouteId}');

      state = updatedShift;
    } catch (e) {
      AppLogger.general(
        '❌ Error updating shift from WebSocket: $e',
        level: AppLogger.error,
      );
      // Fallback to refreshing from backend
      AppLogger.general('   Falling back to refreshShift()...');
      refreshShift();
    }
  }

  /// Reset shift to inactive state (called when shift is deleted)
  Future<void> resetToInactive() async {
    AppLogger.general('🗑️  Resetting shift to inactive state');
    state = const ShiftState(status: ShiftStatus.inactive);

    // Downgrade to background tracking (no shift_id)
    AppLogger.general('📍 Downgrading to background tracking after shift deleted');
    await ref.read(locationTrackingServiceProvider).startBackgroundTracking();
  }

  /// Get current shift duration (excluding pause time)
  Duration getActiveShiftDuration() {
    if (state.startTime == null) {
      return Duration.zero;
    }

    final now = DateTime.now();
    final totalSeconds = now.difference(state.startTime!).inSeconds;

    // Subtract pause time
    int pauseSeconds = state.totalPauseSeconds;

    // If currently paused, add current pause duration
    if (state.pauseStartTime != null) {
      pauseSeconds += now.difference(state.pauseStartTime!).inSeconds;
    }

    final activeSeconds = totalSeconds - pauseSeconds;
    return Duration(seconds: activeSeconds.clamp(0, totalSeconds));
  }

  /// Check if route is complete
  bool isRouteComplete() {
    return state.completedBins >= state.totalBins;
  }

  /// Get completion percentage
  double getCompletionPercentage() {
    if (state.totalBins == 0) return 0.0;
    return (state.completedBins / state.totalBins).clamp(0.0, 1.0);
  }
}
