import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/enums/stop_type.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/services/shift_service.dart';
import 'package:ropacalapp/providers/api_provider.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/core/services/location_tracking_service.dart';
import 'package:ropacalapp/core/services/centrifugo_service.dart';

part 'shift_provider.g.dart';

/// Provider for ShiftService
@riverpod
ShiftService shiftService(ShiftServiceRef ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ShiftService(apiService);
}

@Riverpod(keepAlive: true)
class ShiftNotifier extends _$ShiftNotifier {
  Timer? _pollingTimer;
  StreamSubscription? _shiftUpdatesSubscription;
  String? _subscribedShiftId;
  static const Duration _pollingInterval = Duration(seconds: 30);

  @override
  ShiftState build() {
    // Don't fetch on initialization - will be called after login
    // Clean up timer and subscription when provider is disposed
    ref.onDispose(() {
      _stopPolling();
      _unsubscribeFromShiftUpdates();
    });
    return const ShiftState(status: ShiftStatus.inactive);
  }

  /// Start polling for shift assignments when driver is inactive
  void _startPolling() {
    if (_pollingTimer != null && _pollingTimer!.isActive) {
      AppLogger.general('📊 Polling already active, skipping start');
      return;
    }

    AppLogger.general('📊 Starting shift polling (every ${_pollingInterval.inSeconds}s)');
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) async {
      if (state.status == ShiftStatus.inactive) {
        AppLogger.general('📊 Polling: Checking for new shift assignment...');
        try {
          await fetchCurrentShift();
        } catch (e) {
          AppLogger.general('📊 Polling: Error fetching shift: $e');
        }
      } else {
        AppLogger.general('📊 Polling: Shift is ${state.status}, stopping poll');
        _stopPolling();
      }
    });
  }

  /// Stop polling timer
  void _stopPolling() {
    if (_pollingTimer != null) {
      AppLogger.general('📊 Stopping shift polling');
      _pollingTimer?.cancel();
      _pollingTimer = null;
    }
  }

  /// Manage Centrifugo subscription based on shift status
  /// Subscribe when shift is active/ready, unsubscribe when inactive
  void _manageShiftSubscription() {
    final shiftId = state.shiftId;
    final isActiveOrReady = state.status == ShiftStatus.active ||
        state.status == ShiftStatus.ready;

    // Subscribe if shift is active/ready and we haven't subscribed yet
    if (isActiveOrReady && shiftId != null && _subscribedShiftId != shiftId) {
      _subscribeToShiftUpdates(shiftId);
    }

    // Unsubscribe if shift is no longer active/ready
    if (!isActiveOrReady && _shiftUpdatesSubscription != null) {
      _unsubscribeFromShiftUpdates();
    }
  }

  /// Subscribe to shift updates channel via Centrifugo
  Future<void> _subscribeToShiftUpdates(String shiftId) async {
    try {
      AppLogger.general('🔔 Subscribing to shift updates for shift: $shiftId');

      final centrifugo = ref.read(centrifugoServiceProvider);
      _shiftUpdatesSubscription = await centrifugo.subscribeToShiftUpdates(
        shiftId,
        (data) {
          final type = data['type'] as String?;
          AppLogger.general('🔔 Received shift update via Centrifugo: type=$type');

          if (type == 'shift_cancelled') {
            AppLogger.general('❌ Shift cancelled via Centrifugo - calling handleShiftCancellation()');
            handleShiftCancellation();
          }
        },
      );

      _subscribedShiftId = shiftId;
      AppLogger.general('✅ Subscribed to shift:updates:$shiftId channel');
    } catch (e) {
      AppLogger.general(
        '⚠️  Failed to subscribe to shift updates: $e',
        level: AppLogger.warning,
      );
      // Don't throw - subscription is not critical (API polling is fallback)
    }
  }

  /// Unsubscribe from shift updates channel
  void _unsubscribeFromShiftUpdates() {
    if (_shiftUpdatesSubscription != null) {
      AppLogger.general('🔕 Unsubscribing from shift updates (shift: $_subscribedShiftId)');
      _shiftUpdatesSubscription?.cancel();
      _shiftUpdatesSubscription = null;
      _subscribedShiftId = null;
      AppLogger.general('✅ Unsubscribed from shift updates');
    }
  }

  /// Fetch current shift from backend (called after login and on app startup)
  Future<void> fetchCurrentShift() async {
    try {
      final now = DateTime.now().toIso8601String();
      AppLogger.general('[DIAGNOSTIC] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.general('[DIAGNOSTIC] 🔍 fetchCurrentShift: Starting at $now');
      AppLogger.general('[DIAGNOSTIC] 🔍 fetchCurrentShift: Called from: ${StackTrace.current.toString().split('\n').take(3).join('\n')}');
      AppLogger.general('[DIAGNOSTIC] 🔍 fetchCurrentShift: Calling backend API GET /api/driver/shift/current');
      AppLogger.general('[DIAGNOSTIC]    Current state BEFORE fetch:');
      AppLogger.general('[DIAGNOSTIC]      Status: ${state.status}');
      AppLogger.general('[DIAGNOSTIC]      RouteID: ${state.assignedRouteId}');
      AppLogger.general('[DIAGNOSTIC]      RouteBins: ${state.routeBins.length}');
      AppLogger.general('[DIAGNOSTIC]      ShiftID: ${state.shiftId}');

      final shiftService = ref.read(shiftServiceProvider);
      final currentShift = await shiftService.getCurrentShift();

      AppLogger.general('[DIAGNOSTIC] 🔍 fetchCurrentShift: Got response from backend');
      AppLogger.general('[DIAGNOSTIC]    isNull: ${currentShift == null}');

      if (currentShift != null) {
        AppLogger.general('[DIAGNOSTIC] ✅ fetchCurrentShift: Shift data received!');
        AppLogger.general('[DIAGNOSTIC]    Status: ${currentShift.status}');
        AppLogger.general('[DIAGNOSTIC]    RouteID: ${currentShift.assignedRouteId}');
        AppLogger.general('[DIAGNOSTIC]    RouteBins.length: ${currentShift.routeBins.length}');
        AppLogger.general('[DIAGNOSTIC]    CompletedBins: ${currentShift.completedBins}/${currentShift.totalBins}');

        if (currentShift.routeBins.isNotEmpty) {
          AppLogger.general('[DIAGNOSTIC]    First 3 bins:');
          for (var i = 0; i < currentShift.routeBins.length && i < 3; i++) {
            final bin = currentShift.routeBins[i];
            AppLogger.general('[DIAGNOSTIC]      ${i + 1}. Bin #${bin.binNumber} - ${bin.currentStreet} (completed: ${bin.isCompleted})');
          }
        } else {
          AppLogger.general('[DIAGNOSTIC]    ⚠️  WARNING: routeBins array is EMPTY!');
        }

        state = currentShift;
        AppLogger.general('[DIAGNOSTIC] 📥 Current shift loaded and state updated');

        // Manage Centrifugo subscription based on shift status
        _manageShiftSubscription();

        // Stop polling since we found a shift
        _stopPolling();

        // Start background tracking if shift is ready/active
        if (currentShift.status == ShiftStatus.ready ||
            currentShift.status == ShiftStatus.active ||
            currentShift.status == ShiftStatus.paused) {
          AppLogger.general('[DIAGNOSTIC] 📍 Starting background location tracking');
          ref.read(currentLocationProvider.notifier).startBackgroundTracking();
        }
      } else {
        // No shift found - reset to inactive
        state = const ShiftState(status: ShiftStatus.inactive);
        AppLogger.general('[DIAGNOSTIC] 📥 No active shift found in backend - state reset to inactive');

        // Manage subscription (will unsubscribe since status is inactive)
        _manageShiftSubscription();

        // Start polling to check for new assignments
        _startPolling();

        // Downgrade to background tracking (no shift_id)
        AppLogger.general('[DIAGNOSTIC] 📍 Downgrading to background tracking (no shift)');
        await ref.read(locationTrackingServiceProvider).startBackgroundTracking();
      }
      AppLogger.general('[DIAGNOSTIC] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e, stack) {
      AppLogger.general('[DIAGNOSTIC] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.general('[DIAGNOSTIC] ❌ ERROR in fetchCurrentShift: $e', level: AppLogger.warning);
      AppLogger.general('[DIAGNOSTIC] Stack trace: $stack');
      // On error, reset to inactive to be safe
      state = const ShiftState(status: ShiftStatus.inactive);

      // Manage subscription (will unsubscribe since status is inactive)
      _manageShiftSubscription();

      // Start polling to keep checking for shifts
      _startPolling();

      // On error, downgrade to background tracking (defensive)
      AppLogger.general('[DIAGNOSTIC] 📍 Error fetching shift - downgrading to background tracking');
      await ref.read(locationTrackingServiceProvider).startBackgroundTracking();
      AppLogger.general('[DIAGNOSTIC] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      // Rethrow to allow retry logic to handle it
      rethrow;
    }
  }

  /// Fetch current shift with retry logic and exponential backoff
  /// Returns true if successful, false if all retries failed
  Future<bool> fetchCurrentShiftWithRetry({int maxAttempts = 3}) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        AppLogger.general('🔄 Fetch shift attempt $attempt/$maxAttempts');
        await fetchCurrentShift();
        AppLogger.general('✅ Fetch shift succeeded on attempt $attempt');
        return true;
      } catch (e) {
        AppLogger.general('❌ Fetch shift failed on attempt $attempt: $e');

        if (attempt < maxAttempts) {
          // Exponential backoff: 1s, 2s, 4s
          final delaySeconds = (1 << (attempt - 1)); // 2^(attempt-1)
          AppLogger.general('⏳ Waiting ${delaySeconds}s before retry...');
          await Future.delayed(Duration(seconds: delaySeconds));
        } else {
          AppLogger.general('❌ All $maxAttempts attempts failed');
          return false;
        }
      }
    }
    return false;
  }

  /// Manually refresh shift from backend
  Future<void> refreshShift() async {
    AppLogger.general('🔄 refreshShift() called');
    await fetchCurrentShift();
    AppLogger.general('✅ refreshShift() complete');
  }

  /// Reset shift state to inactive (called on logout)
  void reset() {
    AppLogger.general('🔄 Resetting shift state to inactive');
    _stopPolling();
    _unsubscribeFromShiftUpdates();
    state = const ShiftState(status: ShiftStatus.inactive);
    AppLogger.general('✅ Shift state reset complete');
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

    // Stop polling since we got an assignment
    _stopPolling();

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
      final overallStartTime = DateTime.now();
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.general('🚀 SHIFT ACCEPTANCE FLOW STARTED');
      AppLogger.general('   Shift ID: ${state.shiftId}');
      AppLogger.general('   Start time: ${overallStartTime.toIso8601String()}');
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Send current location before starting shift
      // This ensures backend has a location entry in driver_current_location table
      AppLogger.general('📍 STEP 1: Sending current location before starting shift...');
      final locationStartTime = DateTime.now();
      await ref.read(locationTrackingServiceProvider).sendCurrentLocation();
      final locationEndTime = DateTime.now();
      final locationDuration = locationEndTime.difference(locationStartTime).inMilliseconds;
      AppLogger.general('✅ Location step completed in ${locationDuration}ms');

      // STEP 2: Preflight check with retry logic
      AppLogger.general('');
      AppLogger.general('🔍 STEP 2: Running preflight checks...');
      final preflightStartTime = DateTime.now();
      final shiftService = ref.read(shiftServiceProvider);

      // Retry logic: Max 3 attempts with exponential backoff (1s, 2s, 4s)
      bool preflightReady = false;
      int attempt = 0;
      const maxAttempts = 3;
      String? preflightMessage;

      while (!preflightReady && attempt < maxAttempts) {
        attempt++;
        AppLogger.general('   Attempt $attempt/$maxAttempts...');

        try {
          final preflightResult = await shiftService.preflightCheck();
          preflightReady = preflightResult['ready'] as bool? ?? false;
          preflightMessage = preflightResult['message'] as String?;

          if (preflightReady) {
            AppLogger.general('   ✅ Preflight passed: $preflightMessage');
            break;
          } else {
            final retryAfter = preflightResult['retry_after'] as int? ?? 2;
            AppLogger.general('   ⚠️  Not ready: $preflightMessage');

            if (attempt < maxAttempts) {
              final delay = Duration(seconds: retryAfter);
              AppLogger.general('   ⏳ Retrying in ${delay.inSeconds}s...');
              await Future.delayed(delay);
            }
          }
        } catch (e) {
          AppLogger.general('   ❌ Preflight error: $e');
          if (attempt < maxAttempts) {
            final delay = Duration(seconds: 1 << (attempt - 1)); // 1s, 2s, 4s
            AppLogger.general('   ⏳ Retrying in ${delay.inSeconds}s...');
            await Future.delayed(delay);
          }
        }
      }

      final preflightEndTime = DateTime.now();
      final preflightDuration = preflightEndTime.difference(preflightStartTime).inMilliseconds;

      if (!preflightReady) {
        throw Exception(preflightMessage ?? 'Preflight checks failed after $maxAttempts attempts');
      }

      AppLogger.general('✅ Preflight checks completed in ${preflightDuration}ms');

      // STEP 3: Start shift (instant - already validated)
      AppLogger.general('');
      AppLogger.general('📡 STEP 3: Starting shift...');
      final apiStartTime = DateTime.now();
      final updatedShift = await shiftService.startShift();
      final apiEndTime = DateTime.now();
      final apiDuration = apiEndTime.difference(apiStartTime).inMilliseconds;
      AppLogger.general('✅ Shift started in ${apiDuration}ms');

      // IMPORTANT: Preserve routeBins from current state
      // The API response doesn't include bins array, but we already have it from route assignment
      // This prevents the navigation page from being blocked due to empty routeBins
      state = updatedShift.copyWith(
        routeBins: state.routeBins.isNotEmpty ? state.routeBins : updatedShift.routeBins,
      );

      AppLogger.general('');
      AppLogger.general('📍 STEP 4: Starting continuous location tracking...');
      // Start location tracking (sends GPS every ~1 second)
      if (state.shiftId != null) {
        ref.read(locationTrackingServiceProvider).startTracking(
          state.shiftId!,
        );
        AppLogger.general('✅ Location tracking started - will publish every ~1 second');
      } else {
        AppLogger.general('⚠️ Cannot start location tracking - shiftId is null');
      }

      final overallEndTime = DateTime.now();
      final totalDuration = overallEndTime.difference(overallStartTime).inMilliseconds;

      AppLogger.general('');
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.general('✅ SHIFT ACCEPTANCE FLOW COMPLETED');
      AppLogger.general('   Total duration: ${totalDuration}ms');
      AppLogger.general('   - Step 1 (Location): ${locationDuration}ms');
      AppLogger.general('   - Step 2 (Preflight): ${preflightDuration}ms');
      AppLogger.general('   - Step 3 (Start): ${apiDuration}ms');
      AppLogger.general('   Shift Status: ${state.status}');
      AppLogger.general('   Shift started at: ${state.startTime}');
      AppLogger.general('   Route bins: ${state.routeBins.length}');
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      AppLogger.general('');
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.general('❌ SHIFT ACCEPTANCE FLOW FAILED');
      AppLogger.general('   Error: $e');
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
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

  /// Mark a task as completed with updated fill percentage and optional photo
  /// Uses optimistic updates for instant UI feedback
  Future<void> completeTask(
    String taskId, // ID of route_tasks record (route task UUID)
    String binId, // DEPRECATED: kept for reference only
    int? updatedFillPercentage, { // Now nullable for incident reports
    String? photoUrl,
    int? newBinNumber, // REQUIRED for placement tasks
    bool hasIncident = false,
    String? incidentType,
    String? incidentPhotoUrl,
    String? incidentDescription,
    String? moveRequestId, // Links check to move request for pickup/dropoff
  }) async {
    if (state.status != ShiftStatus.active) {
      AppLogger.general('⚠️ Cannot complete task - shift not active');
      return;
    }

    // STEP 1: Save previous state for rollback
    final previousState = state;

    // STEP 2: Optimistic update - update UI immediately
    try {
      AppLogger.general('⚡ Optimistic update: Marking task complete instantly');

      // Find and mark the bin as completed
      final updatedRouteBins = state.routeBins.map((bin) {
        if (bin.id == taskId) {
          return bin.copyWith(
            isCompleted: 1,
            fillPercentage: updatedFillPercentage ?? bin.fillPercentage,
          );
        }
        return bin;
      }).toList();

      // Update state immediately (navigation will recalculate now!)
      state = state.copyWith(
        routeBins: updatedRouteBins,
        completedBins: state.completedBins + 1,
      );

      AppLogger.general('✅ Optimistic update applied - UI updated instantly');
      AppLogger.general('   Completed: ${state.completedBins}/${state.totalBins}');
      AppLogger.general('   Remaining bins: ${state.remainingBins.length}');

      // STEP 3: Confirm with server in background
      final shiftService = ref.read(shiftServiceProvider);
      await shiftService.completeTask(
        taskId,
        binId,
        updatedFillPercentage,
        photoUrl: photoUrl,
        newBinNumber: newBinNumber,
        hasIncident: hasIncident,
        incidentType: incidentType,
        incidentPhotoUrl: incidentPhotoUrl,
        incidentDescription: incidentDescription,
        moveRequestId: moveRequestId,
      );

      if (hasIncident) {
        AppLogger.general(
          '🚨 Task completed with incident report (type: $incidentType)${photoUrl != null ? ' with photo' : ''}, confirmed by server',
        );
      } else {
        AppLogger.general(
          '✅ Task completion confirmed by server (fill: $updatedFillPercentage%)${photoUrl != null ? ' with photo' : ''}',
        );
      }

      // Note: WebSocket will receive shift_update later
      // If WebSocket state differs from our optimistic update, server state wins
    } catch (e) {
      // STEP 4: Rollback on failure
      AppLogger.general('❌ Error completing task - rolling back optimistic update: $e', level: AppLogger.error);
      state = previousState;
      AppLogger.general('↩️  Rolled back to previous state');
      rethrow;
    }
  }

  /// Skip a task with a required reason
  /// If skipping a pickup, the paired dropoff will also be skipped automatically
  /// Uses optimistic updates for instant UI feedback
  Future<void> skipTask(String taskId, String reason) async {
    if (state.status != ShiftStatus.active) {
      AppLogger.general('⚠️ Cannot skip task - shift not active');
      return;
    }

    // STEP 1: Save previous state for rollback
    final previousState = state;

    // STEP 2: Optimistic update - update UI immediately
    try {
      AppLogger.general('⚡ Optimistic update: Skipping task instantly');

      // Find the bin being skipped and check if it's a pickup (for paired dropoff)
      final binToSkip = state.routeBins.firstWhere(
        (bin) => bin.id == taskId,
        orElse: () => state.routeBins.first, // Fallback
      );

      final isPickup = binToSkip.stopType == StopType.pickup;
      final moveRequestId = binToSkip.moveRequestId;

      // Mark the bin as skipped (isCompleted = 2 means skipped)
      final updatedRouteBins = state.routeBins.map((bin) {
        // Skip the target bin
        if (bin.id == taskId) {
          return bin.copyWith(isCompleted: 2); // 2 = skipped
        }

        // If skipping a pickup, also skip paired dropoff automatically
        if (isPickup &&
            moveRequestId != null &&
            bin.moveRequestId == moveRequestId &&
            bin.stopType == StopType.dropoff) {
          AppLogger.general('   Also skipping paired dropoff for move request: $moveRequestId');
          return bin.copyWith(isCompleted: 2); // 2 = skipped
        }

        return bin;
      }).toList();

      // Count how many bins were skipped (1 or 2)
      final skippedCount = updatedRouteBins.where((bin) => bin.isCompleted == 2).length -
          previousState.routeBins.where((bin) => bin.isCompleted == 2).length;

      // Update state immediately (navigation will recalculate now!)
      state = state.copyWith(
        routeBins: updatedRouteBins,
        completedBins: state.completedBins + skippedCount,
      );

      AppLogger.general('✅ Optimistic update applied - task skipped instantly');
      AppLogger.general('   Skipped count: $skippedCount (includes paired dropoff if applicable)');
      AppLogger.general('   Completed: ${state.completedBins}/${state.totalBins}');
      AppLogger.general('   Remaining bins: ${state.remainingBins.length}');

      // STEP 3: Confirm with server in background
      final shiftService = ref.read(shiftServiceProvider);
      await shiftService.skipTask(taskId, reason);

      AppLogger.general(
        '✅ Task skip confirmed by server (reason: $reason)',
      );

      // Note: WebSocket will receive shift_update later
      // If WebSocket state differs from our optimistic update, server state wins
    } catch (e) {
      // STEP 4: Rollback on failure
      AppLogger.general('❌ Error skipping task - rolling back optimistic update: $e', level: AppLogger.error);
      state = previousState;
      AppLogger.general('↩️  Rolled back to previous state');
      rethrow;
    }
  }

  /// Update shift state from WebSocket data (called by WebSocket listener)
  /// This is more efficient and reliable than calling refreshShift()
  ///
  /// SYNC STRATEGY: Server always wins
  /// - If we have an optimistic update and server confirms it → No visual change
  /// - If server state differs from optimistic update → Server state overwrites ours
  /// - This prevents sync bugs and race conditions
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

      // DEBUG: Log logical counting
      AppLogger.general('🔍 DEBUG: Logical bin counts:');
      AppLogger.general('   - logicalTotalBins: ${updatedShift.logicalTotalBins}');
      AppLogger.general('   - logicalCompletedBins: ${updatedShift.logicalCompletedBins}');
      AppLogger.general('   - remainingBins.length: ${updatedShift.remainingBins.length}');

      if (updatedShift.remainingBins.isNotEmpty) {
        AppLogger.general('🔍 DEBUG: First remaining bin:');
        final nextBin = updatedShift.remainingBins.first;
        AppLogger.general('   - Bin #${nextBin.binNumber}');
        AppLogger.general('   - Stop type: ${nextBin.stopType}');
        AppLogger.general('   - Address: ${nextBin.currentStreet}');
        AppLogger.general('   - Is completed: ${nextBin.isCompleted}');
        AppLogger.general('   - Move request ID: ${nextBin.moveRequestId}');
      }

      // Server state always wins (overwrites optimistic updates)
      // This ensures eventual consistency and prevents sync bugs
      state = updatedShift;

      // Manage Centrifugo subscription based on updated shift status
      _manageShiftSubscription();
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

    // Immediately check for new assignment after deletion
    AppLogger.general('📊 Checking immediately for new shift assignment after deletion');
    try {
      await fetchCurrentShift();
    } catch (e) {
      AppLogger.general('📊 Error fetching shift after deletion: $e');
      // Start polling if immediate fetch fails
      _startPolling();
    }

    // Downgrade to background tracking (no shift_id)
    AppLogger.general('📍 Downgrading to background tracking after shift deleted');
    await ref.read(locationTrackingServiceProvider).startBackgroundTracking();
  }

  /// Handle shift cancellation (called when shift is cancelled by manager)
  /// Sets status to 'cancelled' to trigger cancellation dialog in UI
  Future<void> handleShiftCancellation() async {
    AppLogger.general('❌ Handling shift cancellation by manager');

    // Set status to cancelled (preserving current shift data for dialog)
    state = state.copyWith(status: ShiftStatus.cancelled);

    AppLogger.general('   Status set to cancelled, UI will show cancellation dialog');

    // Dialog now has manual dismiss button, so we wait a bit longer before resetting
    // This ensures the dialog has time to display before state changes
    await Future.delayed(const Duration(milliseconds: 1000));

    // Then reset to inactive after user dismisses dialog
    AppLogger.general('   Resetting to inactive after dialog dismissed');
    state = const ShiftState(status: ShiftStatus.inactive);

    // Check for new assignment
    _startPolling();

    // Downgrade to background tracking
    AppLogger.general('📍 Downgrading to background tracking after cancellation');
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
