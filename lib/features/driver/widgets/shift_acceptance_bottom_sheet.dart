import 'package:flutter/material.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/shift_overview.dart';

/// Premium Lyft-style bottom sheet for shift acceptance
/// Optimized for quick decision-making with clear visual hierarchy
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
    final formattedTime =
        '${estimatedEndTime.hour}:${estimatedEndTime.minute.toString().padLeft(2, '0')}';

    // Calculate average fill percentage for urgency indicator
    final avgFillPercentage = shiftOverview.routeBins.isEmpty
        ? 0
        : shiftOverview.routeBins
                .map((b) => b.fillPercentage)
                .reduce((a, b) => a + b) ~/
            shiftOverview.routeBins.length;

    // Determine urgency level
    final isUrgent = avgFillPercentage >= 80;
    final isMedium = avgFillPercentage >= 50 && avgFillPercentage < 80;

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

          Padding(
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
                                '${shiftOverview.totalBins}',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                shiftOverview.totalBins == 1 ? 'Bin' : 'Bins',
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
                          // Distance and time
                          Text(
                            '${shiftOverview.distanceFormatted} away • ${shiftOverview.durationFormatted}',
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

                // Location and fill percentage (compact)
                Row(
                  children: [
                    // Location pin icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
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
                            shiftOverview.routeBins.first.currentStreet,
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
                                    shiftOverview.routeBins.first.fillPercentage,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${shiftOverview.routeBins.first.fillPercentage}% full',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (shiftOverview.routeBins.length > 1) ...[
                                Text(
                                  '  •  ',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                Text(
                                  '+${shiftOverview.routeBins.length - 1} more',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
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
                    onPressed: onAccept,
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
                    onPressed: onDecline,
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
        ],
      ),
    );
  }

  Color _getFillColor(int fillPercentage) {
    if (fillPercentage >= 80) {
      return Colors.red;
    } else if (fillPercentage >= 50) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
