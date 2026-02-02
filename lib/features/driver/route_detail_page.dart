import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/models/shift_history.dart';
import 'package:ropacalapp/providers/route_history_provider.dart';

/// Route Detail Page - Shows detailed information about a specific shift
class RouteDetailPage extends ConsumerWidget {
  final String shiftId;

  const RouteDetailPage({
    required this.shiftId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftDetailAsync = ref.watch(shiftDetailProvider(shiftId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Shift Details'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: shiftDetailAsync.when(
        data: (shiftDetail) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shift summary card
                _ShiftSummaryCard(shift: shiftDetail.shift),

                // Tasks list
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Tasks (${shiftDetail.bins.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                // Task cards
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: shiftDetail.bins.length,
                  itemBuilder: (context, index) {
                    final bin = shiftDetail.bins[index];
                    return _BinCard(
                      bin: bin,
                      index: index,
                    );
                  },
                ),

                const SizedBox(height: 24),
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
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load shift details',
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
                  ref.invalidate(shiftDetailProvider(shiftId));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shift summary card at the top
class _ShiftSummaryCard extends StatelessWidget {
  final ShiftHistory shift;

  const _ShiftSummaryCard({required this.shift});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shift title with date
          Text(
            shift.startTime != null
                ? 'Shift - ${dateFormat.format(shift.startTime!)}'
                : 'Shift Summary',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          // Time only (date is now in title)
          if (shift.startTime != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 18,
                  color: Colors.white70,
                ),
                const SizedBox(width: 8),
                Text(
                  '${timeFormat.format(shift.startTime!)} - ${shift.endTime != null ? timeFormat.format(shift.endTime!) : "In Progress"}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryStatColumn(
                icon: Icons.delete_outline,
                label: 'Bins',
                value: '${shift.completedBins}/${shift.totalBins}',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white30,
              ),
              _SummaryStatColumn(
                icon: Icons.timer_outlined,
                label: 'Duration',
                value: _formatDuration(shift.activeDuration),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white30,
              ),
              _SummaryStatColumn(
                icon: Icons.check_circle_outline,
                label: 'Complete',
                value: '${(shift.completionPercentage * 100).toInt()}%',
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

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

/// Stat column in summary card
class _SummaryStatColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryStatColumn({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 28,
          color: Colors.white,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

/// Individual bin card showing before/after fill
class _BinCard extends StatelessWidget {
  final RouteBin bin;
  final int index;

  const _BinCard({
    required this.bin,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final isCompleted = bin.isCompleted == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? AppColors.successGreen.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
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
            // Header: Sequence number + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Sequence badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.successGreen
                            : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      bin.getTaskLabel(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                // Status icon
                Icon(
                  isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isCompleted
                      ? AppColors.successGreen
                      : Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Address
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${bin.currentStreet}, ${bin.city} ${bin.zip}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),

            // Completion time
            if (isCompleted && bin.completedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(
                      DateTime.fromMillisecondsSinceEpoch(
                        bin.completedAt! * 1000,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Fill percentage bars
            Row(
              children: [
                // Before
                Expanded(
                  child: _FillBar(
                    label: 'Before',
                    percentage: bin.fillPercentage,
                  ),
                ),
                const SizedBox(width: 16),

                // After
                Expanded(
                  child: _FillBar(
                    label: 'After',
                    percentage: bin.updatedFillPercentage ?? bin.fillPercentage,
                    isAfter: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }
}

/// Fill percentage bar with label
class _FillBar extends StatelessWidget {
  final String label;
  final int percentage;
  final bool isAfter;

  const _FillBar({
    required this.label,
    required this.percentage,
    this.isAfter = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor(percentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 12,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Color _getColor(int percentage) {
    if (percentage >= 80) {
      return Colors.red.shade600;
    } else if (percentage >= 50) {
      return Colors.orange.shade600;
    } else if (percentage >= 30) {
      return Colors.amber.shade700;
    } else {
      return AppColors.successGreen;
    }
  }
}
