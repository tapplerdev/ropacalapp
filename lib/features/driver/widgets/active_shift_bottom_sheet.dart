import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/enums/bin_status.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/providers/simulation_provider.dart';
import 'package:ropacalapp/providers/voice_instruction_provider.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/utils/location_helpers.dart';
import 'package:ropacalapp/core/services/geofence_service.dart';

/// Bottom sheet showing active shift navigation
class ActiveShiftBottomSheet extends HookConsumerWidget {
  final List<RouteBin> routeBins;
  final int completedBins;
  final int totalBins;
  final VoidCallback? onNavigateToNextBin;
  final List<latlong.LatLng>? preComputedPolyline; // Optional pre-fetched polyline

  // Google Navigation data
  final Duration? googleRemainingTime; // Time to final destination
  final double? googleTotalDistanceRemaining; // Distance to final destination (meters)
  final double? googleDistanceToNextManeuver; // Distance to next turn (meters)

  const ActiveShiftBottomSheet({
    super.key,
    required this.routeBins,
    required this.completedBins,
    required this.totalBins,
    this.onNavigateToNextBin,
    this.preComputedPolyline,
    this.googleRemainingTime,
    this.googleTotalDistanceRemaining,
    this.googleDistanceToNextManeuver,
  });

  RouteBin? get nextBin {
    // Find first incomplete bin
    for (final bin in routeBins) {
      if (bin.isCompleted == 0) {
        return bin;
      }
    }
    return null;
  }

  /// Get index of the next bin in the route (0-based)
  int _getNextBinIndex(RouteBin bin) {
    // Find how many incomplete bins are before this one
    final incompleteBins = routeBins.where((b) => b.isCompleted == 0).toList();
    final index = incompleteBins.indexWhere((b) => b.binId == bin.binId);

    // AppLogger.routing('🔍 _getNextBinIndex:');
    // AppLogger.routing('   Looking for binId: ${bin.binId}');
    // AppLogger.routing('   Bin number: ${bin.binNumber}');
    // AppLogger.routing('   Total route bins: ${routeBins.length}');
    // AppLogger.routing('   Incomplete bins: ${incompleteBins.length}');
    // AppLogger.routing('   Calculated index: $index');

    return index;
  }

  /// Calculate distance to next bin in kilometers using straight-line distance
  double? _calculateDistance(
    RouteBin bin,
    latlong.LatLng? currentLocation,
    int binIndex,
  ) {
    // Use straight-line distance
    if (currentLocation == null) return null;

    final distance = latlong.Distance();
    final binLocation = latlong.LatLng(bin.latitude, bin.longitude);

    // Returns distance in meters, convert to kilometers
    return distance.as(
      latlong.LengthUnit.Kilometer,
      currentLocation,
      binLocation,
    );
  }

  /// Calculate ETA in minutes using simple calculation (30 km/h average)
  int? _calculateETA(
    double? distanceKm,
    int binIndex,
  ) {
    // Simple calculation based on distance and average speed
    if (distanceKm == null) {
      // AppLogger.routing('   ❌ No distance available, returning null');
      return null;
    }

    const averageSpeedKmh = 30.0; // City driving speed
    final hours = distanceKm / averageSpeedKmh;
    final minutes = (hours * 60).round();
    // AppLogger.routing('   ⚠️  Using FALLBACK calculation: $minutes min (${distanceKm}km ÷ ${averageSpeedKmh}km/h)');
    return minutes;
  }

  /// Format distance for display (imperial units)
  /// Delegates to GeofenceService for consistent formatting
  String _formatDistance(double? distanceKm) {
    if (distanceKm == null) return 'Calculating...';

    // Convert km to meters and use GeofenceService formatting
    return GeofenceService.formatDistance(distanceKm * 1000);
  }

