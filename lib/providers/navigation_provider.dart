import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// import 'package:turf/turf.dart' as turf; // Removed - was Mapbox-specific
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/navigation_state.dart';
import 'package:ropacalapp/models/route_step.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/providers/mapbox_route_provider.dart';
import 'package:ropacalapp/providers/voice_instruction_provider.dart';
import 'package:ropacalapp/services/mapbox_route_fetcher_service.dart';
import 'package:ropacalapp/core/services/mapbox_directions_service.dart';
import 'package:ropacalapp/services/gps_kalman_filter.dart';

part 'navigation_provider.g.dart';

@Riverpod(keepAlive: true)
class NavigationNotifier extends _$NavigationNotifier {
  StreamSubscription<Position>? _positionSubscription;

  // Kalman filter for GPS smoothing
  final _kalmanFilter = GpsKalmanFilter();

  // Thresholds
  static const int rerouteDebounceSeconds = 5;

  DateTime? _lastRerouteTime;

  @override
  NavigationState? build() {
    // Keep provider alive even when not watched
    ref.keepAlive();

    // Cleanup when provider is disposed
    ref.onDispose(() {
      AppLogger.navigation('🗑️  NavigationNotifier disposed');
      _positionSubscription?.cancel();
    });

    AppLogger.navigation('🏗️  NavigationNotifier.build() called');
    return null;
  }

