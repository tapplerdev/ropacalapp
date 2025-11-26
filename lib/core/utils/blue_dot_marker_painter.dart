import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Creates a custom blue dot marker icon for navigation
/// Matches EXACT design from NavigationBlueDotOverlay:
/// - 20x20 total size (scaled up for visibility as marker)
/// - Blue circle
/// - 3px white border
/// - Shadow: black 0.3 opacity, 6 blur, offset (0, 2)
class BlueDotMarkerPainter {
  /// Generate a blue dot marker icon
  /// Returns a BitmapDescriptor that can be used for Google Maps markers
  ///
  /// [size] is the total diameter in pixels (default 60)
  static Future<BitmapDescriptor> createBlueDotMarker({
    double size = 60.0, // Total size in pixels
  }) async {
    // Calculate proportions based on original 20x20 design
    // Original: 20px total, 3px border, 6px shadow blur, (0,2) shadow offset
    const baseSize = 20.0;
    final scale = size / baseSize;

    final borderWidth = 3.0 * scale;
    final shadowBlur = 6.0 * scale;
    final shadowOffset = Offset(0, 2.0 * scale);

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..isAntiAlias = true;

    final center = Offset(size / 2, size / 2);
    final outerRadius = size / 2; // Total radius (includes border)
    final innerRadius = outerRadius - borderWidth; // Blue circle radius

    // Draw shadow
    paint.color = Colors.black.withOpacity(0.3);
    paint.maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur);
    canvas.drawCircle(center + shadowOffset, outerRadius, paint);

    // Draw white border circle
    paint.color = Colors.white;
    paint.maskFilter = null;
    canvas.drawCircle(center, outerRadius, paint);

    // Draw blue inner circle
    paint.color = Colors.blue;
    canvas.drawCircle(center, innerRadius, paint);

    // Convert to image
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(bytes);
  }
}
