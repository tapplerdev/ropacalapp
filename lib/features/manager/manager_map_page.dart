import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/providers/bins_provider.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/features/driver/widgets/circular_map_button.dart';
import 'package:ropacalapp/features/driver/notifications_page.dart';
import 'package:ropacalapp/core/services/google_navigation_marker_service.dart';
import 'package:ropacalapp/core/services/marker_animation_service.dart';

/// Manager dashboard map showing all active drivers
class ManagerMapPage extends HookConsumerWidget {
  const ManagerMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(driversNotifierProvider);
    final binsAsync = ref.watch(binsListProvider);
    final locationState = ref.watch(currentLocationProvider);
    final mapController = useState<GoogleNavigationViewController?>(null);
    final cachedBinMarkers = useState<List<MarkerOptions>?>(null);
    // Cache driver marker icons to avoid recreating them (performance optimization)
    final cachedDriverIcons = useState<Map<String, ImageDescriptor>>({});
    // Track current driver positions for animation
    final currentDriverPositions = useState<Map<String, LatLng>>({});

    // Create animation service
    final animationService = useMemoized(
      () => MarkerAnimationService(),
      [],
    );

    // Listen to animation state changes (triggers update loop)
    final hasActiveAnimations = useValueListenable(animationService.animationStateNotifier);

    // Flag to prevent concurrent marker updates
    final isUpdatingMarkers = useState<bool>(false);

