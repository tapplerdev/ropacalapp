import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/providers/bins_provider.dart';
import 'package:ropacalapp/providers/focused_driver_provider.dart';
import 'package:ropacalapp/providers/potential_locations_list_provider.dart';
import 'package:ropacalapp/providers/focused_potential_location_provider.dart';
import 'package:ropacalapp/models/active_driver.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/models/potential_location.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/features/driver/widgets/circular_map_button.dart';
import 'package:ropacalapp/features/driver/notifications_page.dart';
import 'package:ropacalapp/features/driver/widgets/bin_details_bottom_sheet.dart';
import 'package:ropacalapp/features/manager/widgets/potential_location_bottom_sheet.dart';
import 'package:ropacalapp/core/services/google_navigation_marker_service.dart';
import 'package:ropacalapp/core/services/google_navigation_service.dart';
import 'package:ropacalapp/core/services/marker_animation_service.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';

/// Manager dashboard map showing all active drivers
class ManagerMapPage extends HookConsumerWidget {
  const ManagerMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the focused driver provider
    final focusedDriverState = ref.watch(focusedDriverProvider);
    final focusedDriverId = focusedDriverState.driverId;
    final isFollowing = focusedDriverState.mode == FollowMode.following;

    // Watch the focused potential location provider
    final focusedPotentialLocationState = ref.watch(focusedPotentialLocationProvider);
    final focusedPotentialLocationId = focusedPotentialLocationState.locationId;

    // 🔍 DIAGNOSTIC: Log every build
    AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLogger.general('🏗️ ManagerMapPage.build() CALLED');
    AppLogger.general('   Timestamp: ${DateTime.now().millisecondsSinceEpoch}');

    final driversAsync = ref.watch(driversNotifierProvider);
    AppLogger.general('   🚗 driversAsync: ${driversAsync.runtimeType}, hasValue: ${driversAsync.hasValue}, valueOrNull?.length: ${driversAsync.valueOrNull?.length}');

    final binsAsync = ref.watch(binsListProvider);
    AppLogger.general('   📦 binsAsync: ${binsAsync.runtimeType}, hasValue: ${binsAsync.hasValue}, valueOrNull?.length: ${binsAsync.valueOrNull?.length}');

    final potentialLocationsAsync = ref.watch(potentialLocationsListNotifierProvider);
    AppLogger.general('   📍 potentialLocationsAsync: ${potentialLocationsAsync.runtimeType}, hasValue: ${potentialLocationsAsync.hasValue}, valueOrNull?.length: ${potentialLocationsAsync.valueOrNull?.length}');

    final locationState = ref.watch(currentLocationProvider);
    AppLogger.general('   📍 locationState: ${locationState.runtimeType}, hasValue: ${locationState.hasValue}');

    AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // WAIT for initial data before rendering map (prevents timing issues)
    if (!binsAsync.hasValue || !driversAsync.hasValue) {
      AppLogger.general('⏳ Waiting for initial data...');
      AppLogger.general('   Bins loaded: ${binsAsync.hasValue}');
      AppLogger.general('   Drivers loaded: ${driversAsync.hasValue}');

      return Scaffold(
        appBar: AppBar(
          title: const Text('Manager Dashboard'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading map data...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                binsAsync.hasValue ? '✓ Bins loaded' : '⏳ Loading bins...',
                style: TextStyle(
                  fontSize: 14,
                  color: binsAsync.hasValue ? AppColors.successGreen : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                driversAsync.hasValue ? '✓ Drivers loaded' : '⏳ Loading drivers...',
                style: TextStyle(
                  fontSize: 14,
                  color: driversAsync.hasValue ? AppColors.successGreen : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    AppLogger.general('✅ Initial data loaded - proceeding with map render');

    final mapController = useState<GoogleNavigationViewController?>(null);
    final navigatorInitialized = useState(false);

    // Bin markers (added once, never cleared)
    final binMarkers = useState<List<Marker>>([]);
    final binMarkersMap = useState<Map<String, Bin>>({}); // markerId → Bin

    // Potential location markers (added once, updated when list changes)
    final locationMarkers = useState<List<Marker>>([]);
    final locationMarkersMap = useState<Map<String, PotentialLocation>>({}); // markerId → Location

    // Driver markers (updated at 60fps during animation)
    final driverMarkers = useState<Map<String, Marker>>({}); // driverId → Marker

    // Cache driver marker icons to avoid recreating them
    final cachedDriverIcons = useState<Map<String, ImageDescriptor>>({});

    // Track current driver positions for animation
    final currentDriverPositions = useState<Map<String, LatLng>>({});

    // Track the last programmatic camera target (for detecting manual pan/zoom)
    final lastProgrammaticTarget = useState<LatLng?>(null);

    // Create animation service
    final animationService = useMemoized(
      () => MarkerAnimationService(),
      [],
    );

    // Listen to animation state changes (triggers update loop)
    final hasActiveAnimations = useValueListenable(animationService.animationStateNotifier);

    // Flag to prevent concurrent marker updates
    final isUpdatingMarkers = useState<bool>(false);

    // Initialize Google Maps Navigator BEFORE view creation
    // This prevents SDK 0.8.2 crashes when using GoogleMapsNavigationView without navigation session
    useEffect(() {
      var isMounted = true;

      Future<void> initializeNavigator() async {
        AppLogger.map('🚀 [Manager Map] Initializing navigation session...');

        try {
          await GoogleNavigationService.initializeNavigation(context, ref);
          if (!isMounted) {
            AppLogger.map('⚠️  [Manager Map] Widget disposed during initialization');
            return;
          }

          navigatorInitialized.value = true;
          AppLogger.map('✅ [Manager Map] Navigation session initialized successfully');
        } catch (e) {
          AppLogger.map('❌ [Manager Map] Navigation initialization error: $e');
          // Don't prevent map loading even if initialization fails
          if (isMounted) {
            navigatorInitialized.value = true; // Still allow map to load
          }
        }
      }

      initializeNavigator();

      return () {
        isMounted = false;
      };
    }, []); // Run once on mount

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
                  '   Driver: ${driver.driverName}, Status: ${driver.status}, HasLocation: ${driver.currentLocation != null}',
                );
                if (driver.currentLocation != null) {
                  AppLogger.map(
                    '      Location: (${driver.currentLocation!.latitude}, ${driver.currentLocation!.longitude})',
                  );
                }
              }

              final filtered = drivers
                  .where(
                    (d) =>
                        d.status == ShiftStatus.active && d.currentLocation != null,
                  )
                  .toList();

              AppLogger.map('✅ Filtered to ${filtered.length} active drivers with location');
              return filtered;
            },
            [drivers],
          );

          // Effect 1a: Add/remove bin markers (add new bins, remove deleted bins)
          useEffect(
            () {
              if (binsAsync.hasValue && mapController.value != null) {
                AppLogger.map('🎨 Syncing bin markers with current bin list...');

                () async {
                  try {
                    await binsAsync.whenOrNull(
                      data: (binsList) async {
                        // Filter bins with valid coordinates
                        final validBins = binsList
                            .where((bin) =>
                                bin.latitude != null && bin.longitude != null)
                            .toList();

                        // Get current bin IDs from provider
                        final currentBinIds = validBins.map((b) => b.id).toSet();

                        // Get existing bin IDs that already have markers
                        final existingBinIds = binMarkersMap.value.values.map((b) => b.id).toSet();

                        // Find bins to remove (have markers but not in current list)
                        final binsToRemove = existingBinIds.difference(currentBinIds);

                        // Find new bins that don't have markers yet
                        final newBins = validBins
                            .where((bin) => !existingBinIds.contains(bin.id))
                            .toList();

                        // Remove deleted bin markers
                        if (binsToRemove.isNotEmpty) {
                          AppLogger.map('   🗑️ Removing ${binsToRemove.length} deleted bin markers');

                          // Find markers to remove
                          final markersToRemove = binMarkersMap.value.entries
                              .where((entry) => binsToRemove.contains(entry.value.id))
                              .map((entry) => binMarkers.value.firstWhere(
                                    (marker) => marker.markerId == entry.key,
                                  ))
                              .toList();

                          // Remove from map
                          await mapController.value!.removeMarkers(markersToRemove);

                          // Update state - remove from both lists
                          final updatedMarkers = binMarkers.value
                              .where((marker) => !markersToRemove.contains(marker))
                              .toList();
                          final updatedMarkerMap = Map<String, Bin>.from(binMarkersMap.value);
                          for (final binId in binsToRemove) {
                            updatedMarkerMap.removeWhere((_, bin) => bin.id == binId);
                          }

                          binMarkers.value = updatedMarkers;
                          binMarkersMap.value = updatedMarkerMap;

                          AppLogger.map('   ✅ Removed ${markersToRemove.length} bin markers (remaining: ${updatedMarkers.length})');
                        }

                        if (newBins.isEmpty && binsToRemove.isEmpty) {
                          AppLogger.map('   No changes needed (${validBins.length} total bins, all synced)');
                          return;
                        }

                        if (newBins.isNotEmpty) {
                          AppLogger.map('   ➕ Adding ${newBins.length} new bin markers (${existingBinIds.length} existing)');

                          final binMarkerOptions = <MarkerOptions>[];
                          final binsToAdd = <Bin>[];

                          for (final bin in newBins) {
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
                            binsToAdd.add(bin);
                          }

                          // Add new markers to map
                          final addedMarkers = await mapController.value!.addMarkers(binMarkerOptions);

                          // Filter out nulls
                          final newMarkers = addedMarkers.whereType<Marker>().toList();

                          // Update state by appending new markers to existing ones
                          final updatedMarkers = [...binMarkers.value, ...newMarkers];
                          final updatedMarkerMap = {...binMarkersMap.value};

                          for (int i = 0; i < newMarkers.length; i++) {
                            updatedMarkerMap[newMarkers[i].markerId] = binsToAdd[i];
                          }

                          binMarkers.value = updatedMarkers;
                          binMarkersMap.value = updatedMarkerMap;

                          AppLogger.map('   ✅ Added ${newMarkers.length} new bin markers (total: ${updatedMarkers.length})');
                        }
                      },
                    );
                  } catch (e) {
                    AppLogger.map('❌ Failed to sync bin markers: $e');
                  }
                }();
              }
              return null;
            },
            [binsAsync.hasValue, mapController.value != null, binsAsync],
          );

          // Effect 1b: Add/update potential location markers when provider data changes
          // Extract data directly for dependency tracking
          final potentialLocationsData = potentialLocationsAsync.valueOrNull;
          final potentialLocationsCount = potentialLocationsData?.length ?? 0;

          AppLogger.map('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          AppLogger.map('🔑 LOCATION MARKERS DEPENDENCY CHECK');
          AppLogger.map('   potentialLocationsCount: $potentialLocationsCount');
          AppLogger.map('   Pending locations: ${potentialLocationsData?.where((loc) => loc.convertedToBinId == null).length ?? 0}');
          AppLogger.map('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

          useEffect(
            () {
              if (potentialLocationsAsync.hasValue && mapController.value != null) {
                AppLogger.map('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                AppLogger.map('🔄 POTENTIAL LOCATION MARKERS EFFECT TRIGGERED');
                AppLogger.map('   Provider has value: ${potentialLocationsAsync.hasValue}');
                AppLogger.map('   Map controller exists: ${mapController.value != null}');

                () async {
                  try {
                    final locationMarkerOptions = <MarkerOptions>[];
                    final locations = <PotentialLocation>[];

                    await potentialLocationsAsync.whenOrNull(
                      data: (locationsList) async {
                        AppLogger.map('   Total locations in provider: ${locationsList.length}');

                        // Only show pending locations (not converted ones)
                        final pendingLocations = locationsList
                            .where((loc) =>
                                loc.convertedToBinId == null &&
                                loc.latitude != null &&
                                loc.longitude != null)
                            .toList();

                        AppLogger.map('   Pending locations: ${pendingLocations.length}');
                        AppLogger.map('   Pending IDs: ${pendingLocations.map((l) => l.id).join(", ")}');

                        for (final location in pendingLocations) {
                          // Create custom marker icon
                          final icon = await GoogleNavigationMarkerService
                              .createPotentialLocationMarkerIcon(
                            isPending: true,
                            withPulse: false,
                          );

                          locationMarkerOptions.add(
                            MarkerOptions(
                              position: LatLng(
                                latitude: location.latitude!,
                                longitude: location.longitude!,
                              ),
                              icon: icon,
                              anchor: const MarkerAnchor(u: 0.5, v: 1.0), // Bottom center (pin point)
                              zIndex: 9998.0, // Below bins but above Google markers
                              consumeTapEvents: true,
                              infoWindow: InfoWindow(
                                title: 'Potential Location',
                                snippet: '${location.street}, ${location.city}',
                              ),
                            ),
                          );
                          locations.add(location);
                        }

                        // Remove old location markers if any exist
                        if (locationMarkers.value.isNotEmpty) {
                          AppLogger.map('   🗑️ Removing ${locationMarkers.value.length} old location markers from map');
                          await mapController.value!.removeMarkers(locationMarkers.value);
                          AppLogger.map('   ✅ Old markers removed');
                        }

                        // Add new markers to map
                        AppLogger.map('   ➕ Adding ${locationMarkerOptions.length} new markers to map');
                        final addedMarkers = await mapController.value!.addMarkers(locationMarkerOptions);

                        // Filter out nulls and create markerId → Location map
                        final markers = addedMarkers.whereType<Marker>().toList();
                        final markerMap = <String, PotentialLocation>{};
                        for (int i = 0; i < markers.length; i++) {
                          markerMap[markers[i].markerId] = locations[i];
                        }

                        locationMarkers.value = markers;
                        locationMarkersMap.value = markerMap;

                        AppLogger.map('✅ POTENTIAL LOCATION MARKERS UPDATED');
                        AppLogger.map('   Final marker count: ${markers.length}');
                        AppLogger.map('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                      },
                    );
                  } catch (e) {
                    AppLogger.map('❌ Failed to manage potential location markers: $e');
                  }
                }();
              }
              return null;
            },
            [potentialLocationsCount, mapController.value != null], // Depend on count change!
          );

          // Effect 2: Start animations when driver positions change
          // Create position key to trigger effect when ANY position changes
          final positionKey = activeDrivers.map((d) =>
            '${d.driverId}:${d.currentLocation?.latitude},${d.currentLocation?.longitude}'
          ).join('|');

          useEffect(
            () {
              if (activeDrivers.isEmpty) return null;

              AppLogger.map('🔄 Effect 2: Checking ${activeDrivers.length} drivers for position changes...');

              // Start animations for any changed positions
              for (final driver in activeDrivers) {
                final location = driver.currentLocation!;
                final newPosition = LatLng(
                  latitude: location.latitude,
                  longitude: location.longitude,
                );

                final currentPosition = currentDriverPositions.value[driver.driverId];

                // Start animation if position changed
                if (currentPosition == null ||
                    currentPosition.latitude != newPosition.latitude ||
                    currentPosition.longitude != newPosition.longitude) {

                  AppLogger.map('🎯 Position change detected for ${driver.driverName}!');
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
                  AppLogger.map('   ${driver.driverName}: No position change');
                }
              }

              return null;
            },
            [positionKey], // Depend on position key, not driver list
          );

          // Effect 3: Auto-center camera on focused driver
          // - For focusOnce mode: center once then clear
          // - For following mode: continuously follow driver as they move
          useEffect(
            () {
              if (mapController.value == null || focusedDriverId == null) {
                return null;
              }

              AppLogger.map('🎯 ${isFollowing ? "Following" : "Focusing on"} driver: $focusedDriverId');

              // Find the focused driver's location
              ActiveDriver? focusedDriver;
              try {
                focusedDriver = activeDrivers.firstWhere(
                  (d) => d.driverId == focusedDriverId,
                );
              } catch (e) {
                // Driver not found in active drivers list
                focusedDriver = null;
              }

              if (focusedDriver != null && focusedDriver.currentLocation != null) {
                final location = focusedDriver.currentLocation!;
                final targetPosition = LatLng(
                  latitude: location.latitude,
                  longitude: location.longitude,
                );

                AppLogger.map(
                  '📍 Auto-centering camera to (${location.latitude}, ${location.longitude})',
                );

                // Store this as a programmatic camera movement
                lastProgrammaticTarget.value = targetPosition;

                // Delay to ensure map is fully initialized
                Future.delayed(const Duration(milliseconds: 500), () async {
                  try {
                    await mapController.value?.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: targetPosition,
                          zoom: 16.0, // Slightly closer for following mode
                        ),
                      ),
                    );
                    AppLogger.map('✅ Camera centered on ${isFollowing ? "followed" : "focused"} driver');

                    // If focusOnce mode, clear focus after centering
                    // If following mode, keep following (don't clear)
                    if (!isFollowing) {
                      ref.read(focusedDriverProvider.notifier).clearFocus();
                    }
                  } catch (e) {
                    AppLogger.map('⚠️ Failed to center camera: $e');
                  }
                });
              } else {
                AppLogger.map('⚠️ Focused driver has no location');
              }

              return null;
            },
            // Re-trigger whenever driver location changes (for following mode)
            [
              mapController.value,
              focusedDriverId,
              if (isFollowing)
                activeDrivers.where((d) => d.driverId == focusedDriverId).firstOrNull?.currentLocation,
            ],
          );

          // Effect 3b: Detect manual camera movement and exit following mode
          // Poll camera position every 500ms and compare to programmatic target
          useEffect(
            () {
              if (!isFollowing || mapController.value == null) {
                // Clear target when not following
                if (!isFollowing) {
                  lastProgrammaticTarget.value = null;
                }
                return null;
              }

              AppLogger.map('📷 Starting pan/zoom detection polling...');

              // Delay polling start by 1 second to allow initial camera animation to complete
              // This prevents false positives when first entering following mode
              Timer? pollTimer;
              final startDelay = Timer(const Duration(milliseconds: 1000), () {
                // Poll every 500ms to check if camera position changed
                pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
                try {
                  final currentPosition = await mapController.value?.getCameraPosition();

                  if (currentPosition == null || lastProgrammaticTarget.value == null) {
                    return;
                  }

                  final target = currentPosition.target;
                  final programmaticTarget = lastProgrammaticTarget.value!;

                  // Calculate distance between current position and programmatic target
                  // Using simple lat/lng difference (approximate, good enough for detection)
                  final latDiff = (target.latitude - programmaticTarget.latitude).abs();
                  final lngDiff = (target.longitude - programmaticTarget.longitude).abs();

                  // Thresholds:
                  // - Position: 0.001 degrees (~111 meters at equator, ~76m at Dallas latitude)
                  // - This is sensitive enough to detect panning but won't trigger on minor GPS drift
                  const positionThreshold = 0.001;

                  if (latDiff > positionThreshold || lngDiff > positionThreshold) {
                    AppLogger.map('🚨 Manual pan detected!');
                    AppLogger.map('   Expected: (${programmaticTarget.latitude}, ${programmaticTarget.longitude})');
                    AppLogger.map('   Current: (${target.latitude}, ${target.longitude})');
                    AppLogger.map('   Diff: ($latDiff, $lngDiff)');
                    AppLogger.map('   Exiting following mode...');

                    // User manually panned - exit following mode
                    ref.read(focusedDriverProvider.notifier).stopFollowing();
                  }
                  } catch (e) {
                    // Ignore errors (controller might be disposed)
                    AppLogger.map('⚠️ Pan detection error (expected if map disposed): $e');
                  }
                });
              });

              return () {
                AppLogger.map('📷 Stopping pan/zoom detection polling');
                startDelay.cancel();
                pollTimer?.cancel();
              };
            },
            [isFollowing, mapController.value],
          );

          // Effect 3c: Auto-center camera on focused potential location
          useEffect(
            () {
              if (mapController.value == null || focusedPotentialLocationId == null) {
                return null;
              }

              final potentialLocations = potentialLocationsAsync.valueOrNull ?? [];

              AppLogger.map('🎯 Focusing on potential location: $focusedPotentialLocationId');

              // Find the focused potential location
              PotentialLocation? focusedLocation;
              try {
                focusedLocation = potentialLocations.firstWhere(
                  (loc) => loc.id == focusedPotentialLocationId,
                );
              } catch (e) {
                // Location not found
                focusedLocation = null;
              }

              if (focusedLocation != null &&
                  focusedLocation.latitude != null &&
                  focusedLocation.longitude != null) {
                final targetPosition = LatLng(
                  latitude: focusedLocation.latitude!,
                  longitude: focusedLocation.longitude!,
                );

                AppLogger.map(
                  '📍 Centering camera on potential location at (${focusedLocation.latitude}, ${focusedLocation.longitude})',
                );

                // Delay to ensure map is fully initialized
                Future.delayed(const Duration(milliseconds: 500), () async {
                  try {
                    await mapController.value?.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: targetPosition,
                          zoom: 16.0,
                        ),
                      ),
                    );
                    AppLogger.map('✅ Camera centered on potential location');

                    // Show the bottom sheet for this location
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => PotentialLocationBottomSheet(
                        location: focusedLocation!,
                      ),
                    );

                    // Clear focus after centering
                    ref.read(focusedPotentialLocationProvider.notifier).clearFocus();
                  } catch (e) {
                    AppLogger.map('⚠️ Failed to center camera on potential location: $e');
                  }
                });
              } else {
                AppLogger.map('⚠️ Focused potential location has no coordinates');
              }

