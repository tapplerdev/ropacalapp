import 'package:flutter/material.dart';

/// Responsive helper following Flutter's recommended approach for mobile apps.
///
/// Uses proportional scaling based on screen width to ensure components
/// maintain consistent visual appearance across different phone sizes.
///
/// Reference width: 375dp (iPhone X/11/12/13/14)
class ResponsiveHelper {
  final BuildContext context;

  // Reference width for scaling calculations (iPhone X)
  static const double _referenceWidth = 375.0;

  ResponsiveHelper(this.context);

  /// Get current screen width
  double get screenWidth => MediaQuery.of(context).size.width;

  /// Get current screen height
  double get screenHeight => MediaQuery.of(context).size.height;

  /// Scale factor based on screen width
  double get scaleFactor => screenWidth / _referenceWidth;

  /// Scale a value proportionally based on screen width
  ///
  /// Example: scale(16) returns:
  /// - 14.5 on 340dp screen (small phone)
  /// - 16.0 on 375dp screen (reference)
  /// - 17.6 on 414dp screen (large phone)
  double scale(double value) {
    return value * scaleFactor;
  }

  // SPACING VALUES
  // These values scale proportionally with screen size

  /// Card margin: 16dp on reference screen
  double get cardMargin => scale(16);

  /// Card margin (large): 18dp on reference screen
  double get cardMarginLarge => scale(18);

  /// Card padding: 20dp on reference screen
  double get cardPadding => scale(20);

  /// Card padding (large): 22dp on reference screen
  double get cardPaddingLarge => scale(22);

  /// Card padding (extra large): 24dp on reference screen
  double get cardPaddingXLarge => scale(24);

  /// Card padding (extra extra large): 28dp on reference screen
  double get cardPaddingXXLarge => scale(28);

  /// Location card horizontal margin: 19dp on reference screen
  double get locationCardMargin => scale(19);

  /// Button padding (vertical): 16dp on reference screen
  double get buttonPaddingVertical => scale(16);

  /// Button padding (vertical, large): 18dp on reference screen
  double get buttonPaddingVerticalLarge => scale(18);

  /// Button padding (horizontal): 16dp on reference screen
  double get buttonPaddingHorizontal => scale(16);

  /// Button padding (horizontal, large): 18dp on reference screen
  double get buttonPaddingHorizontalLarge => scale(18);

  /// Tab button padding (vertical): 13dp on reference screen
  double get tabButtonPadding => scale(13);

  // GAPS

  /// Extra small gap: 2dp on reference screen
  double get gapXSmall => scale(2);

  /// Small gap: 4dp on reference screen
  double get gapSmall => scale(4);

  /// Medium-small gap: 8dp on reference screen
  double get gapMediumSmall => scale(8);

  /// Small-medium gap: 9dp on reference screen
  double get gapSmallMedium => scale(9);

  /// Medium gap: 12dp on reference screen
  double get gapMedium => scale(12);

  /// Medium-large gap: 13dp on reference screen
  double get gapMediumLarge => scale(13);

  /// Large gap: 16dp on reference screen
  double get gapLarge => scale(16);

  /// Extra large gap: 24dp on reference screen
  double get gapXLarge => scale(24);

  /// App bar spacing: 48dp on reference screen
  double get appBarBottomSpacing => scale(48);

  // ICON SIZES

  /// Small icon: 16dp on reference screen
  double get iconSmall => scale(16);

  /// Medium-small icon: 20dp on reference screen
  double get iconMediumSmall => scale(20);

  /// Medium icon: 22dp on reference screen
  double get iconMedium => scale(22);

  /// Large icon: 48dp on reference screen
  double get iconLarge => scale(48);

  /// App bar icon: 64dp on reference screen
  double get iconAppBar => scale(64);

  // FONT SIZES

  /// Small font: 15.5sp on reference screen
  double get fontSmall => scale(15.5);

  /// Medium font: 16sp on reference screen
  double get fontMedium => scale(16);

  // MISC

  /// Linear progress indicator height: 12dp on reference screen
  double get progressIndicatorHeight => scale(12);

  /// Border radius: 12dp on reference screen
  double get borderRadius => scale(12);

  /// Border radius (small): 8dp on reference screen
  double get borderRadiusSmall => scale(8);
}
