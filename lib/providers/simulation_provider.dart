import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/animation.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/simulation_state.dart';
import 'package:ropacalapp/providers/location_provider.dart';

part 'simulation_provider.g.dart';

/// Provider for route simulation state and logic
@riverpod
class SimulationNotifier extends _$SimulationNotifier {
  Timer? _simulationTimer;
  double _routeProgress = 0.0;
  List<latlong.LatLng> _routePolyline = [];
  List<double> _cumulativeDistances = [];
  double _totalDistance = 0.0;
  DateTime? _simulationStartTime;

  @override
  SimulationState build() {
    // Cleanup timer on dispose (prevents memory leaks and auto-restart)
    ref.onDispose(() {
      _simulationTimer?.cancel();
      _simulationTimer = null;
      _routeProgress = 0.0;
      _routePolyline = [];
      _cumulativeDistances = [];
      _totalDistance = 0.0;
      _simulationStartTime = null;
    });

    // Return clean initial state
    // This ensures simulation doesn't auto-start on hot restart
    return const SimulationState(
      isSimulating: false,
      simulatedPosition: null,
      bearing: 0.0,
      currentSegmentIndex: 0,
      segmentProgress: 0.0,
      routeProgress: 0.0,
      isNavigationMode: true,
      smoothedBearing: null,
      routePolyline: [],
    );
  }

  /// Calculate bearing between two points in degrees (0-360)
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

  /// Calculate distance between two points in meters
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

  /// Interpolate between two points
  latlong.LatLng interpolate(
    latlong.LatLng from,
    latlong.LatLng to,
    double progress,
  ) {
    final lat = from.latitude + (to.latitude - from.latitude) * progress;
    final lng = from.longitude + (to.longitude - from.longitude) * progress;
    return latlong.LatLng(lat, lng);
  }

  /// Calculate total route distance and cumulative distances for each point
  void _calculateRouteDistances(List<latlong.LatLng> route) {
    if (route.length < 2) {
      _totalDistance = 0.0;
      _cumulativeDistances = [0.0];
      return;
    }

    final distances = <double>[0.0]; // First point is at distance 0
    double cumulative = 0.0;

    for (int i = 0; i < route.length - 1; i++) {
      final segmentDist = calculateDistance(route[i], route[i + 1]);
      cumulative += segmentDist;
      distances.add(cumulative);
    }

    _totalDistance = cumulative;
    _cumulativeDistances = distances;
  }

  /// Get position along route based on overall progress (0.0 to 1.0)
  ({
    latlong.LatLng position,
    double bearing,
    int segmentIndex,
    double segmentProgress,
  })
  _getPositionAtProgress(double progress) {
    if (_routePolyline.length < 2 || progress <= 0.0) {
      return (
        position: _routePolyline.first,
        bearing: _routePolyline.length > 1
            ? calculateBearing(_routePolyline[0], _routePolyline[1])
            : 0.0,
        segmentIndex: 0,
        segmentProgress: 0.0,
      );
    }

    if (progress >= 1.0) {
      final lastIdx = _routePolyline.length - 2;
      return (
        position: _routePolyline.last,
        bearing: calculateBearing(_routePolyline[lastIdx], _routePolyline.last),
        segmentIndex: lastIdx,
        segmentProgress: 1.0,
      );
    }

    final targetDistance = progress * _totalDistance;

    // Find which segment we're on
    int segmentIdx = 0;
    for (int i = 0; i < _cumulativeDistances.length - 1; i++) {
      if (targetDistance >= _cumulativeDistances[i] &&
          targetDistance <= _cumulativeDistances[i + 1]) {
        segmentIdx = i;
        break;
      }
    }

    // Calculate progress within this segment
    final segmentStart = _cumulativeDistances[segmentIdx];
    final segmentEnd = _cumulativeDistances[segmentIdx + 1];
    final segmentLength = segmentEnd - segmentStart;
    final distanceInSegment = targetDistance - segmentStart;
    final segmentProg = segmentLength > 0
        ? distanceInSegment / segmentLength
        : 0.0;

    // Interpolate position within segment
    final fromPoint = _routePolyline[segmentIdx];
    final toPoint = _routePolyline[segmentIdx + 1];
    final position = interpolate(fromPoint, toPoint, segmentProg);
    final bearing = calculateBearing(fromPoint, toPoint);

    return (
      position: position,
      bearing: bearing,
      segmentIndex: segmentIdx,
      segmentProgress: segmentProg,
    );
  }

