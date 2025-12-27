import 'package:flutter/material.dart';

/// Updated App color palette based on the Binly brand identity
class AppColors {
  // ==============================================================================
  // NEW BRAND COLORS (Extracted from the logo)
  // ==============================================================================
  /// The main green used for headers, primary buttons, and the logo text.
  static const Color brandGreen = Color(0xFF5E9646);

  /// The secondary blue accent from the recycling arrows.
  static const Color brandBlueAccent = Color(0xFF4AA0B5);

  /// The secondary yellow accent from the recycling arrows.
  static const Color brandYellowAccent = Color(0xFFF2C94C);
  // ==============================================================================


  // Primary theme colors mapped to the new brand palette
  static const Color primaryColor = brandGreen;
  static const Color primaryGreen = brandGreen;

  /// Backwards compatibility: primaryBlue now maps to brandGreen (legacy)
  /// Use `actionBlue` or `brandBlueAccent` for actual blue colors
  static const Color primaryBlue = brandGreen;

  /// Proper blue color for actions and buttons
  static const Color actionBlue = Color(0xFF2196F3); // Material Blue

  static const Color darkBackground = Color(0xFF252529); // Unchanged

  // Status colors
  /// Updated to use the brand green for consistency.
  static const Color successGreen = brandGreen;
  // Keep existing orange for distinct warnings that aren't just "cautions".
  static const Color warningOrange = Color(0xFFF6AB2F);
  // Keep existing red for standard errors.
  static const Color alertRed = Color(0xFFE6492D);
  /// Updated to use the brand yellow accent.
  static const Color cautionYellow = brandYellowAccent;

  // Text colors (Neutrals remain unchanged as they fit well)
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF6B6C6F);
  static const Color textTertiary = Color(0xFFBCBCBC);

  // Background colors (Neutrals remain unchanged)
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;

  // Additional colors
  static const Color iconGrey = Color(0xFF9EA0A5);
  static const Color divider = Color(0xFFE5E5E5);
}
