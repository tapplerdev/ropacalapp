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
import 'package:ropacalapp/models/potential_location.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/features/driver/widgets/circular_map_button.dart';
import 'package:ropacalapp/features/driver/notifications_page.dart';
import 'package:ropacalapp/features/driver/widgets/bin_details_bottom_sheet.dart';
import 'package:ropacalapp/features/manager/widgets/potential_location_bottom_sheet.dart';
import 'package:ropacalapp/core/services/google_navigation_marker_service.dart';
import 'package:ropacalapp/core/services/marker_animation_service.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/services/centrifugo_service.dart';
import 'package:ropacalapp/providers/centrifugo_provider.dart';
import 'package:ropacalapp/models/driver_location.dart';
import 'package:ropacalapp/features/manager/widgets/map_search_bar.dart';
import 'package:ropacalapp/features/manager/widgets/map_layers_control.dart';
import 'package:ropacalapp/providers/warehouse_provider.dart';
import 'package:ropacalapp/providers/driver_live_position_provider.dart';
import 'package:ropacalapp/providers/route_polyline_provider.dart';
import 'package:ropacalapp/features/manager/widgets/driver_floating_card.dart';

/// Manager dashboard map showing all active drivers
///
/// Uses standard Google Maps view (GoogleMapsMapView) since managers never need navigation.
/// Drivers use GoogleMapsNavigationView when on active shifts via DriverMapWrapper.
class ManagerMapPage extends HookConsumerWidget {
  const ManagerMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the focused driver provider
    final focusedDriverState = ref.watch(focusedDriverProvider);
    final focusedDriverId = focusedDriverState.driverId;
    final isFollowing = focusedDriverState.mode == FollowMode.following;
    final isFocusedOrFollowing = focusedDriverState.mode != FollowMode.none;

    // Watch the focused potential location provider
    final focusedPotentialLocationState = ref.watch(focusedPotentialLocationProvider);
    final focusedPotentialLocationId = focusedPotentialLocationState.locationId;

    final driversAsync = ref.watch(driversNotifierProvider);
    final binsAsync = ref.watch(binsListProvider);
    final potentialLocationsAsync = ref.watch(potentialLocationsListNotifierProvider);
    final locationState = ref.watch(currentLocationProvider);
    final warehouseAsync = ref.watch(warehouseLocationNotifierProvider);

