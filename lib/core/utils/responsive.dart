import 'package:flutter/material.dart';

/// Responsive sizing utility for consistent UI across different screen sizes
///
/// Usage: Responsive.spacing(context, mobile: 16)
/// All methods require BuildContext and support mobile/tablet/desktop breakpoints
class Responsive {

  /// Screen size breakpoints
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;
  static const double desktopMinWidth = 1024;

  /// Get screen width from context
  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Get screen height from context
  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Check if device is mobile (< 600px)
  static bool isMobile(BuildContext context) =>
      width(context) < mobileMaxWidth;

  /// Check if device is tablet (600px - 1024px)
  static bool isTabletSize(BuildContext context) {
    final w = width(context);
    return w >= mobileMaxWidth && w < desktopMinWidth;
  }

  /// Check if device is desktop (>= 1024px)
  static bool isDesktop(BuildContext context) =>
      width(context) >= desktopMinWidth;

  /// Get responsive value based on screen size
  /// Example: Responsive.value(context, mobile: 16, tablet: 24, desktop: 32)
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTabletSize(context) && tablet != null) return tablet;
    return mobile;
  }

  /// Get responsive font size with automatic scaling
  static double fontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return value(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.2,
      desktop: desktop ?? mobile * 1.4,
    );
  }

  /// Get responsive padding
  static EdgeInsets padding(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final paddingValue = value(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.5,
      desktop: desktop ?? mobile * 2,
    );
    return EdgeInsets.all(paddingValue);
  }

  /// Get responsive horizontal padding
  static EdgeInsets paddingHorizontal(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final paddingValue = value(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.5,
      desktop: desktop ?? mobile * 2,
    );
    return EdgeInsets.symmetric(horizontal: paddingValue);
  }

  /// Get responsive vertical padding
  static EdgeInsets paddingVertical(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final paddingValue = value(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.5,
      desktop: desktop ?? mobile * 2,
    );
    return EdgeInsets.symmetric(vertical: paddingValue);
  }

  /// Get responsive spacing between elements
  static double spacing(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return value(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.5,
      desktop: desktop ?? mobile * 2,
    );
  }

  /// Get responsive icon size
  static double iconSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return value(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.3,
      desktop: desktop ?? mobile * 1.6,
    );
  }

  /// Get responsive button height
  static double buttonHeight(BuildContext context) {
    return value(
      context: context,
      mobile: 48.0,
      tablet: 56.0,
      desktop: 64.0,
    );
  }

  /// Get responsive card width for lists/grids
  static double cardWidth(BuildContext context) {
    final screenWidth = width(context);
    if (isDesktop(context)) {
      return (screenWidth - 128) / 3; // 3 columns on desktop
    }
    if (isTabletSize(context)) {
      return (screenWidth - 96) / 2; // 2 columns on tablet
    }
    return screenWidth - 32; // Full width on mobile
  }

  /// Get responsive maximum content width (for centered layouts)
  static double maxContentWidth(BuildContext context) {
    return value(
      context: context,
      mobile: width(context),
      tablet: 768.0,
      desktop: 1200.0,
    );
  }

  /// Build responsive widget based on screen size
  static Widget builder({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTabletSize(context) && tablet != null) return tablet;
    return mobile;
  }

  /// Get safe area padding
  static EdgeInsets safeAreaPadding(BuildContext context) =>
      MediaQuery.of(context).padding;

  /// Get bottom safe area height (for notch/home indicator)
  static double bottomSafeArea(BuildContext context) =>
      MediaQuery.of(context).padding.bottom;

  /// Get top safe area height (for status bar/notch)
  static double topSafeArea(BuildContext context) =>
      MediaQuery.of(context).padding.top;

  /// Get device orientation
  static Orientation orientation(BuildContext context) =>
      MediaQuery.of(context).orientation;

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) =>
      orientation(context) == Orientation.landscape;

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) =>
      orientation(context) == Orientation.portrait;

  /// Get screen size category as string (useful for debugging)
  static String getSizeCategory(BuildContext context) {
    if (isDesktop(context)) return 'Desktop';
    if (isTabletSize(context)) return 'Tablet';
    return 'Mobile';
  }
}
