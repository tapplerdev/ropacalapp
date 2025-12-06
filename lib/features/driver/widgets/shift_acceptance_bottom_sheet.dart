import 'package:flutter/material.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/shift_overview.dart';

/// Premium Lyft-style bottom sheet with expandable route details
/// Two-stage design: Quick view → Full timeline
class ShiftAcceptanceBottomSheet extends StatefulWidget {
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
  State<ShiftAcceptanceBottomSheet> createState() =>
      _ShiftAcceptanceBottomSheetState();
}

class _ShiftAcceptanceBottomSheetState
    extends State<ShiftAcceptanceBottomSheet> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final estimatedEndTime = DateTime.now().add(
      Duration(hours: (widget.shiftOverview.totalBins * 0.25).ceil()),
    );
    final formattedTime = '${estimatedEndTime.hour}:'
        '${estimatedEndTime.minute.toString().padLeft(2, '0')}';

    // Calculate priority counts
    final highPriorityCount = widget.shiftOverview.routeBins
        .where((bin) => bin.fillPercentage >= 80)
        .length;
    final mediumPriorityCount = widget.shiftOverview.routeBins
        .where((bin) => bin.fillPercentage >= 50 && bin.fillPercentage < 80)
        .length;

    final avgFillPercentage = widget.shiftOverview.routeBins.isEmpty
        ? 0
        : widget.shiftOverview.routeBins
                .map((b) => b.fillPercentage)
                .reduce((a, b) => a + b) ~/
            widget.shiftOverview.routeBins.length;

    final isUrgent = avgFillPercentage >= 80;
    final isMedium = avgFillPercentage >= 50 && avgFillPercentage < 80;

    // Priority summary text
    String? prioritySummary;
    if (highPriorityCount > 0 || mediumPriorityCount > 0) {
      if (highPriorityCount > 0) {
        final binWord = highPriorityCount == 1 ? 'bin' : 'bins';
        final needWord = highPriorityCount == 1 ? 'needs' : 'need';
        prioritySummary =
            '$highPriorityCount $binWord $needWord urgent attention';
      } else {
        prioritySummary = '$mediumPriorityCount medium priority';
      }
    }

    return Container(
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

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero section with urgency badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Large bin count
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${widget.shiftOverview.totalBins}',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w800,
                                      height: 1.0,
                                      letterSpacing: -1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.shiftOverview.totalBins == 1
                                        ? 'Bin'
                                        : 'Bins',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Priority summary
                              if (prioritySummary != null)
                                Text(
                                  prioritySummary,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: highPriorityCount > 0
                                        ? Colors.red.shade700
                                        : Colors.orange.shade700,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              // Distance and time
                              Text(
                                '${widget.shiftOverview.distanceFormatted}'
                                ' away • '
                                '${widget.shiftOverview.durationFormatted}',
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
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isUrgent
                                  ? Colors.red.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
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
                                  size: 16,
                                  color: isUrgent ? Colors.red : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isUrgent ? 'URGENT' : 'MEDIUM',
                                  style: TextStyle(
                                    fontSize: 11,
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

                    const SizedBox(height: 20),

                    // Divider
                    Container(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),

                    const SizedBox(height: 20),

                    // Expandable route section
                    _buildExpandableRoute(
                      highPriorityCount,
                      mediumPriorityCount,
                    ),

                    const SizedBox(height: 20),

                    // Completion time (compact)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 20,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Estimated completion: ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Accept button (Large)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Accept',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Decline button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: widget.onDecline,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Decline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableRoute(int highPriority, int mediumPriority) {
    return Column(
      children: [
        // First bin preview (always visible)
        Row(
          children: [
            // Location pin icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_on,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Location text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.shiftOverview.routeBins.first.currentStreet,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      // Fill percentage indicator
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getFillColor(
                            widget.shiftOverview.routeBins.first.fillPercentage,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.shiftOverview.routeBins.first.fillPercentage}'
                        '% full',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // Expand/Collapse button (if multiple bins)
        if (widget.shiftOverview.routeBins.length > 1) ...[
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isExpanded
                          ? 'Hide route details'
                          : 'View full route '
                              '(${widget.shiftOverview.routeBins.length}'
                              ' stops)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  // Priority badge in button
                  if (highPriority > 0 && !_isExpanded)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$highPriority HIGH',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],

        // Expanded timeline (full bin list)
        if (_isExpanded) ...[
          const SizedBox(height: 20),
          _buildFullTimeline(),
        ],
      ],
    );
  }

  Widget _buildFullTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "ROUTE" header
        Text(
          'ROUTE TIMELINE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 16),

        // Timeline items
        ...widget.shiftOverview.routeBins.asMap().entries.map((entry) {
          final index = entry.key;
          final bin = entry.value;
          final isLast = index == widget.shiftOverview.routeBins.length - 1;

          final fillColor = _getFillColor(bin.fillPercentage);
          String? priorityEmoji;
          if (bin.fillPercentage >= 80) {
            priorityEmoji = '🔴';
          } else if (bin.fillPercentage >= 50) {
            priorityEmoji = '🟠';
          }

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Numbered badge
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    // Connecting line
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 32,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Bin details card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                bin.currentStreet,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (priorityEmoji != null)
                              Text(
                                priorityEmoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: fillColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: fillColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${bin.fillPercentage}% full',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: fillColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _getFillColor(int fillPercentage) {
    if (fillPercentage >= 80) {
      return Colors.red.shade600;
    } else if (fillPercentage >= 50) {
      return Colors.orange.shade600;
    } else {
      return Colors.blue.shade600;
    }
  }
}
