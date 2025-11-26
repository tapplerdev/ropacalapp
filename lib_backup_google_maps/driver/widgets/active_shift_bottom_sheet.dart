import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/enums/bin_status.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/providers/simulation_provider.dart';
import 'package:ropacalapp/core/services/osrm_service.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/utils/location_helpers.dart';
import 'package:ropacalapp/providers/here_route_provider.dart';

/// Bottom sheet showing active shift navigation
class ActiveShiftBottomSheet extends HookConsumerWidget {
  final List<RouteBin> routeBins;
  final int completedBins;
  final int totalBins;
  final VoidCallback? onNavigateToNextBin;
  final List<latlong.LatLng>?
  preComputedPolyline; // Optional pre-fetched polyline (e.g., from HERE Maps)

  const ActiveShiftBottomSheet({
    super.key,
    required this.routeBins,
    required this.completedBins,
    required this.totalBins,
    this.onNavigateToNextBin,
    this.preComputedPolyline,
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

  /// Calculate distance to next bin in kilometers
  /// Uses HERE Maps data if available, falls back to straight-line distance
  double? _calculateDistance(
    RouteBin bin,
    latlong.LatLng? currentLocation,
    HereRouteData? hereData,
    int binIndex,
  ) {
    // Try to use HERE Maps distance first
    if (hereData != null && binIndex >= 0) {
      final distanceMeters = hereData.getDistanceToBin(binIndex);
      if (distanceMeters != null) {
        return distanceMeters / 1000; // Convert meters to kilometers
      }
    }

    // Fallback to straight-line distance
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

  /// Calculate ETA in minutes
  /// Uses HERE Maps traffic-aware duration if available,
  /// falls back to simple calculation (30 km/h average)
  int? _calculateETA(
    double? distanceKm,
    HereRouteData? hereData,
    int binIndex,
  ) {
    // AppLogger.routing('🔍 _calculateETA called:');
    // AppLogger.routing('   binIndex: $binIndex');
    // AppLogger.routing('   distanceKm: $distanceKm');
    // AppLogger.routing('   hereData available: ${hereData != null}');

    // Try to use HERE Maps duration first (traffic-aware)
    if (hereData != null && binIndex >= 0) {
      // AppLogger.routing('   HERE Maps data found, attempting to get ETA...');
      final durationSeconds = hereData.getEtaToBin(binIndex);
      // AppLogger.routing('   durationSeconds from HERE: $durationSeconds');

      if (durationSeconds != null) {
        final minutes = (durationSeconds / 60).round();
        // AppLogger.routing('   ✅ Using HERE Maps ETA: $minutes min');
        return minutes;
      } else {
        // AppLogger.routing('   ⚠️  HERE Maps returned null duration for binIndex $binIndex');
      }
    }

    // Fallback to simple calculation
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

  /// Format distance for display
  String _formatDistance(double? distanceKm) {
    if (distanceKm == null) return 'Calculating...';

    if (distanceKm < 1) {
      // Show in meters if less than 1 km
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
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
    final hereRouteData = ref.watch(hereRouteMetadataProvider);

    // Debug: Log what data we have when building
    // AppLogger.routing('🏗️  ActiveShiftBottomSheet.build():');
    // AppLogger.routing('   hereRouteData: ${hereRouteData != null ? "Available" : "NULL"}');
    if (hereRouteData != null) {
      // AppLogger.routing('   - totalDuration: ${hereRouteData.totalDuration}s (${(hereRouteData.totalDuration / 60).toStringAsFixed(1)} min)');
      // AppLogger.routing('   - legDurations: ${hereRouteData.legDurations.length} legs');
    }

    if (next == null) {
      // All bins completed
      return _buildAllCompleteSheet(context, ref);
    }

    // Calculate distance and ETA using HERE Maps data if available
    final nextBinIndex = _getNextBinIndex(next);
    final distanceKm = _calculateDistance(
      next,
      currentLocation,
      hereRouteData,
      nextBinIndex,
    );
    final etaMinutes = _calculateETA(distanceKm, hereRouteData, nextBinIndex);

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
              color: Colors.black.withOpacity(0.08),
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
                    hereRouteData,
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

  /// Build collapsed state - compact bar with timer (Concept A)
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Status indicator (green dot)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                // Bin number badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${next.binNumber}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Truncated address
                Expanded(
                  child: Text(
                    next.currentStreet,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Progress count badge (removed redundant percentage)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$completedBins/$totalBins',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Timer badge
                Consumer(
                  builder: (context, ref, _) {
                    final duration = ref
                        .read(shiftNotifierProvider.notifier)
                        .getActiveShiftDuration();
                    final hours = duration.inHours;
                    final minutes = duration.inMinutes.remainder(60);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Up arrow indicator
                Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.grey.shade400,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar (8px for better visibility when collapsed)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressPercentage,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
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
    HereRouteData? hereRouteData,
    int nextBinIndex,
  ) {
    // Get upcoming bins (next 2-3 bins after current)
    final upcomingBins = _getUpcomingBins(next);
    final showUpNext = useState(true); // Collapsible state

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress header with estimated finish time
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              // Bin count
              Text(
                'Bin $completedBins of $totalBins',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              // Estimated finish time - full skeleton when loading
              if (hereRouteData == null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.grey.shade300,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      _buildSkeletonLoader(
                        width: 85,
                        height: 12,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppColors.primaryBlue,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Est. finish: ${_calculateEstimatedFinishTime(hereRouteData)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              // Down arrow to collapse
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  isExpanded.value = false;
                },
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        // Progress bar (increased from 3px to 6px)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progressPercentage,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Current bin info (removed divider for cleaner look)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Bin number badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${next.binNumber}',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                        // Address as title
                        Text(
                          next.currentStreet,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Chips row (fill % + distance + ETA) - compact spacing
                        Wrap(
                          spacing: 3,
                          runSpacing: 4,
                          children: [
                            // Fill percentage badge (always shown)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getFillColor(
                                  next.fillPercentage,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${next.fillPercentage}% full',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _getFillColor(next.fillPercentage),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Distance badge - full skeleton when loading
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: hereRouteData == null
                                  ? _buildSkeletonLoader(
                                      width: 45,
                                      height: 14,
                                      borderRadius: 4,
                                    )
                                  : Text(
                                      _formatDistance(distanceKm),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                            // ETA badge - full skeleton when loading
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: hereRouteData == null
                                  ? _buildSkeletonLoader(
                                      width: 55,
                                      height: 14,
                                      borderRadius: 4,
                                    )
                                  : Text(
                                      'ETA ${_formatETA(_calculateETA(distanceKm, hereRouteData, nextBinIndex))}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // TESTING: Play/Pause button
                  IconButton(
                    onPressed: () async {
                      if (simulationState.isSimulating) {
                        ref
                            .read(simulationNotifierProvider.notifier)
                            .stopSimulation();
                        return;
                      }

                      try {
                        List<latlong.LatLng> polyline;

                        // Use pre-computed polyline if available (e.g., from HERE Maps)
                        if (preComputedPolyline != null &&
                            preComputedPolyline!.isNotEmpty) {
                          AppLogger.navigation(
                            '🗺️  Using pre-computed polyline (HERE Maps)',
                          );
                          polyline = preComputedPolyline!;
                          AppLogger.navigation(
                            '✅ Got HERE Maps route: ${polyline.length} pts',
                          );
                        } else {
                          // Fall back to OSRM
                          AppLogger.navigation(
                            '🎮 Fetching OSRM route for simulation...',
                          );
                          final location = currentLocation;
                          if (location == null) {
                            AppLogger.navigation('❌ No location available');
                            return;
                          }

                          final bins = routeBins
                              .map(
                                (rb) => Bin(
                                  id: rb.binId,
                                  binNumber: rb.binNumber,
                                  currentStreet: rb.currentStreet,
                                  city: rb.city,
                                  zip: rb.zip,
                                  latitude: rb.latitude,
                                  longitude: rb.longitude,
                                  fillPercentage: rb.fillPercentage,
                                  status: BinStatus.active,
                                  lastMoved: null,
                                  lastChecked: null,
                                  checked: false,
                                  moveRequested: false,
                                ),
                              )
                              .toList();

                          final osrmService = OSRMService();
                          final routeResponse = await osrmService.getRoute(
                            start: location,
                            destinations: bins,
                          );

                          polyline = osrmService.getRoutePolyline(
                            routeResponse,
                          );
                          if (polyline.isEmpty) {
                            AppLogger.navigation('❌ No polyline returned');
                            return;
                          }

                          AppLogger.navigation(
                            '✅ Got OSRM route: ${polyline.length} pts',
                          );
                        }

                        ref
                            .read(simulationNotifierProvider.notifier)
                            .startSimulation(polyline);
                      } catch (e) {
                        AppLogger.navigation('❌ Failed to fetch route: $e');
                      }
                    },
                    icon: Icon(
                      simulationState.isSimulating
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: AppColors.primaryBlue,
                      size: 22,
                    ),
                    tooltip: simulationState.isSimulating ? 'Stop' : 'Start',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 12),
                  // Overflow menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey.shade600,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'pause') {
                        _pauseShift(ref, context);
                      } else if (value == 'end') {
                        _endShift(ref, context);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pause',
                        child: Row(
                          children: [
                            Icon(
                              Icons.pause_circle_outline,
                              color: Colors.grey.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text('Pause Shift'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'end',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.stop_circle_outlined,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'End Shift',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Complete Bin button with proximity check
              SizedBox(
                width: double.infinity,
                child: Builder(
                  builder: (context) {
                    // Check if user is within 100m of the bin
                    final isWithinRange = LocationHelpers.isWithinProximity(
                      userLocation: currentLocation,
                      binLatitude: next.latitude,
                      binLongitude: next.longitude,
                    );

                    // Get current distance to bin
                    final distanceMeters = LocationHelpers.getDistanceToBin(
                      userLocation: currentLocation,
                      binLatitude: next.latitude,
                      binLongitude: next.longitude,
                    );

                    return Column(
                      children: [
                        // Distance indicator (shown when out of range)
                        if (!isWithinRange && distanceMeters != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Get within 100m to complete (${distanceMeters.round()}m away)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Complete button
                        ElevatedButton(
                          onPressed: isWithinRange
                              ? () {
                                  HapticFeedback.lightImpact();
                                  _completeBin(ref, next.binId);
                                }
                              : null, // Disabled when out of range
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isWithinRange
                                ? Colors.green
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 48),
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade600,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!isWithinRange)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(Icons.lock, size: 18),
                                ),
                              Text(
                                isWithinRange ? 'Complete Bin' : 'Too Far Away',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
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
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          // Bin number badge (smaller)
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${bin.binNumber}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Address
                          Expanded(
                            child: Text(
                              bin.currentStreet,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Fill percentage chip (color-coded for urgency)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getFillColor(
                                bin.fillPercentage,
                              ).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${bin.fillPercentage}% full',
                              style: TextStyle(
                                fontSize: 11,
                                color: _getFillColor(bin.fillPercentage),
                                fontWeight: FontWeight.w600,
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
  /// Uses HERE Maps traffic-aware durations if available,
  /// falls back to simple 15 min/bin estimate
  String _calculateEstimatedFinishTime(HereRouteData? hereData) {
    final remainingBins = totalBins - completedBins;
    final now = DateTime.now();

    // AppLogger.routing('🔍 _calculateEstimatedFinishTime called:');
    // AppLogger.routing('   Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
    // AppLogger.routing('   Remaining bins: $remainingBins');
    // AppLogger.routing('   hereData available: ${hereData != null}');

    if (remainingBins <= 0) {
      // AppLogger.routing('   ✅ All bins completed');
      return 'Complete!';
    }

    int estimatedMinutes;

    // Try to use HERE Maps total duration (traffic-aware)
    if (hereData != null && hereData.totalDuration > 0) {
      // Use total duration from HERE Maps (already accounts for traffic)
      estimatedMinutes = (hereData.totalDuration / 60).round();
      // AppLogger.routing('   ✅ Using HERE Maps totalDuration: ${hereData.totalDuration}s = $estimatedMinutes min');
    } else {
      // Fallback: Estimate ~15 minutes per bin
      estimatedMinutes = remainingBins * 15;
      // AppLogger.routing('   ⚠️  Using FALLBACK: $remainingBins bins × 15 min = $estimatedMinutes min');
    }

    final estimatedFinish = now.add(Duration(minutes: estimatedMinutes));

    // Format as 12-hour time
    final hour = estimatedFinish.hour;
    final minute = estimatedFinish.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    final result = '$displayHour:$minute $period';
    // AppLogger.routing('   📅 Estimated finish: $result (now + $estimatedMinutes min)');

    return result;
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
                    foregroundColor: Colors.white,
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
        color: color.withOpacity(0.1),
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
      await ref.read(shiftNotifierProvider.notifier).completeBin(binId);
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
              foregroundColor: Colors.white,
            ),
            child: const Text('End Shift'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(shiftNotifierProvider.notifier).endShift();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to end shift: $e')));
        }
      }
    }
  }
}
