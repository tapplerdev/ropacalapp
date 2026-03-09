import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/active_driver.dart';
import 'package:ropacalapp/models/manager_shift_history.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/providers/manager_shift_history_provider.dart';
import 'package:ropacalapp/services/manager_service.dart';

/// Manager Shifts Tab — shift lifecycle management + history.
/// "Today" shows current shifts with real data.
/// "History" shows completed shifts with performance metrics.
class ManagerShiftsTab extends HookConsumerWidget {
  const ManagerShiftsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = useState(0); // 0 = Today, 1 = History

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Shifts',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/manager/shift-builder'),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Create'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(
              children: [
                _TabButton(
                  label: 'Today',
                  isSelected: selectedTab.value == 0,
                  onTap: () => selectedTab.value = 0,
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: 'History',
                  isSelected: selectedTab.value == 1,
                  onTap: () => selectedTab.value = 1,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selectedTab.value == 0
                  ? _TodayView(key: const ValueKey('today'))
                  : _HistoryView(key: const ValueKey('history')),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Tab Button
// ═══════════════════════════════════════════════════════════════

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGreen : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Today View
// ═══════════════════════════════════════════════════════════════

class _TodayView extends ConsumerWidget {
  const _TodayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDriversAsync = ref.watch(driversNotifierProvider);

    return allDriversAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text('Error: $e', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
      data: (allDrivers) {
        // Filter for drivers with shifts (not idle)
        final shiftDrivers = allDrivers
            .where((d) =>
                d.status == ShiftStatus.active ||
                d.status == ShiftStatus.paused ||
                d.status == ShiftStatus.ready)
            .toList();

        if (shiftDrivers.isEmpty) {
          return _EmptyTodayState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(driversNotifierProvider.notifier).refresh();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ShiftSummaryStats(allDrivers: allDrivers),
              const SizedBox(height: 16),
              _DateHeader(),
              const SizedBox(height: 12),
              ...shiftDrivers.map((driver) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DismissableShiftCard(
                      driver: driver,
                      onCancelShift: () => _cancelShift(
                        context,
                        ref,
                        driver,
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Swipe-to-Cancel Shift Card Wrapper
// ═══════════════════════════════════════════════════════════════

Future<void> _cancelShift(
  BuildContext context,
  WidgetRef ref,
  ActiveDriver driver,
) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CancelShiftModal(driverName: driver.driverName),
  );

  if (confirmed == true && context.mounted) {
    try {
      final managerService = ref.read(managerServiceProvider);
      await managerService.cancelShift(driver.shiftId);
      await ref.read(driversNotifierProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${driver.driverName}\'s shift has been cancelled'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel shift: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

class _DismissableShiftCard extends StatelessWidget {
  final ActiveDriver driver;
  final VoidCallback onCancelShift;

  const _DismissableShiftCard({
    required this.driver,
    required this.onCancelShift,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_shift_${driver.shiftId}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onCancelShift();
        return false; // Never actually dismiss — the modal handles everything
      },
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade500,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      child: _TodayShiftCard(driver: driver),
    );
  }
}

class _CancelShiftModal extends StatelessWidget {
  final String driverName;

  const _CancelShiftModal({required this.driverName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade500,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cancel Shift?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to cancel $driverName\'s shift?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'This will stop navigation and notify the driver immediately.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Keep Shift',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade500,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel Shift',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Summary Stats
// ═══════════════════════════════════════════════════════════════

class _ShiftSummaryStats extends StatelessWidget {
  final List<ActiveDriver> allDrivers;

  const _ShiftSummaryStats({required this.allDrivers});

  @override
  Widget build(BuildContext context) {
    final activeCount =
        allDrivers.where((d) => d.status == ShiftStatus.active).length;
    final pausedCount =
        allDrivers.where((d) => d.status == ShiftStatus.paused).length;
    final readyCount =
        allDrivers.where((d) => d.status == ShiftStatus.ready).length;
    final endedCount =
        allDrivers.where((d) => d.status == ShiftStatus.ended).length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatPill(
              count: activeCount,
              label: 'Active',
              color: Colors.green.shade600),
          _StatPill(
              count: pausedCount,
              label: 'Paused',
              color: Colors.amber.shade700),
          _StatPill(
              count: readyCount,
              label: 'Ready',
              color: Colors.blue.shade600),
          _StatPill(
              count: endedCount, label: 'Done', color: Colors.teal.shade600),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatPill({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Date Header
// ═══════════════════════════════════════════════════════════════

class _DateHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formatted = DateFormat('EEEE, MMMM d, y').format(now);

    return Row(
      children: [
        const Text(
          'Today',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Text(
          '· $formatted',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Today Shift Card
// ═══════════════════════════════════════════════════════════════

class _TodayShiftCard extends StatelessWidget {
  final ActiveDriver driver;

  const _TodayShiftCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(driver.status);
    final hasProgress = driver.status == ShiftStatus.active ||
        driver.status == ShiftStatus.paused;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (driver.shiftId.isNotEmpty) {
            context.push('/shifts/${driver.shiftId}');
          } else {
            context.push('/manager/drivers/${driver.driverId}');
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Driver name + status badge
              Row(
                children: [
                  Icon(Icons.assignment, size: 18, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      driver.driverName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _StatusBadge(
                    label: statusInfo.label,
                    color: statusInfo.color,
                    icon: statusInfo.icon,
                  ),
                ],
              ),

              // Row 2: Route name
              if (driver.routeDisplayName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 26),
                    Icon(Icons.route, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text(
                      driver.routeDisplayName,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],

              // Row 3: Time info
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 26),
                  Icon(Icons.access_time,
                      size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text(
                    _formatTimeInfo(driver),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),

              // Row 4: Bins info (shown for all statuses with bins)
              if (driver.totalBins > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 26),
                    Icon(Icons.inventory_2_outlined,
                        size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text(
                      '${driver.completedBins}/${driver.totalBins} bins assigned',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],

              // Row 5: Progress bar (for active/paused shifts)
              if (hasProgress && driver.totalBins > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: driver.completionPercentage,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _progressColor(driver.completionPercentage),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(driver.completionPercentage * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _progressColor(driver.completionPercentage),
                      ),
                    ),
                  ],
                ),
              ],

              // Row 6: View Shift Details chevron
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Shift Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 16, color: AppColors.primaryGreen),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeInfo(ActiveDriver driver) {
    if (driver.startTime == null) {
      if (driver.status == ShiftStatus.ready) return 'Scheduled — not started';
      return 'No time info';
    }

    final startFormatted = DateFormat('h:mm a').format(driver.startTime!);
    final duration = driver.activeDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    String elapsed;
    if (hours > 0) {
      elapsed = '${hours}h ${minutes}m';
    } else {
      elapsed = '${minutes}m';
    }

    if (driver.status == ShiftStatus.active ||
        driver.status == ShiftStatus.paused) {
      return 'Started $startFormatted · $elapsed elapsed';
    }

    return 'Started $startFormatted';
  }

  Color _progressColor(double percentage) {
    if (percentage >= 0.7) return Colors.green.shade600;
    if (percentage >= 0.4) return Colors.amber.shade700;
    return Colors.red.shade500;
  }

  _StatusInfo _getStatusInfo(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.active:
        return _StatusInfo(
          label: 'In Progress',
          color: Colors.green.shade600,
          icon: Icons.play_circle_outline,
        );
      case ShiftStatus.paused:
        return _StatusInfo(
          label: 'Paused',
          color: Colors.amber.shade700,
          icon: Icons.pause_circle_outline,
        );
      case ShiftStatus.ready:
        return _StatusInfo(
          label: 'Scheduled',
          color: Colors.blue.shade600,
          icon: Icons.schedule_outlined,
        );
      case ShiftStatus.ended:
        return _StatusInfo(
          label: 'Completed',
          color: Colors.teal.shade600,
          icon: Icons.check_circle_outline,
        );
      case ShiftStatus.cancelled:
        return _StatusInfo(
          label: 'Cancelled',
          color: Colors.red.shade600,
          icon: Icons.cancel_outlined,
        );
      default:
        return _StatusInfo(
          label: 'Unknown',
          color: Colors.grey.shade500,
          icon: Icons.help_outline,
        );
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// History View
// ═══════════════════════════════════════════════════════════════

class _HistoryView extends HookConsumerWidget {
  const _HistoryView({super.key});

  static const _statusFilters = [
    _StatusFilter('All', null),
    _StatusFilter('Completed', 'completed'),
    _StatusFilter('Driver Ended', 'manual_end'),
    _StatusFilter('Manager Ended', 'manager_ended'),
    _StatusFilter('Cancelled', 'manager_cancelled'),
    _StatusFilter('Disconnected', 'driver_disconnected'),
    _StatusFilter('Timed Out', 'system_timeout'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDateFilter = useState('7 days');
    final selectedStatusFilter = useState<String?>(null); // null = All
    final daysBack = selectedDateFilter.value == '7 days'
        ? 7
        : selectedDateFilter.value == '30 days'
            ? 30
            : 0; // 0 = all time

    final historyAsync =
        ref.watch(managerShiftHistoryNotifierProvider(daysBack: daysBack));

    return Column(
      children: [
        // Date filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              _FilterChip(
                label: '7 days',
                isSelected: selectedDateFilter.value == '7 days',
                onTap: () => selectedDateFilter.value = '7 days',
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: '30 days',
                isSelected: selectedDateFilter.value == '30 days',
                onTap: () => selectedDateFilter.value = '30 days',
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'All',
                isSelected: selectedDateFilter.value == 'All',
                onTap: () => selectedDateFilter.value = 'All',
              ),
            ],
          ),
        ),

        // Status filter chips (scrollable)
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _statusFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final filter = _statusFilters[index];
              final isSelected =
                  selectedStatusFilter.value == filter.endReason;
              return _FilterChip(
                label: filter.label,
                isSelected: isSelected,
                onTap: () => selectedStatusFilter.value = filter.endReason,
              );
            },
          ),
        ),
        const SizedBox(height: 4),

        // History list
        Expanded(
          child: historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text('Error loading history',
                      style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('$e',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                ],
              ),
            ),
            data: (shifts) {
              // Apply status filter client-side
              final filtered = selectedStatusFilter.value == null
                  ? shifts
                  : shifts
                      .where(
                          (s) => s.endReason == selectedStatusFilter.value)
                      .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,
                          size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        selectedStatusFilter.value != null
                            ? 'No matching shifts'
                            : 'No shift history',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedStatusFilter.value != null
                            ? 'Try a different status filter'
                            : 'Completed shifts will appear here',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(managerShiftHistoryNotifierProvider(
                      daysBack: daysBack));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child:
                          _HistoryShiftCard(shift: filtered[index]),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatusFilter {
  final String label;
  final String? endReason;

  const _StatusFilter(this.label, this.endReason);
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// History Shift Card
// ═══════════════════════════════════════════════════════════════

class _HistoryShiftCard extends StatelessWidget {
  final ManagerShiftHistory shift;

  const _HistoryShiftCard({required this.shift});

  @override
  Widget build(BuildContext context) {
    final completionPct = (shift.completionRate).clamp(0.0, 100.0);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          context.push('/shifts/${shift.shiftId}');
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Driver name + end reason badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shift.driverName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _EndReasonBadge(endReason: shift.endReason),
                ],
              ),
              const SizedBox(height: 6),

              // Row 2: Route + date
              Row(
                children: [
                  Icon(Icons.route, size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 5),
                  Text(
                    shift.routeDisplayName,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '· ${shift.endedDateFormatted}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Row 3: Stats row
              Row(
                children: [
                  _MiniStat(
                    icon: Icons.timer_outlined,
                    value: shift.durationFormatted,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 16),
                  _MiniStat(
                    icon: Icons.check_circle_outline,
                    value: '${completionPct.toInt()}%',
                    color: _completionColor(completionPct),
                  ),
                  const SizedBox(width: 16),
                  _MiniStat(
                    icon: Icons.inventory_2_outlined,
                    value: '${shift.completedBins}/${shift.totalBins}',
                    color: Colors.grey.shade600,
                  ),
                  if (shift.totalSkipped > 0) ...[
                    const SizedBox(width: 16),
                    _MiniStat(
                      icon: Icons.skip_next_outlined,
                      value: '${shift.totalSkipped} skipped',
                      color: Colors.orange.shade600,
                    ),
                  ],
                ],
              ),

              // Row 4: Task type breakdown (only non-zero)
              if (_hasTaskBreakdown()) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (shift.collectionsCompleted > 0)
                      _TypeLabel('Collections: ${shift.collectionsCompleted}'),
                    if (shift.placementsCompleted > 0)
                      _TypeLabel('Placements: ${shift.placementsCompleted}'),
                    if (shift.moveRequestsCompleted > 0)
                      _TypeLabel('Moves: ${shift.moveRequestsCompleted}'),
                    if (shift.warehouseStops > 0)
                      _TypeLabel('Warehouse: ${shift.warehouseStops}'),
                  ],
                ),
              ],

              // Row 5: View details chevron
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Shift Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 16, color: AppColors.primaryGreen),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasTaskBreakdown() {
    return shift.collectionsCompleted > 0 ||
        shift.placementsCompleted > 0 ||
        shift.moveRequestsCompleted > 0 ||
        shift.warehouseStops > 0;
  }

  Color _completionColor(double pct) {
    if (pct >= 90) return Colors.green.shade600;
    if (pct >= 60) return Colors.amber.shade700;
    return Colors.red.shade500;
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TypeLabel extends StatelessWidget {
  final String text;

  const _TypeLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// End Reason Badge
// ═══════════════════════════════════════════════════════════════

class _EndReasonBadge extends StatelessWidget {
  final String endReason;

  const _EndReasonBadge({required this.endReason});

  @override
  Widget build(BuildContext context) {
    final info = _getEndReasonInfo(endReason);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: info.bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: info.textColor,
        ),
      ),
    );
  }

  _EndReasonInfo _getEndReasonInfo(String reason) {
    switch (reason) {
      case 'completed':
        return _EndReasonInfo(
          label: 'Completed',
          bgColor: Colors.green.shade50,
          textColor: Colors.green.shade700,
        );
      case 'manual_end':
        return _EndReasonInfo(
          label: 'Driver Ended',
          bgColor: Colors.blue.shade50,
          textColor: Colors.blue.shade700,
        );
      case 'manager_ended':
        return _EndReasonInfo(
          label: 'Manager Ended',
          bgColor: Colors.amber.shade50,
          textColor: Colors.amber.shade800,
        );
      case 'manager_cancelled':
        return _EndReasonInfo(
          label: 'Cancelled',
          bgColor: Colors.red.shade50,
          textColor: Colors.red.shade700,
        );
      case 'driver_disconnected':
        return _EndReasonInfo(
          label: 'Disconnected',
          bgColor: Colors.orange.shade50,
          textColor: Colors.orange.shade700,
        );
      case 'system_timeout':
        return _EndReasonInfo(
          label: 'Timed Out',
          bgColor: Colors.grey.shade100,
          textColor: Colors.grey.shade600,
        );
      default:
        return _EndReasonInfo(
          label: 'Ended',
          bgColor: Colors.grey.shade100,
          textColor: Colors.grey.shade600,
        );
    }
  }
}

class _EndReasonInfo {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _EndReasonInfo({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });
}

// ═══════════════════════════════════════════════════════════════
// Empty State
// ═══════════════════════════════════════════════════════════════

class _EmptyTodayState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text(
              'No Active Shifts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new shift to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.push('/manager/shift-builder'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Shift'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
