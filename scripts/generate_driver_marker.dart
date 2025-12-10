import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create blue circle marker
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = 96.0; // 2x for @2x asset

  // Draw solid blue circle background
  final bgPaint = Paint()
    ..color = const Color(0xFF2196F3) // Material Blue
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    size / 2,
    bgPaint,
  );

  // Draw white border
  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6.0
    ..isAntiAlias = true;

  canvas.drawCircle(
    const Offset(size / 2, size / 2),
    size / 2 - 3,
    borderPaint,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  // Save to file
  final file = File('assets/images/driver_marker.png');
  await file.writeAsBytes(bytes!.buffer.asUint8List());

  print('✅ Driver marker created: ${file.path}');
  exit(0);
}
