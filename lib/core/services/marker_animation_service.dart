import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/animation.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for animating driver markers smoothly (Uber-style)
///
/// Uses linear interpolation to smoothly transition markers between GPS updates
/// instead of instant "teleportation".
///
/// Features:
/// - Snap-to-roads API for perfect turn following (hybrid approach)
/// - Turn detection (heading changes > 15°)
/// - Poor GPS accuracy detection (> 20m)
/// - Graceful fallback to simple interpolation
///
/// Inspired by flutter_animarker's approach but adapted for google_navigation_flutter.
class MarkerAnimationService {
  // Animation state
  final Map<String, _DriverMarkerAnimation> _activeAnimations = {};

  // Notifier for when animations become active/inactive
  final animationStateNotifier = ValueNotifier<bool>(false);

  // Animation configuration
  static const Duration _animationDuration = Duration(milliseconds: 800);
  static const Curve _animationCurve = Curves.easeInOut;

  // Snap-to-roads configuration
  static const double _turnDetectionThreshold = 15.0; // degrees
  static const double _poorAccuracyThreshold = 20.0; // meters
  final Map<String, double> _previousHeadings = {};
  final Dio _dio = Dio();
  final String? _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  MarkerAnimationService();

  /// Start animating a driver marker from current position to new position
  ///
  /// Hybrid approach: Snap-to-roads if turning OR GPS accuracy is poor
  Future<void> animateMarker({
    required String driverId,
    required LatLng newPosition,
    LatLng? currentPosition,
    double? heading,
    double? accuracy,
  }) async {
    // If no current position, start from new position (no animation needed)
    final startPosition = currentPosition ?? newPosition;

    // Calculate distance to determine if animation is needed
    final distance = _calculateDistance(startPosition, newPosition);

    // Skip animation if movement is tiny (< 1 meter)
    if (distance < 1.0) {
      AppLogger.map('🔇 Skipping animation for $driverId (distance: ${distance.toStringAsFixed(1)}m)');
      return;
    }

    // Detect if we should use snap-to-roads (hybrid approach)
    final isTurning = _detectTurn(driverId, heading);
    final poorAccuracy = (accuracy ?? 0) > _poorAccuracyThreshold;
    final shouldSnapToRoads = isTurning || poorAccuracy;

    if (shouldSnapToRoads) {
      AppLogger.map(
        '🛣️ Using snap-to-roads for $driverId '
        '(turning: $isTurning, poor accuracy: $poorAccuracy)',
      );

      // Try to snap to roads
      final snappedPath = await _snapToRoads(startPosition, newPosition);

      if (snappedPath.length > 2) {
        // Successfully got snapped path - animate along it
        _animateAlongPath(driverId, snappedPath);
        return;
      }
    }

    // Fallback: Simple straight-line interpolation
    AppLogger.map('🎬 Starting simple animation for $driverId: ${distance.toStringAsFixed(1)}m');

    _activeAnimations[driverId] = _DriverMarkerAnimation(
      driverId: driverId,
      path: [startPosition, newPosition],
      startTime: DateTime.now(),
      duration: _animationDuration,
    );

    // Notify listeners that animations are active
    if (!animationStateNotifier.value) {
      animationStateNotifier.value = true;
      AppLogger.map('🔔 Animation state notifier set to TRUE');
    }
  }

  /// Detect if driver is making a turn (heading change > threshold)
  bool _detectTurn(String driverId, double? heading) {
    if (heading == null) return false;

    final previousHeading = _previousHeadings[driverId];
    if (previousHeading == null) {
      _previousHeadings[driverId] = heading;
      return false;
    }

    // Calculate heading delta (accounting for 360° wraparound)
    final delta = _calculateHeadingDelta(previousHeading, heading);
    _previousHeadings[driverId] = heading;

    // Consider it a turn if heading changed > threshold degrees
    final isTurning = delta.abs() > _turnDetectionThreshold;

    if (isTurning) {
      AppLogger.map(
        '🔄 Turn detected for $driverId: ${delta.toStringAsFixed(1)}° change',
      );
    }

    return isTurning;
  }

  /// Calculate heading delta (accounting for 360° wraparound)
  double _calculateHeadingDelta(double h1, double h2) {
    var delta = h2 - h1;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    return delta;
  }