  /// Start route simulation
  void startSimulation(List<latlong.LatLng> routePolyline) {
    if (routePolyline.isEmpty || routePolyline.length < 2) {
      AppLogger.navigation('❌ Cannot simulate - route has less than 2 points');
      return;
    }

    if (state.isSimulating) {
      // Stop simulation
      _stopSimulation();
      return;
    }

    AppLogger.navigation('🎮 Starting BUTTERY SMOOTH route simulation');
    AppLogger.navigation('   Total polyline points: ${routePolyline.length}');
    AppLogger.navigation(
      '   Speed: ${BinConstants.simulationSpeed} m/s (~54 km/h)',
    );

    _routePolyline = routePolyline;
    _calculateRouteDistances(routePolyline);

    // AppLogger.routing('📏 Route metrics calculated:');
    // AppLogger.routing('   Total distance: ${(_totalDistance / 1000).toStringAsFixed(2)} km');
    // AppLogger.routing('   Points: ${_cumulativeDistances.length}');

    // Calculate animation duration based on speed
    const speed = BinConstants.simulationSpeed; // m/s
    final durationSeconds = _totalDistance / speed;

    AppLogger.navigation(
      '⏱️  Animation duration: ${durationSeconds.toStringAsFixed(1)} seconds',
    );

    // Reset state
    _routeProgress = 0.0;
    _simulationStartTime = DateTime.now();

    // Set initial position (convert latlong.LatLng to LatLng)
    final initialPosition = LatLng(
      latitude: routePolyline.first.latitude,
      longitude: routePolyline.first.longitude,
    );

    // Convert latlong.LatLng list to google_navigation_flutter LatLng list
    final convertedPolyline = routePolyline.map((point) =>
      LatLng(latitude: point.latitude, longitude: point.longitude)
    ).toList();

    state = state.copyWith(
      isSimulating: true,
      simulatedPosition: initialPosition,
      currentSegmentIndex: 0,
      segmentProgress: 0.0,
      routeProgress: 0.0,
      isNavigationMode: true, // Auto-enable 3D navigation mode
      isFollowing: true, // Auto-enable camera following
      routePolyline:
          convertedPolyline, // Store the full OSRM polyline for map rendering (converted)
    );

    AppLogger.navigation('📍 Simulation state after start:');
    AppLogger.navigation('   isNavigationMode: ${state.isNavigationMode}');
    AppLogger.navigation('   isFollowing: ${state.isFollowing}');
    AppLogger.navigation('   isSimulating: ${state.isSimulating}');

    // Start timer for 60 FPS updates (16.67ms per frame)
    const frameDuration = Duration(milliseconds: 16); // ~60 FPS
    int frameCount = 0;

    _simulationTimer = Timer.periodic(frameDuration, (timer) {
      frameCount++;

      // Calculate elapsed time
      final elapsed = DateTime.now().difference(_simulationStartTime!);
      final progress = (elapsed.inMilliseconds / (durationSeconds * 1000))
          .clamp(0.0, 1.0);

      _routeProgress = progress;

      // Check if completed
      if (progress >= 1.0) {
        AppLogger.navigation('✅ Route simulation complete');
        AppLogger.navigation('   Total frames: $frameCount');
        _stopSimulation();
        return;
      }

      // Get position at current progress
      final positionData = _getPositionAtProgress(progress);
      final currentPosition = positionData.position;
      final bearing = positionData.bearing;
      final segmentIdx = positionData.segmentIndex;
      final segmentProg = positionData.segmentProgress;

      // Log occasionally
      if (frameCount % 180 == 0 || frameCount <= 5) {
        AppLogger.navigation('🚗 Smooth simulation frame $frameCount');
        AppLogger.navigation(
          '   Progress: ${(progress * 100).toStringAsFixed(1)}%',
        );
        AppLogger.navigation(
          '   Segment: ${segmentIdx + 1}/${_routePolyline.length - 1}',
        );
        AppLogger.navigation('   Bearing: ${bearing.toStringAsFixed(1)}°');
      }

      // Apply bearing smoothing
      final smoothedBearing = state.smoothedBearing == null
          ? bearing
          : state.smoothedBearing! * BinConstants.bearingSmoothingFactor +
                bearing * (1 - BinConstants.bearingSmoothingFactor);

      // Update state
      state = state.copyWith(
        simulatedPosition: LatLng(
          latitude: currentPosition.latitude,
          longitude: currentPosition.longitude,
        ),
        bearing: bearing,
        smoothedBearing: smoothedBearing,
        currentSegmentIndex: segmentIdx,
        segmentProgress: segmentProg,
        routeProgress: progress,
      );

      // Update location provider
      ref
          .read(currentLocationProvider.notifier)
          .setSimulatedLocation(
            latitude: currentPosition.latitude,
            longitude: currentPosition.longitude,
            speed: speed,
            heading: bearing,
          );
    });

    AppLogger.navigation(
      '▶️  Simulation started - 60 FPS smooth movement enabled',
    );
  }

