import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Creates a navigation arrow marker icon using the provided SVG asset
/// Arrow points upward (north) by default, rotates based on compass heading
class NavigationArrowMarkerPainter {
  /// Generate a navigation arrow marker icon from SVG asset
  /// Returns an ImageDescriptor that can be used for Google Maps markers
  ///
  /// [size] is the total diameter in pixels (default 80)
  static Future<ImageDescriptor> createNavigationArrow({
    double size = 80.0,
  }) async {
    // Load the SVG from assets
    final svgString = await rootBundle.loadString(
      'assets/images/navigation_arrow.svg',
    );

    // Parse SVG and convert to DrawableRoot
    final pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);

    // Create a canvas to draw the SVG
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Scale the SVG to the desired size
    final svgWidth = pictureInfo.size.width;
    final svgHeight = pictureInfo.size.height;
    final scale = size / svgWidth.clamp(1, double.infinity);

    canvas.scale(scale);
    canvas.drawPicture(pictureInfo.picture);

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (svgWidth * scale).toInt(),
      (svgHeight * scale).toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    // Clean up
    pictureInfo.picture.dispose();

    // Return ImageDescriptor (will need to be registered with map controller)
    return ImageDescriptor(
      registeredImageId: 'navigation_arrow',
      width: svgWidth * scale,
      height: svgHeight * scale,
    );
  }
}
