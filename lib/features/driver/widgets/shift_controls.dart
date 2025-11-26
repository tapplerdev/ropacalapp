import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/providers/shift_provider.dart';

/// Active shift controls - shows timer, pause, and end shift buttons
class ShiftControls extends HookConsumerWidget {
  const ShiftControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftState = ref.watch(shiftNotifierProvider);
    final shiftNotifier = ref.read(shiftNotifierProvider.notifier);

    // Update timer every second
    final timerTick = useState(0);
    useEffect(() {
      if (shiftState.status == ShiftStatus.active ||
          shiftState.status == ShiftStatus.paused) {
        final timer = Timer.periodic(const Duration(seconds: 1), (_) {
          timerTick.value++;
        });
        return timer.cancel;
      }
      return null;
    }, [shiftState.status]);

    if (shiftState.status == ShiftStatus.inactive ||
        shiftState.status == ShiftStatus.ready) {
      return const SizedBox.shrink();
    }

    final duration = shiftNotifier.getActiveShiftDuration();
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final completionPercentage = shiftNotifier.getCompletionPercentage();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status and timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: shiftState.status == ShiftStatus.active
                          ? AppColors.successGreen
                          : AppColors.warningOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    shiftState.status == ShiftStatus.active
                        ? 'On Shift'
                        : 'On Break',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '$hours:$minutes:$seconds',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${shiftState.completedBins} of ${shiftState.totalBins} bins',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    '${(completionPercentage * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: completionPercentage,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.primaryBlue,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              // Pause/Resume button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (shiftState.status == ShiftStatus.active) {
                      shiftNotifier.pauseShift();
                    } else {
                      shiftNotifier.resumeShift();
                    }
                  },
                  icon: Icon(
                    shiftState.status == ShiftStatus.active
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 18,
                  ),
                  label: Text(
                    shiftState.status == ShiftStatus.active
                        ? 'Pause'
                        : 'Resume',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: shiftState.status == ShiftStatus.active
                        ? AppColors.warningOrange
                        : AppColors.successGreen,
                    side: BorderSide(
                      color: shiftState.status == ShiftStatus.active
                          ? AppColors.warningOrange
                          : AppColors.successGreen,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // End shift button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showEndShiftConfirmation(
                    context,
                    ref,
                    shiftNotifier.isRouteComplete(),
                  ),
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('End Shift'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alertRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEndShiftConfirmation(
    BuildContext context,
    WidgetRef ref,
    bool isComplete,
  ) {
    final shiftNotifier = ref.read(shiftNotifierProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Shift'),
        content: Text(
          isComplete
              ? 'Great job! You\'ve completed all bins on your route. Ready to end your shift?'
              : 'You haven\'t completed all bins on your route yet. Are you sure you want to end your shift early?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              shiftNotifier.endShift();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Shift'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
