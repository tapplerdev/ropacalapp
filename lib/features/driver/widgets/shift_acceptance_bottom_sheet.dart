import 'package:flutter/material.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/shift_overview.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/core/enums/stop_type.dart';

/// Timeline-based bottom sheet for shift acceptance
/// Inspired by ride-sharing apps with compact, scannable design
/// Bins timeline is scrollable for routes with many stops
class ShiftAcceptanceBottomSheet extends StatelessWidget {
  const ShiftAcceptanceBottomSheet({
    super.key,
    required this.shiftOverview,
    required this.onAccept,
    required this.onDecline,
  });

  final ShiftOverview shiftOverview;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    // Bin count label
    final binLabel = shiftOverview.totalBins == 1 ? 'bin' : 'bins';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45, // Smaller height to show ~2 bins
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Fixed header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main title
                const Text(
                  'New Route Available',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                // Subtitle with bin count (no distance)
                Text(
                  '${shiftOverview.totalBins} $binLabel',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
          ),

          const SizedBox(height: 16),

          // Show task summary for task-based shifts, timeline for old bin-based shifts
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: shiftOverview.isTaskBased
                    ? _buildTaskSummary()
                    : _buildTimeline(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Fixed bottom start button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build task summary with badges showing task types and counts
  Widget _buildTaskSummary() {
    final taskCounts = shiftOverview.taskCounts;
    if (taskCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info text explaining route optimization
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Route will be optimized when you start',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Task type badges
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: taskCounts.entries.map((entry) {
            return _buildTaskTypeBadge(entry.key, entry.value);
          }).toList(),
        ),
      ],
    );
  }

  /// Build individual task type badge
  Widget _buildTaskTypeBadge(StopType taskType, int count) {
    final config = _getTaskTypeConfig(taskType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Text(
            config.emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          // Count
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: config.color,
            ),
          ),
          const SizedBox(width: 6),
          // Label
          Text(
            config.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// Get configuration for task type (color, icon, label)
  ({Color color, String emoji, String label}) _getTaskTypeConfig(
    StopType taskType,
  ) {
    switch (taskType) {
      case StopType.collection:
        return (
          color: AppColors.primaryGreen,
          emoji: '🗑️',
          label: 'Collection${shiftOverview.taskCounts[taskType]! > 1 ? 's' : ''}',
        );
      case StopType.placement:
        return (
          color: Colors.orange.shade600,
          emoji: '📍',
          label: 'Placement${shiftOverview.taskCounts[taskType]! > 1 ? 's' : ''}',
        );
      case StopType.pickup:
        return (
          color: Colors.purple.shade600,
          emoji: '⬆️',
          label: 'Pickup${shiftOverview.taskCounts[taskType]! > 1 ? 's' : ''}',
        );
      case StopType.dropoff:
        return (
          color: Colors.purple.shade600,
          emoji: '⬇️',
          label: 'Dropoff${shiftOverview.taskCounts[taskType]! > 1 ? 's' : ''}',
        );
      case StopType.warehouseStop:
        return (
          color: Colors.grey.shade700,
          emoji: '🏭',
          label: 'Warehouse',
        );
    }
  }

  Widget _buildTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Starting point (current location)
        _buildTimelineStartPoint(),

        // Route bins
        ...shiftOverview.routeBins.asMap().entries.map((entry) {
          final index = entry.key;
          final bin = entry.value;
          final isLast = index == shiftOverview.routeBins.length - 1;

          return _buildTimelineBinStop(
            bin: bin,
            index: index,
            isLast: isLast,
          );
        }),
      ],
    );
  }

  Widget _buildTimelineStartPoint() {
    return Column(
      children: [
        // Row with dot and text aligned
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Dot (12px centered in 28px container)
            SizedBox(
              width: 28,
              height: 28,
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Location info - aligned with dot center
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.my_location,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Current Location',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Connecting line below
        Row(
          children: [
            SizedBox(
              width: 28,
              child: Center(
                child: Container(
                  width: 2,
                  height: 28,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.grey.shade400,
                        Colors.grey.shade300,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineBinStop({
    required RouteBin bin,
    required int index,
    required bool isLast,
  }) {
    final fillColor = _getFillColor(bin.fillPercentage);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Column(
        children: [
          // Row with badge and street name aligned
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Numbered badge (28px)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: fillColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: fillColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Street name - aligned with badge center
              Expanded(
                child: Text(
                  bin.currentStreet,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Fill percentage below
          // (with left padding to align under street name)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: fillColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${bin.fillPercentage}% full',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fillColor,
                  ),
                ),
              ),
            ),
          ),

          // Connecting line (if not last)
          if (!isLast)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Center(
                      child: Container(
                        width: 2,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              fillColor.withValues(alpha: 0.4),
                              Colors.grey.shade300,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getFillColor(int fillPercentage) {
    if (fillPercentage >= 80) {
      return Colors.red.shade600;
    } else if (fillPercentage >= 50) {
      return Colors.orange.shade600;
    } else {
      return AppColors.primaryGreen;
    }
  }
}
