import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/active_driver.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/features/manager/driver_history_page.dart';
import 'package:ropacalapp/models/manager_shift_history.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/providers/focused_driver_provider.dart';
import 'package:ropacalapp/providers/manager_shift_history_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverDetailPage extends HookConsumerWidget {
  final String driverId;

  const DriverDetailPage({super.key, required this.driverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDriversAsync = ref.watch(driversNotifierProvider);
    final historyAsync = ref.watch(driverShiftHistoryProvider(driverId));
    final history = historyAsync.valueOrNull ?? const <ManagerShiftHistory>[];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Driver Details'),
        backgroundColor: Colors.grey.shade50,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: allDriversAsync.when(
        data: (drivers) {
          final driver = drivers.firstWhere(
            (d) => d.driverId == driverId,
            orElse: () => throw Exception('Driver not found'),
          );

          final hasActiveShift = driver.shiftId.isNotEmpty &&
              (driver.status == ShiftStatus.active ||
                  driver.status == ShiftStatus.paused ||
                  driver.status == ShiftStatus.ready);

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(driversNotifierProvider.notifier).refresh();
              ref.invalidate(driverShiftHistoryProvider(driverId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroSection(driver: driver, ref: ref, history: history),
                  const SizedBox(height: 16),

                  if (hasActiveShift) ...[
                    _ActiveShiftBanner(driver: driver),
                    const SizedBox(height: 16),
                  ],

                  if (history.isNotEmpty) ...[
                    _StatsStrip(history: history),
                    const SizedBox(height: 16),
                    _RecentShiftsCard(
                      history: history,
                      onViewAll: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DriverHistoryPage(
                            driverId: driver.driverId,
                            driverName: driver.driverName,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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

// ═══════════════════════════════════════════════════════════════
// Hero Section
// ═══════════════════════════════════════════════════════════════

class _HeroSection extends StatelessWidget {
  final ActiveDriver driver;
  final WidgetRef ref;
  final List<ManagerShiftHistory> history;

  const _HeroSection({
    required this.driver,
    required this.ref,
    required this.history,
  });

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
                        _ScoreBadge(history: history),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.phone,
                  label: 'Call Driver',
                  color: AppColors.actionBlue,
                  onTap: () async {
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
                  // Greyed with an "offline" hint instead of tap-then-dialog
                  // when the driver has no location to show.
                  color: driver.currentLocation != null
                      ? AppColors.brandGreen
                      : Colors.grey.shade400,
                  subtitle:
                      driver.currentLocation == null ? 'offline' : null,
                  onTap: driver.currentLocation == null
                      ? null
                      : () {
                          ref
                              .read(focusedDriverProvider.notifier)
                              .setFocusedDriver(driver.driverId);
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

// ═══════════════════════════════════════════════════════════════
// Active Shift Banner
// ═══════════════════════════════════════════════════════════════

class _ActiveShiftBanner extends StatelessWidget {
  final ActiveDriver driver;

  const _ActiveShiftBanner({required this.driver});

  @override
  Widget build(BuildContext context) {
    final duration = driver.activeDuration;
    final statusColor = _bannerStatusColor(driver.status);
    final statusLabel = _bannerStatusLabel(driver.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push('/manager/drivers/${driver.driverId}/shift');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.08),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: status badge + elapsed time
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Route name
              Text(
                driver.routeDisplayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              // Progress
              Row(
                children: [
                  Text(
                    '${driver.completedBins}/${driver.totalBins} bins',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(driver.completionPercentage * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: driver.completionPercentage,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 14),

              // View Live Shift link
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Live Shift',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: statusColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _bannerStatusColor(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.active:
        return AppColors.primaryGreen;
      case ShiftStatus.paused:
        return AppColors.warningOrange;
      case ShiftStatus.ready:
        return AppColors.brandBlueAccent;
      default:
        return Colors.grey;
    }
  }

  String _bannerStatusLabel(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.active:
        return 'Active Shift';
      case ShiftStatus.paused:
        return 'Shift Paused';
      case ShiftStatus.ready:
        return 'Shift Ready';
      default:
        return 'Shift';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

// ═══════════════════════════════════════════════════════════════
// Helper Widgets
// ═══════════════════════════════════════════════════════════════

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
        return (
          label: driver.status.toString().split('.').last,
          color: Colors.grey.shade600
        );
    }
  }
}

class _ScoreBadge extends StatelessWidget {
  final List<ManagerShiftHistory> history;

  const _ScoreBadge({required this.history});

  @override
  Widget build(BuildContext context) {
    // A real performance stat: average completion rate over the last 30
    // days of archived shifts. The old badge showed the CURRENT shift's
    // completion, so every idle driver wore an alarming red "0 Score".
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recent = history
        .where((s) =>
            s.totalBins > 0 &&
            s.startTime != null &&
            s.startTime!.isAfter(cutoff))
        .toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    final avg = recent.map((s) => s.completionRate).reduce((a, b) => a + b) /
        recent.length;
    final score = avg.round();
    final scoreColor = score >= 80
        ? AppColors.successGreen
        : score >= 60
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scoreColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '$score% avg (30d)',
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
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap; // null = disabled
  final String? subtitle;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.subtitle,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
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
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// History stats + recent shifts
// ═══════════════════════════════════════════════════════════════

class _StatsStrip extends StatelessWidget {
  final List<ManagerShiftHistory> history;

  const _StatsStrip({required this.history});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    final shiftsThisWeek = history
        .where((s) => s.startTime != null && s.startTime!.isAfter(weekAgo))
        .length;
    final bins30d = history
        .where((s) => s.startTime != null && s.startTime!.isAfter(monthAgo))
        .fold<int>(0, (sum, s) => sum + s.completedBins);
    final durations = history
        .where((s) => s.startTime != null && s.endTime != null)
        .map((s) =>
            s.endTime!.difference(s.startTime!).inSeconds -
            s.totalPauseSeconds)
        .where((sec) => sec > 0)
        .toList();
    final avgDuration = durations.isEmpty
        ? '—'
        : () {
            final sec = durations.reduce((a, b) => a + b) ~/ durations.length;
            final h = sec ~/ 3600;
            final m = (sec % 3600) ~/ 60;
            return h > 0 ? '${h}h ${m}m' : '${m}m';
          }();

    Widget stat(String value, String label) => Expanded(
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          stat('$shiftsThisWeek', 'shifts this week'),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          stat('$bins30d', 'bins collected (30d)'),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          stat(avgDuration, 'avg duration'),
        ],
      ),
    );
  }
}

class _RecentShiftsCard extends StatelessWidget {
  final List<ManagerShiftHistory> history;
  final VoidCallback onViewAll;

  const _RecentShiftsCard({required this.history, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final recent = history.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Recent Shifts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (history.length > recent.length)
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('View all'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < recent.length; i++) ...[
            if (i > 0) Divider(height: 16, color: Colors.grey.shade100),
            ShiftHistoryRow(shift: recent[i]),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Quick Actions
// ═══════════════════════════════════════════════════════════════

class _QuickActionsCard extends StatelessWidget {
  final ActiveDriver driver;

  const _QuickActionsCard({required this.driver});

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
              Icon(Icons.touch_app, size: 22, color: AppColors.brandGreen),
              const SizedBox(width: 8),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ActionRow(
            icon: Icons.assignment,
            label: 'Assign New Route',
            onTap: () {
              // The shift builder is the single creation door (and has the
              // inactive-bin gate); arrive with this driver pre-selected.
              context.push(
                '/manager/shift-builder'
                '?driverId=${driver.driverId}'
                '&driverName=${Uri.encodeComponent(driver.driverName)}',
              );
            },
          ),
          const Divider(height: 24),
          _ActionRow(
            icon: Icons.history,
            label: 'View Full History',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DriverHistoryPage(
                    driverId: driver.driverId,
                    driverName: driver.driverName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
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
