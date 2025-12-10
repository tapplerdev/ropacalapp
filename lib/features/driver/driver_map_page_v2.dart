import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/utils/bin_helpers.dart';
import 'package:ropacalapp/providers/bins_provider.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/providers/bin_marker_cache_provider.dart';
import 'package:ropacalapp/features/driver/widgets/alerts_bottom_sheet.dart';
import 'package:ropacalapp/features/driver/widgets/bin_details_bottom_sheet.dart';
import 'package:ropacalapp/features/driver/widgets/route_summary_card.dart';

/// V2 Design: DoorDash-inspired clean, modern interface
/// Key differences from V1:
/// - Larger, card-based stats overlay with better hierarchy
/// - Bottom action bar instead of scattered FABs
/// - More prominent "Start Route" CTA
/// - Cleaner visual design with better spacing
class DriverMapPageV2 extends HookConsumerWidget {
  const DriverMapPageV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final binsState = ref.watch(binsListProvider);
    final locationState = ref.watch(currentLocationProvider);
    final mapController = useState<GoogleMapController?>(null);
    final markers = useState<Set<Marker>>({});
    final selectedBin = useState<dynamic>(null);
    final showRouteCard = useState(false);

    // Generate markers when bins load
    useEffect(() {
      binsState.whenData((bins) {
        if (bins != null && bins.isNotEmpty && mapController.value != null) {
          final newMarkers = <Marker>{};

          for (var bin in bins) {
            if (bin.latitude != null && bin.longitude != null) {
              final customIcon = ref
                  .read(binMarkerCacheNotifierProvider.notifier)
                  .getBinMarker(bin.id);

              newMarkers.add(
                Marker(
                  markerId: MarkerId('bin_${bin.id}'),
                  position: LatLng(bin.latitude!, bin.longitude!),
                  icon: customIcon ?? MarkerIcon.defaultMarker,
                  onTap: () {
                    selectedBin.value = bin;
                  },
                ),
              );
            }
          }

          markers.value = newMarkers;
          AppLogger.map('Generated ${newMarkers.length} bin markers (V2)');
        }
      });
      return null;
    }, [binsState]);

    return Scaffold(
      body: binsState.when(
        data: (bins) {
          if (bins == null || bins.isEmpty) {
            return const Center(child: Text('No bins available'));
          }

          // Calculate stats
          final stats = BinHelpers.calculateFillStats(bins);
          final highFillBins = bins
              .where(
                (b) =>
                    (b.fillPercentage ?? 0) >
                    BinConstants.criticalFillThreshold,
              )
              .toList();

          return Stack(
            children: [
              // Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: locationState.value != null
                      ? LatLng(
                          locationState.value!.latitude,
                          locationState.value!.longitude,
                        )
                      : const LatLng(37.7749, -122.4194), // SF default
                  zoom: 14,
                ),
                onMapCreated: (controller) {
                  mapController.value = controller;
                  AppLogger.map('Map created (V2)');
                },
                markers: markers.value,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
              ),

              // V2 Design: Large stats card at top with better hierarchy
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: _StatsCardV2(
                  totalBins: bins.length,
                  activeBins: stats.high + stats.medium,
                  highFillCount: stats.high,
                  onNotificationTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          AlertsBottomSheet(bins: highFillBins),
                    );
                  },
                ),
              ),

              // V2: Bottom action bar (instead of scattered FABs)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _BottomActionBar(
                  onStartRoute: () {
                    showRouteCard.value = true;
                  },
                  onViewList: () {
                    // Navigate to bins list
                  },
                  onRecenter: () {
                    final location = locationState.value;
                    if (location != null && mapController.value != null) {
                      try {
                        mapController.value!.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: LatLng(
                                location.latitude,
                                location.longitude,
                              ),
                              zoom: 15.0,
                            ),
                          ),
                        );
                      } catch (e) {
                        AppLogger.map(
                          'Recenter skipped - controller disposed',
                          level: AppLogger.debug,
                        );
                      }
                    }
                  },
                ),
              ),

              // Route summary card (slides up when triggered)
              if (showRouteCard.value)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: RouteSummaryCard(
                    routeBins: bins,
                    ref: ref,
                    onClearRoute: () => showRouteCard.value = false,
                    currentLocation: locationState.value != null
                        ? latlong.LatLng(
                            locationState.value!.latitude,
                            locationState.value!.longitude,
                          )
                        : null,
                  ),
                ),

              // Bin details bottom sheet
              if (selectedBin.value != null)
                GestureDetector(
                  onTap: () => selectedBin.value = null,
                  child: Container(
                    color: Colors.black26,
                    child: GestureDetector(
                      onTap: () {}, // Prevent tap from bubbling
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: BinDetailsBottomSheet(bin: selectedBin.value!),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading bins: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(binsListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// V2 Stats Card: Larger, more prominent with better visual hierarchy
class _StatsCardV2 extends StatelessWidget {
  final int totalBins;
  final int activeBins;
  final int highFillCount;
  final VoidCallback onNotificationTap;

  const _StatsCardV2({
    required this.totalBins,
    required this.activeBins,
    required this.highFillCount,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today\'s Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: onNotificationTap,
                      color: AppColors.primaryBlue,
                    ),
                    if (highFillCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.alertRed,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            highFillCount > 9 ? '9+' : '$highFillCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Stats grid
          Container(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Row(
              children: [
                Expanded(
                  child: _StatItemV2(
                    icon: Icons.delete_outline,
                    value: '$totalBins',
                    label: 'Total',
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatItemV2(
                    icon: Icons.check_circle_outline,
                    value: '$activeBins',
                    label: 'Active',
                    color: AppColors.successGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatItemV2(
                    icon: Icons.warning_amber_rounded,
                    value: '$highFillCount',
                    label: 'High Fill',
                    color: AppColors.alertRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItemV2 extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItemV2({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// V2 Bottom Action Bar: DoorDash-style bottom actions
class _BottomActionBar extends StatelessWidget {
  final VoidCallback onStartRoute;
  final VoidCallback onViewList;
  final VoidCallback onRecenter;

  const _BottomActionBar({
    required this.onStartRoute,
    required this.onViewList,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Row(
        children: [
          // Secondary actions
          IconButton(
            onPressed: onRecenter,
            icon: const Icon(Icons.my_location),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: onViewList,
            icon: const Icon(Icons.list),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),

          // Primary CTA: Start Route
          Expanded(
            child: ElevatedButton(
              onPressed: onStartRoute,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.navigation, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Start Route',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
