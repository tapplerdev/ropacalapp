import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';

class MapMarkerUtils {
  // Cache for generated markers to avoid regenerating identical ones
  static final Map<String, BitmapDescriptor> _markerCache = {};

  /// Creates a bin marker icon with number and fill percentage ring
  static Future<BitmapDescriptor> createBinMarker({
    required int binNumber,
    required int fillPercentage,
  }) async {
    // Cache key based on bin number and fill percentage
    final cacheKey = 'bin_${binNumber}_$fillPercentage';
    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    final color = _getFillColor(fillPercentage);

    // Get pixel ratio for high-DPI displays (3x on iPhone 14/15/16)
    final pixelRatio =
        ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

    // Size in logical pixels - how big it appears on screen
    const size = 100.0;
    const radius = size / 2;
    const strokeWidth = 8.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw white background circle
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(const Offset(radius, radius), radius, backgroundPaint);

    // Draw progress arc
    if (fillPercentage > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      const startAngle = -90 * 3.14159 / 180;
      final sweepAngle = 2 * 3.14159 * (fillPercentage / 100);

      canvas.drawArc(
        Rect.fromCircle(
          center: const Offset(radius, radius),
          radius: radius - strokeWidth / 2,
        ),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..isAntiAlias = true;
    canvas.drawCircle(const Offset(radius, radius), radius, borderPaint);

    // Draw bin number
    final textPainter = TextPainter(
      text: TextSpan(
        text: binNumber.toString(),
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontWeight: FontWeight.bold,
          fontSize: 48.0,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );

    // Convert to image at display size
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final imageData = byteData!.buffer.asUint8List();

    // Create BitmapDescriptor from image data
    final bitmapDescriptor = BitmapDescriptor.fromBytes(imageData);

    // Cache the result
    _markerCache[cacheKey] = bitmapDescriptor;
    return bitmapDescriptor;
  }

  /// Creates a numbered route marker icon
  static Future<BitmapDescriptor> createRouteMarker({
    required int routeNumber,
  }) async {
    // Cache key based on route number
    final cacheKey = 'route_$routeNumber';
    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    // Get pixel ratio for high-DPI displays (3x on iPhone 14/15/16)
    final pixelRatio =
        ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

    // Size in logical pixels - how big it appears on screen
    const size = 100.0;
    const radius = size / 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..isAntiAlias = true;
    canvas.drawCircle(const Offset(radius, radius + 2), radius, shadowPaint);

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(const Offset(radius, radius), radius, borderPaint);

    // Draw blue circle
    final circlePaint = Paint()
      ..color = AppColors.primaryBlue
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(const Offset(radius, radius), radius - 8.0, circlePaint);

    // Draw route number
    final textPainter = TextPainter(
      text: TextSpan(
        text: routeNumber.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 44.0,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );

    // Convert to image at display size
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final imageData = byteData!.buffer.asUint8List();

    // Create BitmapDescriptor from image data
    final bitmapDescriptor = BitmapDescriptor.fromBytes(imageData);

    // Cache the result
    _markerCache[cacheKey] = bitmapDescriptor;
    return bitmapDescriptor;
  }

  /// Creates a blue dot marker icon matching the overlay widget design
  /// Used for current location in 2D map mode
  static Future<BitmapDescriptor> createBlueDotMarker() async {
    const cacheKey = 'blue_dot';
    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    // Larger size for better visibility on map
    const size = 80.0; // Larger canvas for better quality
    const radius = size / 2;
    const dotRadius = 18.0; // Actual blue dot radius (36px diameter)
    const borderWidth = 4.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw shadow (matching overlay BoxShadow)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..isAntiAlias = true;
    canvas.drawCircle(
      const Offset(radius, radius + 2),
      dotRadius + borderWidth,
      shadowPaint,
    );

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(
      const Offset(radius, radius),
      dotRadius + borderWidth,
      borderPaint,
    );

    // Draw blue circle (matching overlay Colors.blue)
    final bluePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(const Offset(radius, radius), dotRadius, bluePaint);

    // Convert to image at display size
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final imageData = byteData!.buffer.asUint8List();

    // Create BitmapDescriptor from image data
    final bitmapDescriptor = BitmapDescriptor.fromBytes(imageData);

    // Cache the result
    _markerCache[cacheKey] = bitmapDescriptor;
    return bitmapDescriptor;
  }

  static Color _getFillColor(int fillPercentage) {
    if (fillPercentage > 74) {
      return AppColors.alertRed;
    } else if (fillPercentage > 49) {
      return AppColors.warningOrange;
    } else {
      return AppColors.successGreen;
    }
  }
}