              return null;
            },
            [mapController.value, focusedPotentialLocationId],
          );

          // Effect 3a: Manage driver marker lifecycle (add/remove when driver list changes)
          useEffect(
            () {
              if (mapController.value == null) {
                return null;
              }

              // Get list of current driver IDs
              final currentDriverIds = activeDrivers.map((d) => d.driverId).toSet();
              final existingDriverIds = driverMarkers.value.keys.toSet();

              () async {
                try {
                  // Find new drivers (in current but not in existing)
                  final newDriverIds = currentDriverIds.difference(existingDriverIds);

                  // Find removed drivers (in existing but not in current)
                  final removedDriverIds = existingDriverIds.difference(currentDriverIds);

                  // Remove markers for offline drivers
                  if (removedDriverIds.isNotEmpty) {
                    final markersToRemove = removedDriverIds
                        .map((id) => driverMarkers.value[id])
                        .whereType<Marker>()
                        .toList();

                    if (markersToRemove.isNotEmpty) {
                      await mapController.value!.removeMarkers(markersToRemove);
                      AppLogger.map('🗑️ Removed ${markersToRemove.length} offline driver markers');
                    }

                    // Update driver markers map
                    final updatedMap = Map<String, Marker>.from(driverMarkers.value);
                    for (final id in removedDriverIds) {
                      updatedMap.remove(id);
                    }
                    driverMarkers.value = updatedMap;
                  }

                  // Add markers for new drivers
                  if (newDriverIds.isNotEmpty) {
                    final newMarkerOptions = <MarkerOptions>[];
                    final newDriversList = <ActiveDriver>[];

                    for (final driverId in newDriverIds) {
                      final driver = activeDrivers.firstWhere((d) => d.driverId == driverId);
                      final location = driver.currentLocation!;

                      // Create driver icon
                      final icon = await GoogleNavigationMarkerService.createDriverMarkerIcon(
                        driver.driverName,
                        isFocused: false,
                        isPulsing: false,
                      );

                      // Cache the icon
                      cachedDriverIcons.value = {
                        ...cachedDriverIcons.value,
                        driverId: icon,
                      };

                      newMarkerOptions.add(
                        MarkerOptions(
                          position: LatLng(
                            latitude: location.latitude,
                            longitude: location.longitude,
                          ),
                          infoWindow: InfoWindow(
                            title: driver.driverName,
                            snippet: '${driver.completedBins ?? 0}/${driver.totalBins ?? 0} bins completed',
                          ),
                          icon: icon,
                          anchor: const MarkerAnchor(u: 0.5, v: 0.5),
                          flat: true,
                          zIndex: 10000.0,
                        ),
                      );
                      newDriversList.add(driver);
                    }

                    // Add new markers to map
                    final addedMarkers = await mapController.value!.addMarkers(newMarkerOptions);

                    // Store markers with driver IDs
                    final updatedMap = Map<String, Marker>.from(driverMarkers.value);
                    for (int i = 0; i < addedMarkers.length; i++) {
                      final marker = addedMarkers[i];
                      if (marker != null) {
                        updatedMap[newDriversList[i].driverId] = marker;
                      }
                    }
                    driverMarkers.value = updatedMap;

                    AppLogger.map('➕ Added ${addedMarkers.length} new driver markers');
                  }
                } catch (e) {
                  AppLogger.map('❌ Error managing driver markers: $e');
                }
              }();

              return null;
            },
            [activeDrivers.map((d) => d.driverId).join(','), mapController.value],
          );

          // Effect 4: Update driver marker positions at 60fps (using updateMarkers)
          // This only updates positions, never adds/removes markers
          useEffect(
            () {
              if (mapController.value == null || driverMarkers.value.isEmpty) {
                return null;
              }

              AppLogger.map('🔧 Effect 4: Setting up driver position update logic (hasActiveAnimations=$hasActiveAnimations)');

              // Function to update driver marker positions
              Future<void> updateDriverPositions() async {
                // Prevent concurrent updates
                if (isUpdatingMarkers.value) {
                  return;
                }

                try {
                  isUpdatingMarkers.value = true;

                  // Get current positions (either animated or final)
                  final interpolatedPositions = animationService.getInterpolatedPositions();

                  // Create updated markers for each driver
                  final updatedMarkers = <Marker>[];

                  for (final driver in activeDrivers) {
                    final existingMarker = driverMarkers.value[driver.driverId];
                    if (existingMarker == null) continue; // Skip if marker not yet added

                    final location = driver.currentLocation!;
                    final isFocused = driver.driverId == focusedDriverId;

                    // Use interpolated position if animating, otherwise use real position
                    final position = interpolatedPositions[driver.driverId] ??
                        LatLng(
                          latitude: location.latitude,
                          longitude: location.longitude,
                        );

                    // Get or create cached driver icon
                    final isFollowingThisDriver = driver.driverId == focusedDriverId && isFollowing;
                    final cacheKey = isFollowingThisDriver
                        ? '${driver.driverId}_following'
                        : isFocused
                            ? '${driver.driverId}_focused'
                            : driver.driverId;

                    ImageDescriptor? driverIcon = cachedDriverIcons.value[cacheKey];
                    if (driverIcon == null) {
                      AppLogger.map('🎨 Creating ${isFollowingThisDriver ? "FOLLOWING " : isFocused ? "FOCUSED " : ""}icon for driver: ${driver.driverName}');
                      driverIcon = await GoogleNavigationMarkerService.createDriverMarkerIcon(
                        driver.driverName,
                        isFocused: isFocused,
                        isPulsing: isFollowingThisDriver,
                      );
                      cachedDriverIcons.value = {
                        ...cachedDriverIcons.value,
                        cacheKey: driverIcon,
                      };
                    }

                    // Create updated marker with new position/icon
                    final updatedMarker = existingMarker.copyWith(
                      options: MarkerOptions(
                        position: position,
                        infoWindow: InfoWindow(
                          title: driver.driverName,
                          snippet: '${driver.completedBins ?? 0}/${driver.totalBins ?? 0} bins completed',
                        ),
                        icon: driverIcon,
                        anchor: const MarkerAnchor(u: 0.5, v: 0.5),
                        flat: true,
                        zIndex: isFocused ? 10001.0 : 10000.0,
                      ),
                    );
                    updatedMarkers.add(updatedMarker);
                  }

                  // Update only driver markers (bins/locations untouched!)
                  if (updatedMarkers.isNotEmpty) {
                    await mapController.value!.updateMarkers(updatedMarkers);
                  }
                } catch (e) {
                  AppLogger.map('Failed to update driver positions: $e');
                } finally {
                  isUpdatingMarkers.value = false;
                }
              }

              // Use Timer.periodic for 60fps updates when animating
              if (hasActiveAnimations) {
                AppLogger.map('🎬 Starting 60fps timer for driver position updates');

                final timer = Timer.periodic(
                  const Duration(milliseconds: 16), // ~60fps (16ms per frame)
                  (_) {
                    if (!isUpdatingMarkers.value) {
                      updateDriverPositions();
                    }
                  },
                );

                return () {
                  AppLogger.map('🎬 Cancelling timer');
                  timer.cancel();
                };
              } else {
                // No animation - just update once
                AppLogger.map('📍 No animation, updating driver positions once');
                updateDriverPositions();
                return null;
              }
            },
            [
              mapController.value,
              hasActiveAnimations,
              driverMarkers.value.isNotEmpty,
            ],
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
                onMarkerClicked: (markerId) {
                  AppLogger.map('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                  AppLogger.map('🎯 MARKER CLICKED: $markerId');
                  AppLogger.map('   Current bin markers: ${binMarkers.value.length} (IDs: ${binMarkers.value.take(5).map((m) => m.markerId).join(", ")}...)');
                  AppLogger.map('   Current location markers: ${locationMarkers.value.length} (IDs: ${locationMarkers.value.map((m) => m.markerId).join(", ")})');
                  AppLogger.map('   Current driver markers: ${driverMarkers.value.length}');

                  // Direct lookup using stable marker IDs!
                  // Check if it's a bin marker
                  final bin = binMarkersMap.value[markerId];
                  if (bin != null) {
                    AppLogger.map('📦 Bin marker tapped: Bin #${bin.binNumber}');
                    AppLogger.map('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => BinDetailsBottomSheet(bin: bin),
                    );
                    return;
                  }

                  // Check if it's a potential location marker
                  final location = locationMarkersMap.value[markerId];
                  if (location != null) {
                    AppLogger.map('📍 Potential location marker tapped: ${location.street}');
                    AppLogger.map('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => PotentialLocationBottomSheet(
                        location: location,
                      ),
                    );
                    return;
                  }

                  // It's a driver marker - ignore
                  AppLogger.map('   → Driver marker, ignoring');
                  AppLogger.map('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                },
              ),

              // Following driver banner - shown when actively following a driver
              // Clean luxury floating pill design - centered horizontally
              if (isFollowing && focusedDriverId != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 72, // Below notification bell
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white, // Pure white background
                        borderRadius: BorderRadius.circular(100), // Full pill/stadium shape
                        boxShadow: [
                          // Soft, multi-layered shadow for floating effect
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Shrink to content
                        children: [
                          // Custom radar icon with concentric circles
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CustomPaint(
                              painter: _RadarIconPainter(color: AppColors.brandGreen),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Following ${activeDrivers.firstWhere((d) => d.driverId == focusedDriverId, orElse: () => activeDrivers.first).driverName}',
                            style: const TextStyle(
                              color: Color(0xFF333333), // Dark charcoal
                              fontWeight: FontWeight.w600, // Semibold for readability
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Notification button - positioned top-left
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: CircularMapButton(
                  icon: Icons.notifications_outlined,
                  iconColor: AppColors.primaryGreen,
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

              // Potential Locations button - positioned below notification button
              Positioned(
                top: MediaQuery.of(context).padding.top + 72,
                left: 16,
                child: CircularMapButton(
                  icon: Icons.add_location_alt_outlined,
                  iconColor: AppColors.primaryGreen,
                  onTap: () {
                    context.push('/manager/potential-locations');
                  },
                ),
              ),

              // Driver count indicator - tap to view active drivers list
              // Hidden when following mode is active
              // Positioned top-right with pulsing green dot - aligned with notification bell
              if (!isFollowing)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      context.push('/manager/active-drivers');
                    },
                    child: Container(
                      height: 40, // Smaller height for more compact look
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
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
                          // Pulsing green dot with animation
                          _PulsingDot(),
                          const SizedBox(width: 7),
                          Text(
                            '${activeDrivers.length} Active Drivers',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Custom recenter button - positioned bottom-right (above bottom nav)
              Positioned(
                bottom: 100,
                right: 16,
                child: CircularMapButton(
                  icon: Icons.my_location,
                  iconColor: Colors.grey.shade700,
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

/// Custom painter for radar icon with concentric semicircles (upper half only)
class _RadarIconPainter extends CustomPainter {
  final Color color;

  _RadarIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw 3 concentric semicircles (upper half only - radar effect)
    // Use drawArc with sweepAngle of pi (180 degrees) starting from left
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.2),
      3.14159, // Start from left (pi radians)
      3.14159, // Sweep 180 degrees (pi radians) - upper half
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.35),
      3.14159,
      3.14159,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.5),
      3.14159,
      3.14159,
      false,
      paint,
    );

    // Draw center dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.1, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pulsing green dot widget for active drivers indicator
class _PulsingDot extends HookWidget {
  const _PulsingDot();

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 1500),
    );

    // Start pulsing animation on mount
    useEffect(() {
      animationController.repeat(reverse: true);
      return null; // Don't manually dispose - framework handles it
    }, []);

    final animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(
                  alpha: 0.3 + (animation.value * 0.4), // Pulse opacity between 0.3 and 0.7
                ),
                blurRadius: 4 + (animation.value * 4), // Pulse blur between 4 and 8
                spreadRadius: animation.value * 2, // Pulse spread between 0 and 2
              ),
            ],
          ),
        );
      },
    );
  }
}
