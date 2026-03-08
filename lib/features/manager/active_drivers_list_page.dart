import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/active_driver.dart';
import 'package:ropacalapp/models/route_task.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/providers/focused_driver_provider.dart';

/// Active Drivers List Page - Shows all drivers with active shifts
/// WebSocket-enabled for real-time updates
class ActiveDriversListPage extends ConsumerWidget {
  const ActiveDriversListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDriversAsync = ref.watch(activeDriversProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Active Drivers'),
        backgroundColor: Colors.grey.shade50,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: activeDriversAsync.when(
        data: (drivers) {
          if (drivers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active drivers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Drivers on active shifts will appear here',
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
              await ref.read(driversNotifierProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                final driver = drivers[index];
                return _DriverCard(driver: driver);
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
                'Failed to load active drivers',
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
                  ref.read(driversNotifierProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual driver card in the list
class _DriverCard extends ConsumerWidget {
  final ActiveDriver driver;

  const _DriverCard({required this.driver});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch shift details for current task info
    final shiftDetailAsync = ref.watch(
      driverShiftDetailProvider(driver.driverId),
    );
    final shiftDetail = shiftDetailAsync.valueOrNull;

    // Find current task (first incomplete, non-skipped)
    final currentTask = shiftDetail?.bins
        .where((t) => t.isCompleted == 0 && !t.skipped)
        .firstOrNull;

    // Calculate current task number (completed + 1)
    final completedTasks =
        shiftDetail?.bins.where((t) => t.isCompleted == 1).length ??
            driver.completedBins;
    final totalTasks = shiftDetail?.bins.length ?? driver.totalBins;
    final currentTaskNumber = completedTasks + 1;

    // Calculate ETA based on pace
    final etaString = _calculateETA(driver, completedTasks, totalTasks);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          context.push('/manager/drivers/${driver.driverId}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Driver name + Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/male-avatar.svg',
                          width: 40,
                          height: 40,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            driver.driverName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(driver: driver),
                ],
              ),

              const SizedBox(height: 12),

              // Route name with efficiency indicator
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getEfficiencyColor(driver),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      driver.routeDisplayName,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Current task info
              if (currentTask != null) ...[
                Row(
                  children: [
                    Icon(
                      _getTaskIcon(currentTask),
                      size: 16,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Task $currentTaskNumber of $totalTasks',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentTask.city ??
                            currentTask.address ??
                            currentTask.displayTitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Progress stats row
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${driver.completedBins}/${driver.totalBins} bins',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(driver.activeDuration),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (etaString != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      etaString,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),

              // Progress bar
              if (driver.totalBins > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: driver.completionPercentage,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getEfficiencyColor(driver),
                    ),
                  ),
                ),
              ],

              // Locate on Map button
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(focusedDriverProvider.notifier)
                        .setFocusedDriver(driver.driverId);
                    context.pop();
                  },
                  icon: Icon(
                    Icons.my_location,
                    size: 16,
                    color: AppColors.primaryGreen,
                  ),
                  label: Text(
                    'Locate on Map',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.primaryGreen.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Calculate ETA string based on current pace.
  /// Returns null if not enough data to estimate.
  String? _calculateETA(
      ActiveDriver driver, int completedTasks, int totalTasks) {
    if (completedTasks == 0 || totalTasks == 0) return null;

    final remaining = totalTasks - completedTasks;
    if (remaining <= 0) return 'Done';

    final elapsed = driver.activeDuration;
    if (elapsed.inMinutes < 1) return null;

    // Pace: minutes per task
    final minutesPerTask = elapsed.inMinutes / completedTasks;
    final etaMinutes = (minutesPerTask * remaining).round();

    if (etaMinutes < 60) {
      return '~${etaMinutes}m left';
    }
    final hours = etaMinutes ~/ 60;
    final mins = etaMinutes % 60;
    return '~${hours}h ${mins}m left';
  }

  IconData _getTaskIcon(RouteTask task) {
    if (task.isCollection) return Icons.delete_outline;
    if (task.isPickup) return Icons.upload_outlined;
    if (task.isDropoff) return Icons.download_outlined;
    if (task.isPlacement) return Icons.add_location_alt_outlined;
    if (task.isWarehouseStop) return Icons.warehouse_outlined;
    return Icons.task_alt;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Color _getEfficiencyColor(ActiveDriver driver) {
    if (driver.totalBins == 0) return Colors.grey;

    final completionRate = driver.completionPercentage;

    if (completionRate >= 0.8) {
      return AppColors.successGreen;
    } else if (completionRate >= 0.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

/// Status badge showing driver shift status
class _StatusBadge extends StatelessWidget {
  final ActiveDriver driver;

  const _StatusBadge({required this.driver});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusInfo.color.withValues(alpha: 0.1),
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

  _StatusInfo _getStatusInfo() {
    switch (driver.status) {
      case ShiftStatus.active:
        return _StatusInfo(
          label: 'Active',
          color: AppColors.primaryGreen,
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
          label: 'Idle',
          color: Colors.grey.shade600,
          icon: Icons.event_available,
        );
      default:
        return _StatusInfo(
          label: driver.status.toString().split('.').last,
          color: Colors.grey.shade600,
          icon: Icons.help_outline,
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
