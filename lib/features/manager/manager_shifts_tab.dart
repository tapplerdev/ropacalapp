import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/models/active_driver.dart';
import 'package:ropacalapp/models/shift_state.dart';

/// Manager Shifts Tab - Mobile-optimized shift management
/// Shows today's shifts with simple week selector
class ManagerShiftsTab extends HookConsumerWidget {
  const ManagerShiftsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedWeek = useState('This Week');
    final activeDriversAsync = ref.watch(activeDriversProvider);

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
          // Create Shift button
          TextButton.icon(
            onPressed: () {
              context.push('/manager/shift-builder');
            },
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
          // Week Selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _WeekButton(
                  label: 'Last Week',
                  isSelected: selectedWeek.value == 'Last Week',
                  onTap: () => selectedWeek.value = 'Last Week',
                ),
                const SizedBox(width: 8),
                _WeekButton(
                  label: 'This Week',
                  isSelected: selectedWeek.value == 'This Week',
                  onTap: () => selectedWeek.value = 'This Week',
                ),
                const SizedBox(width: 8),
                _WeekButton(
                  label: 'Next Week',
                  isSelected: selectedWeek.value == 'Next Week',
                  onTap: () => selectedWeek.value = 'Next Week',
                ),
              ],
            ),
          ),

          // Shifts List
          Expanded(
            child: activeDriversAsync.when(
              data: (drivers) {
                if (drivers.isEmpty) {
                  return _EmptyState(week: selectedWeek.value);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(driversNotifierProvider.notifier).refresh();
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Today's Summary
                      _TodaySummaryCard(drivers: drivers),
                      const SizedBox(height: 16),

                      // Today's Date Header
                      _DateHeader(
                        date: DateTime.now(),
                        isToday: true,
                      ),
                      const SizedBox(height: 12),

                      // Active Shifts
                      ...drivers.map((driver) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ShiftCard(driver: driver),
                      )),
                    ],
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
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Week selector button
class _WeekButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _WeekButton({
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
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Today's summary card
class _TodaySummaryCard extends StatelessWidget {
  final List<ActiveDriver> drivers;

  const _TodaySummaryCard({required this.drivers});

  @override
  Widget build(BuildContext context) {
    final activeCount = drivers.where((d) => d.status == ShiftStatus.active).length;
    final pendingCount = drivers.where((d) => d.status == ShiftStatus.ready).length;
    final completedCount = 0; // TODO: Add completed shifts tracking

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _SummaryItem(
            icon: Icons.check_circle,
            color: Colors.green,
            label: 'Active',
            count: activeCount,
          ),
          const SizedBox(width: 24),
          _SummaryItem(
            icon: Icons.pause_circle,
            color: Colors.orange,
            label: 'Pending',
            count: pendingCount,
          ),
          const SizedBox(width: 24),
          _SummaryItem(
            icon: Icons.done_all,
            color: Colors.blue,
            label: 'Done',
            count: completedCount,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _SummaryItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Date header
class _DateHeader extends StatelessWidget {
  final DateTime date;
  final bool isToday;

  const _DateHeader({
    required this.date,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, MMMM d, y').format(date);

    return Row(
      children: [
        Text(
          isToday ? 'Today' : formattedDate,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isToday) ...[
          const SizedBox(width: 8),
          Text(
            '• $formattedDate',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Shift card
class _ShiftCard extends StatelessWidget {
  final ActiveDriver driver;

  const _ShiftCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final isActive = driver.status == ShiftStatus.active;
    final isReady = driver.status == ShiftStatus.ready;
    final statusColor = isActive ? Colors.green : Colors.orange;
    final statusIcon = isActive ? Icons.check_circle : Icons.pause_circle;
    final statusLabel = isActive ? 'Active' : (isReady ? 'Pending' : 'Inactive');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Icon(Icons.local_shipping, size: 20, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  driver.driverName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Time and route info (placeholder - will be enhanced with real data)
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                '8:00 AM - 4:00 PM',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress info (if active)
          if (isActive) ...[
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: 0.67, // TODO: Calculate from actual progress
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '8/12 bins',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last: Bin #987 • 10 mins ago',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              if (isActive) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Track driver on map
                    },
                    icon: const Icon(Icons.my_location, size: 16),
                    label: const Text('Track'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: BorderSide(color: AppColors.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Show shift details
                  },
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Empty state
class _EmptyState extends StatelessWidget {
  final String week;

  const _EmptyState({required this.week});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No Shifts for $week',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new shift to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/manager/shift-builder');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Shift'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
