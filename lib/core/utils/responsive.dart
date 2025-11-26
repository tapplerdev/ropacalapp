import 'package:flutter/material.dart';

/// Responsive sizing utility for consistent UI across different screen sizes
///
/// Usage:
/// 1. Initialize once in build method: Responsive.init(context);
/// 2. Use wp() for widths: Responsive.wp(50) = 50% of screen width
/// 3. Use hp() for heights: Responsive.hp(10) = 10% of screen height
/// 4. Use sp() for font sizes: Responsive.sp(16) = scaled font size
class Responsive {
  static late double _screenWidth;
  static late double _screenHeight;
  static late double _pixelRatio;

  // Base dimensions (iPhone 11 Pro as reference)
  static const double _baseWidth = 375.0;
  static const double _baseHeight = 812.0;

  /// Initialize with screen dimensions
  /// Call this once in your widget's build method
  static void init(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _screenWidth = mediaQuery.size.width;
    _screenHeight = mediaQuery.size.height;
    _pixelRatio = mediaQuery.devicePixelRatio;
  }

  /// Width as percentage of screen width
  /// Example: Responsive.wp(50) = 50% of screen width
  static double wp(double percentage) {
    return _screenWidth * percentage / 100;
  }

  /// Height as percentage of screen height
  /// Example: Responsive.hp(10) = 10% of screen height
  static double hp(double percentage) {
    return _screenHeight * percentage / 100;
  }

  /// Scaled font size based on screen width
  /// Example: Responsive.sp(16) = 16sp scaled to current screen
  static double sp(double size) {
    return (size / _baseWidth) * _screenWidth;
  }

  /// Scaled size that adapts to both width and height
  /// Useful for square elements (icons, avatars, etc.)
  static double scale(double size) {
    final widthScale = _screenWidth / _baseWidth;
    final heightScale = _screenHeight / _baseHeight;
    final scale = (widthScale + heightScale) / 2;
    return size * scale;
  }

  /// Get screen width
  static double get screenWidth => _screenWidth;

  /// Get screen height
  static double get screenHeight => _screenHeight;

  /// Check if screen is small (< 375px width)
  static bool get isSmallScreen => _screenWidth < 375;

  /// Check if screen is large (> 414px width)
  static bool get isLargeScreen => _screenWidth > 414;

  /// Check if screen is tablet-sized (> 600px width)
  static bool get isTablet => _screenWidth > 600;
}
