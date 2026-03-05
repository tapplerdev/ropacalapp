import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/features/driver/widgets/pin_marker_painter.dart';
import 'package:ropacalapp/models/route_task.dart';
import 'package:ropacalapp/core/enums/stop_type.dart';

/// Service for creating custom markers, circles, and polylines for Google Navigation
class GoogleNavigationMarkerService {
  GoogleNavigationMarkerService._(); // Private constructor - utility class

  // Cache for pre-generated marker icons (key: "binNumber_fillPercentage")
  static final Map<String, ImageDescriptor> _markerCache = {};
  static ImageDescriptor? _warehouseMarkerCache;
  static ImageDescriptor? _placementMarkerCache;

  /// Pre-cache common marker icons to improve performance
  /// Call this during app initialization
  static Future<void> preCacheCommonMarkers() async {
    AppLogger.navigation('🎨 Pre-caching common marker icons...');

    // Pre-cache warehouse marker (used frequently)
    _warehouseMarkerCache = await createWarehouseMarkerIcon();

    // Pre-cache placement marker
    _placementMarkerCache = await createPotentialLocationMarkerIcon(isPending: true);

    AppLogger.navigation('✅ Pre-cached common markers');
  }

  /// Clear marker cache (call when memory needs to be freed)
  static void clearCache() {
    _markerCache.clear();
    _warehouseMarkerCache = null;
    _placementMarkerCache = null;
    AppLogger.navigation('🗑️  Cleared marker cache');
  }

  /// Create custom task markers with numbered pins
  /// Returns list of MarkerOptions and populates the markerToTaskMap for tap handling
  static Future<List<MarkerOptions>> createCustomBinMarkers(
    List<RouteTask> tasks,
    Map<String, RouteTask> markerToTaskMap,
  ) async {
    AppLogger.navigation('🎨 Creating ${tasks.length} custom task markers...');
    final markers = <MarkerOptions>[];

    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final taskNumber = i + 1;

      // Create custom marker icon based on stop type
      final ImageDescriptor icon;
      switch (task.taskType) {
        case StopType.warehouseStop:
          // Use cached warehouse marker if available
          icon = _warehouseMarkerCache ?? await createWarehouseMarkerIcon();
          AppLogger.navigation('   🏭 Creating warehouse marker');
          break;
        case StopType.placement:
          // Use cached placement marker if available
          icon = _placementMarkerCache ?? await createPotentialLocationMarkerIcon(isPending: true);
          AppLogger.navigation('   📍 Creating placement marker (potential location style)');
          break;
        default:
          // Regular pickup bin (collection, pickup, dropoff, etc.)
          final cacheKey = '${task.binNumber ?? 0}_${task.fillPercentage ?? 0}';

          // Check cache first
          if (_markerCache.containsKey(cacheKey)) {
            icon = _markerCache[cacheKey]!;
          } else {
            // Create new marker and cache it
            icon = await createBinMarkerIcon(task.binNumber ?? 0, task.fillPercentage ?? 0);
            _markerCache[cacheKey] = icon;
          }
          break;
      }

      final markerId = 'task_${task.id}';
      markerToTaskMap[markerId] = task;

      final markerOptions = MarkerOptions(
        position: LatLng(
          latitude: task.latitude,
          longitude: task.longitude,
        ),
        icon: icon,
        anchor: const MarkerAnchor(u: 0.5, v: 0.5), // Center
        zIndex: 9999.0 + taskNumber.toDouble(), // Very high z-index to render above Google's default markers
        consumeTapEvents: true,
      );

      markers.add(markerOptions);
      AppLogger.navigation('   ✅ Marker $taskNumber: Bin #${task.binNumber ?? "N/A"} at (${task.latitude}, ${task.longitude})');

      // Add small delay every 5 markers to prevent frame drops
      if ((i + 1) % 5 == 0 && i < tasks.length - 1) {
        await Future.delayed(const Duration(milliseconds: 16)); // ~1 frame at 60fps
      }
    }

