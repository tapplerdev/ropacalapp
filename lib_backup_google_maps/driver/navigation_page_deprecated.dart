// ⚠️ DEPRECATED: This navigation implementation has been replaced
// File: navigation_page_deprecated.dart (formerly navigation_page.dart)
// Replaced on: Nov 18, 2025
// Reason: Switched to HERE Maps implementation with compass-based navigation arrow
// New implementation: navigation_page.dart (formerly here_maps_test_page.dart)
// This file is kept for reference only. Do not use in production.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/navigation_state.dart';
import 'package:ropacalapp/providers/navigation_provider.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/providers/bins_provider.dart';
import 'package:ropacalapp/providers/bin_marker_cache_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ropacalapp/features/driver/widgets/navigation_empty_state.dart';
import 'package:ropacalapp/features/driver/widgets/navigation_blue_dot_overlay.dart';
import 'package:ropacalapp/features/driver/widgets/navigation_bottom_panel.dart';
import 'package:ropacalapp/features/driver/widgets/navigation_action_buttons.dart';

class NavigationPage extends HookConsumerWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationNotifierProvider);
    final locationState = ref.watch(currentLocationProvider);
    final markerCache = ref.watch(binMarkerCacheNotifierProvider);
    final mapController = useState<GoogleMapController?>(null);
    final markers = useState<Set<Marker>>({});
    final polylines = useState<Set<Polyline>>({});
    final userZoomLevel = useState<double>(16.0); // User's preferred zoom level
    final isSimulating = useState<bool>(false);
    final currentSimulationIndex = useState<int>(0);
    final simulatedPosition = useState<LatLng?>(
      null,
    ); // Track simulated position for marker

    // Smooth interpolation state
    final currentSegmentIndex = useState<int>(0); // Which segment we're on
    final segmentProgress = useState<double>(
      0.0,
    ); // Progress along current segment (0.0 to 1.0)

    // Animation controller for 60 FPS smooth animation
    final animationController = useAnimationController(
      duration: const Duration(seconds: 60),
    );
    final routeProgress = useState<double>(
      0.0,
    ); // Overall route progress (0.0 to 1.0)

    // Track route changes to reset simulation indices
    final lastRouteId = useState<String?>(null);

    // Automated wrong turn testing - trigger at specific route progress points
    // COMMENTED OUT - User request to disable automated wrong turn simulation
    // final wrongTurnSchedule = [0.02, 0.04, 0.06]; // 2%, 4%, 6% into route
    // final executedWrongTurns = useState<Set<int>>({});

    // Navigation mode toggle (2D flat vs 3D navigation view)
    final isNavigationMode = useState<bool>(false);

    // Camera update throttling to prevent animation conflicts
    final lastCameraUpdate = useRef<DateTime>(DateTime.now());

    // Smooth bearing to reduce rotation jitter
    final smoothedBearing = useRef<double?>(null);

    // Detect route changes and reset simulation indices
    useEffect(() {
      if (navigationState != null && navigationState.routePolyline.isNotEmpty) {
        // Create a unique ID for this route (length + first point)
        final routeId =
            '${navigationState.routePolyline.length}_'
            '${navigationState.routePolyline.first.latitude.toStringAsFixed(6)}_'
            '${navigationState.routePolyline.first.longitude.toStringAsFixed(6)}';

        // If route changed while simulation is running, reset indices
        if (lastRouteId.value != null &&
            lastRouteId.value != routeId &&
            isSimulating.value) {
          AppLogger.navigation(
            '🔄 ROUTE CHANGED DURING SIMULATION! Resetting indices to 0',
          );
          AppLogger.navigation('   Old route ID: ${lastRouteId.value}');
          AppLogger.navigation('   New route ID: $routeId');
          AppLogger.navigation(
            '   Old indices: segment=${currentSegmentIndex.value}, simulation=${currentSimulationIndex.value}',
          );

          currentSegmentIndex.value = 0;
          currentSimulationIndex.value = 0;
          segmentProgress.value = 0.0;

          AppLogger.navigation('   ✅ Indices reset to 0');
        }

        lastRouteId.value = routeId;
      }
      return null;
    }, [navigationState?.routePolyline]);

    // Calculate bearing between two points
    double calculateBearing(latlong.LatLng from, latlong.LatLng to) {
      final lat1 = from.latitude * math.pi / 180;
      final lat2 = to.latitude * math.pi / 180;
      final dLon = (to.longitude - from.longitude) * math.pi / 180;

      final y = math.sin(dLon) * math.cos(lat2);
      final x =
          math.cos(lat1) * math.sin(lat2) -
          math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

      final bearing = math.atan2(y, x) * 180 / math.pi;
      return (bearing + 360) % 360; // Normalize to 0-360
    }

    // Calculate distance between two points in meters
    double calculateDistance(latlong.LatLng from, latlong.LatLng to) {
      const double earthRadius = 6371000; // meters
      final lat1 = from.latitude * math.pi / 180;
      final lat2 = to.latitude * math.pi / 180;
      final dLat = (to.latitude - from.latitude) * math.pi / 180;
      final dLon = (to.longitude - from.longitude) * math.pi / 180;

      final a =
          math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(lat1) *
              math.cos(lat2) *
              math.sin(dLon / 2) *
              math.sin(dLon / 2);
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

      return earthRadius * c;
    }

    // Interpolate between two points
    latlong.LatLng interpolate(
      latlong.LatLng from,
      latlong.LatLng to,
      double progress,
    ) {
      final lat = from.latitude + (to.latitude - from.latitude) * progress;
      final lng = from.longitude + (to.longitude - from.longitude) * progress;
      return latlong.LatLng(lat, lng);
    }

    // Calculate total route distance and cumulative distances for each point
    ({double totalDistance, List<double> cumulativeDistances})
    calculateRouteDistances(List<latlong.LatLng> route) {
      if (route.length < 2)
        return (totalDistance: 0.0, cumulativeDistances: [0.0]);

      final distances = <double>[0.0]; // First point is at distance 0
      double cumulative = 0.0;

      for (int i = 0; i < route.length - 1; i++) {
        final segmentDist = calculateDistance(route[i], route[i + 1]);
        cumulative += segmentDist;
        distances.add(cumulative);
      }

      return (totalDistance: cumulative, cumulativeDistances: distances);
    }

    // Get position along route based on overall progress (0.0 to 1.0)
    ({
      latlong.LatLng position,
      double bearing,
      int segmentIndex,
      double segmentProgress,
    })
    getPositionAtProgress(
      List<latlong.LatLng> route,
      List<double> cumulativeDistances,
      double totalDistance,
      double progress,
    ) {
      if (route.length < 2 || progress <= 0.0) {
        return (
          position: route.first,
          bearing: route.length > 1
              ? calculateBearing(route[0], route[1])
              : 0.0,
          segmentIndex: 0,
          segmentProgress: 0.0,
        );
      }

      if (progress >= 1.0) {
        final lastIdx = route.length - 2;
        return (
          position: route.last,
          bearing: calculateBearing(route[lastIdx], route.last),
          segmentIndex: lastIdx,
          segmentProgress: 1.0,
        );
      }

      final targetDistance = progress * totalDistance;

      // Find which segment we're on using binary search for efficiency
      int segmentIdx = 0;
      for (int i = 0; i < cumulativeDistances.length - 1; i++) {
        if (targetDistance >= cumulativeDistances[i] &&
            targetDistance <= cumulativeDistances[i + 1]) {
          segmentIdx = i;
          break;
        }
      }

      // Calculate progress within this segment
      final segmentStart = cumulativeDistances[segmentIdx];
      final segmentEnd = cumulativeDistances[segmentIdx + 1];
      final segmentLength = segmentEnd - segmentStart;
      final distanceInSegment = targetDistance - segmentStart;
      final segmentProg = segmentLength > 0
          ? distanceInSegment / segmentLength
          : 0.0;

      // Interpolate position within segment
      final fromPoint = route[segmentIdx];
      final toPoint = route[segmentIdx + 1];
      final position = interpolate(fromPoint, toPoint, segmentProg);
      final bearing = calculateBearing(fromPoint, toPoint);

      return (
        position: position,
        bearing: bearing,
        segmentIndex: segmentIdx,
        segmentProgress: segmentProg,
      );
    }

    // Calculate distance to current bin (not total remaining distance)
    String _calculateDistanceToCurrentBin(NavigationState navState) {
      // Start with distance to next maneuver
      double distanceToBin = navState.distanceToNextManeuver;

      // Add up all steps until we reach the next "arrive" maneuver
      for (
        int i = navState.currentStepIndex + 1;
        i < navState.routeSteps.length;
        i++
      ) {
        final step = navState.routeSteps[i];

        // Stop at the next "arrive" maneuver (which marks reaching a bin)
        if (step.maneuverType == 'arrive') {
          break;
        }

        distanceToBin += step.distance;
      }

      // Convert from meters to kilometers
      final distanceInKm = distanceToBin / 1000;

      return distanceInKm.toStringAsFixed(1);
    }

    // Simulate a realistic wrong turn (turn left or right from route)
    void simulateWrongTurn() {
      if (navigationState == null || !isSimulating.value) {
        AppLogger.navigation(
          '⚠️  Cannot simulate wrong turn - no active simulation',
        );
        return;
      }

      final currentLoc = locationState.value;
      if (currentLoc == null) {
        AppLogger.navigation(
          '⚠️  Cannot simulate wrong turn - no current location',
        );
        return;
      }

      // Get current segment to determine route direction
      final segmentIdx = currentSegmentIndex.value;
      if (segmentIdx >= navigationState.routePolyline.length - 1) {
        AppLogger.navigation(
          '⚠️  Cannot simulate wrong turn - at end of route',
        );
        return;
      }

      // Get current and next point to determine route direction
      final currentPoint = navigationState.routePolyline[segmentIdx];
      final nextPoint = navigationState.routePolyline[segmentIdx + 1];

      // Calculate the direction we SHOULD be going (route bearing)
      final routeBearing = calculateBearing(currentPoint, nextPoint);

      // Randomly choose left or right turn
      final random = math.Random();
      final turnLeft = random.nextBool();

      // Calculate perpendicular direction (90° turn)
      final wrongBearing = turnLeft
          ? (routeBearing - 90) %
                360 // Turn left
          : (routeBearing + 90) % 360; // Turn right

      // Move 75 meters in the wrong direction (like one city block)
      const wrongTurnDistance = BinConstants.wrongTurnDistance; // meters
      final earthRadius = 6371000.0; // meters

      // Convert bearing to radians
      final bearingRad = wrongBearing * math.pi / 180;

      // Calculate new position
      final currentLatRad = currentLoc.latitude * math.pi / 180;
      final currentLonRad = currentLoc.longitude * math.pi / 180;

      final newLatRad = math.asin(
        math.sin(currentLatRad) * math.cos(wrongTurnDistance / earthRadius) +
            math.cos(currentLatRad) *
                math.sin(wrongTurnDistance / earthRadius) *
                math.cos(bearingRad),
      );

      final newLonRad =
          currentLonRad +
          math.atan2(
            math.sin(bearingRad) *
                math.sin(wrongTurnDistance / earthRadius) *
                math.cos(currentLatRad),
            math.cos(wrongTurnDistance / earthRadius) -
                math.sin(currentLatRad) * math.sin(newLatRad),
          );

      final wrongTurnLocation = latlong.LatLng(
        newLatRad * 180 / math.pi,
        newLonRad * 180 / math.pi,
      );

      AppLogger.navigation('');
      AppLogger.navigation('🚨🚨🚨 SIMULATING WRONG TURN! 🚨🚨🚨');
      AppLogger.navigation(
        '   Current location: ${currentLoc.latitude.toStringAsFixed(6)}, ${currentLoc.longitude.toStringAsFixed(6)}',
      );
      AppLogger.navigation(
        '   Route bearing: ${routeBearing.toStringAsFixed(1)}°',
      );
      AppLogger.navigation(
        '   Wrong turn: ${turnLeft ? "LEFT" : "RIGHT"} (${wrongBearing.toStringAsFixed(1)}°)',
      );
      AppLogger.navigation(
        '   Wrong turn to: ${wrongTurnLocation.latitude.toStringAsFixed(6)}, ${wrongTurnLocation.longitude.toStringAsFixed(6)}',
      );
      AppLogger.navigation('   Distance: 75m (~1 block)');
      AppLogger.navigation(
        '   Current route step: ${navigationState.currentStepIndex + 1}/${navigationState.routeSteps.length}',
      );

      // Update location to off-route position
      ref
          .read(currentLocationProvider.notifier)
          .setSimulatedLocation(
            latitude: wrongTurnLocation.latitude,
            longitude: wrongTurnLocation.longitude,
            speed: 10.0,
            heading: currentLoc.heading,
          );

      AppLogger.navigation('   ✅ Location updated to off-route position');

      // Update navigation with off-route position (ENABLE off-route detection!)
      ref
          .read(navigationNotifierProvider.notifier)
          .updateLocation(
            wrongTurnLocation,
            speed: 10.0,
            bearing: currentLoc.heading,
            isSimulation: false, // Enable off-route detection!
          );

      AppLogger.navigation('   ✅ Navigation notified of wrong turn');
      AppLogger.navigation(
        '   ⏳ Waiting for off-route detection (threshold: 50m)...',
      );
      AppLogger.navigation('   ⏳ Rerouting will trigger after detection...');
      AppLogger.navigation('   📊 Current simulation indices:');
      AppLogger.navigation(
        '      currentSegmentIndex: ${currentSegmentIndex.value}',
      );
      AppLogger.navigation(
        '      currentSimulationIndex: ${currentSimulationIndex.value}',
      );
      AppLogger.navigation('');

      // Pause animation briefly
      final wasPlaying = animationController.isAnimating;
      animationController.stop();

      // Resume animation after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (wasPlaying && isSimulating.value) {
          AppLogger.navigation('   🔄 Resuming animation from new position');
          AppLogger.navigation('   📊 Simulation indices after reroute:');
          AppLogger.navigation(
            '      currentSegmentIndex: ${currentSegmentIndex.value}',
          );
          AppLogger.navigation(
            '      currentSimulationIndex: ${currentSimulationIndex.value}',
          );
          AppLogger.navigation(
            '      NEW route total points: ${navigationState?.routePolyline.length ?? 0}',
          );
          AppLogger.navigation(
            '   ⚠️  WARNING: Indices from OLD route may not match NEW route!',
          );
          // Animation continues automatically from current position
          animationController.forward();
        }
      });
    }

    // Simulate route movement with BUTTERY SMOOTH 60 FPS ANIMATION
    void startSimulation() {
      if (navigationState == null || navigationState.routePolyline.isEmpty) {
        AppLogger.navigation('❌ Cannot simulate - no route available');
        return;
      }

      if (isSimulating.value) {
        // Stop simulation
        AppLogger.navigation('🛑 Stopping route simulation');
        animationController.stop();
        animationController.reset();
        isSimulating.value = false;
        simulatedPosition.value = null;
        currentSimulationIndex.value = 0;
        currentSegmentIndex.value = 0;
        segmentProgress.value = 0.0;
        routeProgress.value = 0.0;
        return;
      }

      AppLogger.navigation(
        '🎮 Starting BUTTERY SMOOTH 60 FPS route simulation',
      );
      AppLogger.navigation(
        '   Total polyline points: ${navigationState.routePolyline.length}',
      );
      AppLogger.navigation('   Animation: 60 FPS (Ticker-based)');
      AppLogger.navigation(
        '   Speed: ${BinConstants.simulationSpeed} m/s (~54 km/h)',
      );
      AppLogger.navigation(
        '   Route start: ${navigationState.routePolyline.first.latitude}, ${navigationState.routePolyline.first.longitude}',
      );
      AppLogger.navigation(
        '   Route end: ${navigationState.routePolyline.last.latitude}, ${navigationState.routePolyline.last.longitude}',
      );

      // Pre-calculate route distances
      final routeMetrics = calculateRouteDistances(
        navigationState.routePolyline,
      );
      final totalDistance = routeMetrics.totalDistance;
      final cumulativeDistances = routeMetrics.cumulativeDistances;

      AppLogger.routing('📏 Route metrics calculated:');
      AppLogger.routing(
        '   Total distance: ${(totalDistance / 1000).toStringAsFixed(2)} km',
      );
      AppLogger.routing('   Points: ${cumulativeDistances.length}');

      // Calculate animation duration based on speed
      const speed = BinConstants.simulationSpeed; // m/s (~54 km/h)
      final durationSeconds = totalDistance / speed;

      AppLogger.navigation(
        '⏱️  Animation duration: ${durationSeconds.toStringAsFixed(1)} seconds',
      );

      // Reset state
      isSimulating.value = true;
      isNavigationMode.value =
          true; // Auto-enable 3D Navigation Mode for immersive experience
      currentSegmentIndex.value = 0;
      segmentProgress.value = 0.0;
      currentSimulationIndex.value = 0;
      routeProgress.value = 0.0;
      // executedWrongTurns.value = {}; // Reset wrong turn tracker - COMMENTED OUT

      // Set initial position
      simulatedPosition.value = LatLng(
        navigationState.routePolyline.first.latitude,
        navigationState.routePolyline.first.longitude,
      );

      // Update animation controller duration
      animationController.duration = Duration(
        milliseconds: (durationSeconds * 1000).toInt(),
      );

      int frameCount = 0;

      // Add listener for 60 FPS updates
      void animationListener() {
        if (!isSimulating.value) return;

        frameCount++;
        final progress = animationController.value; // 0.0 to 1.0
        routeProgress.value = progress;

        // Check if completed
        if (progress >= 1.0) {
          AppLogger.navigation('✅ Route simulation complete');
          AppLogger.navigation('');
          AppLogger.navigation('📊 SIMULATION STATS:');
          // COMMENTED OUT - User request to disable automated wrong turn simulation
          // AppLogger.navigation('   Programmed wrong turns: ${wrongTurnSchedule.length}');
          // AppLogger.navigation('   Executed wrong turns: ${executedWrongTurns.value.length}');
          AppLogger.navigation('   Total frames: $frameCount');
          // if (wrongTurnSchedule.isNotEmpty) {
          //   final successRate = (executedWrongTurns.value.length / wrongTurnSchedule.length * 100).toStringAsFixed(0);
          //   AppLogger.navigation('   Success rate: $successRate%');
          // }
          AppLogger.navigation('');
          animationController.stop();
          isSimulating.value = false;
          simulatedPosition.value = null;
          currentSimulationIndex.value = 0;
          currentSegmentIndex.value = 0;
          segmentProgress.value = 0.0;
          routeProgress.value = 0.0;
          return;
        }

        // Get position at current progress
        final positionData = getPositionAtProgress(
          navigationState!.routePolyline,
          cumulativeDistances,
          totalDistance,
          progress,
        );

        final currentPosition = positionData.position;
        final bearing = positionData.bearing;
        final segmentIdx = positionData.segmentIndex;
        final segmentProg = positionData.segmentProgress;

        // Update segment tracking for polyline updates
        currentSegmentIndex.value = segmentIdx;
        segmentProgress.value = segmentProg;
        currentSimulationIndex.value = segmentIdx;

        // Log occasionally for debugging (every 3 seconds at 60fps = every 180 frames)
        if (frameCount % 180 == 0 || frameCount <= 5) {
          AppLogger.navigation('🚗 Smooth 60 FPS simulation frame $frameCount');
          AppLogger.navigation(
            '   Overall Progress: ${(progress * 100).toStringAsFixed(1)}%',
          );
          AppLogger.navigation(
            '   Segment: ${segmentIdx + 1}/${navigationState.routePolyline.length - 1}',
          );
          AppLogger.navigation(
            '   Position: ${currentPosition.latitude.toStringAsFixed(6)}, ${currentPosition.longitude.toStringAsFixed(6)}',
          );
          AppLogger.navigation('   Bearing: ${bearing.toStringAsFixed(1)}°');

          // Check if we should trigger an automated wrong turn
          // COMMENTED OUT - User request to disable automated wrong turn simulation
          // for (int i = 0; i < wrongTurnSchedule.length; i++) {
          //   if (!executedWrongTurns.value.contains(i) && progress >= wrongTurnSchedule[i]) {
          //     executedWrongTurns.value = {...executedWrongTurns.value, i};
          //     AppLogger.navigation('');
          //     AppLogger.navigation('🤖 AUTO WRONG TURN #${i + 1} at ${(progress * 100).toStringAsFixed(1)}%');
          //     Future.delayed(const Duration(milliseconds: 100), () => simulateWrongTurn());
          //     break;
          //   }
          // }
        }

        // Update location provider
        ref
            .read(currentLocationProvider.notifier)
            .setSimulatedLocation(
              latitude: currentPosition.latitude,
              longitude: currentPosition.longitude,
              speed: speed,
              heading: bearing,
            );

        // Update simulated position state
        simulatedPosition.value = LatLng(
          currentPosition.latitude,
          currentPosition.longitude,
        );

        // Update navigation provider
        ref
            .read(navigationNotifierProvider.notifier)
            .updateLocation(
              currentPosition,
              speed: speed,
              bearing: bearing,
              isSimulation: true,
            );
      }

      // Attach listener and start animation
      animationController.addListener(animationListener);

      // Remove listener when done
      animationController.addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          animationController.removeListener(animationListener);
        }
      });

      // Start the animation
      animationController.forward(from: 0.0);

      AppLogger.navigation(
        '▶️  Animation started - 60 FPS smooth movement enabled',
      );
    }

    // Update polylines and markers when navigation state changes OR simulation index changes
    useEffect(
      () {
        // print('🗺️  ROUTE/POLYLINE UPDATE TRIGGERED');
        // print('   navigationState != null: ${navigationState != null}');
        // print('   routePolyline.length: ${navigationState?.routePolyline.length ?? 0}');
        // print('   currentSimulationIndex: ${currentSimulationIndex.value}');
        // print('   currentSegmentIndex: ${currentSegmentIndex.value}');
        // print('   isSimulating: ${isSimulating.value}');

        if (navigationState != null &&
            navigationState.routePolyline.isNotEmpty) {
          // For simulation: show remaining route starting from CURRENT INTERPOLATED position
          List<LatLng> routeCoordinates;

          if (isSimulating.value &&
              currentSegmentIndex.value <
                  navigationState.routePolyline.length - 1) {
            // Calculate current interpolated position within segment (smooth!)
            final fromPoint =
                navigationState.routePolyline[currentSegmentIndex.value];
            final toPoint =
                navigationState.routePolyline[currentSegmentIndex.value + 1];
            final currentInterpolated = interpolate(
              fromPoint,
              toPoint,
              segmentProgress.value,
            );

            // Start polyline from interpolated position
            routeCoordinates = [
              LatLng(
                currentInterpolated.latitude,
                currentInterpolated.longitude,
              ), // Current smooth position
            ];

            // Add remaining route points (from next segment onwards)
            final remainingPoints = navigationState.routePolyline.skip(
              currentSegmentIndex.value + 1,
            );
            routeCoordinates.addAll(
              remainingPoints.map(
                (point) => LatLng(point.latitude, point.longitude),
              ),
            );
          } else {
            // Non-simulation or at route end: show full route
            final startIndex = isSimulating.value
                ? currentSimulationIndex.value
                : 0;
            final remainingRoute = navigationState.routePolyline.sublist(
              startIndex.clamp(0, navigationState.routePolyline.length - 1),
            );
            routeCoordinates = remainingRoute
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList();
          }

          // print('🗺️  Creating DYNAMIC route polyline');
          // print('   Total points: ${routeCoordinates.length}');
          // print('   Showing from: ${routeCoordinates.first}');
          // print('   Showing to: ${routeCoordinates.last}');
          // print('   Remaining distance: ${routeCoordinates.length} points');
          // print('   Color: ${AppColors.primaryBlue}');

          final routePolyline = Polyline(
            polylineId: const PolylineId('navigation_route'),
            points: routeCoordinates,
            color: AppColors.primaryBlue,
            width: 8, // Thicker line for better visibility
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
            visible: true,
            zIndex: 100, // Very high z-index to ensure it's on top
          );

          polylines.value = {routePolyline};

          // print('✅ Route polyline set: ${polylines.value.length} polyline(s)');
          // print('   Polyline ID: ${routePolyline.polylineId}');
          // print('   Polyline visible: ${routePolyline.visible}');
          // print('   Polyline color: ${routePolyline.color}');
          // print('   Polyline width: ${routePolyline.width}');
          // print('   Polyline zIndex: ${routePolyline.zIndex}');

          // Create markers for destination bins using global cache
          final newMarkers = <Marker>{};
          for (var i = 0; i < navigationState.destinationBins.length; i++) {
            final bin = navigationState.destinationBins[i];
            if (bin.latitude != null && bin.longitude != null) {
              // Get custom marker from global cache (instant if cached)
              final customIcon = ref
                  .read(binMarkerCacheNotifierProvider.notifier)
                  .getBinMarker(bin.id);

              // Fallback to default marker if cache not ready (shouldn't happen)
              final markerIcon =
                  customIcon ??
                  (i == navigationState.currentBinIndex
                      ? BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue,
                        )
                      : BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ));

              newMarkers.add(
                Marker(
                  markerId: MarkerId('bin_${bin.id}'),
                  position: LatLng(bin.latitude!, bin.longitude!),
                  infoWindow: InfoWindow(
                    title: 'Stop ${i + 1}: Bin #${bin.binNumber}',
                    snippet: '${bin.fillPercentage}% full',
                  ),
                  icon: markerIcon,
                ),
              );
            }
          }

          // Add custom blue dot marker for current location (2D mode only)
          // In 2D mode: use Marker so it stays at correct GPS coordinates when map is panned
          // In 3D mode: use centered overlay (see below) since camera is locked to position
          if (!isNavigationMode.value && locationState.value != null) {
            final currentLoc = locationState.value!;

            // Get custom blue dot marker from cache (matches overlay design)
            final blueDotIcon = ref
                .read(binMarkerCacheNotifierProvider.notifier)
                .getBlueDotMarker();

            newMarkers.add(
              Marker(
                markerId: const MarkerId('current_location'),
                position: LatLng(currentLoc.latitude, currentLoc.longitude),
                icon:
                    blueDotIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                anchor: const Offset(0.5, 0.5),
                flat: true,
                zIndex: 1000,
              ),
            );
          }

          markers.value = newMarkers;
          // print('📍 Total markers: ${newMarkers.length} markers (${newMarkers.length - 1} bins + 1 current location)')
        } else {
          polylines.value = {};
          markers.value = {};
        }
        return null;
      },
      [
        navigationState?.routePolyline,
        navigationState?.currentBinIndex,
        currentSimulationIndex.value,
        simulatedPosition.value,
        currentSegmentIndex.value, // Track segment changes
        segmentProgress.value, // Track smooth progress within segment (10fps)
        markerCache, // Re-render when marker cache updates
      ],
    );

    // Debug logging
    // useEffect(() {
    //   print('🔍 NavigationPage: state = ${navigationState != null ? "ACTIVE" : "NULL"}');
    //   if (navigationState != null) {
    //     print('   Destinations: ${navigationState.destinationBins.length} bins');
    //     print('   Current bin: ${navigationState.currentBinIndex + 1}/${navigationState.destinationBins.length}');
    //   }
    //   return null;
    // }, [navigationState]);

    // Update camera position when location changes (following mode)
    useEffect(
      () {
        // Track if this effect is still active (for cleanup)
        var isActive = true;

        // Schedule camera update for next frame to avoid concurrent modifications
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!isActive || mapController.value == null) {
            return;
          }

          // Use simulated position during simulation, otherwise use GPS location
          LatLng? targetPosition;
          double? gpsHeading;

          if (isSimulating.value && simulatedPosition.value != null) {
            // During simulation: use simulated position
            targetPosition = simulatedPosition.value;
            gpsHeading = navigationState?.currentBearing ?? 0.0;
          } else if (locationState.value != null) {
            // Not simulating: use GPS location
            final location = locationState.value!;
            targetPosition = LatLng(location.latitude, location.longitude);
            gpsHeading = location.heading;
          }

          // Only update camera if we have a valid position
          if (targetPosition == null || !isActive) {
            return;
          }

          // Navigation mode: Close zoom, 3D tilt, rotate to direction
          // Map mode: User zoom, flat, north up
          final zoom = isNavigationMode.value
              ? BinConstants.navigationZoom
              : userZoomLevel.value;
          final tilt = isNavigationMode.value
              ? BinConstants.navigationTilt
              : BinConstants.mapModeTilt;

          // Get raw bearing from GPS or route
          final rawBearing = isNavigationMode.value
              ? (gpsHeading != null && gpsHeading >= 0
                    ? gpsHeading
                    : navigationState?.currentBearing ?? 0.0)
              : 0.0;

          // Apply exponential smoothing to bearing to reduce jitter
          if (smoothedBearing.value == null) {
            smoothedBearing.value = rawBearing; // Initialize on first update
          } else {
            // Exponential moving average: 70% old value + 30% new value
            smoothedBearing.value =
                smoothedBearing.value! * BinConstants.bearingSmoothingFactor +
                rawBearing * (1 - BinConstants.bearingSmoothingFactor);
          }
          final bearing = smoothedBearing.value!;

          // Throttle camera updates to prevent animation conflicts
          final now = DateTime.now();
          if (now.difference(lastCameraUpdate.value).inMilliseconds <
              BinConstants.cameraUpdateThrottleMs) {
            return; // Skip this update - too soon after last one
          }
          lastCameraUpdate.value = now;

          // Safely animate camera with error handling for disposed controller
          if (isActive && mapController.value != null) {
            try {
              mapController.value!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: targetPosition,
                    zoom: zoom,
                    bearing: bearing,
                    tilt: tilt,
                  ),
                ),
              );
            } catch (e) {
              // Controller was disposed - ignore error
              AppLogger.map(
                'Camera animation skipped - controller disposed',
                level: AppLogger.debug,
              );
            }
          }
        });

        // Cleanup function to prevent updates after effect is disposed
        return () {
          isActive = false;
        };
      },
      [
        locationState.value,
        simulatedPosition.value, // Watch simulated position too!
        navigationState?.currentBearing,
        isNavigationMode.value,
        isSimulating.value, // Watch simulation state
      ],
    );

    if (navigationState == null) {
      return NavigationEmptyState(
        onBackToMap: () => Navigator.of(context).pop(),
      );
    }

    // Check if navigation is complete
    if (navigationState.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCompletionDialog(context, ref);
      });
    }

    final currentLocation = locationState.value;
    final initialPosition = currentLocation != null
        ? CameraPosition(
            target: LatLng(currentLocation.latitude, currentLocation.longitude),
            zoom: 15.0,
            bearing: navigationState.currentBearing ?? 0.0,
            tilt: 0.0, // 2D flat view
          )
        : CameraPosition(
            target: LatLng(
              navigationState.currentLocation.latitude,
              navigationState.currentLocation.longitude,
            ),
            zoom: 15.0,
            bearing: navigationState.currentBearing ?? 0.0,
            tilt: 0.0, // 2D flat view
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle
          .dark, // Dark status bar icons (for light backgrounds)
      child: Scaffold(
        body: Stack(
          children: [
            // Google Map with manual camera control
            GoogleMap(
              initialCameraPosition: initialPosition,
              myLocationEnabled:
                  false, // Disabled - using custom marker instead
              myLocationButtonEnabled: false,
              compassEnabled: false,
              trafficEnabled:
                  false, // Disable traffic to show our blue route clearly
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              markers: markers.value,
              polylines: polylines.value,
              onMapCreated: (controller) {
                mapController.value = controller;
                AppLogger.map('🗺️  Google Map created');
                AppLogger.map('   Markers count: ${markers.value.length}');
                AppLogger.map('   Polylines count: ${polylines.value.length}');
                if (polylines.value.isNotEmpty) {
                  final polyline = polylines.value.first;
                  AppLogger.map(
                    '   Polyline points: ${polyline.points.length}',
                  );
                  AppLogger.map('   Polyline color: ${polyline.color}');
                  AppLogger.map('   Polyline visible: ${polyline.visible}');

                  // Fit camera to show full route now that map is created
                  if (polyline.points.isNotEmpty) {
                    // Calculate bounds from all route points
                    double minLat = polyline.points.first.latitude;
                    double maxLat = polyline.points.first.latitude;
                    double minLng = polyline.points.first.longitude;
                    double maxLng = polyline.points.first.longitude;

                    for (final point in polyline.points) {
                      if (point.latitude < minLat) minLat = point.latitude;
                      if (point.latitude > maxLat) maxLat = point.latitude;
                      if (point.longitude < minLng) minLng = point.longitude;
                      if (point.longitude > maxLng) maxLng = point.longitude;
                    }

                    final bounds = LatLngBounds(
                      southwest: LatLng(minLat, minLng),
                      northeast: LatLng(maxLat, maxLng),
                    );

                    AppLogger.map(
                      '📐 Fitting camera to route bounds (after map created)',
                    );
                    AppLogger.map(
                      '   Southwest: (${bounds.southwest.latitude}, ${bounds.southwest.longitude})',
                    );
                    AppLogger.map(
                      '   Northeast: (${bounds.northeast.latitude}, ${bounds.northeast.longitude})',
                    );

                    // Delay to ensure map is fully initialized
                    Future.delayed(const Duration(milliseconds: 300), () {
                      try {
                        controller
                            .animateCamera(
                              CameraUpdate.newLatLngBounds(
                                bounds,
                                100,
                              ), // 100px padding
                            )
                            .then((_) {
                              AppLogger.map(
                                '✅ Camera fitted to bounds successfully',
                              );
                            })
                            .catchError((e) {
                              AppLogger.map(
                                '❌ Failed to fit camera to bounds: $e',
                              );
                            });
                      } catch (e) {
                        AppLogger.map('❌ Error creating camera update: $e');
                      }
                    });
                  }
                }
              },
            ),

            // Custom overlay: Blue dot at screen center (3D navigation mode only)
            // In 3D mode camera is locked to user position, so centered overlay works perfectly
            // Provides smooth, stutter-free rendering compared to Marker widget
            if (isNavigationMode.value && locationState.value != null)
              const NavigationBlueDotOverlay(),

            // Navigation info panel at bottom
            NavigationBottomPanel(
              navigationState: navigationState,
              distanceToCurrentBin: _calculateDistanceToCurrentBin(
                navigationState,
              ),
              onStopNavigation: () => _showStopNavigationDialog(context, ref),
              onCompleteAndNext: () => ref
                  .read(navigationNotifierProvider.notifier)
                  .markCurrentBinComplete(),
              onShowBinActions: () => _showBinActionsDialog(
                context,
                ref,
                navigationState.destinationBins[navigationState
                    .currentBinIndex],
              ),
            ),

            // Zoom in button - Close navigation view
            // COMMENTED OUT - User request to hide zoom controls
            // Positioned(
            //   bottom: 340,
            //   right: 16,
            //   child: FloatingActionButton(
            //     mini: true,
            //     heroTag: 'zoom_in',
            //     backgroundColor: isNavigationMode.value ? Colors.grey : null,
            //     onPressed: isNavigationMode.value ? null : () async {
            //       if (mapController.value != null && currentLocation != null) {
            //         final oldZoom = userZoomLevel.value;
            //         final newZoom = 19.0;

            //         print('➕ Zoom IN button clicked');
            //         print('   Current zoom: $oldZoom');
            //         print('   Target zoom: $newZoom');

            //         // Update user preference
            //         userZoomLevel.value = newZoom;

            //         // Get current camera position to check actual zoom
            //         print('   Updated user zoom preference: ${userZoomLevel.value}');

            //         await mapController.value!.animateCamera(
            //           CameraUpdate.newCameraPosition(
            //             CameraPosition(
            //               target: LatLng(currentLocation.latitude, currentLocation.longitude),
            //               zoom: newZoom,
            //               bearing: 0.0, // North up in map mode
            //               tilt: 0.0, // Flat 2D
            //             ),
            //           ),
            //         );

            //         print('✅ Zoom completed: $oldZoom → $newZoom');
            //       }
            //     },
            //     child: const Icon(Icons.add, size: 20),
            //   ),
            // ),
            // Floating action buttons for navigation controls
            NavigationActionButtons(
              isNavigationMode: isNavigationMode.value,
              isSimulating: isSimulating.value,
              currentLocation: currentLocation,
              navigationState: navigationState,
              userZoomLevel: userZoomLevel.value,
              mapController: mapController.value,
              onToggleNavigationMode: () {
                isNavigationMode.value = !isNavigationMode.value;
                AppLogger.navigation(
                  '🧭 Navigation mode toggled: ${isNavigationMode.value ? "ON (3D)" : "OFF (2D)"}',
                );
              },
              onToggleSimulation: startSimulation,
              onRecenter: () {},
            ),
            // Zoom out button - Overview
            // COMMENTED OUT - User request to hide zoom controls
            // Positioned(
            //   bottom: 400,
            //   right: 16,
            //   child: FloatingActionButton(
            //     mini: true,
            //     heroTag: 'zoom_out',
            //     backgroundColor: isNavigationMode.value ? Colors.grey : null,
            //     onPressed: isNavigationMode.value ? null : () async {
            //       if (mapController.value != null && currentLocation != null) {
            //         final oldZoom = userZoomLevel.value;
            //         final newZoom = 16.0;

            //         print('➖ Zoom OUT button clicked');
            //         print('   Current zoom: $oldZoom');
            //         print('   Target zoom: $newZoom');

            //         // Update user preference
            //         userZoomLevel.value = newZoom;

            //         print('   Updated user zoom preference: ${userZoomLevel.value}');

            //         await mapController.value!.animateCamera(
            //           CameraUpdate.newCameraPosition(
            //             CameraPosition(
            //               target: LatLng(currentLocation.latitude, currentLocation.longitude),
            //               zoom: newZoom,
            //               bearing: 0.0, // North up in map mode
            //               tilt: 0.0, // Flat 2D
            //             ),
            //           ),
            //         );

            //         print('✅ Zoom completed: $oldZoom → $newZoom');
            //       }
            //     },
            //     child: const Icon(Icons.remove, size: 20),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.green),
            SizedBox(width: 12),
            Text('Navigation Complete!'),
          ],
        ),
        content: const Text(
          'You have completed all bin collections on this route.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(navigationNotifierProvider.notifier).stopNavigation();
              ref.read(optimizedRouteProvider.notifier).clearRoute();
              Navigator.of(context).pop(); // Close dialog
              context.go('/home'); // Go back to map
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showStopNavigationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Navigation?'),
        content: const Text(
          'Are you sure you want to stop navigation? Your progress will be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(navigationNotifierProvider.notifier).stopNavigation();
              ref.read(optimizedRouteProvider.notifier).clearRoute();
              Navigator.of(context).pop(); // Close dialog
              context.go('/home'); // Go back to map
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }

  void _showBinActionsDialog(BuildContext context, WidgetRef ref, dynamic bin) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.skip_next),
              title: const Text('Skip this bin'),
              onTap: () {
                Navigator.of(context).pop();
                ref
                    .read(navigationNotifierProvider.notifier)
                    .markCurrentBinComplete();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View bin details'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/bin/${bin.id}');
              },
            ),
          ],
        ),
      ),
    );
  }
}
