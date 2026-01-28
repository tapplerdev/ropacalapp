import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:action_slider/action_slider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/enums/bin_status.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/utils/bin_helpers.dart';
import 'package:ropacalapp/core/utils/responsive.dart';
import 'package:ropacalapp/providers/bins_provider.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/providers/bin_marker_cache_provider.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/simulation_provider.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/providers/map_controller_provider.dart';
import 'package:ropacalapp/core/enums/user_role.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/features/driver/widgets/alerts_bottom_sheet.dart';
import 'package:ropacalapp/features/driver/widgets/bin_details_bottom_sheet.dart';
import 'package:ropacalapp/features/driver/widgets/potential_location_form_dialog.dart';
import 'package:ropacalapp/features/driver/widgets/route_summary_card.dart';
import 'package:ropacalapp/features/driver/widgets/stat_card.dart';
import 'package:ropacalapp/features/driver/widgets/active_shift_bottom_sheet.dart';
import 'package:ropacalapp/features/driver/widgets/pre_shift_overview_card.dart';
import 'package:ropacalapp/features/driver/widgets/navigation_blue_dot_overlay.dart';
import 'package:ropacalapp/features/driver/widgets/positioned_blue_dot_overlay.dart';
import 'package:ropacalapp/features/driver/widgets/no_shift_empty_state.dart';
import 'package:ropacalapp/features/driver/widgets/animated_shift_transition.dart';
import 'package:ropacalapp/features/driver/widgets/map_notification_button.dart';
import 'package:ropacalapp/features/driver/widgets/map_2d_3d_toggle_button.dart';
import 'package:ropacalapp/features/driver/widgets/map_location_button.dart';
import 'package:ropacalapp/features/driver/widgets/circular_map_button.dart';
import 'package:ropacalapp/features/driver/widgets/shift_acceptance_bottom_sheet.dart';
import 'package:ropacalapp/features/driver/widgets/move_request_notification_dialog.dart';
import 'package:ropacalapp/providers/move_request_notification_provider.dart';
import 'package:ropacalapp/features/driver/google_navigation_page.dart';
import 'package:ropacalapp/features/driver/notifications_page.dart';
import 'package:ropacalapp/models/shift_overview.dart';
// DEPRECATED: NavigationPage uses old google_maps_flutter - replaced by GoogleNavigationPage
// import 'package:ropacalapp/features/driver/navigation_page.dart';
import 'package:ropacalapp/core/utils/navigation_arrow_marker_painter.dart';

class DriverMapPage extends HookConsumerWidget {
  const DriverMapPage({super.key});

