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
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/models/route_task.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/providers/navigation_page_provider.dart';
import 'package:ropacalapp/core/enums/stop_type.dart';
import 'package:ropacalapp/providers/move_request_provider.dart';

/// Expandable bottom panel showing bin details and progress
/// Displays collapsed (85px) or expanded (320px) state with animation
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
      // New task-based system
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
      // Legacy bin-based system
      final currentBin = shift.remainingBins.isNotEmpty &&
              currentIndex < shift.remainingBins.length
          ? shift.remainingBins[currentIndex]
          : null;

      if (currentBin == null) {
        return const SizedBox.shrink();
      }

      return _buildBinPanel(
        context,
        navState,
        navNotifier,
        currentBin,
      );
    }
  }

  /// Legacy bin-based collapsed content
  Widget _buildCollapsedContent(
    RouteBin currentBin,
    int completedBins,
    int totalBins,
    Duration? remainingTime,
  ) {
    // Use logical progress percentage (treats pickup+dropoff as 1 action)
    final progressPercentage = totalBins > 0 ? completedBins / totalBins : 0.0;

    // Stop type color coding
    final Color statusColor;
    final Color badgeColor;
    final String stopTypeLabel;
    final bool showBadge; // Only show badge for actual bin collections

    switch (currentBin.stopType) {
      case StopType.pickup:
        statusColor = Colors.orange.shade600;
        badgeColor = Colors.orange.shade600;
        stopTypeLabel = '🚚 PICKUP';
        showBadge = currentBin.binNumber != null && currentBin.binNumber! > 0;
        break;
      case StopType.dropoff:
        statusColor = Colors.green.shade600;
        badgeColor = Colors.green.shade600;
        stopTypeLabel = '📍 DROPOFF';
        showBadge = false; // No badge for dropoffs
        break;
      case StopType.warehouseStop:
        statusColor = Colors.grey.shade700;
        badgeColor = Colors.grey.shade700;
        stopTypeLabel = '🏭 WAREHOUSE';
        showBadge = false; // No badge for warehouse
        break;
      case StopType.placement:
        statusColor = Colors.orange.shade600;
        badgeColor = Colors.orange.shade600;
        stopTypeLabel = '📍 PLACEMENT';
        showBadge = false; // No badge for placement
        break;
      case StopType.collection:
      default:
        statusColor = const Color(0xFF4CAF50);
        badgeColor = AppColors.primaryGreen;
        stopTypeLabel = '';
        showBadge = currentBin.binNumber != null && currentBin.binNumber! > 0;
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
              // Stop type label for non-collection types
              if (currentBin.stopType != StopType.collection) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    stopTypeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Bin number badge (only for actual bins with numbers > 0)
              if (showBadge) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${currentBin.binNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              // Address
              Expanded(
                child: Text(
                  currentBin.currentStreet,
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
              // Progress count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$completedBins/$totalBins',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Up arrow icon
              Icon(
                Icons.keyboard_arrow_up,
                color: Colors.grey.shade500,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Thin progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progressPercentage,
              minHeight: 4,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build panel for new task-based system
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
                color: Colors.black.withValues(alpha: 0.1),
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
                    ? _buildTaskExpandedContent(context, ref, currentTask, navState)
                    : _buildTaskCollapsedContent(currentTask, navState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Collapsed task content - proper labels without bin badges for warehouse/placement
  Widget _buildTaskCollapsedContent(RouteTask task, dynamic navState) {
    final progressPercentage = shift.logicalTotalBins > 0
        ? shift.logicalCompletedBins / shift.logicalTotalBins
        : 0.0;

    // Get task-specific styling
    final Color statusColor;
    final String displayLabel;
    final bool showBadge;

    switch (task.taskType) {
      case StopType.pickup:
        statusColor = Colors.orange.shade600;
        displayLabel = task.displayTitle;
        showBadge = task.binNumber != null;
        break;
      case StopType.dropoff:
        statusColor = Colors.green.shade600;
        displayLabel = task.displayTitle;
        showBadge = false; // No badge for dropoffs
        break;
      case StopType.warehouseStop:
        statusColor = Colors.grey.shade700;
        displayLabel = task.displayTitle; // "Warehouse - Load 6 bins"
        showBadge = false; // No bin badge for warehouse
        break;
      case StopType.placement:
        statusColor = Colors.orange.shade600;
        displayLabel = task.displayTitle; // "Place New Bin"
        showBadge = false; // No bin badge for placements
        break;
      case StopType.collection:
      default:
        statusColor = AppColors.primaryGreen;
        displayLabel = task.displayTitle; // "Bin #123"
        showBadge = task.binNumber != null;
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

              // Task badge (only for tasks with bin numbers)
              if (showBadge) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${task.binNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Task label
              Expanded(
                child: Text(
                  task.taskType == StopType.collection && showBadge
                      ? task.displaySubtitle // Show address for collections
                      : displayLabel, // Show full label for warehouse/placement
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

  /// Expanded task content - show full details
  Widget _buildTaskExpandedContent(
    BuildContext context,
    WidgetRef ref,
    RouteTask task,
    dynamic navState,
  ) {
    // TODO: Implement expanded view
    return Center(
      child: Text('Task: ${task.displayTitle}'),
    );
  }

  /// Build panel for legacy bin-based system
  Widget _buildBinPanel(
    BuildContext context,
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
                color: Colors.black.withValues(alpha: 0.1),
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

              // Content - show collapsed or expanded based on state
              Expanded(
                child: navState.isBottomPanelExpanded
                    ? _buildBinExpandedContent(
                        context,
                        currentBin,
                        navState,
                      )
                    : _buildCollapsedContent(
                        currentBin,
                        shift.logicalCompletedBins,
                        shift.logicalTotalBins,
                        navState.remainingTime,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build expanded content for legacy bin system (with UP NEXT section)
  Widget _buildBinExpandedContent(
    BuildContext context,
    RouteBin currentBin,
    dynamic navState,
  ) {
    final progressPercentage = shift.logicalTotalBins > 0
        ? shift.logicalCompletedBins / shift.logicalTotalBins
        : 0.0;

    // Get upcoming bins (next 2-3 bins after current)
    final currentIndex = shift.remainingBins.indexOf(currentBin);
    final upcomingBins = currentIndex >= 0 && currentIndex < shift.remainingBins.length - 1
        ? shift.remainingBins.skip(currentIndex + 1).take(3).toList()
        : <RouteBin>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current bin info
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentBin.stopType == StopType.warehouseStop
                          ? '🏭 Warehouse Stop'
                          : currentBin.stopType == StopType.placement
                              ? '📍 Place New Bin'
                              : 'Cl. ${currentBin.binNumber} ${currentBin.currentStreet}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (currentBin.stopType == StopType.collection)
                      Text(
                        '${currentBin.fillPercentage}% full',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${shift.logicalCompletedBins}/${shift.logicalTotalBins}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPercentage,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryGreen,
              ),
            ),
          ),

          // UP NEXT section
          if (upcomingBins.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'UP NEXT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${upcomingBins.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...upcomingBins.map((bin) {
              final bool showBadge = bin.stopType == StopType.collection &&
                  bin.binNumber != null &&
                  bin.binNumber! > 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    if (showBadge)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${bin.binNumber}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    if (bin.stopType != StopType.collection)
                      Text(
                        bin.stopType == StopType.warehouseStop
                            ? '🏭 Warehouse'
                            : bin.stopType == StopType.placement
                                ? '📍 Placement'
                                : bin.stopType == StopType.pickup
                                    ? '🚚 Pickup'
                                    : '📍 Dropoff',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        bin.currentStreet,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (bin.stopType == StopType.collection)
                      Text(
                        '${bin.fillPercentage}% full',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  /// Build expanded panel content (full bin details) - matching screenshot design
  Widget _buildExpandedContent(
    BuildContext context,
    WidgetRef ref,
    ShiftState shift,
    RouteBin currentBin,
    int currentIndex,
    Duration? remainingTime,
    double? totalDistanceRemaining,
    LatLng? driverLocation,
  ) {
    // Use logical progress (treats pickup+dropoff as 1 action)
    final progressPercentage = shift.logicalTotalBins > 0
        ? shift.logicalCompletedBins / shift.logicalTotalBins
        : 0.0;

    // Get upcoming bins and filter out dropoffs if current bin is the pickup
    final upcomingBins = GoogleNavigationHelpers.getUpcomingBins(
      shift.remainingBins,
      currentIndex,
    ).where((bin) {
      // Filter out dropoff if current bin is its corresponding pickup
      if (currentBin.stopType == StopType.pickup &&
          bin.stopType == StopType.dropoff &&
          currentBin.moveRequestId != null &&
          currentBin.moveRequestId == bin.moveRequestId) {
        return false; // Skip dropoff from "UP NEXT" (it's part of current action)
      }
      return true;
    }).toList();

    // Calculate distance to bin for geofence check (using centralized GeofenceService)
    final double? distanceToBin = driverLocation != null
        ? GeofenceService.getDistanceToTargetInMeters(
            currentLocation: driverLocation,
            targetLocation: LatLng(
              latitude: currentBin.latitude,
              longitude: currentBin.longitude,
            ),
          )
        : null;

    // Check if within geofence (100m = ~328 feet)
    final bool isWithinGeofence = driverLocation != null &&
        GeofenceService.isWithinGeofence(
          currentLocation: driverLocation,
          targetLocation: LatLng(
            latitude: currentBin.latitude,
            longitude: currentBin.longitude,
          ),
        );

    // Stop type color coding for badges
    final Color badgeColor;
    final String stopTypeLabel;

    switch (currentBin.stopType) {
      case StopType.pickup:
        badgeColor = Colors.orange.shade600;
        stopTypeLabel = '🚚 PICKUP';
        break;
      case StopType.dropoff:
        badgeColor = Colors.green.shade600;
        stopTypeLabel = '📍 DROPOFF';
        break;
      case StopType.collection:
      default:
        badgeColor = AppColors.primaryGreen;
        stopTypeLabel = '';
        break;
    }

    return Column(
      children: [
        // Scrollable content
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
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                // Progress text (logical count - treats move requests as 1 action)
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
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
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
                const SizedBox(width: 8),
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
                  Color(0xFF4CAF50),
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
                // Stop type badge (pickup/dropoff indicator)
                if (currentBin.stopType != StopType.collection) ...[
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
                    // Bin number badge (36px blue square - more compact)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${currentBin.binNumber}',
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
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
                          // Address as title
                          Text(
                            currentBin.currentStreet,
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
                              // Fill percentage badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: GoogleNavigationMarkerService.getFillColor(
                                    currentBin.fillPercentage,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${currentBin.fillPercentage}% full',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: GoogleNavigationMarkerService.getFillColor(
                                      currentBin.fillPercentage,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Distance badge
                              if (totalDistanceRemaining != null) ...[
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
                                    color: AppColors.primaryGreen.withValues(alpha: 0.15),
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
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            // Scrollable list of upcoming bins - shows first bin, scroll for more
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 60), // Show only 1 bin
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: upcomingBins.length,
                itemBuilder: (context, index) {
                  final bin = upcomingBins[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        // Bin number badge (slightly grey background)
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${bin.binNumber}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Address (darker text)
                        Expanded(
                          child: Text(
                            bin.currentStreet,
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
                        // Fill percentage badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: GoogleNavigationMarkerService.getFillColor(
                              bin.fillPercentage,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${bin.fillPercentage}% full',
                            style: TextStyle(
                              fontSize: 12,
                              color: GoogleNavigationMarkerService.getFillColor(
                                bin.fillPercentage,
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

        // Complete Bin button - fixed at bottom (not in scrollview)
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
                    'You need to be within ${GeofenceService.defaultGeofenceRadiusMeters.toInt()}m of the bin to check in (${distanceToBin.toInt()}m away)',
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
                        'Complete Bin button pressed for Bin #${currentBin.binNumber} (stopType: ${currentBin.stopType})',
                      );

                      // Show different dialog based on stop type
                      switch (currentBin.stopType) {
                        case StopType.pickup:
                          // Show move request pickup dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => MoveRequestPickupDialog(
                              bin: currentBin,
                              onPickupComplete: () {
                                AppLogger.general(
                                  '✅ Move request pickup completed for Bin #${currentBin.binNumber}',
                                );
                              },
                            ),
                          );
                          break;

                        case StopType.dropoff:
                          // Show move request placement dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => MoveRequestPlacementDialog(
                              bin: currentBin,
                              onPlacementComplete: () {
                                AppLogger.general(
                                  '✅ Move request dropoff completed for Bin #${currentBin.binNumber}',
                                );
                              },
                            ),
                          );
                          break;

                        case StopType.collection:
                        default:
                          // Show regular check-in dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => CheckInDialogV2(
                              bin: currentBin,
                              onCheckedIn: () {
                                AppLogger.general(
                                  '✅ Bin #${currentBin.binNumber} checked in',
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
                    ? const Color(0xFF4CAF50)
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
                isWithinGeofence ? 'Complete Bin' : 'Too Far Away',
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
}
