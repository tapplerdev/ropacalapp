import 'package:flutter/material.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/responsive.dart';
import 'package:ropacalapp/models/shift_overview.dart';

/// Lyft-style bottom sheet for shift acceptance
/// Shows route summary with large accept button
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(
              Responsive.spacing(context, mobile: 20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route earnings-style header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${shiftOverview.totalBins} Bins',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(
                                context,
                                mobile: 28,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            height: Responsive.spacing(context, mobile: 4),
                          ),
                          Text(
                            '${shiftOverview.distanceFormatted} • ~${shiftOverview.durationFormatted}',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(
                                context,
                                mobile: 16,
                              ),
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: Responsive.spacing(context, mobile: 20)),

                // Route timeline preview (first 3 stops)
                _buildRoutePreview(),

                SizedBox(height: Responsive.spacing(context, mobile: 16)),

                // Estimated completion time
                Container(
                  padding: EdgeInsets.all(
                    Responsive.spacing(context, mobile: 12),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: Responsive.iconSize(context, mobile: 20),
                        color: AppColors.primaryBlue,
                      ),
                      SizedBox(width: Responsive.spacing(context, mobile: 8)),
                      Text(
                        'Est. completion: ',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, mobile: 14),
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, mobile: 14),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: Responsive.spacing(context, mobile: 24)),

                // Accept button (Lyft-style)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: Responsive.spacing(context, mobile: 16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, mobile: 18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: Responsive.spacing(context, mobile: 12)),

                // Decline button (subtle)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onDecline,
                    child: Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, mobile: 16),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),

                // Bottom safe area padding
                SizedBox(
                  height: Responsive.bottomSafeArea(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePreview() {
    // Show first 3 bins as preview
    final previewBins = shiftOverview.routeBins.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        ...previewBins.asMap().entries.map((entry) {
          final index = entry.key;
          final bin = entry.value;
          final isLast = index == previewBins.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline connector
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? AppColors.primaryBlue
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 32,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Bin info
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: isLast ? 0 : 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bin.currentStreet,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${bin.fillPercentage}% full',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),

        // "View all X stops" link
        if (shiftOverview.routeBins.length > 3) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              // TODO: Show full route list modal
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                'View all ${shiftOverview.routeBins.length} stops',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