    // WAIT for initial data before rendering map (prevents timing issues)
    if (!binsAsync.hasValue || !driversAsync.hasValue) {

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

    // Initial data loaded - proceed with map render

    final mapController = useState<GoogleMapViewController?>(null);

    // Bin markers (added once, never cleared)
    final binMarkers = useState<List<Marker>>([]);
    final binMarkersMap = useState<Map<String, Bin>>({}); // markerId → Bin

    // Potential location markers (added once, updated when list changes)
    final locationMarkers = useState<List<Marker>>([]);
    final locationMarkersMap = useState<Map<String, PotentialLocation>>({}); // markerId → Location

    // Warehouse marker (single marker, added once)
    final warehouseMarker = useState<Marker?>(null);

    // Driver markers (updated at 60fps during animation)
    final driverMarkers = useState<Map<String, Marker>>({}); // driverId → Marker

    // Layer visibility
    final layerVisibility = useState(const MapLayerVisibility());

    // Track current driver positions and headings for animation
    final currentDriverPositions = useState<Map<String, LatLng>>({});
    final currentDriverHeadings = useState<Map<String, double>>({});

    // Guard to suppress gesture-exit during programmatic camera moves
    final isProgrammaticMove = useState<bool>(false);

    // Route polyline visibility (user toggles via "Route" button on card)
    final isRouteVisible = useState<bool>(false);

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
          // Use useMemoized to prevent list recreation on every build
          final activeDrivers = useMemoized(
            () {
              // Show all drivers with location regardless of status (for testing)
              // TODO: Revert to: d.status == ShiftStatus.active && d.currentLocation != null
              return drivers
                  .where((d) => d.currentLocation != null)
                  .toList();
            },
            [drivers],
          );

          // Centrifugo connection status (from global CentrifugoManager)
          // Watch the provider to rebuild when connection state changes,
          // then read .isConnected from the notifier for the actual flag.
          ref.watch(centrifugoManagerProvider);
          final isCentrifugoConnected = ref.read(centrifugoManagerProvider.notifier).isConnected;

          // Search bar expanded state
          final isSearchExpanded = useState<bool>(false);

          // Seed currentDriverPositions from API data on first mount
          // This ensures follow mode has a starting position before Centrifugo updates arrive.
          // Without this, currentDriverPositions is empty and follow mode falls back to
          // the provider's currentLocation which never updates after the flashing fix.
          useEffect(() {
            final initialPositions = <String, LatLng>{};
            for (final driver in activeDrivers) {
              if (driver.currentLocation != null) {
                initialPositions[driver.driverId] = LatLng(
                  latitude: driver.currentLocation!.latitude,
                  longitude: driver.currentLocation!.longitude,
                );
              }
            }
            if (initialPositions.isNotEmpty) {
              currentDriverPositions.value = initialPositions;
              AppLogger.map('🌱 SEED: Pre-populated ${initialPositions.length} driver positions from API data');
              for (final entry in initialPositions.entries) {
                AppLogger.map('   📍 ${entry.key}: (${entry.value.latitude}, ${entry.value.longitude})');
              }
            }
            return null;
          }, []); // Only on first mount

          // Effect -1 REMOVED: Connection is now managed exclusively by
          // CentrifugoManager (centrifugo_provider.dart) which watches auth state.
          // This eliminates the dual-connection race condition.

          // Effect 0: Subscribe to driver locations via Centrifugo
          // Handles location updates directly: updates provider (first fix only),
          // starts marker animations, and tracks current positions.
          // Depends on CentrifugoManager.isConnected (via centrifugoManagerProvider).
          useEffect(
            () {
              // Wait for CentrifugoManager to establish connection
              if (!isCentrifugoConnected) {
                AppLogger.map('📡 CENTRIFUGO: Waiting for CentrifugoManager connection...');
                return null;
              }

              AppLogger.map('📡 CENTRIFUGO: Setting up subscriptions for ${drivers.length} drivers');

              final centrifugo = ref.read(centrifugoServiceProvider);
              final subscriptions = <StreamSubscription>[];

              for (final driver in drivers) {
                centrifugo.subscribeToDriverLocation(
                    driver.driverId,
                    (locationData) {
                      try {
                        final location = DriverLocation(
                          driverId: locationData['driver_id'] ?? driver.driverId,
                          latitude: (locationData['latitude'] as num).toDouble(),
                          longitude: (locationData['longitude'] as num).toDouble(),
                          heading: (locationData['heading'] as num?)?.toDouble(),
                          speed: (locationData['speed'] as num?)?.toDouble(),
                          accuracy: (locationData['accuracy'] as num?)?.toDouble(),
                          shiftId: locationData['shift_id'] as String?,
                          timestamp: locationData['timestamp'] as int?,
                        );

                        // Update provider (only triggers state change on first location)
                        ref.read(driversNotifierProvider.notifier)
                            .updateDriverLocation(location);

                        // Feed the live-position store (used by polyline trimming)
                        ref.read(driverLivePositionsProvider.notifier)
                            .updatePosition(location);

                        // Start marker animation directly (bypass provider rebuild chain)
                        final newPos = LatLng(
                          latitude: location.latitude,
                          longitude: location.longitude,
                        );
                        final driverId = location.driverId ?? driver.driverId;
                        final currentPos = currentDriverPositions.value[driverId];

                        if (currentPos == null ||
                            currentPos.latitude != newPos.latitude ||
                            currentPos.longitude != newPos.longitude) {
                          AppLogger.map('📡 LIVE UPDATE: ${driverId} → (${newPos.latitude}, ${newPos.longitude}) [prev: ${currentPos != null ? "(${currentPos.latitude}, ${currentPos.longitude})" : "NONE"}]');
                          animationService.animateMarker(
                            driverId: driverId,
                            newPosition: newPos,
                            currentPosition: currentPos,
                            heading: location.heading,
                            accuracy: location.accuracy,
                          );

                          currentDriverPositions.value = {
                            ...currentDriverPositions.value,
                            driverId: newPos,
                          };
                        }

                        // Always track heading for truck marker rotation
                        if (location.heading != null) {
                          currentDriverHeadings.value = {
                            ...currentDriverHeadings.value,
                            driverId: location.heading!,
                          };
                        }
                      } catch (e) {
                        AppLogger.map('❌ Error parsing location: $e');
                      }
                    },
                ).then((subscription) {
                  subscriptions.add(subscription);
                }).catchError((error) {
                  AppLogger.map('❌ Failed to subscribe to ${driver.driverName}: $error');
                });
              }

              AppLogger.map('✅ CENTRIFUGO: Subscription setup complete');

              return () {
                for (final subscription in subscriptions) {
                  subscription.cancel();
                }
                for (final driver in drivers) {
                  centrifugo.unsubscribe('driver:location:${driver.driverId}');
                }
              };
            },
            [isCentrifugoConnected, drivers.map((d) => '${d.driverId}:${d.status}').join('|')],
          );

          // Effect 1a: Add/remove bin markers (add new bins, remove deleted bins)
          useEffect(
            () {
              if (binsAsync.hasValue && mapController.value != null && layerVisibility.value.bins) {
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
                                      '${bin.address} - ${bin.fillPercentage ?? 0}% full',
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
            [binsAsync.hasValue, mapController.value != null, binsAsync, layerVisibility.value.bins],
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
              if (potentialLocationsAsync.hasValue && mapController.value != null && layerVisibility.value.potentialLocations) {
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
            [potentialLocationsCount, mapController.value != null, layerVisibility.value.potentialLocations],
          );

          // Effect 1c: Add warehouse marker when map and warehouse location are ready
          useEffect(
            () {
              if (mapController.value == null || !warehouseAsync.hasValue) return null;
              final warehouse = warehouseAsync.value;
              if (warehouse == null) return null;

              () async {
                try {
                  // Remove old warehouse marker if it exists
                  if (warehouseMarker.value != null) {
                    await mapController.value!.removeMarkers([warehouseMarker.value!]);
                  }

                  final icon = await GoogleNavigationMarkerService.createWarehouseMarkerIcon();

                  final markers = await mapController.value!.addMarkers([
                    MarkerOptions(
                      position: LatLng(
                        latitude: warehouse.latitude,
                        longitude: warehouse.longitude,
                      ),
                      icon: icon,
                      anchor: const MarkerAnchor(u: 0.5, v: 0.5),
                      zIndex: 9997.0,
                      consumeTapEvents: false,
                      infoWindow: InfoWindow(
                        title: 'Warehouse',
                        snippet: warehouse.address,
                      ),
                    ),
                  ]);

                  if (markers.isNotEmpty && markers.first != null) {
                    warehouseMarker.value = markers.first;
                    AppLogger.map('🏭 Warehouse marker added at (${warehouse.latitude}, ${warehouse.longitude})');
                  }
                } catch (e) {
                  AppLogger.map('❌ Failed to add warehouse marker: $e');
                }
              }();
              return null;
            },
            [mapController.value != null, warehouseAsync.hasValue],
          );

          // Effect: Toggle marker visibility based on layer controls
          useEffect(
            () {
              final controller = mapController.value;
              if (controller == null) return null;

              Future<void> toggleLayers() async {
                try {
                  // Bins — toggle off: remove from map AND clear state
                  if (!layerVisibility.value.bins && binMarkers.value.isNotEmpty) {
                    await controller.removeMarkers(binMarkers.value);
                    binMarkers.value = [];
                    binMarkersMap.value = {};
                  }

                  // Potential locations — toggle off: remove from map AND clear state
                  if (!layerVisibility.value.potentialLocations && locationMarkers.value.isNotEmpty) {
                    await controller.removeMarkers(locationMarkers.value);
                    locationMarkers.value = [];
                    locationMarkersMap.value = {};
                  }

                  // Drivers — toggle off: remove from map AND clear state
                  if (!layerVisibility.value.drivers && driverMarkers.value.isNotEmpty) {
                    await controller.removeMarkers(driverMarkers.value.values.toList());
                    driverMarkers.value = {};
                  }
                } catch (e) {
                  AppLogger.map('Layer toggle error: $e');
                }
              }

              toggleLayers();
              return null;
            },
            [
              layerVisibility.value.bins,
              layerVisibility.value.drivers,
              layerVisibility.value.potentialLocations,
            ],
          );

          // Effect 2 REMOVED: Animation is now triggered directly in the
          // Centrifugo callback (Effect 0) to avoid provider rebuild cascades.

          // Effect 3: Auto-center camera on focused driver
          // - For focused mode: center once (card + polyline persist)
          // - For following mode: continuously follow driver as they move
          useEffect(
            () {
              if (mapController.value == null || focusedDriverId == null) {
                return null;
              }

              // Use live position from currentDriverPositions (updated by Centrifugo)
              // Fall back to provider's initial location for first focus
              final livePos = currentDriverPositions.value[focusedDriverId];
              final initialDriver = activeDrivers
                  .where((d) => d.driverId == focusedDriverId)
                  .firstOrNull;

              final targetPosition = livePos ??
                  (initialDriver?.currentLocation != null
                      ? LatLng(
                          latitude: initialDriver!.currentLocation!.latitude,
                          longitude: initialDriver.currentLocation!.longitude,
                        )
                      : null);

              // Diagnostic logging for follow mode debugging
              AppLogger.map('🎯 FOLLOW: Effect 3 triggered for driver $focusedDriverId');
              AppLogger.map('   livePos (currentDriverPositions): ${livePos != null ? "(${livePos.latitude}, ${livePos.longitude})" : "NULL"}');
              AppLogger.map('   providerPos (API/Redis): ${initialDriver?.currentLocation != null ? "(${initialDriver!.currentLocation!.latitude}, ${initialDriver!.currentLocation!.longitude})" : "NULL"}');
              AppLogger.map('   targetPosition: ${targetPosition != null ? "(${targetPosition.latitude}, ${targetPosition.longitude})" : "NULL"}');
              AppLogger.map('   source: ${livePos != null ? "LIVE (Centrifugo)" : "FALLBACK (provider)"}');

              if (targetPosition == null) return null;

              // Mark as programmatic move to suppress gesture-exit
              isProgrammaticMove.value = true;

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

                  // In focused mode, keep focus (card + polyline persist)
                  // In following mode, keep following (camera continues)
                } catch (e) {
                  AppLogger.map('⚠️ Failed to center camera: $e');
                } finally {
                  // Allow gesture-exit again after animation settles
                  Future.delayed(const Duration(milliseconds: 300), () {
                    isProgrammaticMove.value = false;
                  });
                }
              });

              return null;
            },
            // Use live position for following mode (updated by Centrifugo callback)
            [
              mapController.value,
              focusedDriverId,
              if (isFollowing)
                currentDriverPositions.value[focusedDriverId],
            ],
          );

          // Effect 3b REMOVED: Pan detection now handled by onCameraMoveStarted
          // callback on GoogleMapsMapView (instant gesture detection, no polling).

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
              if (mapController.value == null || !layerVisibility.value.drivers) {
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

                      // Create truck icon with heading rotation
                      final heading = currentDriverHeadings.value[driverId] ??
                          location.heading ?? 0.0;
                      final icon = await GoogleNavigationMarkerService.createDriverTruckMarkerIcon(
                        heading: heading,
                        isFocused: false,
                      );

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
            [activeDrivers.map((d) => d.driverId).join(','), mapController.value, layerVisibility.value.drivers],
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
                // Skip if drivers layer is hidden
                if (!layerVisibility.value.drivers) return;

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

                    final isFocused = driver.driverId == focusedDriverId;

                    // Use interpolated position if animating, then live position,
                    // then fall back to provider's initial location
                    final livePos = currentDriverPositions.value[driver.driverId];
                    final position = interpolatedPositions[driver.driverId] ??
                        livePos ??
                        (driver.currentLocation != null
                            ? LatLng(
                                latitude: driver.currentLocation!.latitude,
                                longitude: driver.currentLocation!.longitude,
                              )
                            : null);
                    if (position == null) continue;

                    // Create truck icon with current heading (cached by angle internally)
                    final heading = currentDriverHeadings.value[driver.driverId] ??
                        driver.currentLocation?.heading ?? 0.0;
                    final driverIcon = await GoogleNavigationMarkerService.createDriverTruckMarkerIcon(
                      heading: heading,
                      isFocused: isFocused,
                    );

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
              focusedDriverId,
              isFollowing,
            ],
          );