  /// Format ETA for display
  String _formatETA(int? minutes) {
    if (minutes == null) return '';

    if (minutes < 1) return '< 1 min';
    if (minutes < 60) return '$minutes min';

    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  /// Build skeleton loader widget
  Widget _buildSkeletonLoader({
    required double width,
    required double height,
    double borderRadius = 4.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        );
      },
      onEnd: () {
        // Reverse animation by rebuilding
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false); // Start collapsed for clean UI
    final next = nextBin;
    final locationState = ref.watch(currentLocationProvider);
    final currentLocation = locationState.value != null
        ? latlong.LatLng(
            locationState.value!.latitude,
            locationState.value!.longitude,
          )
        : null;
    final simulationState = ref.watch(simulationNotifierProvider);
    if (next == null) {
      // All bins completed - modal disabled per user request
      // return _buildAllCompleteSheet(context, ref);
      return const SizedBox.shrink(); // Hide the bottom sheet when all bins are done
    }

    // Calculate distance and ETA using straight-line distance
    final nextBinIndex = _getNextBinIndex(next);
    final distanceKm = _calculateDistance(
      next,
      currentLocation,
      nextBinIndex,
    );
    final etaMinutes = _calculateETA(distanceKm, nextBinIndex);

    // Calculate progress percentage
    final progressPercentage = totalBins > 0 ? completedBins / totalBins : 0.0;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        // Swipe down to collapse, swipe up to expand
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 0) {
            // Swiped down
            HapticFeedback.selectionClick();
            isExpanded.value = false;
          } else if (details.primaryVelocity! < 0) {
            // Swiped up
            HapticFeedback.selectionClick();
            isExpanded.value = true;
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            child: isExpanded.value
                ? _buildExpandedContent(
                    context,
                    ref,
                    next,
                    progressPercentage,
                    distanceKm,
                    currentLocation,
                    simulationState,
                    isExpanded,
                    nextBinIndex,
                  )
                : _buildCollapsedContent(
                    context,
                    ref,
                    next,
                    progressPercentage,
                    isExpanded,
                  ),
          ),
        ),
      ),
    );
  }

  /// Build collapsed state - minimal single row (matching screenshot)
  Widget _buildCollapsedContent(
    BuildContext context,
    WidgetRef ref,
    RouteBin next,
    double progressPercentage,
    ValueNotifier<bool> isExpanded,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        isExpanded.value = true;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${next.binNumber}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Address (truncated)
                Expanded(
                  child: Text(
                    next.currentStreet,
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
                    color: Colors.grey.shade300,
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
                // Up arrow
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
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build expanded state - full bin details
  Widget _buildExpandedContent(
    BuildContext context,
    WidgetRef ref,
    RouteBin next,
    double progressPercentage,
    double? distanceKm,
    latlong.LatLng? currentLocation,
    dynamic simulationState,
    ValueNotifier<bool> isExpanded,
    int nextBinIndex,
  ) {
    // Get upcoming bins (next 2-3 bins after current)
    final upcomingBins = _getUpcomingBins(next);
    final showUpNext = useState(true); // Collapsible state

    return Column(
      mainAxisSize: MainAxisSize.min,
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
                '$completedBins of $totalBins complete',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              // Est. finish time badge
              if (googleRemainingTime != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppColors.primaryGreen,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Est. finish: ${_calculateEstimatedFinishTime()}',
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
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  isExpanded.value = false;
                },
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade500,
                  size: 24,
                ),
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
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ),
        ),
        const SizedBox(height: 18),
        // Current bin info (removed divider for cleaner look)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Bin number badge (larger, matching screenshot)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${next.binNumber}',
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Bin info (takes available space)
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Address as title (larger to match screenshot)
                        Text(
                          next.currentStreet,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Badges row (fill % + distance + ETA) in horizontal row
                        Row(
                          children: [
                            // Fill percentage badge with background color matching fill level
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _getFillColor(next.fillPercentage).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${next.fillPercentage}% full',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getFillColor(next.fillPercentage),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Distance badge
                            if (googleTotalDistanceRemaining != null)
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
                                  _formatDistance(googleTotalDistanceRemaining! / 1000),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (googleTotalDistanceRemaining != null)
                              const SizedBox(width: 6),
                            // ETA badge
                            if (googleRemainingTime != null)
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
                                  'ETA ${_formatETA(googleRemainingTime!.inMinutes)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Complete Bin button (simple green button matching screenshot)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // Check proximity before completing
                    final isWithinRange = LocationHelpers.isWithinProximity(
                      userLocation: currentLocation,
                      binLatitude: next.latitude,
                      binLongitude: next.longitude,
                    );

                    if (isWithinRange) {
                      _completeBin(ref, next.binId);
                    } else {
                      // Show snackbar if out of range
                      final distanceMeters = LocationHelpers.getDistanceToBin(
                        userLocation: currentLocation,
                        binLatitude: next.latitude,
                        binLongitude: next.longitude,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Get within 100m to complete (${distanceMeters?.round() ?? 0}m away)',
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.orange.shade700,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50), // Green matching screenshot
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 54),
                  ),
                  child: const Text(
                    'Complete Bin',
                    style: TextStyle(
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
        // Up Next section (Concept 1)
        if (upcomingBins.isNotEmpty) ...[
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              showUpNext.value = !showUpNext.value;
            },
            child: Container(
              color: Colors.transparent,
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
                  const Spacer(),
                  Icon(
                    showUpNext.value
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
          if (showUpNext.value)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: upcomingBins.map((bin) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          // Bin number badge (matching screenshot style)
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
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Address
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
                          // Fill percentage badge with colored background
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getFillColor(bin.fillPercentage).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${bin.fillPercentage}% full',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getFillColor(bin.fillPercentage),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ],
    );
  }

  /// Get upcoming bins (next 2-3 bins after current)
  List<RouteBin> _getUpcomingBins(RouteBin currentBin) {
    final incompleteBins = routeBins
        .where((bin) => bin.isCompleted == 0)
        .toList();
    final currentIndex = incompleteBins.indexWhere(
      (bin) => bin.binId == currentBin.binId,
    );

    if (currentIndex == -1 || currentIndex >= incompleteBins.length - 1) {
      return []; // No upcoming bins
    }

    // Return next 2-3 bins
    final startIndex = currentIndex + 1;
    final endIndex = (startIndex + 3).clamp(0, incompleteBins.length);
    return incompleteBins.sublist(startIndex, endIndex);
  }

  /// Get color based on fill percentage (Option 3: Color coding)
  Color _getFillColor(int fillPercentage) {
    if (fillPercentage > 80) return Colors.red.shade600;
    if (fillPercentage > 50) return Colors.orange.shade600;
    return Colors.blue.shade600;
  }

  /// Calculate estimated finish time based on remaining bins
  /// Uses Google Navigation traffic-aware duration when available
  String _calculateEstimatedFinishTime() {
    final remainingBins = totalBins - completedBins;
    final now = DateTime.now();

    if (remainingBins <= 0) {
      return 'Complete!';
    }

    int estimatedMinutes;

    // Use Google Navigation remaining time (traffic-aware)
    if (googleRemainingTime != null) {
      estimatedMinutes = googleRemainingTime!.inMinutes;
    } else {
      // Fallback: Estimate ~15 minutes per bin
      estimatedMinutes = remainingBins * 15;
    }

    final estimatedFinish = now.add(Duration(minutes: estimatedMinutes));

    // Format as 12-hour time
    final hour = estimatedFinish.hour;
    final minute = estimatedFinish.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period';
  }

  Widget _buildAllCompleteSheet(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'All Bins Collected!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'ve completed all $totalBins bins on this route.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _endShift(ref, context),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('End Shift'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeBin(WidgetRef ref, String binId) async {
    try {
      // Using 50% as placeholder - actual implementation uses check-in dialog
      await ref.read(shiftNotifierProvider.notifier).completeBin(binId, 50);
    } catch (e) {
      // Error will be shown by the provider
    }
  }

  Future<void> _pauseShift(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(shiftNotifierProvider.notifier).pauseShift();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pause shift: $e')));
      }
    }
  }

  Future<void> _endShift(WidgetRef ref, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Shift?'),
        content: const Text(
          'Are you sure you want to end this shift? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('End Shift'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Show loading overlay
      EasyLoading.show(
        status: 'Ending shift...',
        maskType: EasyLoadingMaskType.black,
      );

      try {
        await ref.read(shiftNotifierProvider.notifier).endShift();
        // Loading will auto-dismiss when listener detects status change
      } catch (e) {
        // Dismiss loading on error
        await EasyLoading.dismiss();

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(
            content: Text('Failed to end shift: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }
}