  /// Helper to convert bearing to compass direction name
  static String _getDirectionName(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'North (↑)';
    if (bearing >= 22.5 && bearing < 67.5) return 'Northeast (↗)';
    if (bearing >= 67.5 && bearing < 112.5) return 'East (→)';
    if (bearing >= 112.5 && bearing < 157.5) return 'Southeast (↘)';
    if (bearing >= 157.5 && bearing < 202.5) return 'South (↓)';
    if (bearing >= 202.5 && bearing < 247.5) return 'Southwest (↙)';
    if (bearing >= 247.5 && bearing < 292.5) return 'West (←)';
    if (bearing >= 292.5 && bearing < 337.5) return 'Northwest (↖)';
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔍 DIAGNOSTIC: Log every build (COMMENTED - too spammy)
    // AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    // AppLogger.general('🏗️ DriverMapPage.build() CALLED');
    // AppLogger.general('   Timestamp: ${DateTime.now().millisecondsSinceEpoch}');

    final binsState = ref.watch(binsListProvider); // Used for Bins tab, NOT for map markers
    // AppLogger.general('   📦 binsState: ${binsState.runtimeType}, hasValue: ${binsState.hasValue}, valueOrNull?.length: ${binsState.valueOrNull?.length}');

    final locationState = ref.watch(currentLocationProvider);
    // AppLogger.general('   📍 locationState: ${locationState.runtimeType}, hasValue: ${locationState.hasValue}, value: ${locationState.valueOrNull != null ? "(${locationState.valueOrNull!.latitude.toStringAsFixed(6)}, ${locationState.valueOrNull!.longitude.toStringAsFixed(6)})" : "null"}');

    final routeState = ref.watch(optimizedRouteProvider);
    // AppLogger.general('   🗺️ routeState: ${routeState.runtimeType}, hasValue: ${routeState.hasValue}');

    final markerCache = ref.watch(binMarkerCacheNotifierProvider);
    // AppLogger.general('   📌 markerCache: ${markerCache.runtimeType}');

    // DON'T watch shiftState - we don't want to rebuild the entire page when shift changes
    // Individual shift-aware widgets will watch it internally
    // final shiftState = ref.watch(shiftNotifierProvider);
    // AppLogger.general('   🚚 shiftState: status=${shiftState.status}, routeBins=${shiftState.routeBins.length}');

    // SIMULATION DISABLED - Not used in production
    // final simulationState = ref.watch(simulationNotifierProvider);
    // AppLogger.general('   🎮 simulationState: isSimulating=${simulationState.isSimulating}');

    final user = ref.watch(authNotifierProvider).value;
    // AppLogger.general('   👤 user: ${user?.email ?? "null"}');

    // AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final mapController = useState<GoogleMapViewController?>(null);
    final markers = useState<Set<Marker>>({});
    final polylines = useState<Set<Polyline>>({});
    final cameraPosition = useMemoized(
      () => ValueNotifier<CameraPosition?>(null),
      [],
    );
    final navigationArrowIcon = useState<ImageDescriptor?>(null);
    final compassHeading = useState<double?>(null);
    final previousPosition = useState<Position?>(
      null,
    ); // Track previous GPS position for bearing calculation

    // Camera update throttling to prevent animation conflicts (max 10 FPS)
    final lastCameraUpdate = useRef<DateTime>(DateTime.now());
    // Smooth bearing to reduce rotation jitter
    final smoothedBearing = useRef<double?>(null);
    // Track last logged segment to reduce log spam
    final lastLoggedSegment = useRef<int>(-1);
    // Track if camera auto-follow is enabled (disabled when user pans)
    final isAutoFollowEnabled = useState<bool>(true);

    // Default to San Jose if no location available
    final initialCenter = useMemoized(
      () => locationState.value != null
          ? LatLng(
              latitude: locationState.value!.latitude,
              longitude: locationState.value!.longitude,
            )
          : const LatLng(latitude: 37.3382, longitude: -121.8863), // San Jose, CA
      [locationState.value],
    );

    // Memoize initial camera position to prevent map re-creation on shift updates
    // This is only used ONCE when map is created, so it should not react to shiftState changes
    final initialCameraPosition = useMemoized(
      () => CameraPosition(
        target: initialCenter,
        zoom: 15.0, // Default zoom level
        tilt: 0.0, // Always start in 2D mode
        bearing: 0.0, // North-up orientation
      ),
      [initialCenter], // Only recreate if initial center changes (location load)
    );

    // Watch the map controller provider and perform setup when it becomes available
    final mapControllerFromProvider = ref.watch(driverMapControllerProvider);

    useEffect(() {
      if (mapControllerFromProvider != null && mapController.value == null) {
        // Sync provider controller to local state
        mapController.value = mapControllerFromProvider;

        // Perform one-time setup
        () async {
          try {
            // Enable My Location (blue dot) - Google Maps built-in feature
            await mapControllerFromProvider.setMyLocationEnabled(true);
            AppLogger.map('✅ My Location (blue dot) enabled');

            // Disable the default My Location button (we'll use a custom one)
            await mapControllerFromProvider.settings.setMyLocationButtonEnabled(false);
            AppLogger.map('✅ Default My Location button disabled (using custom button)');

            AppLogger.map('✅ Using default Google Maps style (custom style disabled)');
            AppLogger.map('🗺️  Google Map setup complete');
            AppLogger.map('   Markers count: ${markers.value.length}');
            AppLogger.map('   Polylines count: ${polylines.value.length}');
          } catch (e) {
            AppLogger.map('⚠️  Map setup error: $e');
          }
        }();
      }
      return null;
    }, [mapControllerFromProvider]);

    // Load navigation arrow icon on mount
    useEffect(() {
      NavigationArrowMarkerPainter.createNavigationArrow(size: 96.0)
          .then((icon) {
            navigationArrowIcon.value = icon;
          })
          .catchError((error) {
            AppLogger.map('❌ Failed to load navigation arrow: $error');
          });
      return null;
    }, []);

    // Listen to compass heading for navigation arrow rotation
    useEffect(() {
      StreamSubscription<CompassEvent>? compassSubscription;

      compassSubscription = FlutterCompass.events?.listen((event) {
        if (event.heading != null) {
          compassHeading.value = event.heading;
        }
      });

      return () {
        compassSubscription?.cancel();
      };
    }, []);

    // SIMULATION DISABLED - GPS bearing calculation not needed
    // useEffect(() {
    //   AppLogger.navigation('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    //   AppLogger.navigation('🔄 GPS BEARING EFFECT TRIGGERED');
    //   // ... GPS bearing calculation code ...
    //   return null;
    // }, [locationState.value]);

    // Update markers and polylines when data changes
    useEffect(
      () {
        final bins = binsState.value;
        final routeBins = routeState.value;
        final location = locationState.value;

        // Read shift state without watching (doesn't cause rebuilds)
        final currentShift = ref.read(shiftNotifierProvider);

        // DEBUG: Check data availability
        // Use marker cache for instant marker rendering
        final newMarkers = <Marker>{};

        // ✅ ONLY show markers for bins in the assigned shift
        // When no shift → routeBins is empty → clean map with just blue dot
        if (currentShift.routeBins.isNotEmpty && bins != null) {

          for (var i = 0; i < currentShift.routeBins.length; i++) {
            final routeBin = currentShift.routeBins[i];

            if (routeBin.latitude != null && routeBin.longitude != null) {
              // Find the corresponding Bin object for the bottom sheet
              final binForSheet = bins.firstWhere(
                (b) => b.id == routeBin.id,
                orElse: () => bins.first, // Fallback (shouldn't happen)
              );

              // Get numbered route marker from cache
              final routeIcon = ref
                  .read(binMarkerCacheNotifierProvider.notifier)
                  .getRouteMarker(i + 1);

              newMarkers.add(
                Marker(
                  markerId: 'route_bin_${routeBin.id}',
                  options: MarkerOptions(
                    position: LatLng(latitude: routeBin.latitude, longitude: routeBin.longitude),
                    icon: routeIcon ?? ImageDescriptor.defaultImage,
                    anchor: const MarkerAnchor(u: 0.5, v: 0.5),
                    consumeTapEvents: true,
                  ),
                ),
              );
            }
          }
        }

        // Add route polyline (simple lines from current location through bins)
        final routePoints = <LatLng>[];

        // ✅ ONLY show polylines if there's a shift with bins
        // When no shift → clean map (no route lines)
        if (currentShift.routeBins.isNotEmpty && routeBins != null && routeBins.isNotEmpty) {
          // Draw simple straight lines from current location through bins
          AppLogger.map('   → Drawing route polyline');
          if (location != null) {
            routePoints.add(LatLng(latitude: location.latitude, longitude: location.longitude));
          }
          routePoints.addAll(
            routeBins
                .where((b) => b.latitude != null && b.longitude != null)
                .map((b) => LatLng(latitude: b.latitude!, longitude: b.longitude!)),
          );

          if (routePoints.isNotEmpty) {
            final routePolyline = Polyline(
              polylineId: 'route',
              options: PolylineOptions(
                points: routePoints,
                strokeColor: AppColors.primaryGreen,
                strokeWidth: 4,
                visible: true,
                zIndex: 100,
              ),
            );

            polylines.value = {routePolyline};

            AppLogger.map('✅ Route polyline set');
            AppLogger.map('   Points: ${routePoints.length}');
          } else {
            polylines.value = {};
            AppLogger.map('❌ No route points to draw');
          }
        } else {
          // No shift bins → clean map with no route polylines
          polylines.value = {};
        }

        // SIMULATION DISABLED - User location marker code removed
        // Google Maps built-in blue dot is enabled via controller.setMyLocationEnabled
        // No custom navigation arrow needed without simulation

        markers.value = newMarkers;
        return null;
      },
      [
        binsState.value,
        locationState.value,
        routeState.value,
        markerCache,
        // REMOVED shiftState.status to prevent page rebuilds
        // We'll use ref.listen() to update markers when shift changes
      ],
    );

    // Listen to shift changes WITHOUT rebuilding the entire page
    // This triggers marker updates when routes are assigned/completed
    ref.listen(shiftNotifierProvider, (previous, next) {
      AppLogger.general('🔔 Shift state changed: ${previous?.status} → ${next.status}');

      // Force marker update by invalidating the bins list provider
      // This will trigger the useEffect above to re-run
      if (previous?.status != next.status || previous?.routeBins.length != next.routeBins.length) {
        AppLogger.general('   → Triggering marker update');
        ref.invalidate(binsListProvider);
      }
    });

    // SIMULATION DISABLED - Route change detection not needed
    // useEffect(() {
    //   // ... simulation route change detection ...
    //   return null;
    // }, []);

    // SIMULATION DISABLED - Camera following effects removed (lines 317-468)
    // These effects were causing rebuild loops by watching and modifying simulationState


    // NOTE: Removed custom camera following for no-shift case
    // When there's no shift, we use vanilla Google Maps with default behavior
    // (no forced camera movements, user controls the map freely)

    // Listen for move request notifications and show dialog
    final moveRequestNotification = ref.watch(moveRequestNotificationNotifierProvider);

    useEffect(() {
      if (moveRequestNotification != null) {
        AppLogger.general('🔔 Move request notification received in driver_map_page - showing dialog');

        // Show dialog on next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => MoveRequestNotificationDialog(
                moveRequest: moveRequestNotification.moveRequest,
                onClose: () {
                  Navigator.of(dialogContext).pop();
                  ref.read(moveRequestNotificationNotifierProvider.notifier).clear();
                  AppLogger.general('✅ Move request notification dialog closed');
                },
              ),
            );
          }
        });
      }
      return null;
    }, [moveRequestNotification]);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, // Dark status bar icons
      child: Scaffold(
        body: Stack(
          children: [
            // MAP LAYER - Never rebuilds (doesn't watch shiftState)
            _MapLayer(
              initialCameraPosition: initialCameraPosition,
            ),

            // ALWAYS VISIBLE BUTTONS - Positioned outside binsState.when()
            SafeArea(
              child: Stack(
                children: [
                  // Notification bell button (top left)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: MapNotificationButton(binsState: binsState),
                  ),
                  // Potential Location button (below notification button)
                  Positioned(
                    top: 72, // Match manager view spacing
                    left: 16,
                    child: CircularMapButton(
                      icon: Icons.add_location_alt_outlined,
                      iconColor: AppColors.primaryGreen,
                      onTap: () => _showPotentialLocationMenu(context, ref),
                    ),
                  ),
                  // Location button (bottom right)
                  _DynamicLocationButton(mapController: mapController.value),
                ],
              ),
            ),

            // SHIFT-AWARE OVERLAYS - Full screen (no SafeArea, extends into status bar)
            // These watch shift state internally to prevent parent rebuilds
            _ShiftReadyOverlay(),
            _ShiftInactiveOverlay(),
            _ShiftActiveOverlay(mapController: mapController.value),

            // OVERLAYS LAYER - Rebuilds when shiftState changes
            binsState.when(
              data: (bins) {
                return SafeArea(
                  child: Stack(
                    children: [
                      // COMMENTED OUT: Recenter button (restores following mode)
                      // Replaced with custom My Location button at bottom-right
                      // Positioned(
                      //   top: 72,
                      //   right: 16,
                      //   child: Container(
                      //     decoration: BoxDecoration(
                      //       color:
                      //           (simulationState.isFollowing ||
                      //               isAutoFollowEnabled.value)
                      //           ? AppColors.primaryGreen
                      //           : Colors.white,
                      //       shape: BoxShape.circle,
                      //       boxShadow: [
                      //         BoxShadow(
                      //           color: Colors.black.withValues(alpha: 0.1),
                      //           blurRadius: 8,
                      //           offset: const Offset(0, 2),
                      //         ),
                      //       ],
                      //     ),
                      //     child: Material(
                      //       color: Colors.transparent,
                      //       child: InkWell(
                      //         onTap: () {
                      //           // Re-enable simulation following
                      //           ref
                      //               .read(simulationNotifierProvider.notifier)
                      //               .enableFollowing();
                      //
                      //           // Re-enable camera auto-follow for active shifts
                      //           if (shiftState.status == ShiftStatus.active) {
                      //             AppLogger.map(
                      //               '📍 Recenter button tapped - re-enabling camera auto-follow',
                      //             );
                      //             isAutoFollowEnabled.value = true;
                      //           }
                      //
                      //           final location =
                      //               simulationState.simulatedPosition ??
                      //               (locationState.value != null
                      //                   ? LatLng(
                      //                       latitude: locationState.value!.latitude,
                      //                       longitude: locationState.value!.longitude,
                      //                     )
                      //                   : null);
                      //
                      //           if (location != null &&
                      //               mapController.value != null) {
                      //             try {
                      //               // Animate to current position in current mode (preserve 2D/3D state)
                      //               mapController.value!.animateCamera(
                      //                 CameraUpdate.newCameraPosition(
                      //                   CameraPosition(
                      //                     target: location,
                      //                     zoom: simulationState.isNavigationMode
                      //                         ? BinConstants.navigationZoom
                      //                         : 15.0,
                      //                     bearing:
                      //                         simulationState.isNavigationMode
                      //                         ? (simulationState
                      //                                   .smoothedBearing ??
                      //                               simulationState.bearing ??
                      //                               compassHeading.value ??
                      //                               0.0)
                      //                         : 0.0,
                      //                     tilt: simulationState.isNavigationMode
                      //                         ? BinConstants.navigationTilt
                      //                         : 0.0,
                      //                   ),
                      //                 ),
                      //               );
                      //             } catch (e) {
                      //               AppLogger.map(
                      //                 'Recenter skipped - controller disposed',
                      //                 level: AppLogger.debug,
                      //               );
                      //             }
                      //           }
                      //         },
                      //         customBorder: const CircleBorder(),
                      //         child: Padding(
                      //           padding: const EdgeInsets.all(12.0),
                      //           child: Icon(
                      //             Icons.my_location,
                      //             color:
                      //                 (simulationState.isFollowing ||
                      //                     isAutoFollowEnabled.value)
                      //                 ? Colors.white
                      //                 : Colors.grey.shade800,
                      //             size: 24,
                      //           ),
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      // SIMULATION DISABLED - 2D/3D toggle button not needed
                      // if (shiftState.status == ShiftStatus.active)
                      //   Positioned(
                      //     top: 128,
                      //     right: 16,
                      //     child: Map2D3DToggleButton(...),
                      //   ),
                      // Stats card (only visible to admin users)
                      if (user?.role == UserRole.admin)
                        Positioned(
                          top: 72,
                          left: 16,
                          right: 16,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  StatCard(
                                    icon: Icons.delete_outline,
                                    label: 'Total',
                                    value: bins.length.toString(),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  StatCard(
                                    icon: Icons.check_circle,
                                    label: 'Active',
                                    value: bins
                                        .where(
                                          (b) => b.status == BinStatus.active,
                                        )
                                        .length
                                        .toString(),
                                    color: Colors.green,
                                  ),
                                  StatCard(
                                    icon: Icons.warning,
                                    label: 'High Fill',
                                    value: bins
                                        .where(
                                          (b) =>
                                              (b.fillPercentage ?? 0) >
                                              BinConstants
                                                  .criticalFillThreshold,
                                        )
                                        .length
                                        .toString(),
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Route summary card
                      if (routeState.value != null &&
                          routeState.value!.isNotEmpty)
                        Positioned(
                          top: 168,
                          left: 16,
                          right: 16,
                          child: RouteSummaryCard(
                            routeBins: routeState.value!,
                            ref: ref,
                            currentLocation: locationState.value != null
                                ? latlong.LatLng(
                                    locationState.value!.latitude,
                                    locationState.value!.longitude,
                                  )
                                : null,
                            onClearRoute: () {
                              ref
                                  .read(optimizedRouteProvider.notifier)
                                  .clearRoute();
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  /// Show bottom sheet menu for potential location options
  void _showPotentialLocationMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.add_location_alt_rounded,
                      color: Colors.green[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Suggest Location',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // GPS Location Option
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    Navigator.pop(context);
                    await _suggestCurrentLocation(context, ref);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.my_location_rounded,
                            color: Colors.blue[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Use Current Location',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Auto-fill with GPS coordinates',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: Colors.blue[700],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Manual Entry Option
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.pop(context);
                    _openManualForm(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.edit_location_alt_rounded,
                            color: Colors.green[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enter Manually',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Type address information',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: Colors.green[700],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Quick suggest using current GPS location
  Future<void> _suggestCurrentLocation(BuildContext context, WidgetRef ref) async {
    try {
      // Get current location from location service
      final locationService = ref.read(locationServiceProvider);
      final location = await locationService.getCurrentLocation();

      if (location == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not get current location'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Open form with GPS pre-filled
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => PotentialLocationFormDialog(
            initialLatitude: location.latitude,
            initialLongitude: location.longitude,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error getting current location', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Open manual entry form (no GPS)
  void _openManualForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PotentialLocationFormDialog(),
    );
  }
}

/// Separate map layer widget that NEVER rebuilds on shift state changes
/// This prevents the white flash when accepting a route
class _MapLayer extends HookConsumerWidget {
  final CameraPosition initialCameraPosition;

  const _MapLayer({
    required this.initialCameraPosition,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GoogleMapsMapView(
      key: const ValueKey('driver_map'),
      initialCameraPosition: initialCameraPosition,
      initialMapType: MapType.normal,
      initialZoomControlsEnabled: false,
      onViewCreated: (GoogleMapViewController controller) {
        // Store controller in provider for other components to access
        ref.read(driverMapControllerProvider.notifier).state = controller;

        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        AppLogger.general('🗺️ onMapViewCreated CALLED - Storing controller in provider');
        AppLogger.general('   Timestamp: ${DateTime.now().millisecondsSinceEpoch}');
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      },
    );
  }
}

/// Calculate total distance for route in kilometers
double _calculateTotalDistance(List<dynamic> routeBins) {
  // print('🧮 Calculating distance for ${routeBins.length} bins');

  if (routeBins.isEmpty) {
    // print('   ⚠️ Route bins is empty, returning 0');
    return 0.0;
  }

  if (routeBins.length == 1) {
    // print('   ⚠️ Only 1 bin in route, returning 0');
    return 0.0;
  }

  double totalKm = 0.0;
  final distance = const latlong.Distance();

  for (int i = 0; i < routeBins.length - 1; i++) {
    final current = routeBins[i];
    final next = routeBins[i + 1];

    // print('   Bin ${i + 1}: lat=${current.latitude}, lng=${current.longitude}');
    // print('   Bin ${i + 2}: lat=${next.latitude}, lng=${next.longitude}');

    final currentPoint = latlong.LatLng(current.latitude, current.longitude);
    final nextPoint = latlong.LatLng(next.latitude, next.longitude);

    // Use .distance() method which returns meters
    final segmentMeters = distance.distance(currentPoint, nextPoint);
    final segmentKm = segmentMeters / 1000.0;

    // print('   → Raw distance (meters): $segmentMeters');
    // print('   → Distance to bin ${i + 2}: ${segmentKm.toStringAsFixed(4)} km');
    totalKm += segmentKm;
  }

  // print('   ✅ Total distance: ${totalKm.toStringAsFixed(2)} km');
  return totalKm;
}

/// Shift-aware overlay that shows shift acceptance modal when status is ready
/// This widget watches shift state internally to prevent parent rebuilds
class _ShiftReadyOverlay extends ConsumerWidget {
  // Removed const to ensure fresh BuildContext for navigation
  _ShiftReadyOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftState = ref.watch(shiftNotifierProvider);

    // LOGS COMMENTED OUT - too spammy
    // if (shiftState.status == ShiftStatus.ready) {
    //   AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    //   AppLogger.general('🎭 _ShiftReadyOverlay: Status is READY!');
    //   AppLogger.general('   ✅ Showing ShiftAcceptanceBottomSheet!');
    //   AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    // }

    if (shiftState.status != ShiftStatus.ready) {
      return const SizedBox.shrink();
    }
    return Stack(
      children: [
        // Dark overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        // Acceptance modal
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ShiftAcceptanceBottomSheet(
            shiftOverview: ShiftOverview(
              shiftId: shiftState.assignedRouteId ?? '',
              startTime: DateTime.now(),
              estimatedEndTime: DateTime.now().add(
                Duration(
                  hours: (shiftState.totalBins * 0.25).ceil(),
                ),
              ),
              totalBins: shiftState.totalBins,
              totalDistanceKm: _calculateTotalDistance(
                shiftState.routeBins,
              ),
              routeBins: shiftState.routeBins,
              routeName: 'Route ${shiftState.assignedRouteId ?? ''}',
            ),
            onAccept: () async {
              AppLogger.general('🚀 SHIFT ACCEPTED - Starting shift');
              EasyLoading.show(
                status: 'Starting shift...',
                maskType: EasyLoadingMaskType.black,
              );

              try {
                AppLogger.general('📡 Calling startShift()...');
                await ref.read(shiftNotifierProvider.notifier).startShift();
                AppLogger.general('✅ Shift started successfully');

                // Hide loading
                await EasyLoading.dismiss();

                // No manual navigation needed!
                // DriverMapWrapper watches shiftNotifierProvider
                // When status changes to 'active', it automatically switches to GoogleNavigationPage
                AppLogger.general('✅ Shift active - DriverMapWrapper will auto-switch to navigation');
              } catch (e) {
                AppLogger.general('❌ Error starting shift: $e');
                AppLogger.general('   Error type: ${e.runtimeType}');
                await EasyLoading.dismiss();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to start shift: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            onDecline: () async {
              AppLogger.general('❌ SHIFT DECLINED');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Shift declined (not implemented)'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Shift-aware overlay that shows empty state when status is inactive
/// This widget watches shift state internally to prevent parent rebuilds
class _ShiftInactiveOverlay extends ConsumerWidget {
  // Removed const to ensure fresh BuildContext
  _ShiftInactiveOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftState = ref.watch(shiftNotifierProvider);

    if (shiftState.status != ShiftStatus.inactive) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 90, // Position very close to bottom tab navigator
      left: 0,
      right: 0,
      child: AnimatedShiftTransitionWithSlide(
        useSlideAnimation: true, // Use slide-up animation for bottom content
        hasActiveShift: false, // Lyft-style modal handles shift acceptance now
        emptyState: NoShiftEmptyState(
          onRefresh: () async {
            // Refresh shift status from backend
            await ref.read(shiftNotifierProvider.notifier).fetchCurrentShift();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Shift status refreshed'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          // TODO: Get next shift time from backend if available
          nextShiftTime: null,
        ),
        activeRouteCard: const SizedBox.shrink(),
      ),
    );
  }
}

/// Shift-aware overlay that shows active shift bottom sheet when status is active
/// This widget watches shift state internally to prevent parent rebuilds
class _ShiftActiveOverlay extends ConsumerWidget {
  final GoogleMapViewController? mapController;

  const _ShiftActiveOverlay({required this.mapController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftState = ref.watch(shiftNotifierProvider);

    if (shiftState.status != ShiftStatus.active) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ActiveShiftBottomSheet(
        routeBins: shiftState.routeBins,
        completedBins: shiftState.completedBins,
        totalBins: shiftState.totalBins,
        onNavigateToNextBin: () {
          // Find next incomplete bin
          final nextBin = shiftState.routeBins.firstWhere(
            (bin) => bin.isCompleted == 0,
            orElse: () => shiftState.routeBins.first,
          );

          // Animate camera to next bin
          if (mapController != null) {
            try {
              mapController!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: LatLng(
                      latitude: nextBin.latitude,
                      longitude: nextBin.longitude,
                    ),
                    zoom: 18,
                  ),
                ),
              );
            } catch (e) {
              AppLogger.map('❌ Error animating camera: $e');
            }
          }
        },
      ),
    );
  }
}

/// Fixed location button that stays at consistent position
/// Positioned above shift ready modal / no shift card / active shift card
class _DynamicLocationButton extends StatelessWidget {
  final GoogleMapViewController? mapController;

  const _DynamicLocationButton({required this.mapController});

  @override
  Widget build(BuildContext context) {
    // Fixed position that works for all shift states:
    // - Above shift ready modal (45% screen height = ~360px + 80px spacing = 440px)
    // - Above no shift card (~150px tall at bottom: 90 = 240px total, button at 440px is well above)
    // - Above active shift card (~310px at bottom)
    return Positioned(
      bottom: 440.0, // Fixed position - always visible above any bottom sheet
      right: 16,
      child: MapLocationButton(
        mapController: mapController,
      ),
    );
  }
}
