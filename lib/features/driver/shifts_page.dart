import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/shift_history.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/providers/route_history_provider.dart';
import 'package:ropacalapp/providers/shift_provider.dart';

/// Shifts Page - DoorDash style vertical sections
/// Shows: Active Now, Upcoming Shifts, History
class ShiftsPage extends HookConsumerWidget {
  const ShiftsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentShift = ref.watch(shiftNotifierProvider);
    final historyAsync = ref.watch(routeHistoryProvider);

    // Auto-refresh every 30 seconds
    useEffect(() {
      final timer = Stream.periodic(const Duration(seconds: 30)).listen((_) {
        ref.read(shiftNotifierProvider.notifier).fetchCurrentShift();
        ref.read(routeHistoryProvider.notifier).refresh();
      });
      return timer.cancel;
    }, []);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Shifts'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(shiftNotifierProvider.notifier).fetchCurrentShift();
          await ref.read(routeHistoryProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION 1: ACTIVE NOW
              _ActiveNowSection(currentShift: currentShift),

              const SizedBox(height: 24),

              // SECTION 2: UPCOMING SHIFTS
              const _UpcomingShiftsSection(),

              const SizedBox(height: 24),

              // SECTION 3: HISTORY
              _HistorySection(historyAsync: historyAsync),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section: Active Now - Shows current active shift
class _ActiveNowSection extends StatelessWidget {
  final ShiftState currentShift;

  const _ActiveNowSection({required this.currentShift});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'ACTIVE NOW',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.grey,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Active shift card or empty state
        if (currentShift.status == ShiftStatus.active ||
            currentShift.status == ShiftStatus.ready ||
            currentShift.status == ShiftStatus.paused)
          _ActiveShiftCard(shift: currentShift)
        else
          _NoActiveShiftCard(),
      ],
    );
  }
}

/// Active shift card with green accent
class _ActiveShiftCard extends StatelessWidget {
  final ShiftState shift;

  const _ActiveShiftCard({required this.shift});

  @override
  Widget build(BuildContext context) {
    final progress = shift.totalBins > 0
        ? shift.completedBins / shift.totalBins
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.08),
            Colors.white,
          ],
        ),
        border: Border.all(
          color: AppColors.primaryGreen,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/home'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Status badge + Pulsing dot
                Row(
                  children: [
                    // Pulsing green dot
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.successGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.successGreen.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      shift.status == ShiftStatus.active
                          ? 'SHIFT IN PROGRESS'
                          : shift.status == ShiftStatus.paused
                              ? 'SHIFT PAUSED'
                              : 'SHIFT READY',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: AppColors.successGreen,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Route info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift.totalBins > 0
                          ? '${shift.totalBins} ${shift.totalBins == 1 ? 'Bin' : 'Bins'} to Collect'
                          : 'Shift Active',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (shift.startTime != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Started ${DateFormat('h:mm a').format(shift.startTime!)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0
                          ? AppColors.successGreen
                          : AppColors.primaryGreen,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Bins count
                Text(
                  '${shift.completedBins}/${shift.totalBins} bins completed',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state when no active shift
class _NoActiveShiftCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.schedule,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No Active Shift',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check upcoming shifts below',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section: Upcoming Shifts - Shows scheduled future shifts
class _UpcomingShiftsSection extends StatelessWidget {
  const _UpcomingShiftsSection();

  @override
  Widget build(BuildContext context) {
    // TODO: Connect to actual upcoming shifts provider when available
    final upcomingShifts = <dynamic>[]; // Placeholder

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with count
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'UPCOMING SHIFTS',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.grey,
              ),
            ),
            if (upcomingShifts.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${upcomingShifts.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 12),

        // Upcoming shifts list or empty state
        if (upcomingShifts.isEmpty)
          _EmptyUpcomingCard()
        else
          ...upcomingShifts.map((shift) => _UpcomingShiftCard(shift: shift)),
      ],
    );
  }
}

/// Empty state for upcoming shifts
class _EmptyUpcomingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today,
            size: 32,
            color: Colors.blue.shade300,
          ),
          const SizedBox(height: 10),
          Text(
            'No Upcoming Shifts',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your scheduled shifts will appear here',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Upcoming shift card (placeholder for future implementation)
class _UpcomingShiftCard extends StatelessWidget {
  final dynamic shift;

  const _UpcomingShiftCard({required this.shift});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: const Text('Upcoming shift card placeholder'),
    );
  }
}

/// Section: History - Shows completed shifts
class _HistorySection extends StatelessWidget {
  final AsyncValue<List<ShiftHistory>> historyAsync;

  const _HistorySection({required this.historyAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'HISTORY',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            historyAsync.whenOrNull(
              data: (shifts) => shifts.isNotEmpty
                  ? TextButton(
                      onPressed: () {
                        context.push('/shift-history');
                      },
                      child: const Text('See All'),
                    )
                  : null,
            ) ?? const SizedBox.shrink(),
          ],
        ),

        const SizedBox(height: 12),

        // History list
        historyAsync.when(
          data: (shifts) {
            if (shifts.isEmpty) {
              return _EmptyHistoryCard();
            }

            // Show only first 3 shifts
            final recentShifts = shifts.take(3).toList();
            return Column(
              children: recentShifts.map((shift) {
                try {
                  return _HistoryCard(shift: shift);
                } catch (e) {
                  // If there's an error rendering a specific shift, skip it
                  return const SizedBox.shrink();
                }
              }).toList(),
            );
          },
          loading: () => _EmptyHistoryCard(), // Show empty state while loading
          error: (error, stack) => _ErrorCard(error: error.toString()),
        ),
      ],
    );
  }
}

/// Empty history card
class _EmptyHistoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 32,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 10),
          Text(
            'No Shift History',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Completed shifts will appear here',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// History shift card
class _HistoryCard extends StatelessWidget {
  final ShiftHistory shift;

  const _HistoryCard({required this.shift});

  @override
  Widget build(BuildContext context) {
    final isComplete = shift.completionPercentage >= 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/shifts/${shift.shiftId}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Checkmark + Route name
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 20,
                            color: isComplete
                                ? AppColors.successGreen
                                : Colors.orange.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              shift.routeDisplayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Date
                    if (shift.startTime != null)
                      Text(
                        _formatDate(shift.startTime!),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Stats row
                Row(
                  children: [
                    // Bins
                    _HistoryStatChip(
                      icon: Icons.delete_outline,
                      label: '${shift.completedBins}/${shift.totalBins} bins',
                      color: isComplete
                          ? AppColors.successGreen
                          : Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    // Duration
                    _HistoryStatChip(
                      icon: Icons.timer_outlined,
                      label: _formatDuration(shift.activeDuration),
                      color: Colors.blue.shade600,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: shift.completionPercentage,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete
                          ? AppColors.successGreen
                          : Colors.orange.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0m';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('MMM d').format(date);
    } catch (e) {
      // Fallback to simple formatting if DateFormat fails
      return '${date.month}/${date.day}';
    }
  }
}

/// Small stat chip for history cards
class _HistoryStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HistoryStatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error card for history section
class _ErrorCard extends StatelessWidget {
  final String error;

  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 32,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            'Failed to load history',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
