import 'package:flutter/material.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/models/active_driver.dart';
import 'package:ropacalapp/models/route_task.dart';

/// Floating info card shown when a driver is focused on the manager map.
/// Displays driver name, current task description, progress, and action buttons.
class DriverFloatingCard extends StatelessWidget {
  final ActiveDriver driver;
  final RouteTask? currentTask;
  final int totalTasks;
  final int completedTasks;
  final bool isRouteVisible;
  final VoidCallback onFollow;
  final VoidCallback onToggleRoute;
  final VoidCallback onDetails;
  final VoidCallback onDismiss;

  const DriverFloatingCard({
    super.key,
    required this.driver,
    this.currentTask,
    required this.totalTasks,
    required this.completedTasks,
    required this.isRouteVisible,
    required this.onFollow,
    required this.onToggleRoute,
    required this.onDetails,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: driver name + dismiss button
          Row(
            children: [
              // Driver avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials(driver.driverName),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Name + progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.driverName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (totalTasks > 0)
                      Text(
                        '$completedTasks / $totalTasks tasks completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              // Dismiss button
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Current task info
          if (currentTask != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.actionBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.actionBlue.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _taskIcon(currentTask!),
                    size: 18,
                    color: AppColors.actionBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Heading to',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.actionBlue.withValues(alpha: 0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          currentTask!.displayTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'No active task',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              // Follow button
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: onFollow,
                    icon: const Icon(Icons.near_me, size: 16),
                    label: const Text(
                      'Follow',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Route toggle button
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: isRouteVisible
                      ? ElevatedButton.icon(
                          onPressed: onToggleRoute,
                          icon: const Icon(Icons.route, size: 16),
                          label: const Text(
                            'Route',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: onToggleRoute,
                          icon: Icon(
                            Icons.route,
                            size: 16,
                            color: Colors.grey.shade700,
                          ),
                          label: Text(
                            'Route',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              // Details button
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: onDetails,
                    icon: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey.shade700,
                    ),
                    label: Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
  }

  IconData _taskIcon(RouteTask task) {
    switch (task.taskType.name) {
      case 'collection':
        return Icons.delete_outline;
      case 'placement':
        return Icons.add_location_outlined;
      case 'pickup':
        return Icons.upload_outlined;
      case 'dropoff':
        return Icons.download_outlined;
      case 'warehouseStop':
        return Icons.warehouse_outlined;
      default:
        return Icons.task_alt;
    }
  }
}