          // Reset route visibility when switching drivers
          useEffect(
            () {
              isRouteVisible.value = false;
              return null;
            },
            [focusedDriverId],
          );

          // Effect 5: Polyline lifecycle — fetch OSRM route, trim, detect task changes
          // Only activates when route is visible (user toggled) or in follow mode
          useEffect(
            () {
              if (focusedDriverId == null || !isFocusedOrFollowing || mapController.value == null ||
                  (!isRouteVisible.value && !isFollowing)) {
                // Not focused or route hidden — clear polyline (deferred to avoid build-phase mutation)
                Future.microtask(() {
                  ref.read(routePolylineProvider.notifier).clear();
                  mapController.value?.clearPolylines();
                });
                return null;
              }

              AppLogger.map('🛤️ Effect 5: Starting polyline for $focusedDriverId');

              bool cancelled = false;
              final driverId = focusedDriverId;

              // Initialize polyline for the focused driver (deferred to avoid build-phase mutation)
              Future.microtask(() {
                if (!cancelled) {
                  ref.read(routePolylineProvider.notifier)
                      .initializeForDriver(driverId);
                }
              });

              // 3s timer: trim polyline based on driver's live position
              final trimTimer = Timer.periodic(
                const Duration(seconds: 3),
                (_) {
                  if (cancelled) return;
                  final livePositions = ref.read(driverLivePositionsProvider);
                  final driverLoc = livePositions[driverId];
                  if (driverLoc != null) {
                    ref.read(routePolylineProvider.notifier).updateDriverPosition(
                      LatLng(
                        latitude: driverLoc.latitude,
                        longitude: driverLoc.longitude,
                      ),
                    );
                  }
                },
              );

              // 30s timer: check if the active task changed
              final taskCheckTimer = Timer.periodic(
                const Duration(seconds: 30),
                (_) {
                  if (cancelled) return;
                  ref.read(routePolylineProvider.notifier)
                      .checkForTaskChange(driverId);
                },
              );

              return () {
                AppLogger.map('🛤️ Effect 5: Cleaning up polyline');
                cancelled = true;
                trimTimer.cancel();
                taskCheckTimer.cancel();
                // Deferred to avoid build-phase mutation
                Future.microtask(() {
                  ref.read(routePolylineProvider.notifier).clear();
                  mapController.value?.clearPolylines();
                });
              };
            },
            [focusedDriverId, isFocusedOrFollowing, isRouteVisible.value, mapController.value],
          );

