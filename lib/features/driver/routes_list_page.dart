import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/shift_history.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/providers/route_history_provider.dart';

/// Routes List Page - Shows driver's shift history
class RoutesListPage extends ConsumerWidget {
  const RoutesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeHistoryAsync = ref.watch(routeHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Routes'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(routeHistoryProvider.notifier).refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: routeHistoryAsync.when(
        data: (shifts) {
          if (shifts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.route_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No routes yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your completed routes will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(routeHistoryProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: shifts.length,
              itemBuilder: (context, index) {
                final shift = shifts[index];
                return _ShiftCard(shift: shift);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load routes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(routeHistoryProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual shift card in the list
class _ShiftCard extends StatelessWidget {
  final ShiftHistory shift;

  const _ShiftCard({required this.shift});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.push('/routes/${shift.shiftId}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Route name + Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      shift.routeDisplayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _StatusBadge(status: shift.status),
                ],
              ),

              const SizedBox(height: 12),

              // Date & Time
              if (shift.startTime != null)
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(shift.startTime!),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${timeFormat.format(shift.startTime!)} - ${shift.endTime != null ? timeFormat.format(shift.endTime!) : "In Progress"}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  // Bins completed
                  _StatChip(
                    icon: Icons.delete_outline,
                    label:
                        '${shift.completedBins}/${shift.totalBins} bins',
                    color: shift.isComplete
                        ? AppColors.successGreen
                        : AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 12),

                  // Duration
                  _StatChip(
                    icon: Icons.timer_outlined,
                    label: _formatDuration(shift.activeDuration),
                    color: Colors.orange,
                  ),
                ],
              ),

              // Progress bar
              if (shift.totalBins > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: shift.completionPercentage,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      shift.isComplete
                          ? AppColors.successGreen
                          : AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

/// Status badge showing shift status
class _StatusBadge extends StatelessWidget {
  final ShiftStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusInfo.color,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo.icon,
            size: 14,
            color: statusInfo.color,
          ),
          const SizedBox(width: 6),
          Text(
            statusInfo.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusInfo.color,
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.ended:
        return _StatusInfo(
          label: 'Completed',
          color: AppColors.successGreen,
          icon: Icons.check_circle,
        );
      case ShiftStatus.cancelled:
        return _StatusInfo(
          label: 'Cancelled',
          color: Colors.orange.shade700,
          icon: Icons.cancel,
        );
      case ShiftStatus.active:
        return _StatusInfo(
          label: 'Active',
          color: AppColors.primaryBlue,
          icon: Icons.play_circle_filled,
        );
      case ShiftStatus.paused:
        return _StatusInfo(
          label: 'Paused',
          color: Colors.amber.shade700,
          icon: Icons.pause_circle_filled,
        );
      case ShiftStatus.ready:
        return _StatusInfo(
          label: 'Ready',
          color: Colors.blue.shade700,
          icon: Icons.schedule,
        );
      case ShiftStatus.inactive:
        return _StatusInfo(
          label: 'Inactive',
          color: Colors.grey.shade600,
          icon: Icons.radio_button_unchecked,
        );
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  _StatusInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}

/// Small stat chip with icon + label
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
