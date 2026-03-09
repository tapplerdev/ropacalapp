import 'package:flutter/material.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';

/// Minimal empty state shown when driver has no active shift.
/// Displays a small pill with a pulsing dot and status text.
class NoShiftEmptyState extends StatefulWidget {
  const NoShiftEmptyState({super.key});

  @override
  State<NoShiftEmptyState> createState() => _NoShiftEmptyStateState();
}

class _NoShiftEmptyStateState extends State<NoShiftEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          const Text(
            'Listening for new shifts',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
