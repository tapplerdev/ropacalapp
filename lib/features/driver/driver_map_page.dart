import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
import 'package:ropacalapp/providers/bins_provider.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/providers/bin_marker_cache_provider.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/simulation_provider.dart';
import 'package:ropacalapp/providers/here_route_provider.dart';
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
import 'package:ropacalapp/features/driver/google_navigation_page.dart';
import 'package:ropacalapp/models/shift_overview.dart';
import 'package:ropacalapp/features/driver/navigation_page.dart';
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
    // DEPRECATED: Using Mapbox instead of HERE - setting to null to avoid compilation errors
    final hereRouteData = null; // ref.watch(hereRouteMetadataProvider);
    final user = ref.watch(authNotifierProvider).value;
    final mapController = useState<GoogleMapController?>(null);
    final markers = useState<Set<Marker>>({});
    final polylines = useState<Set<Polyline>>({});
    final cameraPosition = useMemoized(
      () => ValueNotifier<CameraPosition?>(null),
      [],
    );
    final navigationArrowIcon = useState<BitmapDescriptor?>(null);
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
              locationState.value!.latitude,
              locationState.value!.longitude,
            )
          : const LatLng(37.3382, -121.8863), // San Jose, CA
      [locationState.value],
    );

    // Load navigation arrow icon on mount
    useEffect(() {
      AppLogger.map('🔍 DEBUG - Loading navigation arrow marker...');
      NavigationArrowMarkerPainter.createNavigationArrow(size: 96.0)
          .then((icon) {
            navigationArrowIcon.value = icon;
            AppLogger.map(
              '✅ DEBUG - Navigation arrow marker loaded successfully',
            );
            AppLogger.map('   Icon: ${icon.toString()}');
          })
          .catchError((error) {
            AppLogger.map('❌ DEBUG - Failed to load navigation arrow: $error');
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

    // DEPRECATED: HERE Maps debugging - commented out during Mapbox migration
    // DEBUG: Track hereRouteData provider updates
    // useEffect(() {
    //   AppLogger.map('🔔 DEBUG - hereRouteData provider changed!');
    //   AppLogger.map(
    //     '   Value: ${hereRouteData != null ? "EXISTS (${hereRouteData!.polyline.length} points)" : "NULL"}',
    //   );
    //   if (hereRouteData != null) {
    //     AppLogger.map('   Total distance: ${hereRouteData!.totalDistance}m');
    //     AppLogger.map('   Total duration: ${hereRouteData!.totalDuration}s');
    //   }
    //   return null;
    // }, [hereRouteData]);

    // Update markers and polylines when data changes
    useEffect(
      () {
        final bins = binsState.value;
        final routeBins = routeState.value;
        final location = locationState.value;

        // DEBUG: Check data availability
        AppLogger.map('🔍 DEBUG - Data availability check:');
        // DEPRECATED: HERE Maps - commented out during Mapbox migration
        // AppLogger.map(
        //   '   hereRouteData: ${hereRouteData != null ? "EXISTS (${hereRouteData!.polyline.length} points)" : "NULL"}',
        // );
        AppLogger.map(
          '   shiftState.routeBins: ${shiftState.routeBins.isNotEmpty ? "${shiftState.routeBins.length} bins" : "EMPTY"}',
        );
        AppLogger.map(
          '   routeState.value: ${routeBins != null ? "${routeBins.length} bins" : "NULL"}',
        );
        AppLogger.map('   shift status: ${shiftState.status}');

        // Use marker cache for instant marker rendering
        final newMarkers = <Marker>{};

        // ✅ ONLY show markers for bins in the assigned shift
        // When no shift → routeBins is empty → clean map with just blue dot
        if (shiftState.routeBins.isNotEmpty && bins != null) {
          AppLogger.map('📍 Creating markers for ${shiftState.routeBins.length} bins from shift');

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
                  markerId: MarkerId('route_bin_${routeBin.id}'),
                  position: LatLng(routeBin.latitude, routeBin.longitude),
                  icon: routeIcon ?? BitmapDescriptor.defaultMarker,
                  anchor: const Offset(0.5, 0.5),
                  consumeTapEvents: true,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => BinDetailsBottomSheet(bin: binForSheet),
                  ),
                ),
              );
            }
          }
        } else {
          AppLogger.map('📍 No shift bins - showing clean map (no markers)');
        }

        // Add route polyline (priority: simulation > HERE Maps > simple lines)
        final routePoints = <LatLng>[];

        AppLogger.map('🔍 DEBUG - Polyline decision:');
        AppLogger.map('   isSimulating: ${simulationState.isSimulating}');
        AppLogger.map('   shift has bins: ${shiftState.routeBins.isNotEmpty}');
        AppLogger.map('   routeBins != null: ${routeBins != null}');

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
            routePoints.addAll(
              remainingPoints.map(
                (point) => LatLng(point.latitude, point.longitude),
              ),
            );
          } else {
            // At or near end of route - show full route
            routePoints.addAll(
              simulationState.routePolyline.map(
                (point) => LatLng(point.latitude, point.longitude),
              ),
            );
          }

          final routePolyline = Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: AppColors.primaryBlue,
            width: 8, // Thicker during simulation for visibility
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
            visible: true,
            zIndex: 100,
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
        // DEPRECATED: HERE Maps - commented out during Mapbox migration
        // else if (hereRouteData != null && hereRouteData.polyline.isNotEmpty) {
        //   // Case 2: HERE Maps route available - show detailed traffic-aware route
        //   AppLogger.map('   → Using HERE MAPS route');
        //   routePoints.addAll(
        //     hereRouteData.polyline.map(
        //       (point) => LatLng(point.latitude, point.longitude),
        //     ),
        //   );

        //   final routePolyline = Polyline(
        //     polylineId: const PolylineId('route'),
        //     points: routePoints,
        //     color: AppColors.primaryBlue,
        //     width: 5,
        //     startCap: Cap.roundCap,
        //     endCap: Cap.roundCap,
        //     jointType: JointType.round,
        //     visible: true,
        //     zIndex: 100,
        //   );

        //   polylines.value = {routePolyline};

        //   AppLogger.map('✅ HERE MAPS Route polyline set');
        //   AppLogger.map('   Points: ${routePoints.length}');
        //   AppLogger.map(
        //     '   Distance: ${(hereRouteData.totalDistance / 1000).toStringAsFixed(2)} km',
        //   );
        // }
        else if (routeBins != null && routeBins.isNotEmpty) {
          // Case 3: Fallback - draw simple straight lines from current location through bins
          AppLogger.map('   → Using FALLBACK route (manual bins)');
          if (location != null) {
            routePoints.add(LatLng(location.latitude, location.longitude));
          }
          routePoints.addAll(
            routeBins
                .where((b) => b.latitude != null && b.longitude != null)
                .map((b) => LatLng(b.latitude!, b.longitude!)),
          );

          if (routePoints.isNotEmpty) {
            final routePolyline = Polyline(
              polylineId: const PolylineId('route'),
              points: routePoints,
              color: AppColors.primaryBlue,
              width: 4,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
              visible: true,
              zIndex: 100,
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
          AppLogger.map('   → NO ROUTE (all sources unavailable)');
          // DEPRECATED: HERE Maps reference - commented out during Mapbox migration
          // AppLogger.map(
          //   '❌ No route polyline (not simulating, no HERE data, no routeBins)',
          // );
          AppLogger.map(
            '❌ No route polyline (not simulating, no routeBins)',
          );
        }
        } else {
          // No shift bins → clean map with no route polylines
          polylines.value = {};
          AppLogger.map('📍 No shift bins - clean map (no route polylines)');
        }

        // Add user location marker (only when NOT simulating and NOT following)
        // During simulation, we use overlays (centered or positioned) instead
        final userPosition =
            simulationState.simulatedPosition ??
            (location != null
                ? LatLng(location.latitude, location.longitude)
                : null);

        AppLogger.map('🔍 DEBUG - User marker decision:');
        AppLogger.map(
          '   userPosition: ${userPosition != null ? "EXISTS" : "NULL"}',
        );
        AppLogger.map('   isSimulating: ${simulationState.isSimulating}');
        AppLogger.map('   shiftStatus: ${shiftState.status}');
        AppLogger.map('   shift has bins: ${shiftState.routeBins.isNotEmpty}');
        AppLogger.map(
          '   navigationArrowIcon loaded: ${navigationArrowIcon.value != null}',
        );

        // ✅ ONLY show custom arrow when there's a shift (not during simulation)
        // When no shift → use default Google Maps blue dot (myLocationEnabled: true)
        if (userPosition != null &&
            !simulationState.isSimulating &&
            shiftState.routeBins.isNotEmpty) {
          // Show custom navigation arrow for shift-based navigation
          if (navigationArrowIcon.value != null) {
            AppLogger.map(
              '   → Adding NAVIGATION ARROW marker (current location)',
            );

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
                markerId: const MarkerId('current_location_arrow'),
                position: userPosition,
                icon: navigationArrowIcon.value!,
                anchor: const Offset(0.5, 0.5),
                flat: true, // Keeps marker straight on ground plane - critical!
                rotation: rotation, // Rotation based on movement state
                zIndex: 1000,
              ),
            );
          } else {
            AppLogger.map(
              '   → Navigation arrow not loaded yet, skipping marker',
            );
          }
        } else {
          AppLogger.map('   → NO USER MARKER (userPos null or simulating)');
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
        // DEPRECATED: HERE Maps - removed from dependency array during Mapbox migration
        // hereRouteData,
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
          locationState.value!.latitude,
          locationState.value!.longitude,
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
                  child: GoogleMap(
                    key: const ValueKey('driver_map'),
                    initialCameraPosition: CameraPosition(
                      target: initialCenter,
                      zoom: shiftState.routeBins.isEmpty ? 15.0 : 10.0, // Closer zoom when no shift
                      tilt: 0.0, // Always start in 2D mode
                      bearing: 0.0, // North-up orientation
                    ),
                    myLocationEnabled:
                        shiftState.routeBins.isEmpty, // Default blue dot when no shift, custom arrow when shift exists
                    myLocationButtonEnabled: shiftState.routeBins.isEmpty, // Recenter button when no shift
                    compassEnabled: shiftState.routeBins.isEmpty, // Show compass when no shift
                    trafficEnabled: false, // Always hide traffic on home map
                    buildingsEnabled: shiftState.routeBins.isEmpty, // Show buildings when no shift
                    mapType: MapType.normal,
                    zoomControlsEnabled: false,
                    markers: markers.value,
                    polylines: polylines.value,
                    onMapCreated: (controller) async {
                      mapController.value = controller;

                      // ✅ ONLY apply custom map style when there's a shift
                      // When no shift → vanilla Google Maps style
                      if (shiftState.routeBins.isNotEmpty) {
                        const mapStyle = '''
                    [
                      {
                        "featureType": "poi",
                        "elementType": "geometry",
                        "stylers": [{"visibility": "off"}]
                      },
                      {
                        "featureType": "poi",
                        "elementType": "labels",
                        "stylers": [{"visibility": "off"}]
                      },
                      {
                        "featureType": "landscape.man_made",
                        "elementType": "geometry.fill",
                        "stylers": [{"visibility": "off"}]
                      },
                      {
                        "featureType": "landscape.man_made",
                        "elementType": "geometry.stroke",
                        "stylers": [{"visibility": "off"}]
                      }
                    ]
                    ''';

                        try {
                          await controller.setMapStyle(mapStyle);
                          AppLogger.map(
                            '✅ Custom map style applied - buildings hidden',
                          );
                        } catch (e) {
                          AppLogger.map('⚠️  Failed to apply map style: $e');
                        }
                      } else {
                        // Reset to default style (vanilla Google Maps)
                        try {
                          await controller.setMapStyle(null);
                          AppLogger.map('✅ Default Google Maps style applied');
                        } catch (e) {
                          AppLogger.map('⚠️  Failed to reset map style: $e');
                        }
                      }

                      AppLogger.map('🗺️  Google Map created');
                      AppLogger.map(
                        '   Markers count: ${markers.value.length}',
                      );
                      AppLogger.map(
                        '   Polylines count: ${polylines.value.length}',
                      );
                      if (polylines.value.isNotEmpty) {
                        final polyline = polylines.value.first;
                        AppLogger.map(
                          '   Polyline points: ${polyline.points.length}',
                        );
                        AppLogger.map('   Polyline color: ${polyline.color}');
                        AppLogger.map(
                          '   Polyline visible: ${polyline.visible}',
                        );
                        AppLogger.map('   Polyline width: ${polyline.width}');
                        AppLogger.map('   Polyline zIndex: ${polyline.zIndex}');
                      }

                      // Get initial camera position
                      try {
                        final initialCameraPos = await controller.getLatLng(
                          const ScreenCoordinate(x: 0, y: 0),
                        );
                        cameraPosition.value = CameraPosition(
                          target: initialCameraPos,
                          zoom: 10.0, // Will be updated by onCameraMove
                        );
                      } catch (e) {
                        // Ignore
                      }
                    },
                    onCameraMove: (position) {
                      // Track camera position for synchronous blue dot calculation
                      cameraPosition.value = position;
                    },
                    // Note: Listener.onPointerDown detects actual user touch, unlike onCameraMoveStarted
                    // which fires for both user gestures AND programmatic camera moves
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
                      // Notification bell button (DoorDash style - top right)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
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
                                final bins = binsState.value ?? [];
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) =>
                                      AlertsBottomSheet(bins: bins),
                                );
                              },
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 24,
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
                                                padding: const EdgeInsets.all(
                                                  3,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: AppColors.alertRed,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 16,
                                                      minHeight: 16,
                                                    ),
                                                child: Text(
                                                  highFillCount > 9
                                                      ? '9+'
                                                      : '$highFillCount',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
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
                      // Recenter button (restores following mode)
                      Positioned(
                        top: 72,
                        right: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                (simulationState.isFollowing ||
                                    isAutoFollowEnabled.value)
                                ? AppColors.primaryBlue
                                : Colors.white,
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
                                // Re-enable simulation following
                                ref
                                    .read(simulationNotifierProvider.notifier)
                                    .enableFollowing();

                                // Re-enable camera auto-follow for active shifts
                                if (shiftState.status == ShiftStatus.active) {
                                  AppLogger.map(
                                    '📍 Recenter button tapped - re-enabling camera auto-follow',
                                  );
                                  isAutoFollowEnabled.value = true;
                                }

                                final location =
                                    simulationState.simulatedPosition ??
                                    (locationState.value != null
                                        ? LatLng(
                                            locationState.value!.latitude,
                                            locationState.value!.longitude,
                                          )
                                        : null);

                                if (location != null &&
                                    mapController.value != null) {
                                  try {
                                    // Animate to current position in current mode (preserve 2D/3D state)
                                    mapController.value!.animateCamera(
                                      CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                          target: location,
                                          zoom: simulationState.isNavigationMode
                                              ? BinConstants.navigationZoom
                                              : 15.0,
                                          bearing:
                                              simulationState.isNavigationMode
                                              ? (simulationState
                                                        .smoothedBearing ??
                                                    simulationState.bearing ??
                                                    compassHeading.value ??
                                                    0.0)
                                              : 0.0,
                                          tilt: simulationState.isNavigationMode
                                              ? BinConstants.navigationTilt
                                              : 0.0,
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
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Icon(
                                  Icons.my_location,
                                  color:
                                      (simulationState.isFollowing ||
                                          isAutoFollowEnabled.value)
                                      ? Colors.white
                                      : Colors.grey.shade800,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
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
                                              locationState.value!.latitude,
                                              locationState.value!.longitude,
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
                                  padding: const EdgeInsets.all(12.0),
                                  child: Transform.scale(
                                    scaleX: simulationState.isNavigationMode
                                        ? -1
                                        : 1,
                                    child: Icon(
                                      Icons.explore,
                                      color: Colors.grey.shade800,
                                      size: 24,
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
                      // Pre-shift overview card (when route assigned)
                      if (shiftState.status == ShiftStatus.ready)
                        Positioned(
                          bottom: 80, // Position above bottom tab navigator
                          left: 0,
                          right: 0,
                          child: PreShiftOverviewCard(
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
                                AppLogger.general('🧭 START SHIFT - Checking context.mounted: ${context.mounted}');
                                if (context.mounted) {
                                  AppLogger.general('🧭 START SHIFT - Pushing CupertinoPageRoute to GoogleNavigationPage');
                                  Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (context) {
                                        AppLogger.general('🏗️  START SHIFT - Building GoogleNavigationPage');
                                        return const GoogleNavigationPage();
                                      },
                                    ),
                                  );
                                  AppLogger.general('✅ START SHIFT - Navigation push complete');
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
                                          nextBin.latitude,
                                          nextBin.longitude,
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
  print('🧮 Calculating distance for ${routeBins.length} bins');

  if (routeBins.isEmpty) {
    print('   ⚠️ Route bins is empty, returning 0');
    return 0.0;
  }

  if (routeBins.length == 1) {
    print('   ⚠️ Only 1 bin in route, returning 0');
    return 0.0;
  }

  double totalKm = 0.0;
  final distance = const latlong.Distance();

  for (int i = 0; i < routeBins.length - 1; i++) {
    final current = routeBins[i];
    final next = routeBins[i + 1];

    print('   Bin ${i + 1}: lat=${current.latitude}, lng=${current.longitude}');
    print('   Bin ${i + 2}: lat=${next.latitude}, lng=${next.longitude}');

    final currentPoint = latlong.LatLng(current.latitude, current.longitude);
    final nextPoint = latlong.LatLng(next.latitude, next.longitude);

    // Use .distance() method which returns meters
    final segmentMeters = distance.distance(currentPoint, nextPoint);
    final segmentKm = segmentMeters / 1000.0;

    print('   → Raw distance (meters): $segmentMeters');
    print('   → Distance to bin ${i + 2}: ${segmentKm.toStringAsFixed(4)} km');
    totalKm += segmentKm;
  }

  print('   ✅ Total distance: ${totalKm.toStringAsFixed(2)} km');
  return totalKm;
}