  /// Snap waypoints to actual road geometry using Google Roads API
  Future<List<LatLng>> _snapToRoads(LatLng start, LatLng end) async {
    if (_googleApiKey == null) {
      AppLogger.map('⚠️ Google API key not found, skipping snap-to-roads');
      return [start, end];
    }

    try {
      // Build Roads API request
      final path =
          '${start.latitude},${start.longitude}|${end.latitude},${end.longitude}';
      final url =
          'https://roads.googleapis.com/v1/snapToRoads?path=$path&interpolate=true&key=$_googleApiKey';

      final response = await _dio
          .get(url)
          .timeout(const Duration(milliseconds: 500));

      if (response.statusCode == 200 && response.data != null) {
        final snappedPoints = (response.data['snappedPoints'] as List?)
            ?.map((point) => LatLng(
                  latitude: point['location']['latitude'] as double,
                  longitude: point['location']['longitude'] as double,
                ))
            .toList();

        if (snappedPoints != null && snappedPoints.isNotEmpty) {
          AppLogger.map('✅ Snapped to ${snappedPoints.length} road points');
          return snappedPoints;
        }
      }

      AppLogger.map('⚠️ Snap failed: ${response.statusCode}, using fallback');
      return [start, end];
    } catch (e) {
      AppLogger.map('⚠️ Snap error: $e, using fallback');
      return [start, end];
    }
  }

  /// Animate along a multi-point path (from snap-to-roads)
  void _animateAlongPath(String driverId, List<LatLng> path) {
    if (path.length < 2) return;

    AppLogger.map('🎬 Animating $driverId along ${path.length}-point path');

    // Store path animation data
    _activeAnimations[driverId] = _DriverMarkerAnimation(
      driverId: driverId,
      path: path,
      startTime: DateTime.now(),
      duration: _animationDuration,
    );

    // Notify listeners
    if (!animationStateNotifier.value) {
      animationStateNotifier.value = true;
      AppLogger.map('🔔 Animation state notifier set to TRUE');
    }
  }

  /// Get interpolated positions for all animating drivers
  Map<String, LatLng> getInterpolatedPositions() {
    final now = DateTime.now();
    final positions = <String, LatLng>{};
    final completedDrivers = <String>[];

    for (final entry in _activeAnimations.entries) {
      final animation = entry.value;
      final elapsed = now.difference(animation.startTime);

      if (elapsed >= animation.duration) {
        // Animation complete - use final position
        positions[entry.key] = animation.path.last;
        completedDrivers.add(entry.key);
      } else {
        // Animation in progress - interpolate along path
        final t = elapsed.inMilliseconds / animation.duration.inMilliseconds;
        final curvedT = _animationCurve.transform(t);
        positions[entry.key] = _interpolateAlongPath(animation.path, curvedT);
      }
    }

    // Remove completed animations
    for (final driverId in completedDrivers) {
      AppLogger.map('✅ Animation complete for $driverId');
      _activeAnimations.remove(driverId);
    }

    // Update notifier if all animations complete
    if (_activeAnimations.isEmpty && animationStateNotifier.value) {
      animationStateNotifier.value = false;
      AppLogger.map('🔔 Animation state notifier set to FALSE');
    }

    return positions;
  }

  /// Interpolate position along a multi-point path
  LatLng _interpolateAlongPath(List<LatLng> path, double t) {
    if (path.length == 2) {
      // Simple two-point interpolation
      return _lerpLatLng(path[0], path[1], t);
    }

    // Multi-point path: distribute t across segments
    final segmentCount = path.length - 1;
    final segmentProgress = t * segmentCount;
    final segmentIndex = segmentProgress.floor().clamp(0, segmentCount - 1);
    final segmentT = (segmentProgress - segmentIndex).clamp(0.0, 1.0);

    return _lerpLatLng(path[segmentIndex], path[segmentIndex + 1], segmentT);
  }

  /// Check if any animations are currently running
  bool get hasActiveAnimations => _activeAnimations.isNotEmpty;

  /// Linear interpolation between two LatLng positions
  LatLng _lerpLatLng(LatLng start, LatLng end, double t) {
    return LatLng(
      latitude: start.latitude + (end.latitude - start.latitude) * t,
      longitude: start.longitude + (end.longitude - start.longitude) * t,
    );
  }

  /// Calculate distance between two positions (Haversine formula)
  double _calculateDistance(LatLng start, LatLng end) {
    const earthRadius = 6371000.0; // meters

    final lat1 = start.latitude * (pi / 180.0);
    final lat2 = end.latitude * (pi / 180.0);
    final deltaLat = (end.latitude - start.latitude) * (pi / 180.0);
    final deltaLng = (end.longitude - start.longitude) * (pi / 180.0);

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Clean up resources
  void dispose() {
    _activeAnimations.clear();
    animationStateNotifier.dispose();
  }
}

/// Internal class representing a single driver marker animation
class _DriverMarkerAnimation {
  final String driverId;
  final List<LatLng> path; // Multi-point path (supports snap-to-roads)
  final DateTime startTime;
  final Duration duration;

  _DriverMarkerAnimation({
    required this.driverId,
    required this.path,
    required this.startTime,
    required this.duration,
  });
}
