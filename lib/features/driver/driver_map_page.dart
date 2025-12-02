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
import 'package:ropacalapp/core/enums/user_role.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/features/driver/widgets/alerts_bottom_sheet.dart';
import 'package:ropacalapp/features/driver/widgets/bin_details_bottom_sheet.dart';
import 'package:ropacalapp/features/driver/widgets/route_summary_card.dart';
import 'package:ropacalapp/features/driver/widgets/stat_card.dart';
import 'package:ropacalapp/features/driver/widgets/active_shift_bottom_sheet.dart';
import 'package:ropacalapp/features/driver/widgets/pre_shift_overview_card.dart';
import 'package:ropacalapp/features/driver/widgets/navigation_blue_dot_overlay.dart';
import 'package:ropacalapp/features/driver/widgets/positioned_blue_dot_overlay.dart';
import 'package:ropacalapp/features/driver/widgets/no_shift_empty_state.dart';
import 'package:ropacalapp/features/driver/widgets/animated_shift_transition.dart';
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
    final binsState = ref.watch(binsListProvider); // Used for Bins tab, NOT for map markers
    final locationState = ref.watch(currentLocationProvider);
    final routeState = ref.watch(optimizedRouteProvider);
    final markerCache = ref.watch(binMarkerCacheNotifierProvider);
    final shiftState = ref.watch(shiftNotifierProvider);
    final simulationState = ref.watch(simulationNotifierProvider);
    final user = ref.watch(authNotifierProvider).value;
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

    // Calculate bearing from GPS movement (for current location arrow rotation)
    useEffect(() {
      AppLogger.navigation('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.navigation('🔄 GPS BEARING EFFECT TRIGGERED');
      AppLogger.navigation('   shiftStatus: ${shiftState.status}');
      AppLogger.navigation('   isSimulating: ${simulationState.isSimulating}');
      AppLogger.navigation(
        '   locationState has value: ${locationState.value != null}',
      );

      // Skip during simulation (simulated bearing is calculated separately)
      if (simulationState.isSimulating) {
        AppLogger.navigation('   ⏸️  SKIPPING: Is simulating');
        AppLogger.navigation('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return null;
      }

      // Need current location
      if (locationState.value == null) {
        AppLogger.navigation('   ⏸️  SKIPPING: No location available');
        AppLogger.navigation('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return null;
      }

      final currentPos = locationState.value!;

      AppLogger.navigation('   📍 Current GPS Position:');
      AppLogger.navigation(
        '      Lat: ${currentPos.latitude.toStringAsFixed(6)}',
      );
      AppLogger.navigation(
        '      Lng: ${currentPos.longitude.toStringAsFixed(6)}',
      );
      AppLogger.navigation('      Timestamp: ${currentPos.timestamp}');

      // If we have a previous position, calculate bearing
      if (previousPosition.value != null) {
        final prevPos = previousPosition.value!;

        AppLogger.navigation('   📍 Previous GPS Position:');
        AppLogger.navigation(
          '      Lat: ${prevPos.latitude.toStringAsFixed(6)}',
        );
        AppLogger.navigation(
          '      Lng: ${prevPos.longitude.toStringAsFixed(6)}',
        );
        AppLogger.navigation('      Timestamp: ${prevPos.timestamp}');

        AppLogger.navigation('   ✅ CALLING updateBearingFromGPS()...');
        AppLogger.navigation(
          '      Before: bearing=${simulationState.bearing.toStringAsFixed(2)}°, smoothed=${simulationState.smoothedBearing?.toStringAsFixed(2) ?? "NULL"}',
        );

        // Calculate bearing from previous → current position
        ref
            .read(simulationNotifierProvider.notifier)
            .updateBearingFromGPS(
              prevLat: prevPos.latitude,
              prevLng: prevPos.longitude,
              currLat: currentPos.latitude,
              currLng: currentPos.longitude,
            );

        // Read the updated state
        final updatedState = ref.read(simulationNotifierProvider);
        AppLogger.navigation(
          '      After: bearing=${updatedState.bearing.toStringAsFixed(2)}°, smoothed=${updatedState.smoothedBearing?.toStringAsFixed(2) ?? "NULL"}',
        );
      } else {
        AppLogger.navigation(
          '   ℹ️  No previous position yet - will calculate on next update',
        );
      }

      // Store current position as previous for next update
      previousPosition.value = currentPos;
      AppLogger.navigation(
        '   💾 Stored current position as previous for next update',
      );
      AppLogger.navigation('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return null;
    }, [locationState.value, simulationState.isSimulating]);

    // Update markers and polylines when data changes
    useEffect(
      () {
        final bins = binsState.value;
        final routeBins = routeState.value;
        final location = locationState.value;

        // DEBUG: Check data availability
        // Use marker cache for instant marker rendering
        final newMarkers = <Marker>{};

        // ✅ ONLY show markers for bins in the assigned shift
        // When no shift → routeBins is empty → clean map with just blue dot
        if (shiftState.routeBins.isNotEmpty && bins != null) {

          for (var i = 0; i < shiftState.routeBins.length; i++) {
            final routeBin = shiftState.routeBins[i];

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

        // Add route polyline (priority: simulation > simple lines)
        final routePoints = <LatLng>[];

        // ✅ ONLY show polylines if there's a shift with bins
        // When no shift → clean map (no route lines)
        if (shiftState.routeBins.isNotEmpty) {
          // Case 1: During simulation - show REMAINING route with smooth interpolation
          if (simulationState.isSimulating &&
            simulationState.routePolyline.isNotEmpty) {
          AppLogger.map('   → Using SIMULATION route');
          // For simulation: show remaining route starting from CURRENT SIMULATED position
          if (simulationState.currentSegmentIndex <
                  simulationState.routePolyline.length - 1 &&
              simulationState.simulatedPosition != null) {
            // Start polyline from simulated position (same as blue dot marker!)
            routePoints.add(simulationState.simulatedPosition!);

            // Add remaining route points (from next segment onwards)
            final remainingPoints = simulationState.routePolyline.skip(
              simulationState.currentSegmentIndex + 1,
            );
            routePoints.addAll(remainingPoints);
          } else {
            // At or near end of route - show full route
            routePoints.addAll(simulationState.routePolyline);
          }

          final routePolyline = Polyline(
            polylineId: 'route',
            options: PolylineOptions(
              points: routePoints,
              strokeColor: AppColors.primaryBlue,
              strokeWidth: 8, // Thicker during simulation for visibility
              visible: true,
              zIndex: 100,
            ),
          );

          polylines.value = {routePolyline};

          // Only log when segment changes (not on every frame!)
          if (lastLoggedSegment.value != simulationState.currentSegmentIndex) {
            lastLoggedSegment.value = simulationState.currentSegmentIndex;
            AppLogger.map('✅ SIMULATION Route polyline updated');
            AppLogger.map('   Remaining points: ${routePoints.length}');
            AppLogger.map(
              '   Current segment: ${simulationState.currentSegmentIndex}/${simulationState.routePolyline.length - 1}',
            );
            AppLogger.map(
              '   Segment progress: ${(simulationState.segmentProgress * 100).toStringAsFixed(1)}%',
            );
          }
        }
        else if (routeBins != null && routeBins.isNotEmpty) {
          // Case 2: Fallback - draw simple straight lines from current location through bins
          AppLogger.map('   → Using FALLBACK route (manual bins)');
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
                strokeColor: AppColors.primaryBlue,
                strokeWidth: 4,
                visible: true,
                zIndex: 100,
              ),
            );

            polylines.value = {routePolyline};

            AppLogger.map('✅ FALLBACK Route polyline set (simple lines)');
            AppLogger.map('   Points: ${routePoints.length}');
          } else {
            polylines.value = {};
            AppLogger.map('❌ No route points to draw');
          }
        } else {
          polylines.value = {};
          // AppLogger.map('   → NO ROUTE (all sources unavailable)');
        }
        } else {
          // No shift bins → clean map with no route polylines
          polylines.value = {};
        }

        // Add user location marker (only when NOT simulating and NOT following)
        // During simulation, we use overlays (centered or positioned) instead
        final userPosition =
            simulationState.simulatedPosition ??
            (location != null
                ? LatLng(latitude: location.latitude, longitude: location.longitude)
                : null);

        // ✅ Show user location marker
        // When shift exists → custom navigation arrow
        // When no shift → use Google Maps built-in blue dot (enabled via controller.setMyLocationEnabled)
        if (userPosition != null &&
            !simulationState.isSimulating &&
            shiftState.routeBins.isNotEmpty) {
          // Show custom navigation arrow for shift-based navigation
          if (navigationArrowIcon.value != null) {
            // Determine rotation based on movement state
            // If moving (speed >= 1 m/s): use GPS bearing
            // If stationary (speed < 1 m/s): use compass heading
            final currentSpeed = location?.speed ?? 0.0;
            const speedThreshold = 1.0; // m/s (~3.6 km/h)

            final isMoving = currentSpeed >= speedThreshold;
            final gpsBearing =
                simulationState.smoothedBearing ?? simulationState.bearing;

            // Rotation logic: GPS bearing when moving, compass when stationary
            final rawRotation = isMoving
                ? gpsBearing
                : (compassHeading.value ?? gpsBearing);

            // SVG arrow points northeast (~45°) by default, so subtract offset to make it point north
            const svgRotationOffset = 45.0;
            final rotation = rawRotation - svgRotationOffset;

            newMarkers.add(
              Marker(
                markerId: 'current_location_arrow',
                options: MarkerOptions(
                  position: userPosition,
                  icon: navigationArrowIcon.value!,
                  anchor: const MarkerAnchor(u: 0.5, v: 0.5),
                  flat: true, // Keeps marker straight on ground plane - critical!
                  rotation: rotation, // Rotation based on movement state
                  zIndex: 1000,
                ),
              ),
            );
          }
        }

        markers.value = newMarkers;
        return null;
      },
      [
        binsState.value,
        locationState.value,
        routeState.value,
        markerCache,
        simulationState.simulatedPosition,
        simulationState.isSimulating,
        simulationState.routePolyline,
        simulationState.segmentProgress,
        simulationState.currentSegmentIndex,
        shiftState.status,
        navigationArrowIcon.value,
        compassHeading.value,
        simulationState.bearing,
        simulationState.smoothedBearing,
      ],
    );

    // Route change detection during simulation (prevent crashes)
    useEffect(() {
      // If route changes while simulation is running, stop simulation
      if (simulationState.isSimulating &&
          simulationState.routePolyline.isNotEmpty) {
        // Check if current segment index is out of bounds
        if (simulationState.currentSegmentIndex >=
            simulationState.routePolyline.length) {
          AppLogger.navigation(
            '⚠️  Route changed during simulation - stopping for safety',
          );
          ref.read(simulationNotifierProvider.notifier).stopSimulation();
        }
      }
      return null;
    }, [simulationState.routePolyline]);

    // Continuous first-person camera following during active shift
    // DISABLED: Let Google Maps control the camera naturally
    useEffect(
      () {
        // Disabled - no custom camera animation on home map
        return null;

        // Only run when shift is active
        // ignore: dead_code
        if (shiftState.status != ShiftStatus.active) {
          // Reset bearing smoothing and auto-follow when shift ends
          smoothedBearing.value = null;
          isAutoFollowEnabled.value = true; // Reset for next shift
          return null;
        }

        // Need location and map controller
        if (locationState.value == null || mapController.value == null) {
          return null;
        }

        // Don't update if user is simulating
        if (simulationState.isSimulating) {
          return null;
        }

        // Don't update camera if user disabled auto-follow by panning
        if (!isAutoFollowEnabled.value) {
          AppLogger.map('📹 Camera auto-follow DISABLED (user panned map)');
          return null;
        }

        final location = LatLng(
          latitude: locationState.value!.latitude,
          longitude: locationState.value!.longitude,
        );

        // Speed-aware bearing: use GPS when moving, compass when stationary
        final currentSpeed = locationState.value!.speed ?? 0.0;
        const speedThreshold = 1.0; // m/s (~3.6 km/h)
        final isMoving = currentSpeed >= speedThreshold;
        final gpsBearing =
            simulationState.smoothedBearing ?? simulationState.bearing;

        final rawBearing = isMoving
            ? gpsBearing
            : (compassHeading.value ?? gpsBearing);

        // Debug logs for camera bearing
        AppLogger.map('📹 CAMERA BEARING DEBUG (Active Shift):');
        AppLogger.map(
          '   currentSpeed: ${currentSpeed.toStringAsFixed(2)} m/s',
        );
        AppLogger.map(
          '   isMoving: $isMoving (threshold: $speedThreshold m/s)',
        );
        AppLogger.map(
          '   compassHeading: ${compassHeading.value?.toStringAsFixed(2) ?? "NULL"}°',
        );
        AppLogger.map('   gpsBearing: ${gpsBearing.toStringAsFixed(2)}°');
        AppLogger.map(
          '   → Selected bearing source: ${isMoving ? "GPS" : "COMPASS"}',
        );
        AppLogger.map('   → rawBearing: ${rawBearing.toStringAsFixed(2)}°');

        // Apply exponential smoothing to bearing (70% old + 30% new)
        if (smoothedBearing.value == null) {
          smoothedBearing.value = rawBearing;
        } else {
          smoothedBearing.value =
              smoothedBearing.value! * BinConstants.bearingSmoothingFactor +
              rawBearing * (1 - BinConstants.bearingSmoothingFactor);
        }

        AppLogger.map(
          '   → smoothedBearing: ${smoothedBearing.value!.toStringAsFixed(2)}°',
        );

        // Throttle camera updates to max 10 FPS (100ms intervals)
        final now = DateTime.now();
        if (now.difference(lastCameraUpdate.value).inMilliseconds <
            BinConstants.cameraUpdateThrottleMs) {
          return null; // Skip this update
        }
        lastCameraUpdate.value = now;

        // Only update camera in navigation (3D) mode
        // In 2D mode, let user control the camera
        if (!simulationState.isNavigationMode) {
          return null;
        }

        // Schedule camera update for next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mapController.value != null) {
            try {
              final finalBearing = smoothedBearing.value ?? rawBearing;
              AppLogger.map('📹 ANIMATING CAMERA:');
              AppLogger.map(
                '   target: (${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)})',
              );
              AppLogger.map('   zoom: ${BinConstants.navigationZoom}');
              AppLogger.map('   bearing: ${finalBearing.toStringAsFixed(2)}°');
              AppLogger.map('   tilt: ${BinConstants.navigationTilt}°');

              mapController.value!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: location,
                    zoom: BinConstants.navigationZoom, // 18
                    bearing: finalBearing,
                    tilt: BinConstants.navigationTilt, // 45° first-person view
                  ),
                ),
              );
              AppLogger.map('   ✅ Camera animation sent to Google Maps');
            } catch (e) {
              // Controller was disposed - ignore error
              AppLogger.map(
                '❌ Camera animation skipped - controller disposed',
                level: AppLogger.debug,
              );
            }
          }
        });

        return null;
      },
      [
        locationState.value,
        shiftState.status,
        mapController.value,
        simulationState.isSimulating,
        simulationState.isNavigationMode,
        simulationState.smoothedBearing,
        simulationState.bearing,
        compassHeading.value,
        isAutoFollowEnabled.value,
      ],
    );

    // Camera following during simulation (only when isFollowing is true)
    useEffect(
      () {
        if (!simulationState.isSimulating ||
            simulationState.simulatedPosition == null ||
            mapController.value == null) {
          return null;
        }

        // Only update camera if following
        if (!simulationState.isFollowing) {
          return null; // Don't update camera if user panned away
        }

        // Only update camera in navigation (3D) mode when following
        if (!simulationState.isNavigationMode) {
          return null; // Don't update camera in 2D mode
        }

        // Get raw bearing from simulation
        final rawBearing =
            simulationState.smoothedBearing ?? simulationState.bearing;

        // Apply exponential smoothing to bearing (70% old + 30% new)
        if (smoothedBearing.value == null) {
          smoothedBearing.value = rawBearing;
        } else {
          smoothedBearing.value =
              smoothedBearing.value! * BinConstants.bearingSmoothingFactor +
              rawBearing * (1 - BinConstants.bearingSmoothingFactor);
        }

        // Throttle camera updates to max 10 FPS (100ms intervals)
        final now = DateTime.now();
        if (now.difference(lastCameraUpdate.value).inMilliseconds <
            BinConstants.cameraUpdateThrottleMs) {
          return null; // Skip this update
        }
        lastCameraUpdate.value = now;

        // Schedule camera update for next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mapController.value != null &&
              simulationState.simulatedPosition != null) {
            try {
              mapController.value!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: simulationState.simulatedPosition!,
                    zoom: BinConstants
                        .navigationZoom, // Close zoom for navigation
                    bearing: smoothedBearing.value ?? rawBearing,
                    tilt: BinConstants.navigationTilt, // 3D tilted view
                  ),
                ),
              );
            } catch (e) {
              // Controller was disposed - ignore error
              AppLogger.map(
                'Camera animation skipped - controller disposed',
                level: AppLogger.debug,
              );
            }
          }
        });

        return null;
      },
      [
        simulationState.simulatedPosition,
        simulationState.isSimulating,
        simulationState.isNavigationMode,
        simulationState.isFollowing,
        simulationState.smoothedBearing,
        simulationState.bearing,
      ],
    );

    // NOTE: Removed custom camera following for no-shift case
    // When there's no shift, we use vanilla Google Maps with default behavior
    // (no forced camera movements, user controls the map freely)

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, // Dark status bar icons
      child: Scaffold(
        body: binsState.when(
          data: (bins) {
            return Stack(
              children: [
                // Google Map wrapped in Listener to detect user pan gestures
                Listener(
                  onPointerDown: (event) {
                    // User touched the screen - disable following mode
                    if (simulationState.isFollowing &&
                        simulationState.isSimulating) {
                      AppLogger.navigation(
                        '👆 User touched map - disabling simulation following',
                      );
                      ref
                          .read(simulationNotifierProvider.notifier)
                          .setFollowing(false);
                    }

                    // Disable auto-follow for active shift camera
                    if (shiftState.status == ShiftStatus.active &&
                        isAutoFollowEnabled.value) {
                      AppLogger.map(
                        '👆 User touched map - disabling camera auto-follow',
                      );
                      isAutoFollowEnabled.value = false;
                    }
                  },
                  child: GoogleMapsMapView(
                    key: const ValueKey('driver_map'),
                    initialCameraPosition: CameraPosition(
                      target: initialCenter,
                      zoom: shiftState.routeBins.isEmpty ? 15.0 : 10.0, // Closer zoom when no shift
                      tilt: 0.0, // Always start in 2D mode
                      bearing: 0.0, // North-up orientation
                    ),
                    initialMapType: MapType.normal,
                    // Disable zoom controls (+ and - buttons) - Android only feature
                    initialZoomControlsEnabled: false,
                    onViewCreated: (controller) async {
                      mapController.value = controller;

                      // Enable My Location (blue dot) - Google Maps built-in feature
                      try {
                        await controller.setMyLocationEnabled(true);
                        AppLogger.map('✅ My Location (blue dot) enabled');
                      } catch (e) {
                        AppLogger.map('⚠️  Failed to enable My Location: $e');
                      }

                      // Disable the default My Location button (we'll use a custom one)
                      try {
                        await controller.settings.setMyLocationButtonEnabled(false);
                        AppLogger.map('✅ Default My Location button disabled (using custom button)');
                      } catch (e) {
                        AppLogger.map('⚠️  Failed to disable My Location button: $e');
                      }

                      // CUSTOM MAP STYLE DISABLED - Using default Google Maps style
                      // ✅ ONLY apply custom map style when there's a shift
                      // When no shift → vanilla Google Maps style
                      // if (shiftState.routeBins.isNotEmpty) {
                      //   const mapStyle = '''
                      // [
                      //   {
                      //     "featureType": "poi",
                      //     "elementType": "geometry",
                      //     "stylers": [{"visibility": "off"}]
                      //   },
                      //   {
                      //     "featureType": "poi",
                      //     "elementType": "labels",
                      //     "stylers": [{"visibility": "off"}]
                      //   },
                      //   {
                      //     "featureType": "landscape.man_made",
                      //     "elementType": "geometry.fill",
                      //     "stylers": [{"visibility": "off"}]
                      //   },
                      //   {
                      //     "featureType": "landscape.man_made",
                      //     "elementType": "geometry.stroke",
                      //     "stylers": [{"visibility": "off"}]
                      //   }
                      // ]
                      // ''';
                      //
                      //   try {
                      //     await controller.setMapStyle(mapStyle);
                      //     AppLogger.map(
                      //       '✅ Custom map style applied - buildings hidden',
                      //     );
                      //   } catch (e) {
                      //     AppLogger.map('⚠️  Failed to apply map style: $e');
                      //   }
                      // } else {
                      //   // Reset to default style (vanilla Google Maps)
                      //   try {
                      //     await controller.setMapStyle(null);
                      //     AppLogger.map('✅ Default Google Maps style applied');
                      //   } catch (e) {
                      //     AppLogger.map('⚠️  Failed to reset map style: $e');
                      //   }
                      // }
                      AppLogger.map('✅ Using default Google Maps style (custom style disabled)');

                      AppLogger.map('🗺️  Google Map created');
                      AppLogger.map(
                        '   Markers count: ${markers.value.length}',
                      );
                      AppLogger.map(
                        '   Polylines count: ${polylines.value.length}',
                      );
                    },
                    // Note: Camera position tracking removed as onCameraChanged is not available in this API version
                    // Blue dot overlay may need alternative camera position tracking if required
                  ),
                ),
                // Blue dot overlays during simulation (smooth 60 FPS movement)
                if (simulationState.isSimulating &&
                    simulationState.simulatedPosition != null) ...[
                  // Centered overlay when following
                  if (simulationState.isFollowing)
                    const NavigationBlueDotOverlay(),
                  // Positioned overlay when panned away (synchronous calculation)
                  if (!simulationState.isFollowing)
                    PositionedBlueDotOverlay(
                      position: simulationState.simulatedPosition!,
                      mapController: mapController.value,
                      cameraPosition: cameraPosition,
                    ),
                ],
                // All overlays wrapped in SafeArea
                SafeArea(
                  child: Stack(
                    children: [
                      // Notification bell button (DoorDash-inspired - top left)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NotificationsPage(),
                                  ),
                                );
                              },
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: Responsive.padding(
                                  context,
                                  mobile: 10.0,
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      Icons.notifications_outlined,
                                      color: AppColors.primaryBlue,
                                      size: Responsive.iconSize(
                                        context,
                                        mobile: 22,
                                      ),
                                    ),
                                    // Notification badge
                                    binsState.whenOrNull(
                                          data: (bins) {
                                            final highFillCount = bins
                                                .where(
                                                  (b) =>
                                                      (b.fillPercentage ?? 0) >
                                                      BinConstants
                                                          .criticalFillThreshold,
                                                )
                                                .length;
                                            if (highFillCount == 0)
                                              return const SizedBox.shrink();

                                            return Positioned(
                                              right: -4,
                                              top: -4,
                                              child: Container(
                                                padding: Responsive.padding(
                                                  context,
                                                  mobile: 3,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: AppColors.alertRed,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints: BoxConstraints(
                                                  minWidth: Responsive.spacing(
                                                    context,
                                                    mobile: 16,
                                                  ),
                                                  minHeight: Responsive.spacing(
                                                    context,
                                                    mobile: 16,
                                                  ),
                                                ),
                                                child: Text(
                                                  highFillCount > 9
                                                      ? '9+'
                                                      : '$highFillCount',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: Responsive.fontSize(
                                                      context,
                                                      mobile: 9,
                                                    ),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            );
                                          },
                                        ) ??
                                        const SizedBox.shrink(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
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
                      //           ? AppColors.primaryBlue
                      //           : Colors.white,
                      //       shape: BoxShape.circle,
                      //       boxShadow: [
                      //         BoxShadow(
                      //           color: Colors.black.withOpacity(0.1),
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
                      // 2D/3D toggle button (below recenter)
                      // Show during simulation OR active shift
                      if (simulationState.isSimulating ||
                          shiftState.status == ShiftStatus.active)
                        Positioned(
                          top: 128,
                          right: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  ref
                                      .read(simulationNotifierProvider.notifier)
                                      .toggleNavigationMode();

                                  // Immediately update camera to reflect new mode
                                  final location =
                                      simulationState.simulatedPosition ??
                                      (locationState.value != null
                                          ? LatLng(
                                              latitude: locationState.value!.latitude,
                                              longitude: locationState.value!.longitude,
                                            )
                                          : null);

                                  if (location != null &&
                                      mapController.value != null) {
                                    try {
                                      // Toggle between 2D and 3D
                                      final willBe3D = !simulationState
                                          .isNavigationMode; // It will be toggled

                                      mapController.value!.animateCamera(
                                        CameraUpdate.newCameraPosition(
                                          CameraPosition(
                                            target: location,
                                            zoom: willBe3D
                                                ? BinConstants.navigationZoom
                                                : 15.0,
                                            bearing: willBe3D
                                                ? (simulationState
                                                          .smoothedBearing ??
                                                      simulationState.bearing)
                                                : 0.0,
                                            tilt: willBe3D
                                                ? BinConstants.navigationTilt
                                                : 0.0, // 45° vs 0°
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      AppLogger.map(
                                        'Camera toggle skipped - controller disposed',
                                        level: AppLogger.debug,
                                      );
                                    }
                                  }
                                },
                                customBorder: const CircleBorder(),
                                child: Padding(
                                  padding: Responsive.padding(
                                    context,
                                    mobile: 12.0,
                                  ),
                                  child: Transform.scale(
                                    scaleX: simulationState.isNavigationMode
                                        ? -1
                                        : 1,
                                    child: Icon(
                                      Icons.explore,
                                      color: Colors.grey.shade800,
                                      size: Responsive.iconSize(
                                        context,
                                        mobile: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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
                      // Pre-shift overview card (when route assigned) or empty state
                      // Show only when NOT in active shift (active shift has its own bottom sheet)
                      if (shiftState.status != ShiftStatus.active)
                        Positioned(
                          bottom: 90, // Position very close to bottom tab navigator
                          left: 0,
                          right: 0,
                          child: AnimatedShiftTransitionWithSlide(
                            useSlideAnimation: true, // Use slide-up animation for bottom content
                            hasActiveShift: shiftState.status == ShiftStatus.ready,
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
                            activeRouteCard: PreShiftOverviewCard(
                            shiftOverview: ShiftOverview(
                              shiftId: shiftState.assignedRouteId ?? '',
                              startTime: DateTime.now(),
                              estimatedEndTime: DateTime.now().add(
                                Duration(
                                  hours: (shiftState.totalBins * 0.25).ceil(),
                                ),
                              ), // ~15 min per bin
                              totalBins: shiftState.totalBins,
                              totalDistanceKm: _calculateTotalDistance(
                                shiftState.routeBins,
                              ),
                              routeBins: shiftState.routeBins,
                              routeName:
                                  'Route ${shiftState.assignedRouteId ?? ''}',
                            ),
                            onStartShift: () async {
                              AppLogger.general('🚀 START SHIFT - Button pressed');

                              // Show loading overlay
                              AppLogger.general('📱 START SHIFT - Showing loading overlay');
                              EasyLoading.show(
                                status: 'Starting shift...',
                                maskType: EasyLoadingMaskType.black,
                              );

                              try {
                                // Start the shift
                                AppLogger.general('📡 START SHIFT - Calling startShift() API');
                                await ref
                                    .read(shiftNotifierProvider.notifier)
                                    .startShift();
                                AppLogger.general('✅ START SHIFT - API call successful');

                                // Hide loading
                                AppLogger.general('📱 START SHIFT - Dismissing loading overlay');
                                await EasyLoading.dismiss();

                                // Navigate to navigation page with iOS-style slide transition
                                AppLogger.general('🧭 START SHIFT - Navigating to GoogleNavigationPage');
                                if (context.mounted) {
                                  context.push('/navigation');
                                  AppLogger.general('✅ START SHIFT - Navigation complete');
                                } else {
                                  AppLogger.general('❌ START SHIFT - Context not mounted, cannot navigate!');
                                }
                              } catch (e) {
                                AppLogger.general('❌ START SHIFT - Error: $e');

                                // Hide loading
                                await EasyLoading.dismiss();

                                // Show error
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to start shift: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                            ), // End of AnimatedShiftTransition
                        ),
                      // Active shift bottom sheet
                      if (shiftState.status == ShiftStatus.active)
                        Positioned(
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
                              if (mapController.value != null) {
                                try {
                                  mapController.value!.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                      CameraPosition(
                                        target: LatLng(
                                          latitude: nextBin.latitude,
                                          longitude: nextBin.longitude,
                                        ),
                                        zoom: 17.0, // Closer zoom for bin view
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  AppLogger.map(
                                    'Map recenter skipped - controller disposed',
                                    level: AppLogger.debug,
                                  );
                                }
                              }
                            },
                          ),
                        ),

                      // Custom My Location button - positioned just above Today's Route card
                      Positioned(
                        bottom: 310,
                        right: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                if (mapController.value != null) {
                                  final location = await mapController.value!.getMyLocation();
                                  if (location != null) {
                                    await mapController.value!.animateCamera(
                                      CameraUpdate.newLatLng(location),
                                    );
                                    AppLogger.map('📍 Centered on user location');
                                  }
                                }
                              },
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: Responsive.iconSize(
                                  context,
                                  mobile: 42,
                                ),
                                height: Responsive.iconSize(
                                  context,
                                  mobile: 42,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.my_location,
                                  color: AppColors.primaryBlue,
                                  size: Responsive.iconSize(
                                    context,
                                    mobile: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                Text(
                  'Error loading bins',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(binsListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
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
