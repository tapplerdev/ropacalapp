import 'package:flutter/material.dart';
import 'package:ropacalapp/models/shift_state.dart';

/// Show shift summary dialog with completion stats
/// Displayed when shift ends normally (not cancelled/deleted)
Future<void> showShiftSummaryDialog(
  BuildContext context,
  ShiftState shift,
) async {
  final isCompleted = shift.completedBins >= shift.totalBins;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            isCompleted ? 'Shift Completed!' : 'Shift Ended',
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bins Completed',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${shift.completedBins} of ${shift.totalBins}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (shift.completedBins > 0)
            Text(
              isCompleted
                  ? '<� Great job! All bins collected!'
                  : '=M Good work today!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            // DriverMapWrapper will automatically switch back to DriverMapPage
            // No manual navigation needed!
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: const Text('Back to Home'),
        ),
      ],
    ),
  );
}
