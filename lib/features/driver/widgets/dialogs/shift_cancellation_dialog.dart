import 'package:flutter/material.dart';
import 'package:ropacalapp/models/shift_state.dart';

/// Show brief cancellation notice that auto-dismisses
/// Displayed when shift is cancelled by manager
Future<void> showShiftCancellationDialog(
  BuildContext context,
  ShiftState shift,
) async {
  // Show dialog and capture the context
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.cancel,
            color: Colors.red,
            size: 32,
          ),
          const SizedBox(width: 12),
          const Text('Shift Cancelled'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This shift has been cancelled by your manager.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          if (shift.completedBins > 0) ...[
            const SizedBox(height: 12),
            Text(
              'You completed ${shift.completedBins} of ${shift.totalBins} bins.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    ),
  );

  // Auto-dismiss after 2.5 seconds and pop back to home
  await Future.delayed(const Duration(milliseconds: 2500));
  if (context.mounted) {
    Navigator.of(context).pop(); // Close dialog
    if (context.mounted) {
      Navigator.of(context).pop(); // Pop navigation page with animation
    }
  }
}
