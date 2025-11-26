import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/services/shift_service.dart';
import 'package:ropacalapp/services/mapbox_route_fetcher_service.dart'; // Stub - will be replaced with Google Navigation
import 'package:ropacalapp/core/services/mapbox_directions_service.dart'; // Stub - will be replaced with Google Navigation
import 'package:ropacalapp/providers/api_provider.dart';
import 'package:ropacalapp/providers/mapbox_route_provider.dart'; // Stub - will be replaced with Google Navigation
import 'package:ropacalapp/providers/location_provider.dart';

part 'shift_provider.g.dart';

/// Provider for ShiftService
@riverpod
ShiftService shiftService(ShiftServiceRef ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ShiftService(apiService);
}

@Riverpod(keepAlive: true)
class ShiftNotifier extends _$ShiftNotifier {
  /// Track if we're waiting for location to become available
  bool _isWaitingForLocation = false;

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

        // Auto-fetch Mapbox route if shift has bins
        if (currentShift.routeBins.isNotEmpty) {
          // Check if location is ready
          final locationState = ref.read(currentLocationProvider);

          if (locationState.hasValue && locationState.value != null) {
            // ✅ Location ready - fetch immediately
            AppLogger.general(
              '✅ Location ready, fetching Mapbox route immediately',
            );
            _fetchMapboxRouteForCurrentShift();
          } else {
            // ⏳ Location not ready - wait for it
            AppLogger.general('⏳ Location not ready yet, will wait for it...');
            _waitForLocationThenFetch();
          }
        } else {
          AppLogger.general('⚠️  routeBins is EMPTY, not fetching Mapbox route');
        }
      } else {
        // No shift found - reset to inactive and clear Mapbox route data
        state = const ShiftState(status: ShiftStatus.inactive);
        ref.read(mapboxRouteMetadataProvider.notifier).clearRouteData();
        AppLogger.general('📥 No active shift - state reset to inactive');
        AppLogger.general('🗑️  Cleared Mapbox route data (no shift)');

        // Stop background location tracking
        ref.read(currentLocationProvider.notifier).stopBackgroundTracking();
      }
    } catch (e, stack) {
      AppLogger.general(
        '⚠️ Error fetching shift: $e',
        level: AppLogger.warning,
      );
      AppLogger.general('Stack trace: $stack');
      // On error, reset to inactive to be safe and clear Mapbox route data
      state = const ShiftState(status: ShiftStatus.inactive);
      ref.read(mapboxRouteMetadataProvider.notifier).clearRouteData();
      AppLogger.general('🗑️  Cleared Mapbox route data (error)');

      // Stop background location tracking
      ref.read(currentLocationProvider.notifier).stopBackgroundTracking();
    }
  }

  /// Fetch Mapbox Directions route for current shift's bins
  /// Runs in background, doesn't block UI
  /// Assumes location is already available
  Future<void> _fetchMapboxRouteForCurrentShift() async {
    try {
      AppLogger.routing('🗺️  Auto-fetching Mapbox route for shift...');
      AppLogger.routing(
        '🔍 state.routeBins.length = ${state.routeBins.length}',
      );

      // Get current location
      final locationState = ref.read(currentLocationProvider);
      if (!locationState.hasValue || locationState.value == null) {
        AppLogger.routing('⚠️  No location available, cannot fetch Mapbox route');
        return;
      }

      final location = locationState.value!;
      final currentLocation = latlong.LatLng(
        location.latitude,
        location.longitude,
      );
      AppLogger.routing(
        '📍 Current location: ${location.latitude}, ${location.longitude}',
      );

      // Get Mapbox Directions service with access token
      const accessToken = 'pk.eyJ1IjoiYmlubHl5YWkiLCJhIjoiY21pNzN4bzlhMDVheTJpcHdqd2FtYjhpeSJ9.sQM8WHE2C9zWH0xG107xhw';
      final mapboxService = MapboxDirectionsService(accessToken: accessToken);

      // Create fetcher service
      final fetcher = MapboxRouteFetcherService(
        mapboxService: mapboxService,
        ref: ref,
      );

      // Fetch and store route (runs async, doesn't block)
      AppLogger.routing('🚀 Calling fetchAndStoreRoute...');
      final success = await fetcher.fetchAndStoreRoute(
        currentLocation: currentLocation,
        routeBins: state.routeBins,
        optimize: true,
      );

      if (success) {
        AppLogger.routing('✅ Mapbox route auto-fetch completed');
      } else {
        AppLogger.routing(
          '⚠️  Mapbox route auto-fetch failed (will keep skeleton)',
        );
      }
    } catch (e, stack) {
      AppLogger.routing('❌ Error auto-fetching Mapbox route: $e');
      AppLogger.routing('Stack trace: $stack');
      // Don't throw - let skeleton keep showing
    }
  }

  /// Wait for location to become available, then fetch Mapbox route
  /// Sets up a one-time listener that triggers when location is ready
  void _waitForLocationThenFetch() {
    if (_isWaitingForLocation) {
      AppLogger.routing(
        '⚠️  Already waiting for location, skipping duplicate listener',
      );
      return;
    }

    _isWaitingForLocation = true;
    AppLogger.routing('⏳ Setting up location listener...');

    // Listen for location to become available
    final subscription = ref.listen(currentLocationProvider, (previous, next) {
      // Check if location is now available and we're still waiting
      if (_isWaitingForLocation && next.hasValue && next.value != null) {
        AppLogger.routing('✅ Location ready! Triggering Mapbox route fetch...');
        _isWaitingForLocation = false;

        // Fetch the Mapbox route now that location is available
        _fetchMapboxRouteForCurrentShift();
      }
    });

    // Note: The listener will automatically be disposed when the provider is disposed
    // or when the notifier is rebuilt, so we don't need manual cleanup
  }

  /// Manually refresh shift from backend
  Future<void> refreshShift() async {
    AppLogger.general('🔄 refreshShift() called');
    await fetchCurrentShift();
    AppLogger.general('✅ refreshShift() complete');
  }

  /// Pre-load route data (shift + location + Mapbox Directions)
  /// Returns true if route was successfully loaded, false otherwise
  /// Use this before navigating to map to ensure everything is ready
  Future<bool> preloadRoute() async {
    try {
      AppLogger.general('🚀 preloadRoute: Starting...');

      // Step 1: Fetch shift
      AppLogger.general('📥 preloadRoute: Step 1/3 - Fetching shift...');
      await fetchCurrentShift();

      // Check if we have bins
      if (state.routeBins.isEmpty) {
        AppLogger.general(
          'ℹ️  preloadRoute: No route bins, skipping Mapbox fetch',
        );
        return false;
      }

      AppLogger.general(
        '✅ preloadRoute: Shift loaded with ${state.routeBins.length} bins',
      );

      // Step 2: Wait for location (with timeout)
      AppLogger.general('📍 preloadRoute: Step 2/3 - Waiting for location...');
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

      AppLogger.general('✅ preloadRoute: Location ready');

      // Step 3: Fetch Mapbox route
      AppLogger.general(
        '🗺️  preloadRoute: Step 3/3 - Fetching Mapbox Directions route...',
      );
      await _fetchMapboxRouteForCurrentShift();

      // Check if route was loaded
      final routeMetadata = ref.read(mapboxRouteMetadataProvider);
      if (routeMetadata == null) {
        AppLogger.general(
          '⚠️  preloadRoute: Mapbox route fetch returned no data',
        );
        return false;
      }

      AppLogger.general(
        '✅ preloadRoute: Complete! Route ready with ${routeMetadata.polyline.length} points',
      );
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

      // Clear Mapbox route data when shift ends
      ref.read(mapboxRouteMetadataProvider.notifier).clearRouteData();
      AppLogger.general('🗑️  Cleared Mapbox route data (shift ended)');

      // Stop background location tracking
      ref.read(currentLocationProvider.notifier).stopBackgroundTracking();
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