          // Effect 6: Draw polyline on map when visibleRoute changes
          // Uses ref.listenManual to avoid full widget rebuilds
          useEffect(
            () {
              if (mapController.value == null) return null;

              final sub = ref.listenManual<RoutePolylineState>(
                routePolylineProvider,
                (prev, next) async {
                  // Only redraw if visibleRoute actually changed
                  if (prev?.visibleRoute == next.visibleRoute) return;

                  try {
                    await mapController.value!.clearPolylines();

                    if (next.visibleRoute.length >= 2) {
                      await mapController.value!.addPolylines([
                        PolylineOptions(
                          points: next.visibleRoute,
                          strokeWidth: 6,
                          strokeColor: AppColors.actionBlue,
                          geodesic: true,
                          zIndex: 500,
                          clickable: false,
                        ),
                      ]);
                    }
                  } catch (e) {
                    AppLogger.map('⚠️ Failed to draw polyline: $e');
                  }
                },
              );

              return sub.close;
            },
            [mapController.value],
          );

          // Read polyline state for the floating card
          final polylineState = ref.watch(routePolylineProvider);

          return Stack(
            children: [
              // Standard Google Maps View (no navigation)
              GoogleMapsMapView(
                key: const ValueKey('fleet_map'),
                initialCameraPosition: const CameraPosition(
                  target: LatLng(latitude: 32.886534, longitude: -96.7642497), // Dallas
                  zoom: 12,
                  tilt: 0.0, // Flat 2D view
                  bearing: 0.0, // North-up orientation
                ),
                initialMapType: MapType.normal,
                initialZoomControlsEnabled: false,
                onViewCreated: (GoogleMapViewController controller) async {
                  mapController.value = controller;
                  AppLogger.map('✅ Manager fleet map created (standard Google Maps view)');

                  // Enable MyLocation to show manager's current location (blue dot)
                  await controller.setMyLocationEnabled(true);
                  AppLogger.map('✅ My Location (blue dot) enabled');

                  // Disable Google's native My Location button (use our custom one instead)
                  await controller.settings.setMyLocationButtonEnabled(false);
                  AppLogger.map('✅ Default My Location button disabled (using custom button)');
                },
                onCameraMoveStarted: (position, gesture) {
                  // gesture=true means user physically panned/pinched/rotated
                  if (gesture && isFollowing && !isProgrammaticMove.value) {
                    AppLogger.map('🚨 User gesture detected — dropping to focused mode');
                    // Drop to focused mode (keeps card + polyline, stops auto-centering)
                    ref.read(focusedDriverProvider.notifier)
                        .setFocusedDriver(focusedDriverId!);
                  }
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

                  // Check if it's a driver marker
                  final driverEntry = driverMarkers.value.entries
                      .where((e) => e.value.markerId == markerId)
                      .firstOrNull;
                  if (driverEntry != null) {
                    AppLogger.map('🚛 Driver marker tapped: ${driverEntry.key}');
                    AppLogger.map('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                    ref.read(focusedDriverProvider.notifier).setFocusedDriver(driverEntry.key);
                    return;
                  }

                  AppLogger.map('   → Unknown marker, ignoring');
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

              // Notification button with badge - positioned top-left
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: AnimatedOpacity(
                  opacity: isSearchExpanded.value ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: IgnorePointer(
                    ignoring: isSearchExpanded.value,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircularMapButton(
                          icon: Icons.notifications,
                          backgroundColor: AppColors.primaryGreen,
                          iconColor: Colors.white,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsPage(),
                              ),
                            );
                          },
                        ),
                        // Badge indicator
                        if (binsAsync.valueOrNull != null)
                          Builder(builder: (context) {
                            final count = binsAsync.valueOrNull!
                                .where((b) => (b.fillPercentage ?? 0) > 80)
                                .length;
                            if (count == 0) return const SizedBox.shrink();
                            return Positioned(
                              right: -2,
                              top: -2,
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
                                  count > 9 ? '9+' : '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),

              // Layers control - positioned bottom-right above recenter button
              Positioned(
                bottom: 156,
                right: 16,
                child: MapLayersControl(
                  visibility: layerVisibility.value,
                  onChanged: (newVisibility) {
                    layerVisibility.value = newVisibility;
                  },
                ),
              ),

              // Live status indicator - centered at top below status bar
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: isSearchExpanded.value ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: IgnorePointer(
                    ignoring: isSearchExpanded.value,
                    child: Center(
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCentrifugoConnected
                              ? Colors.green.withValues(alpha: 0.95)
                              : Colors.grey.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Pulsing dot
                            _LiveStatusDot(isConnected: isCentrifugoConnected),
                            const SizedBox(width: 6),
                            Text(
                              'Live',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Driver count button - positioned top-left below notification bell
              // Hidden when following mode is active
              if (!isFollowing)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 72,
                  left: 16,
                  child: AnimatedOpacity(
                    opacity: isSearchExpanded.value ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: IgnorePointer(
                      ignoring: isSearchExpanded.value,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircularMapButton(
                            icon: Icons.local_shipping,
                            backgroundColor: AppColors.primaryGreen,
                            iconColor: Colors.white,
                            onTap: () {
                              context.push('/manager/active-drivers');
                            },
                          ),
                          // Count badge - only show when > 0
                          if (activeDrivers.isNotEmpty)
                            Positioned(
                              right: -2,
                              top: -2,
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
                                  activeDrivers.length > 9 ? '9+' : '${activeDrivers.length}',
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
                    ),
                  ),
                ),

              // Custom recenter button - positioned bottom-right (above bottom nav)
              Positioned(
                bottom: 100,
                right: 16,
                child: CircularMapButton(
                  icon: Icons.my_location,
                  backgroundColor: AppColors.primaryGreen,
                  iconColor: Colors.white,
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

              // Search bar - positioned top-right
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: MapSearchBar(
                  drivers: activeDrivers,
                  bins: binsAsync.valueOrNull ?? [],
                  locations: potentialLocationsAsync.valueOrNull ?? [],
                  onExpandChanged: (expanded) {
                    isSearchExpanded.value = expanded;
                  },
                  onResultSelected: (result) async {
                    if (result.latitude != null &&
                        result.longitude != null &&
                        mapController.value != null) {
                      try {
                        await mapController.value!.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: LatLng(
                                latitude: result.latitude!,
                                longitude: result.longitude!,
                              ),
                              zoom: 17.0,
                            ),
                          ),
                        );
                        AppLogger.map(
                          '🔍 Search: centered on ${result.title}',
                        );
                      } catch (e) {
                        AppLogger.map('Search center failed: $e');
                      }
                    }
                  },
                ),
              ),

              // Floating driver card — shown in focused mode (not following)
              if (focusedDriverState.mode == FollowMode.focused && focusedDriverId != null)
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Builder(
                    builder: (context) {
                      final focusedDriver = activeDrivers
                          .where((d) => d.driverId == focusedDriverId)
                          .firstOrNull;
                      if (focusedDriver == null) return const SizedBox.shrink();

                      return DriverFloatingCard(
                        driver: focusedDriver,
                        currentTask: polylineState.currentTask,
                        totalTasks: polylineState.totalTasks,
                        completedTasks: polylineState.completedTasks,
                        isRouteVisible: isRouteVisible.value,
                        onFollow: () {
                          ref.read(focusedDriverProvider.notifier)
                              .startFollowing(focusedDriverId);
                        },
                        onToggleRoute: () {
                          isRouteVisible.value = !isRouteVisible.value;
                        },
                        onDetails: () {
                          context.push(
                            '/manager/driver-shift-detail/$focusedDriverId',
                          );
                        },
                        onDismiss: () {
                          isRouteVisible.value = false;
                          Future.microtask(() {
                            ref.read(focusedDriverProvider.notifier).clearFocus();
                          });
                        },
                      );
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

/// Pulsing dot widget for Live status indicator
class _LiveStatusDot extends HookWidget {
  final bool isConnected;

  const _LiveStatusDot({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 2000),
    );

    // Only pulse when connected
    useEffect(() {
      if (isConnected) {
        animationController.repeat(reverse: true);
      } else {
        animationController.stop();
      }
      return null;
    }, [isConnected]);

    final animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: isConnected
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(
                        alpha: 0.4 + (animation.value * 0.4),
                      ),
                      blurRadius: 3 + (animation.value * 3),
                      spreadRadius: animation.value * 1.5,
                    ),
                  ]
                : [],
          ),
        );
      },
    );
  }
}
