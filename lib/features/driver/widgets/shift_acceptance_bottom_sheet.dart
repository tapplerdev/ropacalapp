import 'package:flutter/material.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/shift_overview.dart';
import 'package:ropacalapp/models/route_bin.dart';

/// Timeline-based bottom sheet for shift acceptance
/// Inspired by ride-sharing apps with compact, scannable design
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
    final estimatedEndTime = DateTime.now().add(
      Duration(hours: (shiftOverview.totalBins * 0.25).ceil()),
    );
    final formattedTime = '${estimatedEndTime.hour}:'
        '${estimatedEndTime.minute.toString().padLeft(2, '0')}';

    // Calculate priority counts
    final highPriorityCount = shiftOverview.routeBins
        .where((bin) => bin.fillPercentage >= 80)
        .length;

    final avgFillPercentage = shiftOverview.routeBins.isEmpty
        ? 0
        : shiftOverview.routeBins
                .map((b) => b.fillPercentage)
                .reduce((a, b) => a + b) ~/
            shiftOverview.routeBins.length;

    final isUrgent = avgFillPercentage >= 80;
    final isMedium = avgFillPercentage >= 50 && avgFillPercentage < 80;

    // Bin count label
    final binLabel = shiftOverview.totalBins == 1 ? 'Bin' : 'Bins';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compact header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Inline summary with urgency badge
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  Text(
                                    '${shiftOverview.totalBins} $binLabel',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      height: 1.0,
                                    ),
                                  ),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  Text(
                                    '${shiftOverview.distanceFormatted} away',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  Text(
                                    '${shiftOverview.durationFormatted} route',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Urgency badge
                            if (isUrgent || isMedium)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isUrgent
                                      ? Colors.red.shade50
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isUrgent
                                        ? Colors.red.shade200
                                        : Colors.orange.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      size: 14,
                                      color:
                                          isUrgent ? Colors.red : Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isUrgent ? 'URGENT' : 'MEDIUM',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: isUrgent
                                            ? Colors.red.shade700
                                            : Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        // Priority summary
                        if (highPriorityCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '⚠️  $highPriorityCount urgent '
                              '${highPriorityCount == 1 ? 'bin' : 'bins'}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),

                        // Finish time
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Finish by $formattedTime',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
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

                  // Timeline
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildTimeline(),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Fixed bottom buttons (side-by-side)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Accept button (50%)
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Decline button (50%)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dot and line
        Column(
          children: [
            // Start dot
            Container(
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
            // Connecting line
            Container(
              width: 2,
              height: 28,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey.shade300,
                    Colors.grey.shade200,
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 12),

        // Location info
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                // Distance to first bin
                if (shiftOverview.routeBins.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 22),
                    child: Text(
                      '${shiftOverview.distanceFormatted} to first bin',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
    final isUrgent = bin.fillPercentage >= 80;
    final isMedium = bin.fillPercentage >= 50 && bin.fillPercentage < 80;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Numbered dot and line
        Column(
          children: [
            // Numbered badge
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
            // Connecting line (if not last)
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      fillColor.withValues(alpha: 0.3),
                      Colors.grey.shade200,
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(width: 12),

        // Bin details
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Street name with priority emoji
                Row(
                  children: [
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
                    if (isUrgent)
                      const Text(
                        '🔴',
                        style: TextStyle(fontSize: 16),
                      )
                    else if (isMedium)
                      const Text(
                        '🟠',
                        style: TextStyle(fontSize: 16),
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                // Fill percentage badge
                Container(
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getFillColor(int fillPercentage) {
    if (fillPercentage >= 80) {
      return Colors.red.shade600;
    } else if (fillPercentage >= 50) {
      return Colors.orange.shade600;
    } else {
      return AppColors.primaryBlue;
    }
  }
}
