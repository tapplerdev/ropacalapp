import 'package:flutter/material.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/shift_state.dart';

/// DoorDash-style slide to start shift button
class ShiftSlideButton extends StatefulWidget {
  final ShiftStatus status;
  final VoidCallback? onSlideComplete;

  const ShiftSlideButton({
    super.key,
    required this.status,
    this.onSlideComplete,
  });

  @override
  State<ShiftSlideButton> createState() => _ShiftSlideButtonState();
}

class _ShiftSlideButtonState extends State<ShiftSlideButton> {
  double _dragPosition = 0.0;
  static const double _threshold = 0.8; // 80% to complete
  bool _isSliding = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.status == ShiftStatus.ready;
    final screenWidth =
        MediaQuery.of(context).size.width - 64; // Account for padding
    final buttonWidth = screenWidth - 60; // Space for the thumb
    final thumbSize = 56.0;

    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: isEnabled
            ? AppColors.successGreen.withValues(alpha: 0.1)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? AppColors.successGreen : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Background text
          Center(
            child: Text(
              isEnabled
                  ? 'Slide to Start Shift'
                  : 'Waiting for Route Assignment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isEnabled
                    ? AppColors.successGreen.withValues(alpha: 0.6)
                    : Colors.grey.shade500,
              ),
            ),
          ),

          // Sliding thumb
          if (isEnabled)
            Positioned(
              left: _dragPosition * buttonWidth,
              top: 4,
              child: GestureDetector(
                onHorizontalDragStart: (_) {
                  setState(() {
                    _isSliding = true;
                  });
                },
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dragPosition =
                        ((_dragPosition * buttonWidth + details.delta.dx) /
                                buttonWidth)
                            .clamp(0.0, 1.0);
                  });
                },
                onHorizontalDragEnd: (_) {
                  if (_dragPosition >= _threshold) {
                    // Slide completed!
                    widget.onSlideComplete?.call();
                    setState(() {
                      _dragPosition = 1.0;
                    });
                  } else {
                    // Snap back
                    setState(() {
                      _dragPosition = 0.0;
                      _isSliding = false;
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: _isSliding
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  width: thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.successGreen.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
