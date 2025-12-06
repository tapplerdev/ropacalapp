import 'package:flutter/material.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/shift_overview.dart';

/// Lyft-style draggable bottom sheet for shift acceptance
/// Premium design with bold typography and clear hierarchy
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

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle (Material 3 style)
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero section - Large bin count (Lyft-style pricing display)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${shiftOverview.totalBins}',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      shiftOverview.totalBins == 1 ? 'Bin' : 'Bins',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Route metadata (distance + duration)
                Row(
                  children: [
                    Icon(
                      Icons.route,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${shiftOverview.distanceFormatted} • ~${shiftOverview.durationFormatted}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Route preview - First 3 stops with clean timeline
                _buildRoutePreview(context),

                const SizedBox(height: 24),

                // Estimated completion time (subtle info card)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 22,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Est. completion: ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Accept button (Large, inviting, Lyft-style)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Decline button (Subtle, low-key)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onDecline,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildRoutePreview(BuildContext context) {
    // Show first 3 bins as preview
    final previewBins = shiftOverview.routeBins.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Route" label
        Text(
          'ROUTE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 16),

        // Timeline
        ...previewBins.asMap().entries.map((entry) {
          final index = entry.key;
          final bin = entry.value;
          final isFirst = index == 0;
          final isLast = index == previewBins.length - 1;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline connector
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      // Dot
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isFirst
                              ? AppColors.primaryBlue
                              : Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Connecting line
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 36,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Bin info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bin.currentStreet,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${bin.fillPercentage}% full',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        // "View all X stops" link (if more than 3)
        if (shiftOverview.routeBins.length > 3) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: InkWell(
              onTap: () {
                // TODO: Show full route list modal
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: Text(
                  'View all ${shiftOverview.routeBins.length} stops',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
