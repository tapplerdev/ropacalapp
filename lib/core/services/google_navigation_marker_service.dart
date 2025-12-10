import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/features/driver/widgets/pin_marker_painter.dart';
import 'package:ropacalapp/models/route_bin.dart';

/// Service for creating custom markers, circles, and polylines for Google Navigation
class GoogleNavigationMarkerService {
  GoogleNavigationMarkerService._(); // Private constructor - utility class

  /// Create custom bin markers with numbered pins
  /// Returns list of MarkerOptions and populates the markerToBinMap for tap handling
  static Future<List<MarkerOptions>> createCustomBinMarkers(
    List<RouteBin> bins,
    Map<String, RouteBin> markerToBinMap,
  ) async {
    AppLogger.navigation('🎨 Creating ${bins.length} custom bin markers...');
    final markers = <MarkerOptions>[];

    for (int i = 0; i < bins.length; i++) {
      final bin = bins[i];
      final binNumber = i + 1;

      // Create custom marker icon
      final icon = await createBinMarkerIcon(bin.binNumber, bin.fillPercentage);

      final markerId = 'bin_${bin.id}';
      markerToBinMap[markerId] = bin;

      final markerOptions = MarkerOptions(
        position: LatLng(
          latitude: bin.latitude,
          longitude: bin.longitude,
        ),
        icon: icon,
        anchor: const MarkerAnchor(u: 0.5, v: 0.5), // Center
        zIndex: 9999.0 + binNumber.toDouble(), // Very high z-index to render above Google's default markers
        consumeTapEvents: true,
      );

      markers.add(markerOptions);
      AppLogger.navigation('   ✅ Marker $binNumber: Bin #${bin.binNumber} at (${bin.latitude}, ${bin.longitude})');
    }

    AppLogger.navigation('📍 Created ${markers.length} custom markers total');
    return markers;
  }

  /// Create geofence circles around bins (50m radius)
  static Future<List<CircleOptions>> createGeofenceCircles(List<RouteBin> bins) async {
    final circles = <CircleOptions>[];

    for (int i = 0; i < bins.length; i++) {
      final bin = bins[i];

      final circleOptions = CircleOptions(
        position: LatLng(
          latitude: bin.latitude,
          longitude: bin.longitude,
        ),
        radius: 50, // 50 meters
        strokeWidth: 2,
        strokeColor: Colors.blue.withOpacity(0.6),
        fillColor: Colors.blue.withOpacity(0.1),
        zIndex: 1,
        clickable: false,
      );

      circles.add(circleOptions);
    }

    return circles;
  }

  /// Create polyline for completed route segments
  static Future<PolylineOptions?> createCompletedRoutePolyline(List<RouteBin> completedBins) async {
    if (completedBins.length < 2) {
      return null; // Need at least 2 points for a line
    }

    final points = completedBins.map((bin) {
      return LatLng(
        latitude: bin.latitude,
        longitude: bin.longitude,
      );
    }).toList();

    return PolylineOptions(
      points: points,
      strokeWidth: 6,
      strokeColor: Colors.grey.withOpacity(0.6),
      geodesic: true,
      zIndex: 0,
      clickable: false,
    );
  }

  /// Create custom bin marker icon with number badge
  static Future<ImageDescriptor> createBinMarkerIcon(int binNumber, int fillPercentage) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Determine fill color based on fill percentage
    final fillColor = getFillColor(fillPercentage);

    // Use PinMarkerPainter to draw the marker
    final painter = PinMarkerPainter(
      binNumber: binNumber,
      fillPercentage: fillPercentage,
      fillColor: fillColor,
    );
    painter.paint(canvas, const Size(120, 120));

    final picture = recorder.endRecording();
    final image = await picture.toImage(120, 120);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    if (bytes == null) {
      throw Exception('Failed to create marker icon');
    }

    final registeredImage = await registerBitmapImage(
      bitmap: bytes,
      imagePixelRatio: 1.0,
      width: 120,
      height: 120,
    );

    return registeredImage;
  }

  /// Create custom driver marker icon (programmatically drawn)
  static Future<ImageDescriptor> createDriverMarkerIcon(
    String driverName,
  ) async {
    try {
      AppLogger.navigation(
        '📦 Creating driver marker for: $driverName',
      );

      // Create marker programmatically (high-res for sharp display)
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const canvasSize = 120.0;
      const renderScale = 3.0; // Render at 3x for high-DPI screens
      const circleRadius = 20.0 * renderScale;
      const borderWidth = 3.0 * renderScale;

      final center = const Offset(
        canvasSize * renderScale / 2,
        circleRadius,
      );

      // Draw blue circle background
      final paint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, circleRadius, paint);

      // Draw white border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;

      canvas.drawCircle(center, circleRadius - borderWidth / 2, borderPaint);

      // Draw driver initial
      final initial = driverName.isNotEmpty
          ? driverName[0].toUpperCase()
          : '?';

      final textPainter = TextPainter(
        text: TextSpan(
          text: initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16.0 * renderScale,
            fontFamily: 'sans-serif',
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        (canvasSize * renderScale).toInt(),
        (canvasSize * renderScale).toInt(),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      if (bytes == null) {
        throw Exception('Failed to create driver marker icon');
      }

      final registeredImage = await registerBitmapImage(
        bitmap: bytes,
        imagePixelRatio: 3.0,
        // No width/height - let imagePixelRatio calculate natural size
      );

      AppLogger.navigation('✅ Driver marker created for: $driverName');
      return registeredImage;
    } catch (e, stack) {
      AppLogger.navigation('❌ Error creating driver marker: $e');
      AppLogger.navigation('Stack: $stack');
      rethrow;
    }
  }

  /// Get fill color based on fill percentage
  static Color getFillColor(int fillPercentage) {
    if (fillPercentage >= 80) {
      return Colors.red;
    } else if (fillPercentage >= 50) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
