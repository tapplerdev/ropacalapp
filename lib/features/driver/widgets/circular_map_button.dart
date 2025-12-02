import 'package:flutter/material.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';

/// Circular button with shadow for map controls
/// Used for notification, audio, and recenter buttons
class CircularMapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  const CircularMapButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.white;
    final isWhiteBg = bgColor == Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isWhiteBg
                  ? Colors.black.withOpacity(0.12)
                  : bgColor.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor ?? (isWhiteBg ? AppColors.primaryBlue : Colors.white),
          size: 22,
        ),
      ),
    );
  }
}