    AppLogger.navigation('📍 Created ${markers.length} custom markers total');
    return markers;
  }

  /// Create geofence circles around tasks (50m radius)
  static Future<List<CircleOptions>> createGeofenceCircles(List<RouteTask> tasks) async {
    final circles = <CircleOptions>[];

    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];

      final circleOptions = CircleOptions(
        position: LatLng(
          latitude: task.latitude,
          longitude: task.longitude,
        ),
        radius: 50, // 50 meters
        strokeWidth: 2,
        strokeColor: Colors.blue.withValues(alpha: 0.6),
        fillColor: Colors.blue.withValues(alpha: 0.1),
        zIndex: 1,
        clickable: false,
      );

      circles.add(circleOptions);
    }

    return circles;
  }

  /// Create polyline for completed route segments
  static Future<PolylineOptions?> createCompletedRoutePolyline(List<RouteTask> completedTasks) async {
    if (completedTasks.length < 2) {
      return null; // Need at least 2 points for a line
    }

    final points = completedTasks.map((task) {
      return LatLng(
        latitude: task.latitude,
        longitude: task.longitude,
      );
    }).toList();

    return PolylineOptions(
      points: points,
      strokeWidth: 6,
      strokeColor: Colors.grey.withValues(alpha: 0.6),
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

    // Render at 3x resolution for sharp display on high-DPI screens
    // Physical size: 60x60 logical pixels (for tap accuracy)
    // Actual render: 180x180 pixels (for quality)
    const canvasSize = 60.0;
    const renderScale = 3.0;

    // Use PinMarkerPainter to draw the marker at high resolution
    final painter = PinMarkerPainter(
      binNumber: binNumber,
      fillPercentage: fillPercentage,
      fillColor: fillColor,
    );
    painter.paint(canvas, Size(canvasSize * renderScale, canvasSize * renderScale));

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (canvasSize * renderScale).toInt(),
      (canvasSize * renderScale).toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    if (bytes == null) {
      throw Exception('Failed to create marker icon');
    }

    // Use imagePixelRatio to tell system this is a 3x image
    // This displays at 60x60 logical pixels but with 180x180 actual pixels
    final registeredImage = await registerBitmapImage(
      bitmap: bytes,
      imagePixelRatio: 3.0,
    );

    return registeredImage;
  }

  /// Create custom driver marker icon (programmatically drawn)
  static Future<ImageDescriptor> createDriverMarkerIcon(
    String driverName, {
    bool isFocused = false,
    bool isPulsing = false,
  }) async {
    try {
      AppLogger.navigation(
        '📦 Creating ${isFocused ? "FOCUSED " : ""}driver marker for: $driverName',
      );

      // Create marker programmatically (high-res for sharp display)
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      // Reduced canvas size from 120 to 60 to minimize tap overlap
      const canvasSize = 60.0;
      const renderScale = 3.0; // Render at 3x for high-DPI screens

      // Keep normal size when following (isPulsing), only enlarge for one-time focus
      final shouldEnlarge = isFocused && !isPulsing;
      final circleRadius = shouldEnlarge ? 28.0 * renderScale : 20.0 * renderScale;
      final borderWidth = shouldEnlarge ? 4.0 * renderScale : 3.0 * renderScale;

      final center = Offset(
        canvasSize * renderScale / 2,
        circleRadius,
      );

      // Draw highlight ring for one-time focused driver (not for following mode)
      if (shouldEnlarge) {
        final highlightPaint = Paint()
          ..color = Colors.green.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0 * renderScale;
        canvas.drawCircle(center, circleRadius + 8.0 * renderScale, highlightPaint);
      }

      // Draw circle background (green if focused for one-time, blue otherwise)
      // Note: Following mode keeps blue color - no visual change needed
      final paint = Paint()
        ..color = shouldEnlarge ? Colors.green.shade600 : Colors.blue
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

      final fontSize = shouldEnlarge ? 22.0 * renderScale : 16.0 * renderScale; // Larger text only for one-time focus

      final textPainter = TextPainter(
        text: TextSpan(
          text: initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
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

  /// Create custom potential location marker icon
  static Future<ImageDescriptor> createPotentialLocationMarkerIcon({
    bool isPending = true,
    bool withPulse = false,
  }) async {
    try {
      AppLogger.navigation(
        '📍 Creating potential location marker (pending: $isPending)',
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      // Reduced canvas size from 120 to 60 to minimize tap overlap
      const canvasSize = 60.0;
      const renderScale = 3.0;

      final pinHeight = 50.0 * renderScale;
      final circleRadius = 18.0 * renderScale;

      final center = Offset(
        canvasSize * renderScale / 2,
        circleRadius + 5.0 * renderScale,
      );

      // Pin color: Orange for pending, gray for converted
      final pinColor = isPending
          ? const Color(0xFFFF9500) // iOS orange
          : Colors.grey.shade600;

      // Draw pulse effect for pending locations
      if (isPending && withPulse) {
        final pulsePaint = Paint()
          ..color = pinColor.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, circleRadius * 1.6, pulsePaint);
      }

      // Draw pin shape (circle + teardrop)
      final pinPaint = Paint()
        ..color = pinColor
        ..style = PaintingStyle.fill;

      // Draw circle part
      canvas.drawCircle(center, circleRadius, pinPaint);

      // Draw teardrop/point part
      final path = Path();
      path.moveTo(center.dx, center.dy + circleRadius);
      path.lineTo(center.dx - circleRadius * 0.5, center.dy + circleRadius);
      path.lineTo(center.dx, center.dy + pinHeight - circleRadius);
      path.lineTo(center.dx + circleRadius * 0.5, center.dy + circleRadius);
      path.close();
      canvas.drawPath(path, pinPaint);

      // Draw white border around circle
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * renderScale;
      canvas.drawCircle(center, circleRadius - 1.5 * renderScale, borderPaint);

      // Draw icon inside (add location icon)
      final iconSize = 16.0 * renderScale;
      final iconPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * renderScale
        ..strokeCap = StrokeCap.round;

      // Draw plus sign
      canvas.drawLine(
        Offset(center.dx, center.dy - iconSize / 3),
        Offset(center.dx, center.dy + iconSize / 3),
        iconPaint,
      );
      canvas.drawLine(
        Offset(center.dx - iconSize / 3, center.dy),
        Offset(center.dx + iconSize / 3, center.dy),
        iconPaint,
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        (canvasSize * renderScale).toInt(),
        (canvasSize * renderScale).toInt(),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      if (bytes == null) {
        throw Exception('Failed to create potential location marker icon');
      }

      final registeredImage = await registerBitmapImage(
        bitmap: bytes,
        imagePixelRatio: 3.0,
      );

      AppLogger.navigation('✅ Potential location marker created');
      return registeredImage;
    } catch (e, stack) {
      AppLogger.navigation('❌ Error creating potential location marker: $e');
      AppLogger.navigation('Stack: $stack');
      rethrow;
    }
  }

  /// Create custom warehouse marker icon
  static Future<ImageDescriptor> createWarehouseMarkerIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const canvasSize = 60.0;
    const renderScale = 3.0;

    final center = Offset(
      canvasSize * renderScale / 2,
      canvasSize * renderScale / 2,
    );
    final radius = 22.0 * renderScale;

    // Draw purple circle background
    final bgPaint = Paint()
      ..color = const Color(0xFF9C27B0) // Purple
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * renderScale;
    canvas.drawCircle(center, radius - 1.5 * renderScale, borderPaint);

    // Draw warehouse icon (simplified building)
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * renderScale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final iconSize = 18.0 * renderScale;
    final left = center.dx - iconSize / 2;
    final right = center.dx + iconSize / 2;
    final top = center.dy - iconSize / 2;
    final bottom = center.dy + iconSize / 2;

    // Draw warehouse outline (rectangle with roof)
    final path = Path();
    path.moveTo(center.dx, top); // Roof peak
    path.lineTo(right, top + iconSize * 0.25); // Right roof
    path.lineTo(right, bottom); // Right wall
    path.lineTo(left, bottom); // Floor
    path.lineTo(left, top + iconSize * 0.25); // Left wall
    path.close();
    canvas.drawPath(path, iconPaint);

    // Draw door
    final doorWidth = iconSize * 0.3;
    final doorHeight = iconSize * 0.4;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - doorWidth / 2,
        bottom - doorHeight,
        doorWidth,
        doorHeight,
      ),
      iconPaint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (canvasSize * renderScale).toInt(),
      (canvasSize * renderScale).toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    if (bytes == null) {
      throw Exception('Failed to create warehouse marker icon');
    }

    return await registerBitmapImage(
      bitmap: bytes,
      imagePixelRatio: 3.0,
    );
  }

  /// Create custom placement marker icon with bin number
  static Future<ImageDescriptor> createPlacementMarkerIcon(int binNumber) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const canvasSize = 60.0;
    const renderScale = 3.0;

    final pinHeight = 45.0 * renderScale;
    final circleRadius = 20.0 * renderScale;

    final center = Offset(
      canvasSize * renderScale / 2,
      circleRadius + 5.0 * renderScale,
    );

    // Draw teal/cyan pin
    final pinColor = const Color(0xFF00BCD4); // Teal/Cyan

    final pinPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill;

    // Draw circle part
    canvas.drawCircle(center, circleRadius, pinPaint);

    // Draw teardrop/point part
    final path = Path();
    path.moveTo(center.dx, center.dy + circleRadius);
    path.lineTo(center.dx - circleRadius * 0.4, center.dy + circleRadius);
    path.lineTo(center.dx, center.dy + pinHeight - circleRadius);
    path.lineTo(center.dx + circleRadius * 0.4, center.dy + circleRadius);
    path.close();
    canvas.drawPath(path, pinPaint);

    // Draw white border around circle
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * renderScale;
    canvas.drawCircle(center, circleRadius - 1.5 * renderScale, borderPaint);

    // Draw bin number
    final textPainter = TextPainter(
      text: TextSpan(
        text: binNumber.toString(),
        style: TextStyle(
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
      throw Exception('Failed to create placement marker icon');
    }

    return await registerBitmapImage(
      bitmap: bytes,
      imagePixelRatio: 3.0,
    );
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