    return Scaffold(
      body: driversAsync.when(
        data: (drivers) {
          // CRITICAL: Use useMemoized to prevent list recreation on every build
          // This was causing Effect 3 to retrigger constantly!
          final activeDrivers = useMemoized(
            () {
              AppLogger.map('🔄 RECALCULATING activeDrivers list');
              AppLogger.map('📊 Manager received ${drivers.length} total drivers');

              for (final driver in drivers) {
                AppLogger.map(
                  '   Driver: ${driver.name}, Status: ${driver.status}, HasLocation: ${driver.lastLocation != null}',
                );
                if (driver.lastLocation != null) {
                  AppLogger.map(
                    '      Location: (${driver.lastLocation!.latitude}, ${driver.lastLocation!.longitude})',
                  );
                }
              }

              final filtered = drivers
                  .where(
                    (d) =>
                        d.status == ShiftStatus.active && d.lastLocation != null,
                  )
                  .toList();

              AppLogger.map('✅ Filtered to ${filtered.length} active drivers with location');
              return filtered;
            },
            [drivers],
          );

          // Effect 1: Cache bin markers ONCE when bins first load
          useEffect(
            () {
              if (binsAsync.hasValue && cachedBinMarkers.value == null) {
                AppLogger.map('🎨 Creating bin markers cache (one-time operation)...');

                () async {
                  try {
                    final binMarkerOptions = <MarkerOptions>[];

                    await binsAsync.whenOrNull(
                      data: (bins) async {
                        // Filter bins with valid coordinates
                        final validBins = bins
                            .where((bin) =>
                                bin.latitude != null && bin.longitude != null)
                            .toList();

                        for (final bin in validBins) {
                          // Create custom bin marker icon
                          final icon =
                              await GoogleNavigationMarkerService.createBinMarkerIcon(
                            bin.binNumber,
                            bin.fillPercentage ?? 0,
                          );

                          binMarkerOptions.add(
                            MarkerOptions(
                              position: LatLng(
                                latitude: bin.latitude!,
                                longitude: bin.longitude!,
                              ),
                              icon: icon,
                              anchor: const MarkerAnchor(u: 0.5, v: 0.5),
                              zIndex: 9999.0,
                              consumeTapEvents: true,
                              infoWindow: InfoWindow(
                                title: 'Bin #${bin.binNumber}',
                                snippet:
                                    '${bin.currentStreet} - ${bin.fillPercentage ?? 0}% full',
                              ),
                            ),
                          );
                        }

                        AppLogger.map('✅ Cached ${validBins.length} bin markers (will reuse for all updates)');
                      },
                    );

                    cachedBinMarkers.value = binMarkerOptions;
                  } catch (e) {
                    AppLogger.map('❌ Failed to cache bin markers: $e');
                  }
                }();
              }
              return null;
            },
            [binsAsync.hasValue],
          );

          // Effect 2: Start animations when driver positions change
          // Create position key to trigger effect when ANY position changes
          final positionKey = activeDrivers.map((d) =>
            '${d.driverId}:${d.lastLocation?.latitude},${d.lastLocation?.longitude}'
          ).join('|');

          useEffect(
            () {
              if (activeDrivers.isEmpty) return null;

              AppLogger.map('🔄 Effect 2: Checking ${activeDrivers.length} drivers for position changes...');

              // Start animations for any changed positions
              for (final driver in activeDrivers) {
                final location = driver.lastLocation!;
                final newPosition = LatLng(
                  latitude: location.latitude,
                  longitude: location.longitude,
                );

                final currentPosition = currentDriverPositions.value[driver.driverId];

                // Start animation if position changed
                if (currentPosition == null ||
                    currentPosition.latitude != newPosition.latitude ||
                    currentPosition.longitude != newPosition.longitude) {

                  AppLogger.map('🎯 Position change detected for ${driver.name}!');
                  if (currentPosition != null) {
                    AppLogger.map('   Old: (${currentPosition.latitude}, ${currentPosition.longitude})');
                  } else {
                    AppLogger.map('   Old: (none - first position)');
                  }
                  AppLogger.map('   New: (${newPosition.latitude}, ${newPosition.longitude})');

                  // Pass heading and accuracy for snap-to-roads (hybrid approach)
                  animationService.animateMarker(
                    driverId: driver.driverId,
                    newPosition: newPosition,
                    currentPosition: currentPosition,
                    heading: location.heading,
                    accuracy: location.accuracy,
                  );

                  // Update stored position
                  currentDriverPositions.value = {
                    ...currentDriverPositions.value,
                    driver.driverId: newPosition,
                  };
                } else {
                  AppLogger.map('   ${driver.name}: No position change');
                }
              }

              return null;
            },
            [positionKey], // Depend on position key, not driver list
          );

          // Effect 3: Update markers (continuously during animation, or once when animation completes)
          // CRITICAL: Only depends on animation state, not activeDrivers positions
          // This prevents constant retriggering on position updates
          useEffect(
            () {
              if (mapController.value == null || cachedBinMarkers.value == null) {
                return null;
              }

              AppLogger.map('🔧 Effect 3: Setting up marker update logic (hasActiveAnimations=$hasActiveAnimations)');

              // Function to update markers on map
              Future<void> updateMarkersOnMap() async {
                // Prevent concurrent updates
                if (isUpdatingMarkers.value) {
                  return;
                }

                try {
                  isUpdatingMarkers.value = true;
                  final allMarkerOptions = <MarkerOptions>[];

                  // Get current positions (either animated or final)
                  final interpolatedPositions = animationService.getInterpolatedPositions();

                  // IMPORTANT: Get activeDrivers from current state, not from dependency
                  // This allows us to get latest driver data without retriggering effect
                  for (final driver in activeDrivers) {
                    final location = driver.lastLocation!;

                    // Use interpolated position if animating, otherwise use real position
                    final position = interpolatedPositions[driver.driverId] ??
                        LatLng(
                          latitude: location.latitude,
                          longitude: location.longitude,
                        );

                    // Get or create cached driver icon
                    ImageDescriptor? driverIcon = cachedDriverIcons.value[driver.driverId];
                    if (driverIcon == null) {
                      AppLogger.map('🎨 Creating new icon for driver: ${driver.name}');
                      driverIcon = await GoogleNavigationMarkerService
                          .createDriverMarkerIcon(driver.name);
                      cachedDriverIcons.value = {
                        ...cachedDriverIcons.value,
                        driver.driverId: driverIcon,
                      };
                    }

                    allMarkerOptions.add(
                      MarkerOptions(
                        position: position,
                        infoWindow: InfoWindow(
                          title: driver.name,
                          snippet:
                              '${driver.currentBin ?? 0}/${driver.totalBins ?? 0} bins completed',
                        ),
                        icon: driverIcon,
                        anchor: const MarkerAnchor(u: 0.5, v: 0.5),
                        flat: true,
                        zIndex: 10000.0,
                      ),
                    );
                  }

                  // Reuse cached bin markers
                  allMarkerOptions.addAll(cachedBinMarkers.value!);

                  // Update map (this is called at 60fps during animation)
                  await mapController.value!.clearMarkers();
                  await mapController.value!.addMarkers(allMarkerOptions);
                } catch (e) {
                  AppLogger.map('Failed to update markers: $e');
                } finally {
                  isUpdatingMarkers.value = false;
                }
              }

              // Use Timer.periodic for 60fps updates when animating
              if (hasActiveAnimations) {
                AppLogger.map('🎬 Starting 60fps timer for marker updates');

                final timer = Timer.periodic(
                  const Duration(milliseconds: 16), // ~60fps (16ms per frame)
                  (_) {
                    if (!isUpdatingMarkers.value) {
                      updateMarkersOnMap();
                    }
                  },
                );

                return () {
                  AppLogger.map('🎬 Cancelling timer');
                  timer.cancel();
                };
              } else {
                // No animation - just update once
                AppLogger.map('📍 No animation, updating markers once');
                updateMarkersOnMap();
                return null;
              }
            },
            // CRITICAL: Don't depend on activeDrivers! Only animation state matters.
            // activeDrivers is captured in closure and will always have latest value
            [cachedBinMarkers.value, mapController.value, hasActiveAnimations],
          );

          return Stack(
            children: [
              // Google Navigation Map View
              GoogleMapsNavigationView(
                key: const ValueKey('fleet_map'),
                initialCameraPosition: const CameraPosition(
                  target: LatLng(latitude: 32.886534, longitude: -96.7642497), // Dallas
                  zoom: 12,
                ),
                initialZoomControlsEnabled: false,
                onViewCreated: (controller) async {
                  mapController.value = controller;
                  AppLogger.map('Manager fleet map created');

                  // Enable MyLocation to show manager's current location (blue dot)
                  await controller.setMyLocationEnabled(true);

                  // Disable navigation UI elements
                  await controller.setNavigationHeaderEnabled(false);
                  await controller.setNavigationFooterEnabled(false);
                  await controller.setRecenterButtonEnabled(false);

                  // Disable Google's native My Location button (use our custom one instead)
                  await controller.settings.setMyLocationButtonEnabled(false);
                },
              ),

              // Driver count indicator
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_shipping,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${activeDrivers.length} active drivers',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Notification button - positioned top-right
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: CircularMapButton(
                  icon: Icons.notifications_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsPage(),
                      ),
                    );
                  },
                ),
              ),

              // Custom recenter button - positioned bottom-right (above bottom nav)
              Positioned(
                bottom: 100,
                right: 16,
                child: CircularMapButton(
                  icon: Icons.my_location,
                  onTap: () async {
                    final location = locationState.valueOrNull;
                    if (location != null && mapController.value != null) {
                      try {
                        await mapController.value!.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: LatLng(
                                latitude: location.latitude,
                                longitude: location.longitude,
                              ),
                              zoom: 15.0,
                            ),
                          ),
                        );
                        AppLogger.map('📍 Recentered map to current location');
                      } catch (e) {
                        AppLogger.map(
                          'Recenter skipped - controller disposed',
                        );
                      }
                    }
                  },
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
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading drivers: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(driversNotifierProvider.notifier).refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
