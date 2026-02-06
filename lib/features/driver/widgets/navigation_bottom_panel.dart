import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/services/google_navigation_marker_service.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/utils/google_navigation_helpers.dart';
import 'package:ropacalapp/core/services/geofence_service.dart';
import 'package:ropacalapp/features/driver/widgets/check_in_dialog_v2.dart';
import 'package:ropacalapp/features/driver/widgets/move_request_pickup_dialog.dart';
import 'package:ropacalapp/features/driver/widgets/move_request_placement_dialog.dart';
import 'package:ropacalapp/features/driver/widgets/warehouse_checkin_dialog.dart';
import 'package:ropacalapp/features/driver/widgets/placement_checkin_dialog.dart';
import 'package:ropacalapp/core/enums/stop_type.dart';
import 'package:ropacalapp/providers/navigation_page_provider.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/models/route_task.dart';
import 'package:ropacalapp/models/shift_state.dart';

/// Bottom panel showing current bin/task details during navigation
/// Expandable panel with progress tracking and action button
class NavigationBottomPanel extends HookConsumerWidget {
  final ShiftState shift;
  final int currentIndex;

  const NavigationBottomPanel({
    super.key,
    required this.shift,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationPageNotifierProvider);
    final navNotifier = ref.read(navigationPageNotifierProvider.notifier);

    // Support both task-based and bin-based systems
    final usesTasks = shift.usesTasks;

    if (usesTasks) {
      // New task-based system - FULL expandable panel
      final currentTask = shift.remainingTasks.isNotEmpty &&
              currentIndex < shift.remainingTasks.length
          ? shift.remainingTasks[currentIndex]
          : null;

      if (currentTask == null) {
        return const SizedBox.shrink();
      }

      return _buildTaskPanel(
        context,
        ref,
        currentTask,
        navState,
        navNotifier,
      );
    } else {
      // Legacy bin-based system - FULL expandable panel
      final currentBin = shift.remainingBins.isNotEmpty &&
              currentIndex < shift.remainingBins.length
          ? shift.remainingBins[currentIndex]
          : null;

      if (currentBin == null) {
        return const SizedBox.shrink();
      }

      return _buildBinPanel(
        context,
        ref,
        navState,
        navNotifier,
        currentBin,
      );
    }
  }

