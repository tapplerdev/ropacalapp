import 'package:flutter/material.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/shift_overview.dart';

/// Expandable modal showing detailed shift information
/// Slides up from PreShiftOverviewCard
class ShiftDetailsModal extends StatelessWidget {
  final ShiftOverview shiftOverview;
  final VoidCallback onStartShift;

  const ShiftDetailsModal({
    super.key,
    required this.shiftOverview,
    required this.onStartShift,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.7, // 70% of screen height
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Shift Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key metrics row
                  _buildMetricsRow(),
                  const SizedBox(height: 20),
                  // Estimated completion time
                  _buildEstimatedCompletion(),
                  const SizedBox(height: 20),
                  // Upcoming bins header
                  Text(
                    'Upcoming Bins',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Full bin list with timeline
                  _buildFullBinList(),
                  const SizedBox(height: 100), // Space for fixed button
                ],
              ),
            ),
          ),
          // Fixed bottom "Start Shift" button
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onStartShift,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Start Shift',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

  // Metrics row showing key stats
  Widget _buildMetricsRow() {
    final highPriorityCount = shiftOverview.routeBins
        .where((bin) => bin.fillPercentage > 80)
        .length;
    final mediumPriorityCount = shiftOverview.routeBins
        .where((bin) => bin.fillPercentage > 50 && bin.fillPercentage <= 80)
        .length;

    return Row(
      children: [
        _buildMetricCard(
          label: 'Bins',
          value: '${shiftOverview.totalBins}',
          icon: Icons.delete_outline,
          color: AppColors.primaryGreen,
        ),
        const SizedBox(width: 12),
        _buildMetricCard(
          label: 'Distance',
          value: shiftOverview.distanceFormatted,
          icon: Icons.route,
          color: Colors.orange.shade600,
        ),
        const SizedBox(width: 12),
        _buildMetricCard(
          label: 'Time',
          value: '~${shiftOverview.durationFormatted}',
          icon: Icons.schedule,
          color: Colors.green.shade600,
        ),
        const SizedBox(width: 12),
        _buildMetricCard(
          label: 'Priority',
          value: highPriorityCount > 0
              ? '${highPriorityCount} HIGH'
              : mediumPriorityCount > 0
              ? '${mediumPriorityCount} MED'
              : 'None',
          icon: Icons.warning_outlined,
          color: highPriorityCount > 0
              ? Colors.red.shade600
              : mediumPriorityCount > 0
              ? Colors.orange.shade600
              : Colors.grey.shade600,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimatedCompletion() {
    final estimatedEndTime = DateTime.now().add(
      Duration(hours: (shiftOverview.totalBins * 0.25).ceil()),
    );
    final formattedTime =
        '${estimatedEndTime.hour}:${estimatedEndTime.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 10),
          Text(
            'Estimated completion: ',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  // Full bin list with timeline view
  Widget _buildFullBinList() {
    return Column(
      children: shiftOverview.routeBins.asMap().entries.map((entry) {
        final index = entry.key;
        final bin = entry.value;
        final isLast = index == shiftOverview.routeBins.length - 1;

        // Determine priority color
        Color priorityColor;
        String? priorityIndicator;
        if (bin.fillPercentage > 80) {
          priorityColor = Colors.red.shade600;
          priorityIndicator = '🔴';
        } else if (bin.fillPercentage > 50) {
          priorityColor = Colors.orange.shade600;
          priorityIndicator = '🟠';
        } else {
          priorityColor = Colors.blue.shade600;
          priorityIndicator = null;
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline connector - only show sequence numbers if optimized
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: shiftOverview.isOptimized
                            ? AppColors.primaryGreen.withValues(alpha: 0.15)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: shiftOverview.isOptimized
                            ? Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              )
                            : Icon(
                                Icons.circle,
                                size: 8,
                                color: Colors.grey.shade400,
                              ),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.grey.shade300,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Bin details
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (priorityIndicator != null)
                              Text(
                                priorityIndicator,
                                style: const TextStyle(fontSize: 16),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${bin.fillPercentage}% full',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: priorityColor,
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
            if (isLast) const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }
}
