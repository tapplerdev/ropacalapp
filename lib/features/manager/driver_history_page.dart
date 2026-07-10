import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/features/manager/driver_shift_detail_page.dart';
import 'package:ropacalapp/models/manager_shift_history.dart';
import 'package:ropacalapp/providers/manager_shift_history_provider.dart';

/// Full per-driver shift history — every archived shift, newest first.
/// Reached from Driver Details → "View Full History".
class DriverHistoryPage extends ConsumerWidget {
  final String driverId;
  final String driverName;

  const DriverHistoryPage({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(driverShiftHistoryProvider(driverId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('$driverName — Shift History'),
        backgroundColor: Colors.grey.shade50,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: historyAsync.when(
        data: (shifts) => shifts.isEmpty
            ? Center(
                child: Text(
                  'No completed shifts yet',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.refresh(driverShiftHistoryProvider(driverId).future),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: shifts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ShiftHistoryRow(shift: shifts[index]),
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load history',
            style: TextStyle(color: Colors.red.shade400),
          ),
        ),
      ),
    );
  }
}

/// One archived shift: date, bins with completion color, duration,
/// end-reason chip, incidents when nonzero. Shared by the Driver Details
/// recent-shifts card and the full-history page.
class ShiftHistoryRow extends StatelessWidget {
  final ManagerShiftHistory shift;

  const ShiftHistoryRow({super.key, required this.shift});

  Color get _completionColor {
    final rate = shift.completionRate;
    if (rate >= 80) return AppColors.successGreen;
    if (rate >= 60) return Colors.orange;
    return Colors.red.shade400;
  }

  String get _duration {
    final start = shift.startTime;
    final end = shift.endTime;
    if (start == null || end == null) return '—';
    var seconds =
        end.difference(start).inSeconds - shift.totalPauseSeconds;
    if (seconds < 0) seconds = 0;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final date = shift.startTime != null
        ? DateFormat('EEE, MMM d').format(shift.startTime!)
        : 'Unknown date';
    final completed = shift.isCompletedRun;

    final row = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              // Single rich line so the stats ellipsize as a unit instead of
              // creeping under the status pill on narrow screens.
              // completed_bins counts skips as processed — surface skips so a
              // 29/29 shift with skips is visibly not a clean run.
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${shift.completedBins}/${shift.totalBins} bins',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _completionColor,
                      ),
                    ),
                    TextSpan(
                      text: '  ·  $_duration',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (shift.totalSkipped > 0)
                      TextSpan(
                        text: '  ·  ${shift.totalSkipped} skipped',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warningOrange,
                        ),
                      ),
                    if (shift.incidentsReported > 0) ...[
                      WidgetSpan(child: const SizedBox(width: 6)),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(Icons.warning_amber_rounded,
                            size: 14, color: Colors.orange.shade700),
                      ),
                      TextSpan(
                        text: ' ${shift.incidentsReported}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: completed ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            shift.displayStatus,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: completed
                  ? Colors.green.shade700
                  : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );

    // Tap any history row to open its full read-only breakdown (every stop,
    // completed/skipped, photos). Shared by the full-history page and the
    // Driver Details recent-shifts card.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HistoricalShiftDetailPage(shift: shift),
        ),
      ),
      child: row,
    );
  }
}
