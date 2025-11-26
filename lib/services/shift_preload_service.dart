import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' as riverpod;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/services/shift_service.dart';
import 'package:ropacalapp/services/mapbox_route_fetcher_service.dart';
import 'package:ropacalapp/core/services/mapbox_directions_service.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/providers/mapbox_route_provider.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/models/route_bin.dart';

/// Result of shift pre-load operation
class PreloadResult {
  final bool success;
  final String? errorMessage;
  final bool hasActiveShift;

  const PreloadResult({
    required this.success,
    this.errorMessage,
    required this.hasActiveShift,
  });

  factory PreloadResult.success({required bool hasActiveShift}) {
    return PreloadResult(success: true, hasActiveShift: hasActiveShift);
  }

  factory PreloadResult.failure(String errorMessage) {
    return PreloadResult(
      success: false,
      errorMessage: errorMessage,
      hasActiveShift: false,
    );
  }
}

/// Service to pre-load shift data before navigating to map
/// Orchestrates: shift fetch -> location wait -> Mapbox route fetch
class ShiftPreloadService {
  final WidgetRef ref;

  ShiftPreloadService(this.ref);

  /// Pre-load shift data with timeout
  /// Returns PreloadResult indicating success/failure
  Future<PreloadResult> preloadShiftData({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      AppLogger.general('🔄 Starting shift pre-load...');

      // Step 1: Fetch shift from backend
      AppLogger.general('📥 Step 1/3: Fetching shift...');
      final shiftService = ref.read(shiftServiceProvider);
      final currentShift = await shiftService.getCurrentShift();

      if (currentShift == null) {
        AppLogger.general('ℹ️  No active shift found');
        // Update provider state
        ref.read(shiftNotifierProvider.notifier).state = ShiftState(
          status: ShiftStatus.inactive,
        );
        return PreloadResult.success(hasActiveShift: false);
      }

      // Update shift state immediately
      ref.read(shiftNotifierProvider.notifier).state = currentShift;
      AppLogger.general('✅ Shift loaded: ${currentShift.status}');

      // If no bins, no need to fetch route
      if (currentShift.routeBins.isEmpty) {
        AppLogger.general('ℹ️  No route bins in shift');
        return PreloadResult.success(hasActiveShift: true);
      }

      // Step 2: Wait for location (with timeout)
      AppLogger.general('📍 Step 2/3: Waiting for location...');
      final location = await _waitForLocation(timeout: timeout);

      if (location == null) {
        AppLogger.general('⚠️  Location timeout - will skip HERE route');
        return PreloadResult.success(hasActiveShift: true);
      }

      AppLogger.general(
        '✅ Location ready: ${location.latitude}, ${location.longitude}',
      );

      // Step 3: Fetch Mapbox Directions route
      AppLogger.general('🗺️  Step 3/3: Fetching Mapbox Directions route...');
      final routeFetched = await _fetchMapboxRoute(
        location: location,
        routeBins: currentShift.routeBins,
        timeout: timeout,
      );

      if (routeFetched) {
        AppLogger.general('✅ Mapbox Directions route fetched successfully');
      } else {
        AppLogger.general(
          '⚠️  Mapbox Directions route fetch failed - will use skeleton',
        );
      }

      return PreloadResult.success(hasActiveShift: true);
    } catch (e, stack) {
      AppLogger.general('❌ Pre-load failed: $e');
      AppLogger.general('Stack trace: $stack');
      return PreloadResult.failure('Failed to load shift data: $e');
    }
  }

  /// Wait for location to become available (with timeout)
  Future<({double latitude, double longitude})?> _waitForLocation({
    required Duration timeout,
  }) async {
    try {
      // Check if location is already available
      final currentLocationState = ref.read(currentLocationProvider);
      if (currentLocationState.hasValue && currentLocationState.value != null) {
        final pos = currentLocationState.value!;
        return (latitude: pos.latitude, longitude: pos.longitude);
      }

      // Wait for location with timeout
      AppLogger.general('⏳ Waiting for location provider...');
      final locationFuture = ref.read(currentLocationProvider.future);
      final position = await locationFuture.timeout(
        timeout,
        onTimeout: () {
          AppLogger.general('⏱️  Location timeout after ${timeout.inSeconds}s');
          return null;
        },
      );

      if (position == null) {
        return null;
      }

      return (latitude: position.latitude, longitude: position.longitude);
    } catch (e) {
      AppLogger.general('❌ Error waiting for location: $e');
      return null;
    }
  }

  /// Fetch Mapbox Directions route
  Future<bool> _fetchMapboxRoute({
    required ({double latitude, double longitude}) location,
    required List<RouteBin> routeBins,
    required Duration timeout,
  }) async {
    try {
      final currentLocation = latlong.LatLng(
        location.latitude,
        location.longitude,
      );

      // Get Mapbox Directions service with access token
      const accessToken = 'pk.eyJ1IjoiYmlubHl5YWkiLCJhIjoiY21pNzN4bzlhMDVheTJpcHdqd2FtYjhpeSJ9.sQM8WHE2C9zWH0xG107xhw';
      final mapboxService = MapboxDirectionsService(accessToken: accessToken);

      // Create fetcher service (cast WidgetRef to Ref for MapboxRouteFetcherService)
      final fetcher = MapboxRouteFetcherService(
        mapboxService: mapboxService,
        ref: ref as riverpod.Ref,
      );

      // Fetch and store route with timeout
      final success = await fetcher
          .fetchAndStoreRoute(
            currentLocation: currentLocation,
            routeBins: routeBins,
            optimize: true,
          )
          .timeout(
            timeout,
            onTimeout: () {
              AppLogger.routing(
                '⏱️  Mapbox Directions fetch timeout after ${timeout.inSeconds}s',
              );
              return false;
            },
          );

      return success;
    } catch (e) {
      AppLogger.routing('❌ Error fetching Mapbox route: $e');
      return false;
    }
  }
}
