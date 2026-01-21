import 'package:flutter/material.dart';

/// Custom painter for elegant pin-shaped location markers
///
/// Creates a teardrop/location pin shape with:
/// - Circular badge at top containing bin number
/// - Color-coded border ring based on fill percentage
/// - Tapered stem pointing to exact location
/// - Drop shadow for depth
class PinMarkerPainter extends CustomPainter {
  final int binNumber;
  final int fillPercentage;
  final Color fillColor;

  PinMarkerPainter({
    required this.binNumber,
    required this.fillPercentage,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Pin dimensions - scale based on canvas size
    // Base size is 60x60, so scale proportionally
    final scale = size.width / 60.0;
    final circleRadius = 20.0 * scale;
    final stemHeight = 20.0 * scale;
    final borderWidth = 3.0 * scale;

    final circleCenter = Offset(size.width / 2, circleRadius);
    final pinBottom = Offset(size.width / 2, circleRadius * 2 + stemHeight);

    // Draw shadow for depth
    _drawShadow(canvas, circleCenter, circleRadius, pinBottom);

    // Draw pin stem (tapered from circle to point)
    _drawStem(canvas, circleCenter, circleRadius, pinBottom);

    // Draw circular badge (white fill with colored border)
    _drawCircularBadge(canvas, circleCenter, circleRadius, borderWidth);

    // Draw bin number text
    _drawBinNumber(canvas, circleCenter, circleRadius);
  }

  /// Draw drop shadow for depth effect
  void _drawShadow(Canvas canvas, Offset circleCenter, double radius, Offset bottom) {
    final scale = radius / 20.0; // Calculate scale based on radius

    final shadowPath = Path()
      ..addOval(Rect.fromCircle(center: circleCenter, radius: radius))
      ..moveTo(circleCenter.dx - radius / 2, circleCenter.dy + radius)
      ..quadraticBezierTo(
        bottom.dx,
        bottom.dy - 5 * scale,
        bottom.dx,
        bottom.dy,
      )
      ..quadraticBezierTo(
        bottom.dx,
        bottom.dy - 5 * scale,
        circleCenter.dx + radius / 2,
        circleCenter.dy + radius,
      )
      ..close();

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * scale);

    canvas.save();
    canvas.translate(2 * scale, 2 * scale); // Offset shadow slightly
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();
  }

  /// Draw tapered stem from circle to point
  void _drawStem(Canvas canvas, Offset circleCenter, double radius, Offset bottom) {
    final scale = radius / 20.0; // Calculate scale based on radius

    final stemPath = Path()
      ..moveTo(circleCenter.dx - radius / 2, circleCenter.dy + radius)
      ..quadraticBezierTo(
        bottom.dx - 2 * scale,
        bottom.dy - 5 * scale,
        bottom.dx,
        bottom.dy,
      )
      ..quadraticBezierTo(
        bottom.dx + 2 * scale,
        bottom.dy - 5 * scale,
        circleCenter.dx + radius / 2,
        circleCenter.dy + radius,
      )
      ..close();

    final stemPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(stemPath, stemPaint);
  }

  /// Draw circular badge with white fill and colored border
  void _drawCircularBadge(
    Canvas canvas,
    Offset center,
    double radius,
    double borderWidth,
  ) {
    // Draw white interior
    final interiorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, interiorPaint);

    // Draw colored border ring
    final borderPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawCircle(center, radius - borderWidth / 2, borderPaint);
  }

  /// Draw bin number text centered in circle
  void _drawBinNumber(Canvas canvas, Offset center, double radius) {
    final scale = radius / 20.0; // Calculate scale based on radius

    final textSpan = TextSpan(
      text: binNumber.toString(),
      style: TextStyle(
        color: Colors.black,
        fontSize: _getOptimalFontSize(binNumber) * scale,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Center text in circle
    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  /// Get optimal font size based on number of digits (base size for 60x60 canvas)
  double _getOptimalFontSize(int number) {
    if (number < 10) return 16.0;      // Single digit
    if (number < 100) return 14.0;     // Two digits
    return 12.0;                        // Three+ digits
  }

  @override
  bool shouldRepaint(PinMarkerPainter oldDelegate) {
    return oldDelegate.binNumber != binNumber ||
        oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.fillColor != fillColor;
  }
}

/// Helper function to get color based on fill percentage
Color getFillColor(int fillPercentage) {
  if (fillPercentage < 25) {
    return const Color(0xFF4CAF50); // Green - low fill
  } else if (fillPercentage < 50) {
    return const Color(0xFFFFC107); // Amber - medium-low fill
  } else if (fillPercentage < 75) {
    return const Color(0xFFFF9800); // Orange - medium-high fill
  } else {
    return const Color(0xFFF44336); // Red - high fill (needs collection)
  }
}
