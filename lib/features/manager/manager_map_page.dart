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
    // Track last position to avoid unnecessary marker updates
    final lastDriverPositions = useState<Map<String, LatLng>>({});

    return Scaffold(
      body: driversAsync.when(
        data: (drivers) {
          // DEBUG: Log all drivers received
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

          // Filter to only active drivers with location
          final activeDrivers = drivers
              .where(
                (d) =>
                    d.status == ShiftStatus.active && d.lastLocation != null,
              )
              .toList();

          AppLogger.map('✅ Filtered to ${activeDrivers.length} active drivers with location');

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

          // Effect 2: Update driver markers (with icon caching & position filtering)
          useEffect(
            () {
              if (mapController.value == null || cachedBinMarkers.value == null) {
                return null;
              }

              // Build markers with cached bins
              () async {
                try {
                  // Check if any driver position actually changed significantly (> 5m)
                  bool hasSignificantChange = false;
                  for (final driver in activeDrivers) {
                    final location = driver.lastLocation!;
                    final newPos = LatLng(
                      latitude: location.latitude,
                      longitude: location.longitude,
                    );
                    final lastPos = lastDriverPositions.value[driver.id];

                    if (lastPos == null ||
                        _calculateDistance(lastPos, newPos) > 5) {
                      hasSignificantChange = true;
                      break;
                    }
                  }

                  // Skip update if no significant position changes
                  if (!hasSignificantChange && lastDriverPositions.value.isNotEmpty) {
                    AppLogger.map('🔇 Skipping marker update - no significant movement');
                    return;
                  }

                  final allMarkerOptions = <MarkerOptions>[];
                  final newPositions = <String, LatLng>{};

                  AppLogger.map('🔄 Updating ${activeDrivers.length} driver markers...');

                  // 1. Add driver markers with CACHED icons
                  for (final driver in activeDrivers) {
                    final location = driver.lastLocation!;
                    final newPos = LatLng(
                      latitude: location.latitude,
                      longitude: location.longitude,
                    );
                    newPositions[driver.id] = newPos;

                    // Get or create cached driver icon
                    ImageDescriptor? driverIcon = cachedDriverIcons.value[driver.id];
                    if (driverIcon == null) {
                      AppLogger.map('🎨 Creating new icon for driver: ${driver.name}');
                      driverIcon = await GoogleNavigationMarkerService
                          .createDriverMarkerIcon(driver.name);
                      cachedDriverIcons.value = {
                        ...cachedDriverIcons.value,
                        driver.id: driverIcon,
                      };
                    }

                    allMarkerOptions.add(
                      MarkerOptions(
                        position: newPos,
                        infoWindow: InfoWindow(
                          title: driver.name,
                          snippet:
                              '${driver.currentBin ?? 0}/${driver.totalBins ?? 0} bins completed',
                        ),
                        icon: driverIcon,
                        anchor: const MarkerAnchor(u: 0.5, v: 0.5),
                        flat: true,
                        rotation: location.heading ?? 0,  // Point marker in direction of travel
                        zIndex: 10000.0,
                      ),
                    );
                  }

                  // Update last positions
                  lastDriverPositions.value = newPositions;

                  // 2. Reuse cached bin markers
                  allMarkerOptions.addAll(cachedBinMarkers.value!);

                  // Clear and add all markers in one batch
                  await mapController.value!.clearMarkers();
                  await mapController.value!.addMarkers(allMarkerOptions);
                  AppLogger.map('✅ Updated markers (${activeDrivers.length} drivers, ${cachedBinMarkers.value!.length} bins)');
                } catch (e) {
                  AppLogger.map('Failed to update markers: $e');
                }
              }();

              return null;
            },
            [activeDrivers, cachedBinMarkers.value, mapController.value],
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

/// Calculate distance between two LatLng positions (in meters)
double _calculateDistance(LatLng start, LatLng end) {
  const earthRadius = 6371000.0; // meters

  final lat1 = start.latitude * (3.14159265359 / 180.0);
  final lat2 = end.latitude * (3.14159265359 / 180.0);
  final deltaLat = (end.latitude - start.latitude) * (3.14159265359 / 180.0);
  final deltaLng = (end.longitude - start.longitude) * (3.14159265359 / 180.0);

  final a = (deltaLat / 2).sin() * (deltaLat / 2).sin() +
      lat1.cos() * lat2.cos() * (deltaLng / 2).sin() * (deltaLng / 2).sin();

  final c = 2 * a.sqrt().atan2((1 - a).sqrt());

  return earthRadius * c;
}
