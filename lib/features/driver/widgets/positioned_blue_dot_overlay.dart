import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Positioned blue dot overlay that follows a lat/lng position on the map
/// Uses direct synchronous calculation (no async getScreenCoordinate)
/// Calculates screen position from world coordinates using Mercator projection
class PositionedBlueDotOverlay extends HookWidget {
  final LatLng position;
  final GoogleMapViewController? mapController;
  final ValueNotifier<CameraPosition?> cameraPosition;

  const PositionedBlueDotOverlay({
    super.key,
    required this.position,
    required this.mapController,
    required this.cameraPosition,
  });

  // Static throttle for debug logs
  static DateTime _lastLogTime = DateTime.now();
  static const _logThrottleMs = 1000; // Log once per second

  /// Calculate screen position from world coordinates (Mercator projection)
  /// This is 100% synchronous - no async lag!
  Offset? _calculateScreenPosition(
    LatLng worldPos,
    CameraPosition camera,
    Size screenSize,
  ) {
    // Screen center in pixels
    final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);

    // Calculate offset from camera center in degrees
    final latDelta = worldPos.latitude - camera.target.latitude;
    final lngDelta = worldPos.longitude - camera.target.longitude;

    // Convert degrees to pixels using Mercator projection
    // At zoom Z: pixels per degree = (256 * 2^Z) / 360
    final zoom = camera.zoom;
    final scale = 256 * math.pow(2, zoom);
    final pixelsPerDegreeLat = scale / 360;

    // Longitude pixels depend on latitude (Mercator projection)
    final latRad = camera.target.latitude * math.pi / 180;
    final pixelsPerDegreeLng = pixelsPerDegreeLat * math.cos(latRad);

    // Calculate pixel offset from screen center
    final pixelOffsetX = lngDelta * pixelsPerDegreeLng;
    final pixelOffsetY =
        -latDelta *
        pixelsPerDegreeLat; // Negative: lat increases upward, screen Y increases downward

    // Apply offset to screen center
    final screenPos = Offset(
      screenCenter.dx + pixelOffsetX,
      screenCenter.dy + pixelOffsetY,
    );

    // DEBUG LOGS (throttled to once per second) - COMMENTED OUT TO REDUCE LOG SPAM
    // final now = DateTime.now();
    // if (now.difference(_lastLogTime).inMilliseconds >= _logThrottleMs) {
    //   _lastLogTime = now;
    //   print('🔵 Blue Dot Position Calculation:');
    //   print('   World Pos: (${worldPos.latitude.toStringAsFixed(6)}, ${worldPos.longitude.toStringAsFixed(6)})');
    //   print('   Camera Target: (${camera.target.latitude.toStringAsFixed(6)}, ${camera.target.longitude.toStringAsFixed(6)})');
    //   print('   Camera Zoom: ${camera.zoom.toStringAsFixed(2)}');
    //   print('   Screen Size: ${screenSize.width.toStringAsFixed(0)} x ${screenSize.height.toStringAsFixed(0)}');
    //   print('   Screen Center: (${screenCenter.dx.toStringAsFixed(0)}, ${screenCenter.dy.toStringAsFixed(0)})');
    //   print('   Lat Delta: ${latDelta.toStringAsFixed(6)}°');
    //   print('   Lng Delta: ${lngDelta.toStringAsFixed(6)}°');
    //   print('   Pixels Per Degree (Lat): ${pixelsPerDegreeLat.toStringAsFixed(2)}');
    //   print('   Pixels Per Degree (Lng): ${pixelsPerDegreeLng.toStringAsFixed(2)}');
    //   print('   Pixel Offset X: ${pixelOffsetX.toStringAsFixed(2)} px');
    //   print('   Pixel Offset Y: ${pixelOffsetY.toStringAsFixed(2)} px');
    //   print('   Final Screen Pos: (${screenPos.dx.toStringAsFixed(0)}, ${screenPos.dy.toStringAsFixed(0)})');
    //   print('');
    // }

    return screenPos;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Calculate screen position synchronously whenever position or camera changes
    final screenPosition = useMemoized(() {
      if (cameraPosition.value == null) return null;
      return _calculateScreenPosition(
        position,
        cameraPosition.value!,
        screenSize,
      );
    }, [position, cameraPosition.value, screenSize]);

    // Don't render until we have a valid position
    if (screenPosition == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: screenPosition.dx - 10, // Center the 20x20 dot
      top: screenPosition.dy - 10,
      child: IgnorePointer(
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