  /// Build expandable panel for TASK-based shifts
  Widget _buildTaskPanel(
    BuildContext context,
    WidgetRef ref,
    RouteTask currentTask,
    dynamic navState,
    dynamic navNotifier,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {
          navNotifier.toggleBottomPanel();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: navState.isBottomPanelExpanded ? 320 : 85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
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

              // Content
              Expanded(
                child: navState.isBottomPanelExpanded
                    ? _buildTaskExpandedContent(
                        context,
                        ref,
                        currentTask,
                        navState.remainingTime,
                        navState.totalDistanceRemaining,
                        navState.navigationLocation,
                      )
                    : _buildTaskCollapsedContent(currentTask),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build expandable panel for BIN-based shifts (legacy)
  Widget _buildBinPanel(
    BuildContext context,
    WidgetRef ref,
    dynamic navState,
    dynamic navNotifier,
    RouteBin currentBin,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {
          navNotifier.toggleBottomPanel();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: navState.isBottomPanelExpanded ? 320 : 85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
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

              // Content
              Expanded(
                child: navState.isBottomPanelExpanded
                    ? _buildBinExpandedContent(
                        context,
                        ref,
                        currentBin,
                        navState.remainingTime,
                        navState.totalDistanceRemaining,
                        navState.navigationLocation,
                      )
                    : _buildBinCollapsedContent(currentBin),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Collapsed content for TASK-based shifts
  Widget _buildTaskCollapsedContent(RouteTask task) {
    final progressPercentage = shift.logicalTotalBins > 0
        ? shift.logicalCompletedBins / shift.logicalTotalBins
        : 0.0;

    // Get task-specific styling
    final Color statusColor;
    final String displayLabel;
    final bool showBadge;
    final String badgeText;

    switch (task.taskType) {
      case StopType.pickup:
        statusColor = Colors.orange.shade600;
        displayLabel = task.displayTitle;
        showBadge = task.binNumber != null;
        badgeText = '${task.binNumber}';
        break;
      case StopType.dropoff:
        statusColor = Colors.green.shade600;
        displayLabel = task.displayTitle;
        showBadge = false;
        badgeText = '';
        break;
      case StopType.warehouseStop:
        statusColor = Colors.grey.shade700;
        displayLabel = task.displayTitle;
        showBadge = true;
        badgeText = '🏭';
        break;
      case StopType.placement:
        statusColor = Colors.orange.shade600;
        displayLabel = task.displayTitle;
        showBadge = true;
        badgeText = '📍';
        break;
      case StopType.collection:
      default:
        statusColor = AppColors.primaryGreen;
        displayLabel = task.displayTitle;
        showBadge = task.binNumber != null;
        badgeText = '${task.binNumber}';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Status dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),

              // Task badge (bin numbers, warehouse emoji, placement emoji)
              if (showBadge) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: task.taskType == StopType.warehouseStop ||
                              task.taskType == StopType.placement
                          ? 16
                          : 14,
                      fontWeight: FontWeight.bold,
                      color: task.taskType == StopType.warehouseStop ||
                              task.taskType == StopType.placement
                          ? Colors.black87
                          : statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Task label
              Expanded(
                child: Text(
                  task.taskType == StopType.collection && showBadge
                      ? task.displaySubtitle
                      : displayLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),

              // Progress count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${shift.logicalCompletedBins}/${shift.logicalTotalBins}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Up arrow
              Icon(
                Icons.keyboard_arrow_up,
                color: Colors.grey.shade500,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progressPercentage,
              minHeight: 4,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Collapsed content for BIN-based shifts (legacy)
  Widget _buildBinCollapsedContent(RouteBin bin) {
    final progressPercentage = shift.logicalTotalBins > 0
        ? shift.logicalCompletedBins / shift.logicalTotalBins
        : 0.0;

    // Determine badge display
    final bool showBadge = bin.binNumber != null ||
        bin.stopType == StopType.warehouseStop ||
        bin.stopType == StopType.placement;

    final String badgeText = bin.stopType == StopType.warehouseStop
        ? '🏭'
        : bin.stopType == StopType.placement
            ? '📍'
            : '${bin.binNumber}';

    final bool isEmoji = bin.stopType == StopType.warehouseStop ||
        bin.stopType == StopType.placement;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              if (showBadge) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: isEmoji ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: isEmoji ? Colors.black87 : AppColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  bin.currentStreet,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${shift.logicalCompletedBins}/${shift.logicalTotalBins}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_up,
                color: Colors.grey.shade500,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progressPercentage,
              minHeight: 4,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Expanded content for TASK-based shifts - with Complete button
  Widget _buildTaskExpandedContent(
    BuildContext context,
    WidgetRef ref,
    RouteTask task,
    Duration? remainingTime,
    double? totalDistanceRemaining,
    LatLng? driverLocation,
  ) {
    final progressPercentage = shift.logicalTotalBins > 0
        ? shift.logicalCompletedBins / shift.logicalTotalBins
        : 0.0;

    // Get upcoming tasks and filter out dropoffs if current task is the pickup
    final upcomingTasks = shift.remainingTasks.skip(1).where((upcomingTask) {
      // Filter out dropoff if current task is its corresponding pickup
      if (task.taskType == StopType.pickup &&
          upcomingTask.taskType == StopType.dropoff &&
          task.moveRequestId != null &&
          task.moveRequestId == upcomingTask.moveRequestId) {
        return false; // Skip dropoff from "UP NEXT" (it's part of current action)
      }
      return true;
    }).take(3).toList();

    // Calculate distance to task for geofence check
    final double? distanceToTask = driverLocation != null
        ? GeofenceService.getDistanceToTargetInMeters(
            currentLocation: driverLocation,
            targetLocation: LatLng(
              latitude: task.latitude,
              longitude: task.longitude,
            ),
          )
        : null;

    // Check if within geofence (100m = ~328 feet)
    final bool isWithinGeofence = driverLocation != null &&
        GeofenceService.isWithinGeofence(
          currentLocation: driverLocation,
          targetLocation: LatLng(
            latitude: task.latitude,
            longitude: task.longitude,
          ),
        );

    // Stop type badge color
    final Color badgeColor;
    final String stopTypeLabel;

    switch (task.taskType) {
      case StopType.pickup:
        badgeColor = Colors.orange.shade600;
        stopTypeLabel = '🚚 PICKUP';
        break;
      case StopType.dropoff:
        badgeColor = Colors.green.shade600;
        stopTypeLabel = '📍 DROPOFF';
        break;
      case StopType.warehouseStop:
        badgeColor = Colors.grey.shade700;
        stopTypeLabel = '🏭 WAREHOUSE';
        break;
      case StopType.placement:
        badgeColor = Colors.orange.shade600;
        stopTypeLabel = '📍 PLACEMENT';
        break;
      case StopType.collection:
      default:
        badgeColor = AppColors.primaryGreen;
        stopTypeLabel = '';
        break;
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with progress and est. finish time
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: Row(
                    children: [
                      // Green dot
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Progress text
                      Text(
                        '${shift.logicalCompletedBins} of ${shift.logicalTotalBins} complete',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      // Est. finish time badge
                      if (remainingTime != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: AppColors.primaryGreen,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Est. finish: ${GoogleNavigationHelpers.calculateEstimatedFinishTime(remainingTime)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Three-dot menu icon
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.grey.shade600,
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showTaskMenu(context, ref, task),
                      ),
                      const SizedBox(width: 4),
                      // Down arrow
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade500,
                        size: 24,
                      ),
                    ],
                  ),
                ),
                // Thin progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progressPercentage,
                      minHeight: 4,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Current task card
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stop type badge (for non-collection tasks)
                      if (task.taskType != StopType.collection) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: badgeColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            stopTypeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Badge (emoji for warehouse/placement, bin number otherwise)
                          if (task.binNumber != null ||
                              task.taskType == StopType.warehouseStop ||
                              task.taskType == StopType.placement)
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  task.taskType == StopType.warehouseStop
                                      ? '🏭'
                                      : task.taskType == StopType.placement
                                          ? '📍'
                                          : '${task.binNumber ?? 0}',
                                  style: TextStyle(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: task.taskType == StopType.warehouseStop ||
                                            task.taskType == StopType.placement
                                        ? 20
                                        : 18,
                                  ),
                                ),
                              ),
                            ),
                          if (task.binNumber != null ||
                              task.taskType == StopType.warehouseStop ||
                              task.taskType == StopType.placement)
                            const SizedBox(width: 12),
                          // Task info
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Address/title
                                Text(
                                  task.address ?? task.displayTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                // Badges row (fill % + distance + ETA)
                                Row(
                                  children: [
                                    // Fill percentage badge (only for collections - NOT warehouse or placement)
                                    if (task.taskType == StopType.collection &&
                                        task.fillPercentage != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: GoogleNavigationMarkerService
                                              .getFillColor(
                                            task.fillPercentage!,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${task.fillPercentage}% full',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: GoogleNavigationMarkerService
                                                .getFillColor(
                                              task.fillPercentage!,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    // Distance badge
                                    if (totalDistanceRemaining != null) ...[
                                      if (task.taskType == StopType.collection &&
                                          task.fillPercentage != null)
                                        const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          GoogleNavigationHelpers.formatDistance(
                                            totalDistanceRemaining,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade800,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                    // ETA badge
                                    if (remainingTime != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGreen
                                              .withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'ETA ${GoogleNavigationHelpers.formatETA(remainingTime)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primaryGreen,
                                            fontWeight: FontWeight.bold,
                                          ),
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
                    ],
                  ),
                ),

                // UP NEXT section
                if (upcomingTasks.isNotEmpty) ...[
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade200,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'UP NEXT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${upcomingTasks.length}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable list of upcoming tasks
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 60),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: upcomingTasks.length,
                      itemBuilder: (context, index) {
                        final upcomingTask = upcomingTasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              // Badge (emoji for warehouse/placement, bin number otherwise)
                              if (upcomingTask.binNumber != null ||
                                  upcomingTask.taskType == StopType.warehouseStop ||
                                  upcomingTask.taskType == StopType.placement)
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      upcomingTask.taskType == StopType.warehouseStop
                                          ? '🏭'
                                          : upcomingTask.taskType == StopType.placement
                                              ? '📍'
                                              : '${upcomingTask.binNumber ?? 0}',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: upcomingTask.taskType == StopType.warehouseStop ||
                                                upcomingTask.taskType == StopType.placement
                                            ? 18
                                            : 14,
                                      ),
                                    ),
                                  ),
                                ),
                              if (upcomingTask.binNumber != null ||
                                  upcomingTask.taskType == StopType.warehouseStop ||
                                  upcomingTask.taskType == StopType.placement)
                                const SizedBox(width: 12),
                              // Address
                              Expanded(
                                child: Text(
                                  upcomingTask.address ??
                                      upcomingTask.displayTitle,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Fill percentage badge (for collections)
                              if (upcomingTask.taskType == StopType.collection &&
                                  upcomingTask.fillPercentage != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: GoogleNavigationMarkerService
                                        .getFillColor(
                                      upcomingTask.fillPercentage!,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${upcomingTask.fillPercentage}% full',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          GoogleNavigationMarkerService.getFillColor(
                                        upcomingTask.fillPercentage!,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Geofence warning (if too far)
        if (!isWithinGeofence && distanceToTask != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.shade300,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_off,
                  color: Colors.orange.shade700,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'You need to be within ${_formatGeofenceDistance(GeofenceService.defaultGeofenceRadiusMeters)} of the location to check in (${_formatGeofenceDistance(distanceToTask)} away)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Complete Task button (conditionally enabled based on geofence)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isWithinGeofence
                  ? () {
                      AppLogger.general(
                        'Complete Task button pressed for task ${task.id} (type: ${task.taskType})',
                      );

                      // Show different dialog based on task type
                      // TODO: Task-based shifts need proper dialog implementations
                      // Current dialogs expect RouteBin which has more fields than RouteTask
                      switch (task.taskType) {
                        case StopType.warehouseStop:
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => WarehouseCheckinDialog(
                              task: task,
                              shiftBinId: task.id,
                            ),
                          );
                          break;

                        case StopType.placement:
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => PlacementCheckinDialog(
                              task: task,
                              shiftBinId: task.id,
                            ),
                          );
                          break;

                        case StopType.pickup:
                          // Convert task to bin format for legacy dialog
                          final binForPickup = _convertTaskToBin(task);
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => MoveRequestPickupDialog(
                              bin: binForPickup,
                              onPickupComplete: () {
                                AppLogger.general(
                                  '✅ Pickup task completed for Bin #${task.binNumber}',
                                );
                              },
                            ),
                          );
                          break;

                        case StopType.dropoff:
                          // Convert task to bin format for legacy dialog
                          final binForDropoff = _convertTaskToBin(task);
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => MoveRequestPlacementDialog(
                              bin: binForDropoff,
                              onPlacementComplete: () {
                                AppLogger.general(
                                  '✅ Dropoff task completed for Bin #${task.binNumber}',
                                );
                              },
                            ),
                          );
                          break;

                        case StopType.collection:
                          // Convert task to bin format for legacy dialog
                          final binForCollection = _convertTaskToBin(task);
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => CheckInDialogV2(
                              bin: binForCollection,
                              onCheckedIn: () {
                                AppLogger.general(
                                  '✅ Collection task completed for Bin #${task.binNumber}',
                                );
                              },
                            ),
                          );
                          break;

                        default:
                          // Fallback for any unknown task types
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Task completion dialog not yet implemented for ${task.taskType}',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          break;
                      }
                    }
                  : null, // Disabled when not within geofence
              style: ElevatedButton.styleFrom(
                backgroundColor: isWithinGeofence
                    ? AppColors.primaryGreen
                    : Colors.grey.shade400,
                disabledBackgroundColor: Colors.grey.shade400,
                disabledForegroundColor: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                minimumSize: const Size(double.infinity, 54),
              ),
              child: Text(
                isWithinGeofence ? _getButtonText(task.taskType) : 'Too Far Away',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Expanded content for BIN-based shifts (legacy)
  Widget _buildBinExpandedContent(
    BuildContext context,
    WidgetRef ref,
    RouteBin bin,
    Duration? remainingTime,
    double? totalDistanceRemaining,
    LatLng? driverLocation,
  ) {
    final progressPercentage = shift.logicalTotalBins > 0
        ? shift.logicalCompletedBins / shift.logicalTotalBins
        : 0.0;

    // Get upcoming bins and filter out dropoffs if current bin is the pickup
    final upcomingBins = shift.remainingBins.skip(1).where((upcomingBin) {
      // Filter out dropoff if current bin is its corresponding pickup
      if (bin.stopType == StopType.pickup &&
          upcomingBin.stopType == StopType.dropoff &&
          bin.moveRequestId != null &&
          bin.moveRequestId == upcomingBin.moveRequestId) {
        return false; // Skip dropoff from "UP NEXT" (it's part of current action)
      }
      return true;
    }).take(3).toList();

    // Calculate distance to bin for geofence check
    final double? distanceToBin = driverLocation != null
        ? GeofenceService.getDistanceToTargetInMeters(
            currentLocation: driverLocation,
            targetLocation: LatLng(
              latitude: bin.latitude,
              longitude: bin.longitude,
            ),
          )
        : null;

    // Check if within geofence (100m = ~328 feet)
    final bool isWithinGeofence = driverLocation != null &&
        GeofenceService.isWithinGeofence(
          currentLocation: driverLocation,
          targetLocation: LatLng(
            latitude: bin.latitude,
            longitude: bin.longitude,
          ),
        );

    // Stop type badge color
    final Color badgeColor;
    final String stopTypeLabel;

    switch (bin.stopType) {
      case StopType.pickup:
        badgeColor = Colors.orange.shade600;
        stopTypeLabel = '🚚 PICKUP';
        break;
      case StopType.dropoff:
        badgeColor = Colors.green.shade600;
        stopTypeLabel = '📍 DROPOFF';
        break;
      case StopType.warehouseStop:
        badgeColor = Colors.grey.shade700;
        stopTypeLabel = '🏭 WAREHOUSE';
        break;
      case StopType.placement:
        badgeColor = Colors.orange.shade600;
        stopTypeLabel = '📍 PLACEMENT';
        break;
      case StopType.collection:
      default:
        badgeColor = AppColors.primaryGreen;
        stopTypeLabel = '';
        break;
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with progress and est. finish time
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: Row(
                    children: [
                      // Green dot
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Progress text
                      Text(
                        '${shift.logicalCompletedBins} of ${shift.logicalTotalBins} complete',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      // Est. finish time badge
                      if (remainingTime != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: AppColors.primaryGreen,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Est. finish: ${GoogleNavigationHelpers.calculateEstimatedFinishTime(remainingTime)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Three-dot menu icon
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.grey.shade600,
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showTaskMenu(context, ref, _convertBinToTask(bin)),
                      ),
                      const SizedBox(width: 4),
                      // Down arrow
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade500,
                        size: 24,
                      ),
                    ],
                  ),
                ),
                // Thin progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progressPercentage,
                      minHeight: 4,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Current bin card
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stop type badge (for non-collection bins)
                      if (bin.stopType != StopType.collection) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: badgeColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            stopTypeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Badge (emoji for warehouse/placement, bin number otherwise)
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                bin.stopType == StopType.warehouseStop
                                    ? '🏭'
                                    : bin.stopType == StopType.placement
                                        ? '📍'
                                        : '${bin.binNumber ?? 0}',
                                style: TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: bin.stopType == StopType.warehouseStop ||
                                          bin.stopType == StopType.placement
                                      ? 20
                                      : 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Bin info
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Address
                                Text(
                                  bin.currentStreet,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                // Badges row (fill % + distance + ETA)
                                Row(
                                  children: [
                                    // Fill percentage badge (only for collections - NOT warehouse or placement)
                                    if (bin.stopType != StopType.warehouseStop &&
                                        bin.stopType != StopType.placement)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: GoogleNavigationMarkerService
                                              .getFillColor(
                                            bin.fillPercentage,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${bin.fillPercentage}% full',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: GoogleNavigationMarkerService
                                                .getFillColor(
                                              bin.fillPercentage,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    // Distance badge
                                    if (totalDistanceRemaining != null) ...[
                                      if (bin.stopType != StopType.warehouseStop &&
                                          bin.stopType != StopType.placement)
                                        const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          GoogleNavigationHelpers.formatDistance(
                                            totalDistanceRemaining,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade800,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                    // ETA badge
                                    if (remainingTime != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGreen
                                              .withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'ETA ${GoogleNavigationHelpers.formatETA(remainingTime)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primaryGreen,
                                            fontWeight: FontWeight.bold,
                                          ),
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
                    ],
                  ),
                ),

                // UP NEXT section
                if (upcomingBins.isNotEmpty) ...[
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade200,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'UP NEXT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${upcomingBins.length}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable list of upcoming bins
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 60),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: upcomingBins.length,
                      itemBuilder: (context, index) {
                        final upcomingBin = upcomingBins[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              // Badge (emoji for warehouse/placement, bin number otherwise)
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    upcomingBin.stopType == StopType.warehouseStop
                                        ? '🏭'
                                        : upcomingBin.stopType == StopType.placement
                                            ? '📍'
                                            : '${upcomingBin.binNumber ?? 0}',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: upcomingBin.stopType == StopType.warehouseStop ||
                                              upcomingBin.stopType == StopType.placement
                                          ? 18
                                          : 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Address
                              Expanded(
                                child: Text(
                                  upcomingBin.currentStreet,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Fill percentage badge (only for collections - NOT warehouse or placement)
                              if (upcomingBin.stopType != StopType.warehouseStop &&
                                  upcomingBin.stopType != StopType.placement)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: GoogleNavigationMarkerService
                                        .getFillColor(
                                      upcomingBin.fillPercentage,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${upcomingBin.fillPercentage}% full',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        GoogleNavigationMarkerService.getFillColor(
                                      upcomingBin.fillPercentage,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Geofence warning (if too far)
        if (!isWithinGeofence && distanceToBin != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.shade300,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_off,
                  color: Colors.orange.shade700,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'You need to be within ${_formatGeofenceDistance(GeofenceService.defaultGeofenceRadiusMeters)} of the bin to check in (${_formatGeofenceDistance(distanceToBin)} away)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Complete Bin button (conditionally enabled based on geofence)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isWithinGeofence
                  ? () {
                      AppLogger.general(
                        'Complete Bin button pressed for Bin #${bin.binNumber} (stopType: ${bin.stopType})',
                      );

                      // Show different dialog based on stop type
                      switch (bin.stopType) {
                        case StopType.warehouseStop:
                          // Show warehouse check-in confirmation dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            barrierColor: Colors.black.withValues(alpha: 0.6),
                            builder: (context) => Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 0,
                              backgroundColor: Colors.transparent,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Icon
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryGreen.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '🏭',
                                          style: TextStyle(fontSize: 32),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Title
                                    const Text(
                                      'Warehouse Check-In',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Address
                                    Text(
                                      bin.currentStreet,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              side: BorderSide(
                                                color: Colors.grey.shade300,
                                                width: 1.5,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              Navigator.of(context).pop();

                                              AppLogger.general('✅ Warehouse check-in confirmed');

                                              // Mark warehouse stop as complete (no fill % or photo needed)
                                              await ref.read(shiftNotifierProvider.notifier).completeTask(
                                                bin.id, // shiftBinId
                                                bin.binId ?? '', // binId (deprecated)
                                                null, // No fill percentage for warehouse
                                              );

                                              // Show success message
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('✅ Checked in at warehouse'),
                                                    duration: Duration(seconds: 2),
                                                    backgroundColor: AppColors.primaryGreen,
                                                  ),
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primaryGreen,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              'Continue',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                          break;

                        case StopType.placement:
                          // Convert RouteBin to RouteTask for placement dialog
                          final placementTask = RouteTask(
                            id: bin.id,
                            shiftId: bin.shiftId ?? '',
                            sequenceOrder: bin.sequenceOrder ?? 0,
                            taskType: StopType.placement,
                            latitude: bin.latitude ?? 0,
                            longitude: bin.longitude ?? 0,
                            address: bin.currentStreet,
                            isCompleted: 0,
                            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                          );

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => PlacementCheckinDialog(
                              task: placementTask,
                              shiftBinId: bin.id,
                            ),
                          );
                          break;

                        case StopType.pickup:
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => MoveRequestPickupDialog(
                              bin: bin,
                              onPickupComplete: () {
                                AppLogger.general(
                                  '✅ Move request pickup completed for Bin #${bin.binNumber}',
                                );
                              },
                            ),
                          );
                          break;

                        case StopType.dropoff:
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => MoveRequestPlacementDialog(
                              bin: bin,
                              onPlacementComplete: () {
                                AppLogger.general(
                                  '✅ Move request dropoff completed for Bin #${bin.binNumber}',
                                );
                              },
                            ),
                          );
                          break;

                        case StopType.collection:
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => CheckInDialogV2(
                              bin: bin,
                              onCheckedIn: () {
                                AppLogger.general(
                                  '✅ Bin #${bin.binNumber} checked in',
                                );
                              },
                            ),
                          );
                          break;
                      }
                    }
                  : null, // Disabled when not within geofence
              style: ElevatedButton.styleFrom(
                backgroundColor: isWithinGeofence
                    ? AppColors.primaryGreen
                    : Colors.grey.shade400,
                disabledBackgroundColor: Colors.grey.shade400,
                disabledForegroundColor: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                minimumSize: const Size(double.infinity, 54),
              ),
              child: Text(
                isWithinGeofence ? _getButtonText(bin.stopType) : 'Too Far Away',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Returns appropriate button text based on task type
  String _getButtonText(StopType taskType) {
    switch (taskType) {
      case StopType.warehouseStop:
        return 'Check In';
      case StopType.placement:
        return 'Place Bin';
      case StopType.pickup:
        return 'Complete Pickup';
      case StopType.dropoff:
        return 'Complete Dropoff';
      case StopType.collection:
        return 'Complete Bin';
    }
  }

  /// Helper to convert RouteTask to RouteBin for legacy dialog compatibility
  /// The existing dialogs (MoveRequestPickupDialog, MoveRequestPlacementDialog, CheckInDialogV2)
  /// expect RouteBin objects, so we need to convert RouteTask data to RouteBin format
  RouteBin _convertTaskToBin(RouteTask task) {
    // Parse address into components (best effort - dialogs can handle nulls/defaults)
    final addressParts = (task.address ?? '').split(',');
    final street = addressParts.isNotEmpty ? addressParts[0].trim() : task.address ?? 'Unknown';
    final city = addressParts.length > 1 ? addressParts[1].trim() : '';
    final zip = addressParts.length > 2 ? addressParts[2].trim() : '';

    return RouteBin(
      id: task.id,
      shiftId: task.shiftId,
      binId: task.binId ?? '',
      sequenceOrder: task.sequenceOrder,
      stopType: task.taskType,
      moveRequestId: task.moveRequestId,
      originalAddress: task.address, // Pickup location address
      newAddress: task.destinationAddress, // Dropoff location address
      moveType: task.moveType,
      potentialLocationId: task.potentialLocationId,
      newBinNumber: task.newBinNumber,
      warehouseAction: task.warehouseAction,
      binsToLoad: task.binsToLoad,
      isCompleted: task.isCompleted,
      completedAt: task.completedAt,
      updatedFillPercentage: task.updatedFillPercentage,
      createdAt: task.createdAt,
      binNumber: task.binNumber ?? 0,
      currentStreet: street,
      city: city,
      zip: zip,
      fillPercentage: task.fillPercentage ?? 0,
      latitude: task.latitude,
      longitude: task.longitude,
    );
  }

  /// Helper to convert RouteBin to RouteTask for skip task menu
  RouteTask _convertBinToTask(RouteBin bin) {
    final address = [bin.currentStreet, bin.city, bin.zip]
        .where((part) => part.isNotEmpty)
        .join(', ');

    return RouteTask(
      id: bin.id,
      shiftId: bin.shiftId,
      binId: bin.binId.isEmpty ? null : bin.binId,
      sequenceOrder: bin.sequenceOrder,
      taskType: bin.stopType,
      moveRequestId: bin.moveRequestId,
      address: address.isEmpty ? bin.originalAddress : address,
      destinationAddress: bin.newAddress,
      moveType: bin.moveType,
      potentialLocationId: bin.potentialLocationId,
      newBinNumber: bin.newBinNumber,
      warehouseAction: bin.warehouseAction,
      binsToLoad: bin.binsToLoad,
      isCompleted: bin.isCompleted,
      completedAt: bin.completedAt,
      updatedFillPercentage: bin.updatedFillPercentage,
      createdAt: bin.createdAt,
      binNumber: bin.binNumber == 0 ? null : bin.binNumber,
      fillPercentage: bin.fillPercentage == 0 ? null : bin.fillPercentage,
      latitude: bin.latitude,
      longitude: bin.longitude,
    );
  }

  /// Format distance for geofence warnings
  /// - If >= 1 mile (1609m): show in miles (e.g., "1.2 mi")
  /// - If < 1 mile: show in meters (e.g., "328 m")
  String _formatGeofenceDistance(double meters) {
    const metersPerMile = 1609.0;

    if (meters >= metersPerMile) {
      // Show in miles with 1 decimal place
      final miles = meters / metersPerMile;
      return '${miles.toStringAsFixed(1)} mi';
    } else {
      // Show in meters with no decimals
      return '${meters.toInt()} m';
    }
  }

  /// Show task actions menu
  void _showTaskMenu(
    BuildContext context,
    WidgetRef ref,
    RouteTask task,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.skip_next,
                color: Colors.orange.shade600,
              ),
              title: const Text('Skip This Task'),
              subtitle: const Text('Requires explanation'),
              onTap: () {
                Navigator.pop(context);
                _showSkipDialog(context, ref, task);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Show skip task confirmation dialog with required reason
  void _showSkipDialog(
    BuildContext context,
    WidgetRef ref,
    RouteTask task,
  ) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isSubmitting = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.shade600.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.skip_next_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Skip Task',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Provide a reason',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Info banner for pickup pairing
                        if (task.taskType == StopType.pickup &&
                            task.moveRequestId != null)
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.blue.shade100,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade600,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Skipping this pickup will also skip the paired dropoff',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Reason label
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Why are you skipping this task?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),

                        // Reason text field
                        TextFormField(
                          controller: reasonController,
                          maxLines: 3,
                          autofocus: true,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Enter reason...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.orange.shade600,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Reason is required';
                            }
                            if (value.trim().length < 3) {
                              return 'Reason must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: isSubmitting.value
                            ? null
                            : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.grey.shade100,
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isSubmitting,
                        builder: (context, submitting, child) {
                          return ElevatedButton(
                            onPressed: submitting
                                ? null
                                : () async {
                                    if (formKey.currentState?.validate() ??
                                        false) {
                                      isSubmitting.value = true;

                                      try {
                                        await ref
                                            .read(
                                              shiftNotifierProvider.notifier,
                                            )
                                            .skipTask(
                                              task.id,
                                              reasonController.text.trim(),
                                            );

                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withValues(
                                                        alpha: 0.2,
                                                      ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Expanded(
                                                    child: Text(
                                                      'Task skipped successfully',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor:
                                                  Colors.orange[600],
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              margin: const EdgeInsets.all(16),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        isSubmitting.value = false;
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.error_outline,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      'Failed to skip task: $e',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: Colors.red[600],
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              margin: const EdgeInsets.all(16),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Skip Task',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
