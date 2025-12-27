import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/providers/bins_provider.dart';
import 'package:ropacalapp/providers/focused_driver_provider.dart';
import 'package:ropacalapp/models/active_driver.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/features/driver/widgets/circular_map_button.dart';
import 'package:ropacalapp/features/driver/notifications_page.dart';
import 'package:ropacalapp/core/services/google_navigation_marker_service.dart';
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

    // 🔍 DIAGNOSTIC: Log every build
    AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLogger.general('🏗️ ManagerMapPage.build() CALLED');
    AppLogger.general('   Timestamp: ${DateTime.now().millisecondsSinceEpoch}');

    final driversAsync = ref.watch(driversNotifierProvider);
    AppLogger.general('   🚗 driversAsync: ${driversAsync.runtimeType}, hasValue: ${driversAsync.hasValue}, valueOrNull?.length: ${driversAsync.valueOrNull?.length}');

    final binsAsync = ref.watch(binsListProvider);
    AppLogger.general('   📦 binsAsync: ${binsAsync.runtimeType}, hasValue: ${binsAsync.hasValue}, valueOrNull?.length: ${binsAsync.valueOrNull?.length}');

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
    final cachedBinMarkers = useState<List<MarkerOptions>?>(null);
    // Cache driver marker icons to avoid recreating them (performance optimization)
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
                final location = focusedDriver!.currentLocation!;
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

          // Effect 4: Update markers (continuously during animation, or once when animation completes)
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
                    final location = driver.currentLocation!;
                    final isFocused = driver.driverId == focusedDriverId;

                    // Use interpolated position if animating, otherwise use real position
                    final position = interpolatedPositions[driver.driverId] ??
                        LatLng(
                          latitude: location.latitude,
                          longitude: location.longitude,
                        );

                    // Get or create cached driver icon
                    // For focused driver, create a highlighted version
                    // For following driver, create a pulsing version
                    final isFollowingThisDriver = driver.driverId == focusedDriverId && isFollowing;
                    final cacheKey = isFollowingThisDriver
                        ? '${driver.driverId}_following'
                        : isFocused
                            ? '${driver.driverId}_focused'
                            : driver.driverId;
                    ImageDescriptor? driverIcon = cachedDriverIcons.value[cacheKey];
                    if (driverIcon == null) {
                      AppLogger.map('🎨 Creating ${isFollowingThisDriver ? "FOLLOWING " : isFocused ? "FOCUSED " : ""}icon for driver: ${driver.driverName}');
                      driverIcon = await GoogleNavigationMarkerService
                          .createDriverMarkerIcon(
                        driver.driverName,
                        isFocused: isFocused,
                        isPulsing: isFollowingThisDriver,
                      );
                      cachedDriverIcons.value = {
                        ...cachedDriverIcons.value,
                        cacheKey: driverIcon,
                      };
                    }

                    allMarkerOptions.add(
                      MarkerOptions(
                        position: position,
                        infoWindow: InfoWindow(
                          title: driver.driverName,
                          snippet:
                              '${driver.completedBins ?? 0}/${driver.totalBins ?? 0} bins completed',
                        ),
                        icon: driverIcon,
                        anchor: const MarkerAnchor(u: 0.5, v: 0.5),
                        flat: true,
                        zIndex: isFocused ? 10001.0 : 10000.0, // Focused driver on top
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
                  iconColor: Colors.grey.shade700,
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
