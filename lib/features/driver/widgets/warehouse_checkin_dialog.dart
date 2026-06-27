import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/route_task.dart';
import 'package:ropacalapp/providers/shift_provider.dart';

/// Modern warehouse check-in dialog — matches CheckInDialogV2 style
class WarehouseCheckinDialog extends HookConsumerWidget {
  final RouteTask task;
  final String shiftBinId;
  final bool isLastTask;

  const WarehouseCheckinDialog({
    super.key,
    required this.task,
    required this.shiftBinId,
    this.isLastTask = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = useState(false);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.90),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade900.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade50,
                        Colors.blue.shade50.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade600,
                              Colors.blue.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.warehouse_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLastTask ? 'End Shift' : 'Warehouse Stop',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isLastTask
                                  ? 'Return bins and end your shift'
                                  : _getActionText(),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    children: [
                      // Location card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                color: Colors.blue.shade600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                task.address ?? 'Warehouse Location',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting.value
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isLastTask
                                      ? [Colors.blue.shade600, Colors.blue.shade500]
                                      : [AppColors.primaryGreen, AppColors.primaryGreen.withValues(alpha: 0.85)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isLastTask ? Colors.blue : AppColors.primaryGreen).withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isSubmitting.value
                                    ? null
                                    : () => _handleConfirm(context, ref, isSubmitting),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: isSubmitting.value
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        isLastTask ? 'End Shift' : 'Confirm Arrival',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getActionText() {
    final action = task.warehouseAction ?? 'stop';
    switch (action) {
      case 'load':
        final bins = task.binsToLoad ?? 0;
        return 'Load $bins bins';
      case 'unload':
        return 'Unload waste';
      case 'both':
        final bins = task.binsToLoad ?? 0;
        return 'Load/Unload ($bins bins)';
      default:
        return 'Warehouse stop';
    }
  }

  Future<void> _handleConfirm(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isSubmitting,
  ) async {
    isSubmitting.value = true;
    try {
      await ref.read(shiftNotifierProvider.notifier).completeTask(
            shiftBinId,
            task.binId ?? '',
            null,
            photoUrl: null,
            hasIncident: false,
            moveRequestId: null,
          );

      if (context.mounted) {
        Navigator.of(context).pop();
        await Future.delayed(const Duration(milliseconds: 500));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isLastTask
                  ? '✅ Shift complete'
                  : '✅ Warehouse stop completed: ${_getActionText()}'),
              backgroundColor: AppColors.primaryGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      isSubmitting.value = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