  /// Start navigation using Mapbox Directions route data
  void startNavigationWithMapboxData({
    required LatLng startLocation,
    required List<Bin> destinationBins,
  }) {
    AppLogger.navigation('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLogger.navigation('🚀 startNavigationWithMapboxData() CALLED');
    AppLogger.navigation('   📍 startLocation: ${startLocation.latitude}, ${startLocation.longitude}');
    AppLogger.navigation('   📦 destinationBins: ${destinationBins.length}');

    if (destinationBins.isEmpty) {
      AppLogger.navigation('❌ ERROR: No destinations provided');
      throw Exception('No destinations provided');
    }

    // Get Mapbox Directions route data
    AppLogger.navigation('   🔍 Reading mapboxRouteMetadataProvider...');
    final mapboxRouteData = ref.read(mapboxRouteMetadataProvider);
    AppLogger.navigation('   📊 mapboxRouteData: ${mapboxRouteData != null ? "AVAILABLE" : "NULL"}');

    if (mapboxRouteData == null) {
      AppLogger.navigation('❌ ERROR: No route data available. Please fetch route first.');
      throw Exception('No route data available. Please fetch route first.');
    }

    AppLogger.navigation('   ✅ Route data available:');
    AppLogger.navigation('      - Steps: ${mapboxRouteData.steps.length}');
    AppLogger.navigation('      - Polyline points: ${mapboxRouteData.polyline.length}');
    AppLogger.navigation('      - Total distance: ${(mapboxRouteData.totalDistance / 1000).toStringAsFixed(2)} km');
    AppLogger.navigation('      - Total duration: ${(mapboxRouteData.totalDuration / 60).toStringAsFixed(1)} min');

    try {
      AppLogger.navigation(
        '🧭 Starting navigation to ${destinationBins.length} bins',
      );
      AppLogger.navigation(
        '   Start location: ${startLocation.latitude}, ${startLocation.longitude}',
      );
      AppLogger.navigation('   Using Mapbox Directions route data');
      AppLogger.navigation(
        '   Total distance: ${(mapboxRouteData.totalDistance / 1000).toStringAsFixed(2)} km',
      );
      AppLogger.navigation(
        '   Total duration: ${(mapboxRouteData.totalDuration / 60).toStringAsFixed(1)} min',
      );
      AppLogger.navigation('   Route steps: ${mapboxRouteData.steps.length}');
      AppLogger.navigation(
        '   Polyline points: ${mapboxRouteData.polyline.length}',
      );

      // Calculate ETA
      final estimatedArrival = DateTime.now().add(
        Duration(seconds: mapboxRouteData.totalDuration.toInt()),
      );

      // Calculate distance to first maneuver
      final distanceToFirstStep = mapboxRouteData.steps.isNotEmpty
          ? _calculateDistance(startLocation, mapboxRouteData.steps[0].location)
          : 0.0;

      // Initialize navigation state
      final newState = NavigationState(
        routeSteps: mapboxRouteData.steps,
        currentStepIndex: 0,
        currentLocation: startLocation,
        destinationBins: destinationBins,
        currentBinIndex: 0,
        totalDistance: mapboxRouteData.totalDistance,
        remainingDistance: mapboxRouteData.totalDistance,
        distanceToNextManeuver: distanceToFirstStep,
        startTime: DateTime.now(),
        routePolyline: mapboxRouteData.polyline,
        estimatedArrival: estimatedArrival,
      );

      state = newState;
      AppLogger.navigation(
        '✅ Navigation started - ${mapboxRouteData.steps.length} steps',
      );

      // Clear voice instruction history for new route
      final voiceService = ref.read(voiceInstructionServiceProvider);
      voiceService.clearHistory();
      AppLogger.navigation('🔊 Voice instructions ready');

      // Reset Kalman filter for new navigation session
      _kalmanFilter.reset();
      AppLogger.navigation('🎯 GPS Kalman filter initialized');

      // Start GPS tracking
      _startLocationTracking();
    } catch (e) {
      AppLogger.navigation('❌ Failed to start navigation: $e');
      rethrow;
    }
  }

  /// Helper to calculate distance between two LatLng points using latlong2
  double _calculateDistance(LatLng from, LatLng to) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, from, to);
  }

  /// Start listening to location updates
  void _startLocationTracking() {
    _positionSubscription?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) {
            final rawLocation = LatLng(position.latitude, position.longitude);
            AppLogger.navigation(
              '📍 RAW GPS: lat=${position.latitude}, lng=${position.longitude}, heading=${position.heading}, speed=${position.speed}',
            );

            // Filter GPS position through Kalman filter
            final filteredLocation = _kalmanFilter.update(rawLocation);

            updateLocation(
              filteredLocation,
              speed: position.speed,
              bearing: position.heading,
            );
          },
          onError: (error) {
            AppLogger.navigation('❌ Location tracking error: $error');
          },
        );
  }

  /// Update current location and check progress
  void updateLocation(
    LatLng newLocation, {
    double? speed,
    double? bearing,
    bool isSimulation =
        false, // New parameter to disable rerouting during simulation
  }) {
    final currentState = state;
    if (currentState == null) return;

    // Calculate distance to next maneuver
    final currentStep = currentState.currentStep;
    if (currentStep == null) return;

    final distanceToManeuver = _calculateDistance(
      newLocation,
      currentStep.location,
    );

    // Calculate remaining distance (approximate)
    double remainingDistance = distanceToManeuver;
    for (
      int i = currentState.currentStepIndex + 1;
      i < currentState.routeSteps.length;
      i++
    ) {
      remainingDistance += currentState.routeSteps[i].distance;
    }

    // Check if off route (but skip during simulation)
    final isOffRoute = isSimulation
        ? false
        : _checkOffRoute(newLocation, currentStep);

    // Update ETA based on current speed
    DateTime? estimatedArrival;
    if (speed != null && speed > 0) {
      final secondsRemaining = remainingDistance / speed;
      estimatedArrival = DateTime.now().add(
        Duration(seconds: secondsRemaining.toInt()),
      );
    }

    // Update state
    state = currentState.copyWith(
      currentLocation: newLocation,
      distanceToNextManeuver: distanceToManeuver,
      remainingDistance: remainingDistance,
      currentSpeed: speed,
      currentBearing: bearing,
      estimatedArrival: estimatedArrival,
      isOffRoute: isOffRoute,
    );

    // Announce voice instruction based on distance
    // Announce at 500m and 100m before maneuver
    final voiceService = ref.read(voiceInstructionServiceProvider);
    if (distanceToManeuver <= 500 && distanceToManeuver > 400) {
      voiceService.announce(
        announcement: 'In 500 meters, ${currentStep.instruction}',
        distanceToManeuver: distanceToManeuver,
        instructionId: 'step_${currentState.currentStepIndex}_500m',
      );
    } else if (distanceToManeuver <= 100 && distanceToManeuver > 50) {
      voiceService.announce(
        announcement: 'In 100 meters, ${currentStep.instruction}',
        distanceToManeuver: distanceToManeuver,
        instructionId: 'step_${currentState.currentStepIndex}_100m',
      );
    } else if (distanceToManeuver <= 50) {
      voiceService.announce(
        announcement: currentStep.instruction,
        distanceToManeuver: distanceToManeuver,
        instructionId: 'step_${currentState.currentStepIndex}_now',
      );
    }

    // Check if step is complete
    if (distanceToManeuver < BinConstants.stepCompleteThreshold) {
      _advanceToNextStep();
    }

    // Trigger reroute if off route
    if (isOffRoute) {
      _maybeReroute();
    }
  }

  /// Check if current location is off the planned route
  bool _checkOffRoute(LatLng currentLocation, RouteStep currentStep) {
    final distanceToStep = _calculateDistance(
      currentLocation,
      currentStep.location,
    );

    // If we're far from the next maneuver location, check if we're off route
    // This is a simple check - a more sophisticated approach would check
    // distance to the route polyline
    return distanceToStep > BinConstants.offRouteThreshold;
  }

  /// Advance to the next navigation step
  void _advanceToNextStep() {
    final currentState = state;
    if (currentState == null) return;

    final nextStepIndex = currentState.currentStepIndex + 1;

    if (nextStepIndex >= currentState.routeSteps.length) {
      // Navigation complete
      _completeNavigation();
      return;
    }

    // Check if we've reached a bin destination
    int newBinIndex = currentState.currentBinIndex;
    final nextStep = currentState.routeSteps[nextStepIndex];

    // If the next step is an "arrive" maneuver, we've reached a bin
    if (nextStep.maneuverType == 'arrive' &&
        newBinIndex < currentState.destinationBins.length) {
      newBinIndex++;
      AppLogger.navigation(
        '🎯 Reached bin ${newBinIndex}/${currentState.destinationBins.length}',
      );
    }

    state = currentState.copyWith(
      currentStepIndex: nextStepIndex,
      currentBinIndex: newBinIndex,
      distanceToNextManeuver: nextStep.distance,
      isOffRoute: false, // Reset off-route flag
    );

    AppLogger.navigation(
      '➡️  Advanced to step ${nextStepIndex + 1}/${currentState.routeSteps.length}',
    );
  }

  /// Complete navigation and cleanup
  void _completeNavigation() {
    AppLogger.navigation('🏁 Navigation complete!');
    _positionSubscription?.cancel();

    final currentState = state;
    if (currentState != null) {
      state = currentState.copyWith(
        currentStepIndex: currentState.routeSteps.length,
        currentBinIndex: currentState.destinationBins.length,
        remainingDistance: 0,
        distanceToNextManeuver: 0,
      );
    }
  }

  /// Reroute if user has gone off course
  /// Calls Mapbox Directions API to recalculate route from current position
  Future<void> _maybeReroute() async {
    final now = DateTime.now();

    // Debounce rerouting to avoid too many API calls
    if (_lastRerouteTime != null &&
        now.difference(_lastRerouteTime!).inSeconds < rerouteDebounceSeconds) {
      AppLogger.routing('⏳ Rerouting debounced (too soon since last attempt)');
      return;
    }

    _lastRerouteTime = now;

    final currentState = state;
    if (currentState == null) return;

    AppLogger.routing('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLogger.routing('🔄 OFF ROUTE DETECTED - Starting automatic reroute');
    AppLogger.routing('   📍 Current location: ${currentState.currentLocation.latitude}, ${currentState.currentLocation.longitude}');
    AppLogger.routing('   🗺️  Current bin index: ${currentState.currentBinIndex}/${currentState.destinationBins.length}');

    try {
      // Get remaining bins (not yet visited)
      final remainingBins = currentState.destinationBins
          .skip(currentState.currentBinIndex)
          .toList();

      if (remainingBins.isEmpty) {
        AppLogger.routing('✅ No remaining bins - navigation near completion');
        return;
      }

      AppLogger.routing('   📦 Remaining bins: ${remainingBins.length}');

      // Convert Bins to RouteBins for the fetcher service
      final routeBins = remainingBins.map<RouteBin>((bin) {
        return RouteBin(
          id: 0, // Temporary ID for rerouting
          shiftId: '', // Not needed for routing
          binId: bin.id,
          sequenceOrder: remainingBins.indexOf(bin),
          binNumber: bin.binNumber ?? 0,
          currentStreet: bin.currentStreet ?? '',
          city: bin.city ?? '',
          zip: bin.zip ?? '',
          latitude: bin.latitude ?? 0.0,
          longitude: bin.longitude ?? 0.0,
          fillPercentage: bin.fillPercentage ?? 0,
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000, // Current timestamp
        );
      }).toList();

      // Initialize Mapbox Directions service
      const accessToken = 'pk.eyJ1IjoiYmlubHl5YWkiLCJhIjoiY21pNzN4bzlhMDVheTJpcHdqd2FtYjhpeSJ9.sQM8WHE2C9zWH0xG107xhw';
      final mapboxService = MapboxDirectionsService(accessToken: accessToken);

      // Create fetcher service
      final fetcher = MapboxRouteFetcherService(
        mapboxService: mapboxService,
        ref: ref,
      );

      // Fetch new route from current location to remaining bins
      AppLogger.routing('📡 Calling Mapbox Directions API for reroute...');
      final success = await fetcher.fetchAndStoreRoute(
        currentLocation: currentState.currentLocation,
        routeBins: routeBins,
        optimize: false, // Don't reorder bins during reroute
      );

      if (success) {
        AppLogger.routing('✅ Reroute successful!');
        AppLogger.routing('   🗺️  New route calculated and polyline updated');
        AppLogger.routing('   🔵 Blue line now shows path from current position');

        // Reset off-route flag and restart navigation with new route
        final newRouteData = ref.read(mapboxRouteMetadataProvider);
        if (newRouteData != null) {
          // Update navigation state with new route data
          state = currentState.copyWith(
            routeSteps: newRouteData.steps,
            currentStepIndex: 0, // Reset to first step of new route
            totalDistance: newRouteData.totalDistance,
            routePolyline: newRouteData.polyline.map((p) => LatLng(p.latitude, p.longitude)).toList(),
            isOffRoute: false,
          );

          AppLogger.routing('   🎯 Navigation updated with new route data');
          AppLogger.routing('   📋 New steps: ${newRouteData.steps.length}');
        }
      } else {
        AppLogger.routing('❌ Reroute failed - keeping original route');
        AppLogger.routing('   💡 Please try to return to the planned route');

        // Keep off-route flag but don't reset (user should be aware)
      }
    } catch (e, stackTrace) {
      AppLogger.routing('❌ Error during reroute: $e');
      AppLogger.routing('   Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');

      // Reset off-route flag to prevent repeated failed attempts
      if (state != null) {
        state = state!.copyWith(isOffRoute: false);
      }
    }

    AppLogger.routing('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Manually trigger reroute
  /// Allows user to manually recalculate route (e.g., via UI button)
  Future<void> reroute() async {
    AppLogger.routing('👆 Manual reroute triggered by user');

    // Set state as off-route to trigger rerouting
    if (state != null) {
      state = state!.copyWith(isOffRoute: true);
    }

    // Reset debounce timer to allow immediate reroute
    _lastRerouteTime = null;

    // Trigger reroute
    await _maybeReroute();
  }

  /// Stop navigation and cleanup
  void stopNavigation() {
    AppLogger.navigation('🛑 Stopping navigation');
    _positionSubscription?.cancel();
    _lastRerouteTime = null;

    // Reset Kalman filter
    _kalmanFilter.reset();
    AppLogger.navigation('🎯 GPS Kalman filter reset');

    // Stop any ongoing voice announcements
    final voiceService = ref.read(voiceInstructionServiceProvider);
    voiceService.clearHistory();
    AppLogger.navigation('🔇 Voice announcements stopped');

    state = null;
  }

  /// Mark current bin as complete and move to next
  void markCurrentBinComplete() {
    final currentState = state;
    if (currentState == null) return;

    final nextBinIndex = currentState.currentBinIndex + 1;

    if (nextBinIndex >= currentState.destinationBins.length) {
      _completeNavigation();
      return;
    }

    AppLogger.navigation('✅ Bin marked complete, moving to next');

    // Find next "arrive" step in the route
    int nextArriveIndex = currentState.currentStepIndex;
    for (
      int i = currentState.currentStepIndex;
      i < currentState.routeSteps.length;
      i++
    ) {
      if (currentState.routeSteps[i].maneuverType == 'arrive') {
        nextArriveIndex = i + 1; // Move past the arrive step
        break;
      }
    }

    state = currentState.copyWith(
      currentBinIndex: nextBinIndex,
      currentStepIndex: nextArriveIndex,
    );
  }
}
