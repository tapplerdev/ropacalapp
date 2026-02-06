import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/active_driver.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/providers/focused_driver_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverDetailPage extends HookConsumerWidget {
  final String driverId;

  const DriverDetailPage({super.key, required this.driverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDriversAsync = ref.watch(driversNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Driver Details'),
        backgroundColor: Colors.grey.shade50, // Match body background
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: allDriversAsync.when(
        data: (drivers) {
          final driver = drivers.firstWhere(
            (d) => d.driverId == driverId,
            orElse: () => throw Exception('Driver not found'),
          );

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(driversNotifierProvider.notifier).refresh();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Section
                  _HeroSection(driver: driver, ref: ref),
                  const SizedBox(height: 16),

                  // Current Activity (if active)
                  if (driver.status != ShiftStatus.inactive &&
                      driver.shiftId.isNotEmpty) ...[
                    _CurrentActivityCard(driver: driver),
                    const SizedBox(height: 16),
                  ],

                  // Today's Performance
                  _TodaysPerformanceCard(driver: driver),
                  const SizedBox(height: 16),

                  // This Week Summary
                  _WeekSummaryCard(driver: driver),
                  const SizedBox(height: 16),

                  // Recent Shifts
                  _RecentShiftsCard(driver: driver),
                  const SizedBox(height: 16),

                  // Quick Actions
                  _QuickActionsCard(driver: driver),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text('Error loading driver details',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700)),
              const SizedBox(height: 8),
              Text(error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero Section - Driver info and quick actions
class _HeroSection extends StatelessWidget {
  final ActiveDriver driver;
  final WidgetRef ref;

  const _HeroSection({required this.driver, required this.ref});

  bool get isIdle => driver.shiftId.isEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar + Name + Status
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/male-avatar.svg',
                width: 64,
                height: 64,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.driverName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusChip(driver: driver, isIdle: isIdle),
                        const SizedBox(width: 8),
                        _ScoreBadge(driver: driver),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Action Buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.phone,
                  label: 'Call Driver',
                  color: AppColors.actionBlue,
                  onTap: () async {
                    // TODO: Add phone number to driver model
                    final uri = Uri.parse('tel:+1234567890');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.map,
                  label: 'View on Map',
                  color: AppColors.brandGreen,
                  onTap: () {
                    // Check if driver is online (has current location)
                    if (driver.currentLocation == null) {
                      _showDriverOfflineDialog(context);
                      return;
                    }

                    // Start following the driver (continuous auto-center with banner)
                    ref
                        .read(focusedDriverProvider.notifier)
                        .startFollowing(driver.driverId);

                    // Navigate back to home (which will trigger the map to follow driver)
                    context.go('/home');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Status Chip
class _StatusChip extends StatelessWidget {
  final ActiveDriver driver;
  final bool isIdle;

  const _StatusChip({required this.driver, required this.isIdle});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusInfo.color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusInfo.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusInfo.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: statusInfo.color,
            ),
          ),
        ],
      ),
    );
  }

  ({String label, Color color}) _getStatusInfo() {
    if (isIdle) {
      return (label: 'Idle', color: Colors.grey.shade600);
    }

    switch (driver.status) {
      case ShiftStatus.active:
        return (label: 'Active', color: AppColors.primaryGreen);
      case ShiftStatus.paused:
        return (label: 'Paused', color: Colors.amber.shade700);
      case ShiftStatus.ready:
        return (label: 'Ready', color: Colors.blue.shade700);
      case ShiftStatus.inactive:
        return (label: 'Idle', color: Colors.grey.shade600);
      default:
        return (label: driver.status.toString().split('.').last, color: Colors.grey.shade600);
    }
  }
}

/// Score Badge - Shows monthly/overall performance score
class _ScoreBadge extends StatelessWidget {
  final ActiveDriver driver;

  const _ScoreBadge({required this.driver});

  @override
  Widget build(BuildContext context) {
    final score = _calculateScore();
    final scoreColor = _getScoreColor(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scoreColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            '$score Score',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateScore() {
    if (driver.totalBins == 0) return 0;
    return (driver.completionPercentage * 100).toInt();
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.successGreen;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

/// Action Button
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Current Activity Card
class _CurrentActivityCard extends StatelessWidget {
  final ActiveDriver driver;

  const _CurrentActivityCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final duration = driver.activeDuration;
    final estimatedCompletion = _calculateEstimatedCompletion();

    return _SectionCard(
      title: 'Current Activity',
      icon: Icons.directions_run,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route name
          Row(
            children: [
              Icon(Icons.route, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  driver.routeDisplayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar with bins
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${driver.completedBins}/${driver.totalBins} bins',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '${(driver.completionPercentage * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: driver.completionPercentage,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                driver.completionPercentage >= 0.8
                    ? AppColors.successGreen
                    : driver.completionPercentage >= 0.5
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Time info
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                  icon: Icons.schedule,
                  label: 'Time Elapsed',
                  value: _formatDuration(duration),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoPill(
                  icon: Icons.access_time,
                  label: 'Est. Completion',
                  value: estimatedCompletion,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  String _calculateEstimatedCompletion() {
    if (driver.totalBins == 0 || driver.completedBins == 0) return 'N/A';

    final avgTimePerBin = driver.activeDuration.inMinutes / driver.completedBins;
    final remainingBins = driver.totalBins - driver.completedBins;
    final estimatedMinutesRemaining = (avgTimePerBin * remainingBins).round();

    final completion = DateTime.now().add(Duration(minutes: estimatedMinutesRemaining));
    return DateFormat('h:mm a').format(completion);
  }
}

/// Today's Performance Card
class _TodaysPerformanceCard extends StatelessWidget {
  final ActiveDriver driver;

  const _TodaysPerformanceCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    // TODO: Get real data from backend
    final shiftsCompleted = driver.shiftId.isNotEmpty ? 1 : 0;
    final totalShiftsToday = 3;
    final binsCollected = driver.completedBins;
    final totalBinsToday = driver.totalBins > 0 ? driver.totalBins : 120;
    final avgTimePerBin = driver.completedBins > 0
        ? (driver.activeDuration.inMinutes / driver.completedBins)
        : 0.0;
    final efficiencyScore = _calculateEfficiency();

    return _SectionCard(
      title: 'Today\'s Performance',
      icon: Icons.trending_up,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Shifts metric - value + label in vertical column
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CircularProgress(
                value: shiftsCompleted,
                total: totalShiftsToday,
                color: AppColors.successGreen,
              ),
              const SizedBox(height: 8),
              Text(
                'Shifts',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          // Bins metric - value + label in vertical column
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CircularProgress(
                value: binsCollected,
                total: totalBinsToday,
                color: AppColors.successGreen,
              ),
              const SizedBox(height: 8),
              Text(
                'Bins',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          // Time metric - value + label in vertical column
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 60, // Match circle height for alignment
                child: Center(
                  child: Text(
                    avgTimePerBin > 0 ? '${avgTimePerBin.toStringAsFixed(1)}m' : '--m',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Time',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateEfficiency() {
    if (driver.totalBins == 0) return 0;
    return (driver.completionPercentage * 100).toInt();
  }

  Color _getEfficiencyColor(int score) {
    if (score >= 80) return AppColors.successGreen;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

/// This Week Summary Card
class _WeekSummaryCard extends StatelessWidget {
  final ActiveDriver driver;

  const _WeekSummaryCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    // TODO: Get real weekly data from backend
    return _SectionCard(
      title: 'This Week Summary',
      icon: Icons.calendar_today,
      child: Column(
        children: [
          _StatRow(
            label: 'Total Shifts',
            value: '12',
            icon: Icons.work_outline,
          ),
          const Divider(height: 24),
          _StatRow(
            label: 'Total Bins',
            value: '180/180 (100%)',
            icon: Icons.inventory_2_outlined,
          ),
          const Divider(height: 24),
          _StatRow(
            label: 'Avg Shift Duration',
            value: '3h 15m',
            icon: Icons.schedule,
          ),
          const Divider(height: 24),
          _StatRow(
            label: 'Best Route',
            value: 'North District',
            icon: Icons.star_outline,
            valueColor: AppColors.brandGreen,
          ),
        ],
      ),
    );
  }
}

/// Recent Shifts Card
class _RecentShiftsCard extends StatelessWidget {
  final ActiveDriver driver;

  const _RecentShiftsCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    // TODO: Get real shift history from backend
    final dateFormat = DateFormat('MMM d, h:mm a');

    return _SectionCard(
      title: 'Recent Shifts',
      icon: Icons.history,
      child: Column(
        children: List.generate(5, (index) {
          final shiftDate = DateTime.now().subtract(Duration(days: index));
          return Column(
            children: [
              if (index > 0) const Divider(height: 24),
              _ShiftTile(
                date: dateFormat.format(shiftDate),
                route: 'North District',
                completion: '15/15',
                duration: '3h 20m',
                grade: 'A',
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Quick Actions Card
class _QuickActionsCard extends StatelessWidget {
  final ActiveDriver driver;

  const _QuickActionsCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quick Actions',
      icon: Icons.touch_app,
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.assignment,
            label: 'Assign New Route',
            onTap: () {
              // TODO: Navigate to route assignment
            },
          ),
          const Divider(height: 24),
          _ActionRow(
            icon: Icons.history,
            label: 'View Full History',
            onTap: () {
              // TODO: Link to web dashboard
            },
          ),
        ],
      ),
    );
  }
}

// Helper Widgets

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: AppColors.brandGreen),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular progress indicator (just the circle, no label)
class _CircularProgress extends StatelessWidget {
  final int value;
  final int total;
  final Color color;

  const _CircularProgress({
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? value / total : 0.0;

    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 6,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.grey.shade200,
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Value text in center
          Text(
            '$value/$total',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// Large time display metric
class _TimeMetric extends StatelessWidget {
  final double avgTimePerBin;

  const _TimeMetric({required this.avgTimePerBin});

  @override
  Widget build(BuildContext context) {
    final displayTime = avgTimePerBin > 0
        ? avgTimePerBin.toStringAsFixed(1)
        : '--';

    return SizedBox(
      height: 79, // Match the height of circular metrics (60 + 6 + ~13)
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Time value - reduced size
          Text(
            '${displayTime}m',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          // Label
          Text(
            'Time',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _ShiftTile extends StatelessWidget {
  final String date;
  final String route;
  final String completion;
  final String duration;
  final String grade;

  const _ShiftTile({
    required this.date,
    required this.route,
    required this.completion,
    required this.duration,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    final gradeColor = grade == 'A'
        ? AppColors.successGreen
        : grade == 'B'
            ? Colors.blue
            : Colors.orange;

    return Row(
      children: [
        // Grade badge
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: gradeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              grade,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: gradeColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle,
                    size: 14, color: AppColors.successGreen),
                const SizedBox(width: 4),
                Text(
                  completion,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              duration,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.brandGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

/// Show styled dialog when driver is offline
void _showDriverOfflineDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(0, 8),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Offline icon with circular background
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.signal_wifi_off_rounded,
                size: 36,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Driver Not Online',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              'This driver is currently offline. Please try again later.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Dismiss button
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.brandGreen,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Got It',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