  /// Stop simulation
  void _stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _routeProgress = 0.0;
    _routePolyline = [];
    _cumulativeDistances = [];
    _totalDistance = 0.0;
    _simulationStartTime = null;

    state = state.copyWith(
      isSimulating: false,
      simulatedPosition: null,
      currentSegmentIndex: 0,
      segmentProgress: 0.0,
      routeProgress: 0.0,
      smoothedBearing: null,
      routePolyline: [], // Clear the polyline
    );

    AppLogger.navigation('🛑 Simulation stopped');
  }

  /// Stop simulation (public method)
  void stopSimulation() {
    _stopSimulation();
  }

  /// Reset simulation state (called on logout, shift end, etc.)
  void reset() {
    AppLogger.navigation('🔄 Resetting simulation state');
    _stopSimulation();
  }

  /// Toggle navigation mode (2D/3D)
  void toggleNavigationMode() {
    final oldMode = state.isNavigationMode;
    state = state.copyWith(isNavigationMode: !state.isNavigationMode);
    // AppLogger.navigation('');
    // AppLogger.navigation('🧭 TOGGLE NAVIGATION MODE BUTTON PRESSED');
    // AppLogger.navigation('   Before: ${oldMode ? "3D" : "2D"}');
    // AppLogger.navigation('   After: ${state.isNavigationMode ? "3D" : "2D"}');
    // AppLogger.navigation('   isFollowing: ${state.isFollowing}');
    // AppLogger.navigation('');
  }

  /// Set following mode (camera locked to position vs free roam)
  void setFollowing(bool following) {
    state = state.copyWith(isFollowing: following);
    // AppLogger.navigation(
    //   '📍 Following mode: ${following ? "LOCKED (smooth overlay)" : "FREE ROAM (marker)"}',
    // );
  }

  /// Enable following mode (for recenter button)
  void enableFollowing() {
    setFollowing(true);
  }

  /// Update bearing from GPS movement (for active shift navigation)
  /// Calculates bearing from previous position to current position
  /// Only updates if movement is significant (> 3 meters)
  void updateBearingFromGPS({
    required double prevLat,
    required double prevLng,
    required double currLat,
    required double currLng,
  }) {
    AppLogger.navigation('   🧭 updateBearingFromGPS() START');
    AppLogger.navigation('      From: ($prevLat, $prevLng)');
    AppLogger.navigation('      To:   ($currLat, $currLng)');

    // Don't update bearing during simulation - it's already calculated from route
    if (state.isSimulating) {
      AppLogger.navigation('      ⏸️  SKIP: isSimulating=true');
      return;
    }

    // Calculate distance moved
    final from = latlong.LatLng(prevLat, prevLng);
    final to = latlong.LatLng(currLat, currLng);
    final distance = calculateDistance(from, to);

    AppLogger.navigation(
      '      📏 Distance moved: ${distance.toStringAsFixed(2)}m',
    );

    // Minimum movement threshold to prevent jitter from GPS drift
    const minMovementMeters = 3.0;
    if (distance < minMovementMeters) {
      AppLogger.navigation(
        '      ⏸️  SKIP: Movement < ${minMovementMeters}m threshold',
      );
      AppLogger.navigation(
        '      Current state: bearing=${state.bearing.toStringAsFixed(2)}°, smoothed=${state.smoothedBearing?.toStringAsFixed(2) ?? "NULL"}',
      );
      return;
    }

    // Calculate bearing from movement
    final bearing = calculateBearing(from, to);
    AppLogger.navigation(
      '      🧮 Calculated raw bearing: ${bearing.toStringAsFixed(2)}°',
    );

    // Apply exponential smoothing to reduce jitter
    final smoothedBearing = state.smoothedBearing == null
        ? bearing
        : state.smoothedBearing! * BinConstants.bearingSmoothingFactor +
              bearing * (1 - BinConstants.bearingSmoothingFactor);

    AppLogger.navigation(
      '      🔄 Applied smoothing (${(BinConstants.bearingSmoothingFactor * 100).toStringAsFixed(0)}% old + ${((1 - BinConstants.bearingSmoothingFactor) * 100).toStringAsFixed(0)}% new)',
    );
    AppLogger.navigation(
      '      📊 Smoothed bearing: ${smoothedBearing.toStringAsFixed(2)}°',
    );

    // Update state
    state = state.copyWith(bearing: bearing, smoothedBearing: smoothedBearing);

    AppLogger.navigation('      ✅ State updated!');
    AppLogger.navigation(
      '         bearing: ${state.bearing.toStringAsFixed(2)}°',
    );
    AppLogger.navigation(
      '         smoothedBearing: ${state.smoothedBearing?.toStringAsFixed(2) ?? "NULL"}°',
    );
  }
}
