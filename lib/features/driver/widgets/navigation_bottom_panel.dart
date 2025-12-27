import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/services/google_navigation_marker_service.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/utils/google_navigation_helpers.dart';
import 'package:ropacalapp/features/driver/widgets/check_in_dialog_v2.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/providers/navigation_page_provider.dart';

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

    final currentBin = shift.remainingBins.isNotEmpty &&
            currentIndex < shift.remainingBins.length
        ? shift.remainingBins[currentIndex]
        : null;

    if (currentBin == null) {
      return const SizedBox.shrink();
    }

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
                    ? _buildExpandedContent(
                        context,
                        ref,
                        shift,
                        currentBin,
                        currentIndex,
                        navState.remainingTime,
                        navState.totalDistanceRemaining,
                        navState.navigationLocation,
                      )
                    : _buildCollapsedContent(
                        currentBin,
                        shift.completedBins,
                        shift.totalBins,
                        navState.remainingTime,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build collapsed panel content (compact bar) - matching screenshot design
  Widget _buildCollapsedContent(
    RouteBin currentBin,
    int completedBins,
    int totalBins,
    Duration? remainingTime,
  ) {
    final progressPercentage = totalBins > 0 ? completedBins / totalBins : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Green status dot
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              // Bin number badge (blue square)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${currentBin.binNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
    final progressPercentage =
        shift.totalBins > 0 ? shift.completedBins / shift.totalBins : 0.0;
    final upcomingBins = GoogleNavigationHelpers.getUpcomingBins(
      shift.remainingBins,
      currentIndex,
    );

    // Calculate distance to bin for geofence check
    final double? distanceToBin = driverLocation != null
        ? GoogleNavigationHelpers.calculateDistance(
            driverLocation,
            LatLng(
              latitude: currentBin.latitude,
              longitude: currentBin.longitude,
            ),
          )
        : null;

    const double geofenceRadius = 100.0; // 100 meters
    final bool isWithinGeofence =
        distanceToBin != null && distanceToBin <= geofenceRadius;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with progress and est. finish time
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
                // Progress text
                Text(
                  '${shift.completedBins} of ${shift.totalBins} complete',
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
          const SizedBox(height: 18),

          // Current bin card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
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
                const SizedBox(height: 16),
                // Geofence warning message (shown when too far)
                if (!isWithinGeofence && distanceToBin != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                            'You need to be within ${geofenceRadius.toInt()}m of the bin to check in (${distanceToBin.toInt()}m away)',
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isWithinGeofence
                        ? () {
                            AppLogger.general(
                              'Complete Bin button pressed for Bin #${currentBin.binNumber}',
                            );
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => CheckInDialogV2(
                                bin: currentBin,
                                onCheckedIn: () {
                                  // Dialog handles bin completion internally
                                  // This callback can be used for additional actions if needed
                                  AppLogger.general(
                                    '✅ Bin #${currentBin.binNumber} checked in',
                                  );
                                },
                              ),
                            );
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
    );
  }
}
