import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/animation.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

/// Service for animating driver markers smoothly (Uber-style)
///
/// Uses linear interpolation to smoothly transition markers between GPS updates
/// instead of instant "teleportation".
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

  MarkerAnimationService();

  /// Start animating a driver marker from current position to new position
  void animateMarker({
    required String driverId,
    required LatLng newPosition,
    LatLng? currentPosition,
  }) {
    // If no current position, start from new position (no animation needed)
    final startPosition = currentPosition ?? newPosition;

    // Calculate distance to determine if animation is needed
    final distance = _calculateDistance(startPosition, newPosition);

    // Skip animation if movement is tiny (< 1 meter)
    if (distance < 1.0) {
      AppLogger.map('🔇 Skipping animation for $driverId (distance: ${distance.toStringAsFixed(1)}m)');
      return;
    }

    AppLogger.map('🎬 Starting animation for $driverId: ${distance.toStringAsFixed(1)}m');

    // Create new animation
    _activeAnimations[driverId] = _DriverMarkerAnimation(
      driverId: driverId,
      startPosition: startPosition,
      endPosition: newPosition,
      startTime: DateTime.now(),
      duration: _animationDuration,
    );

    // Notify listeners that animations are active
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
        positions[entry.key] = animation.endPosition;
        completedDrivers.add(entry.key);
      } else {
        // Animation in progress - interpolate
        final t = elapsed.inMilliseconds / animation.duration.inMilliseconds;
        final curvedT = _animationCurve.transform(t);
        positions[entry.key] = _lerpLatLng(
          animation.startPosition,
          animation.endPosition,
          curvedT,
        );
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
  final LatLng startPosition;
  final LatLng endPosition;
  final DateTime startTime;
  final Duration duration;

  _DriverMarkerAnimation({
    required this.driverId,
    required this.startPosition,
    required this.endPosition,
    required this.startTime,
    required this.duration,
  });
}
