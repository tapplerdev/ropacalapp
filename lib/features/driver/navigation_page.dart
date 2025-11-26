import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/enums/bin_status.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
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
import 'package:ropacalapp/models/shift_overview.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/core/services/here_maps_service.dart';
import 'package:ropacalapp/providers/here_route_provider.dart';
import 'package:ropacalapp/core/utils/blue_dot_marker_painter.dart';
import 'package:ropacalapp/core/utils/navigation_arrow_marker_painter.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';

/// Navigation Page - Driver navigation with real-time routing using HERE Maps API
/// Features: Compass-based navigation arrow, real-time traffic, route optimization
class NavigationPage extends HookConsumerWidget {
  const NavigationPage({super.key});

  // HERE Maps API key from https://developer.here.com/
  static const String _hereApiKey =
      '8hXsQAEELb3aPPndHQRwOsefH8jlAvid6avXjzjxOhQ';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final binsState = ref.watch(binsListProvider);
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
    final blueDotMarkerIcon = useState<BitmapDescriptor?>(null);
    final navigationArrowIcon = useState<BitmapDescriptor?>(null);
    final compassHeading = useState<double?>(null);

    // HERE Maps service instance
    final hereService = useMemoized(
      () => HEREMapsService(apiKey: _hereApiKey),
      [],
    );

    // Camera update throttling
    final lastCameraUpdate = useRef<DateTime>(DateTime.now());
    final smoothedBearing = useRef<double?>(null);
    final lastLoggedSegment = useRef<int>(-1);
    final hasInitializedNavigation = useRef<bool>(false);

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

    // Create custom blue dot marker icon (once) - KEPT FOR REFERENCE
    useEffect(() {
      BlueDotMarkerPainter.createBlueDotMarker(size: 40.0).then((icon) {
        blueDotMarkerIcon.value = icon;
        AppLogger.map('✅ Custom blue dot marker created (40px)');
      });
      return null;
    }, []);

    // Create navigation arrow marker icon (once) from SVG asset
    useEffect(() {
      NavigationArrowMarkerPainter.createNavigationArrow(size: 96.0).then((
        icon,
      ) {
        navigationArrowIcon.value = icon;
        AppLogger.map('✅ Navigation arrow marker created from SVG (96px)');
      });
      return null;
    }, []);

    // Listen to compass heading
    useEffect(() {
      StreamSubscription? compassSubscription;

      compassSubscription = FlutterCompass.events?.listen((event) {
        if (event.heading != null) {
          compassHeading.value = event.heading;
        }
      });

      return () {
        compassSubscription?.cancel();
      };
    }, []);

    // Auto-enable navigation mode when shift starts (only once)
    useEffect(
      () {
        if (shiftState.status == ShiftStatus.active &&
            shiftState.routeBins != null &&
            shiftState.routeBins!.isNotEmpty &&
            locationState.value != null &&
            mapController.value != null &&
            !hasInitializedNavigation.value) {
          hasInitializedNavigation.value = true;
          AppLogger.navigation(
            '🚀 Shift started - enabling first-person navigation mode',
          );

          // Enable navigation mode and following
          if (!simulationState.isNavigationMode) {
            ref
                .read(simulationNotifierProvider.notifier)
                .toggleNavigationMode();
          }
          if (!simulationState.isFollowing) {
            ref.read(simulationNotifierProvider.notifier).setFollowing(true);
          }

          // Move camera to driver's current position in first-person view
          final currentLocation = locationState.value!;
          final initialBearing = compassHeading.value ?? 0.0;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            mapController.value?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(
                    currentLocation.latitude,
                    currentLocation.longitude,
                  ),
                  zoom: BinConstants.navigationZoom,
                  bearing: initialBearing,
                  tilt: BinConstants.navigationTilt,
                ),
              ),
            );
            AppLogger.navigation(
              '   Camera moved to driver position in first-person view',
            );
          });
        }

        // Reset flag when shift ends
        if (shiftState.status != ShiftStatus.active) {
          hasInitializedNavigation.value = false;
        }

        return null;
      },
      [
        shiftState.status,
        shiftState.routeBins,
        locationState.value,
        mapController.value,
      ],
    );

    // Update markers and polylines when data changes
    useEffect(
      () {
        final bins = binsState.value;
        final routeBins = routeState.value;
        final location = locationState.value;

        if (bins == null) return null;

        final newMarkers = <Marker>{};

        // Add navigation arrow marker - ALWAYS (both when following and panned away)
        // Arrow rotates based on compass heading (where phone is pointing), NOT route direction
        // Show during simulation OR when shift is active with real GPS (for mobile device testing)
        if (navigationArrowIcon.value != null &&
            ((simulationState.isSimulating &&
                    simulationState.simulatedPosition != null) ||
                (shiftState.status == ShiftStatus.active &&
                    location != null))) {
          // Use simulated position if simulating, otherwise use real GPS location
          final position = simulationState.isSimulating
              ? simulationState.simulatedPosition!
              : LatLng(location!.latitude, location!.longitude);

          // Use compass heading if available, otherwise fall back to route bearing
          final rawRotation =
              compassHeading.value ??
              (simulationState.smoothedBearing ?? simulationState.bearing);

          // SVG arrow points northeast (~45°) by default, so subtract offset to make it point north
          const svgRotationOffset = 45.0;
          final rotation = rawRotation - svgRotationOffset;

          newMarkers.add(
            Marker(
              markerId: const MarkerId('navigation_arrow'),
              position: position,
              icon: navigationArrowIcon.value!,
              anchor: const Offset(0.5, 0.5), // Center of the marker
              flat: true, // Marker rotates with map rotation
              rotation: rotation, // Compass heading (where phone points)
              consumeTapEvents: false, // Don't block map interactions
              zIndex: 999,
            ),
          );
        }

        // Add bin markers
        for (final bin in bins) {
          if (bin.latitude != null && bin.longitude != null) {
            final customIcon = ref
                .read(binMarkerCacheNotifierProvider.notifier)
                .getBinMarker(bin.id);

            newMarkers.add(
              Marker(
                markerId: MarkerId('bin_${bin.id}'),
                position: LatLng(bin.latitude!, bin.longitude!),
                icon: customIcon ?? BitmapDescriptor.defaultMarker,
                anchor: const Offset(0.5, 0.5),
                consumeTapEvents: true,
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => BinDetailsBottomSheet(bin: bin),
                ),
              ),
            );
          }
        }

        // Add route markers with numbers
        if (routeBins != null && routeBins.isNotEmpty) {
          for (var i = 0; i < routeBins.length; i++) {
            final bin = routeBins[i];
            if (bin.latitude != null && bin.longitude != null) {
              newMarkers.removeWhere(
                (m) => m.markerId.value == 'bin_${bin.id}',
              );

              final routeIcon = ref
                  .read(binMarkerCacheNotifierProvider.notifier)
                  .getRouteMarker(i + 1);

              newMarkers.add(
                Marker(
                  markerId: MarkerId('route_bin_${bin.id}'),
                  position: LatLng(bin.latitude!, bin.longitude!),
                  icon: routeIcon ?? BitmapDescriptor.defaultMarker,
                  anchor: const Offset(0.5, 0.5),
                  consumeTapEvents: true,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => BinDetailsBottomSheet(bin: bin),
                  ),
                ),
              );
            }
          }
        }

        // Add route polyline - THIS IS WHERE HERE MAPS DIFFERS FROM OSRM
        final routePoints = <LatLng>[];

        // Case 1: During simulation - show remaining route
        if (simulationState.isSimulating &&
            simulationState.routePolyline.isNotEmpty) {
          if (simulationState.currentSegmentIndex <
                  simulationState.routePolyline.length - 1 &&
              simulationState.simulatedPosition != null) {
            routePoints.add(simulationState.simulatedPosition!);

            final remainingPoints = simulationState.routePolyline.skip(
              simulationState.currentSegmentIndex + 1,
            );
            routePoints.addAll(
              remainingPoints.map(
                (point) => LatLng(point.latitude, point.longitude),
              ),
            );
          } else {
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
            width: 8,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
            visible: true,
            zIndex: 100,
          );

          polylines.value = {routePolyline};

          if (lastLoggedSegment.value != simulationState.currentSegmentIndex) {
            lastLoggedSegment.value = simulationState.currentSegmentIndex;
            AppLogger.map('✅ SIMULATION Route polyline updated');
            AppLogger.map('   Remaining points: ${routePoints.length}');
          }
        }
        // DEPRECATED: HERE Maps - commented out during Mapbox migration
        // else if (hereRouteData != null && hereRouteData.polyline.isNotEmpty) {
        //   // Case 2: HERE Maps route available - show detailed traffic-aware route
        //   routePoints.addAll(
        //     hereRouteData.polyline.map(
        //       (point) => LatLng(point.latitude, point.longitude),
        //     ),
        //   );

        //   final routePolyline = Polyline(
        //     polylineId: const PolylineId('route'),
        //     points: routePoints,
        //     color: AppColors.primaryBlue,
        //     width: 6,
        //     startCap: Cap.roundCap,
        //     endCap: Cap.roundCap,
        //     jointType: JointType.round,
        //     visible: true,
        //     zIndex: 200, // Higher to show above traffic
        //   );

        //   polylines.value = {routePolyline};

        //   AppLogger.map('✅ HERE MAPS Route polyline set (detailed)');
        //   AppLogger.map('   Points: ${routePoints.length}');
        //   AppLogger.map(
        //     '   Distance: ${(hereRouteData.totalDistance / 1000).toStringAsFixed(2)} km',
        //   );
        //   AppLogger.map(
        //     '   Duration: ${(hereRouteData.totalDuration / 60).toStringAsFixed(1)} min',
        //   );
        // }
        else if (routeBins != null && routeBins.isNotEmpty) {
          // Case 3: Fallback - simple straight lines
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
            AppLogger.map(
              '✅ FALLBACK Route polyline set (${routePoints.length} points)',
            );
          } else {
            polylines.value = {};
          }
        } else {
          polylines.value = {};
          // DEPRECATED: HERE Maps reference - commented out during Mapbox migration
          // AppLogger.map(
          //   '❌ No route polyline (not simulating, no HERE data, no routeBins)',
          // );
          AppLogger.map(
            '❌ No route polyline (not simulating, no routeBins)',
          );
        }

        // Add user location marker (only when NOT simulating and NOT following)
        // During simulation, we use overlays (centered or positioned) instead
        final userPosition =
            simulationState.simulatedPosition ??
            (location != null
                ? LatLng(location.latitude, location.longitude)
                : null);

        if (userPosition != null &&
            !simulationState.isSimulating &&
            !simulationState.isFollowing) {
          final blueDotIcon = ref
              .read(binMarkerCacheNotifierProvider.notifier)
              .getBlueDotMarker();

          newMarkers.add(
            Marker(
              markerId: const MarkerId('user_location'),
              position: userPosition,
              icon: blueDotIcon ?? BitmapDescriptor.defaultMarker,
              anchor: const Offset(0.5, 0.5),
              flat:
                  false, // Ground-aligned (same perspective as polyline in 3D)
              rotation:
                  simulationState.smoothedBearing ?? simulationState.bearing,
              zIndex: 1000,
            ),
          );
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
        simulationState.isFollowing,
        simulationState.routePolyline,
        simulationState.segmentProgress,
        simulationState.currentSegmentIndex,
        simulationState.bearing,
        simulationState.smoothedBearing,
        // DEPRECATED: HERE Maps - removed from dependency array during Mapbox migration
        // hereRouteData,
        navigationArrowIcon.value,
        compassHeading.value,
      ],
    );

    // Route change detection during simulation
    useEffect(() {
      if (simulationState.isSimulating &&
          simulationState.routePolyline.isNotEmpty) {
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

    // Store location in a ref to avoid triggering useEffect on every location update
    final locationRef = useRef(locationState.value);

    // Update location ref when location changes (separate useEffect)
    useEffect(() {
      locationRef.value = locationState.value;
      return null;
    }, [locationState.value]);

    // Fetch HERE Maps route data when route is optimized OR shift is active
    // Using two-step process: Waypoint Sequence API → Routing API
    useEffect(
      () {
        final optimizedBins = routeState.value;
        final shiftBins = shiftState.status == ShiftStatus.active
            ? shiftState.routeBins
            : null;
        final location = locationRef.value; // Use ref instead of watch

        // Use shift bins if active, otherwise use optimized route bins
        final routeBins = shiftBins ?? optimizedBins;

        // AppLogger.routing('🔍 HERE Maps useEffect triggered:');
        // AppLogger.routing('   optimizedBins: ${optimizedBins?.length ?? 0} bins');
        // AppLogger.routing('   shiftBins: ${shiftBins?.length ?? 0} bins');
        // AppLogger.routing('   isSimulating: ${simulationState.isSimulating}');

        // Early exit conditions
        if (routeBins == null || routeBins.isEmpty || location == null) {
          if ((optimizedBins == null || optimizedBins.isEmpty) &&
              (shiftBins == null || shiftBins.isEmpty)) {
            // DEPRECATED: Using Mapbox instead of HERE
            // Future.microtask(() {
            //   ref.read(hereRouteMetadataProvider.notifier).clearRouteData();
            // });
          }
          return null;
        }

        // Don't fetch during simulation to avoid performance issues
        if (simulationState.isSimulating) {
          // AppLogger.routing('⏸️  Skipping - simulation running');
          return null;
        }

        // AppLogger.routing('✅ Fetching HERE route & waypoint optimization...');

        /// Convert RouteBin to Bin helper
        List<Bin> convertToBins(List<dynamic> bins) {
          if (bins.first is Bin) return bins.cast<Bin>();

          return bins.map((rb) {
            final routeBin = rb as RouteBin;
            return Bin(
              id: routeBin.binId,
              binNumber: routeBin.binNumber,
              currentStreet: routeBin.currentStreet,
              city: routeBin.city,
              zip: routeBin.zip,
              latitude: routeBin.latitude,
              longitude: routeBin.longitude,
              fillPercentage: routeBin.fillPercentage,
              status: BinStatus.active,
              lastMoved: null,
              lastChecked: null,
              checked: false,
              moveRequested: false,
            );
          }).toList();
        }

        // Main route fetching logic with waypoint optimization
        Future<void> fetchOptimizedRoute() async {
          try {
            // Step 1: Convert bins to correct type
            final binList = convertToBins(routeBins);
            final startLatLng = latlong.LatLng(
              location.latitude,
              location.longitude,
            );

            // AppLogger.routing('📍 Current location: ${location.latitude},${location.longitude}');
            // AppLogger.routing('📦 Backend order: ${binList.map((b) => b.binNumber ?? 0).toList()}');

            // Step 2: Get optimized waypoint sequence from Waypoints Sequence API
            final optimizedIndices = await hereService
                .getOptimizedWaypointSequence(
                  start: startLatLng,
                  destinations: binList,
                  departureTime: DateTime.now(),
                  improveFor: 'time', // Optimize for travel time
                );

            // Step 3: Reorder bins based on optimization result
            List<Bin> orderedBins;
            if (optimizedIndices != null && optimizedIndices.isNotEmpty) {
              orderedBins = optimizedIndices
                  .map((idx) => binList[idx])
                  .toList();
              // AppLogger.routing('🎯 HERE optimal order: ${orderedBins.map((b) => b.binNumber ?? 0).toList()}');

              // Log differences
              for (int i = 0; i < binList.length; i++) {
                final backendBin = binList[i].binNumber ?? 0;
                final hereBin = orderedBins[i].binNumber ?? 0;
                if (backendBin != hereBin) {
                  // AppLogger.routing('   Position $i: Backend=#$backendBin → HERE=#$hereBin ⚡');
                }
              }

              // Update route provider with optimized order (only if not in shift)
              if (shiftBins == null) {
                Future.microtask(() {
                  ref.read(optimizedRouteProvider.notifier).state =
                      AsyncValue.data(orderedBins);
                });
              }
            } else {
              // No optimization available - use backend order
              // AppLogger.routing('⚠️  No optimization, using backend order');
              orderedBins = binList;
            }

            // Step 4: Get route with optimized waypoint order
            final hereResponse = await hereService.getRoute(
              start: startLatLng,
              destinations: orderedBins, // Use optimized order
              departureTime: DateTime.now(),
            );

            // Step 5: Extract route data and store
            final legDurations = hereService.getLegDurations(hereResponse);
            final legDistances = hereService.getLegDistances(hereResponse);
            final totalDuration = hereService.getTotalDuration(hereResponse);
            final totalDistance = hereService.getTotalDistance(hereResponse);
            final polyline = hereService.getRoutePolyline(hereResponse);
            final steps = hereService.parseRouteSteps(hereResponse);

            // AppLogger.routing('📏 Route metrics:');
            // AppLogger.routing('   Bins/waypoints: ${orderedBins.length}');
            // AppLogger.routing('   Sections received: ${legDurations.length}');
            // AppLogger.routing('   Total duration: ${(totalDuration / 60).toStringAsFixed(1)} min');
            // AppLogger.routing('   Total distance: ${(totalDistance / 1000).toStringAsFixed(2)} km');
            // AppLogger.routing('   Polyline points: ${polyline.length}');

            // Verify section count matches waypoint count
            if (legDurations.length != orderedBins.length) {
              // AppLogger.routing('⚠️  WARNING: Section count mismatch!');
              // AppLogger.routing('   Expected ${orderedBins.length} sections, got ${legDurations.length}');
              // AppLogger.routing('   This may indicate via waypoints were ignored by API');
            } else {
              // AppLogger.routing('✅ Section count matches waypoint count - via waypoints working!');
            }

            // Store route metadata (DEPRECATED: Using Mapbox instead of HERE)
            // Future.microtask(() {
            //   ref
            //       .read(hereRouteMetadataProvider.notifier)
            //       .setRouteData(
            //         legDurations: legDurations,
            //         legDistances: legDistances,
            //         totalDuration: totalDuration,
            //         totalDistance: totalDistance,
            //         polyline: polyline,
            //         steps: steps,
            //       );
            // });

            // AppLogger.routing('✅ HERE Maps route fetched & stored');
          } catch (e, stackTrace) {
            // AppLogger.routing('❌ Error fetching optimized route: $e');
            // AppLogger.routing('   Stack trace: ${stackTrace.toString().split('\n').take(3).join('\n')}');
          }
        }

        // Trigger the async operation
        fetchOptimizedRoute();
        return null;
      },
      [
        routeState.value,
        shiftState.routeBins,
        shiftState.status,
        simulationState.isSimulating,
      ],
    );

    // Camera following during simulation (only when isFollowing is true)
    useEffect(
      () {
        // AppLogger.navigation('📷 Camera useEffect triggered');
        // AppLogger.navigation('   isSimulating: ${simulationState.isSimulating}');
        // AppLogger.navigation('   simulatedPosition: ${simulationState.simulatedPosition}');
        // AppLogger.navigation('   isNavigationMode: ${simulationState.isNavigationMode}');
        // AppLogger.navigation('   isFollowing: ${simulationState.isFollowing}');
        // AppLogger.navigation('   mapController: ${mapController.value != null}');

        if (!simulationState.isSimulating ||
            simulationState.simulatedPosition == null ||
            mapController.value == null) {
          // AppLogger.navigation('   ❌ Skipping camera update - missing requirements');
          return null;
        }

        if (!simulationState.isFollowing) {
          // AppLogger.navigation('   ❌ Skipping camera update - not in following mode');
          return null;
        }

        // Only update camera in navigation (3D) mode when following
        if (!simulationState.isNavigationMode) {
          // AppLogger.navigation('   ❌ Skipping camera update - not in navigation (3D) mode');
          return null;
        }

        final rawBearing =
            simulationState.smoothedBearing ?? simulationState.bearing;

        if (smoothedBearing.value == null) {
          smoothedBearing.value = rawBearing;
        } else {
          smoothedBearing.value =
              smoothedBearing.value! * BinConstants.bearingSmoothingFactor +
              rawBearing * (1 - BinConstants.bearingSmoothingFactor);
        }

        final now = DateTime.now();
        if (now.difference(lastCameraUpdate.value).inMilliseconds <
            BinConstants.cameraUpdateThrottleMs) {
          return null;
        }
        lastCameraUpdate.value = now;

        // AppLogger.navigation('   ✅ Updating camera to 3D navigation view');
        // AppLogger.navigation('      Zoom: ${BinConstants.navigationZoom}');
        // AppLogger.navigation('      Tilt: ${BinConstants.navigationTilt}');
        // AppLogger.navigation('      Bearing: ${(smoothedBearing.value ?? rawBearing).toStringAsFixed(1)}°');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mapController.value != null &&
              simulationState.simulatedPosition != null) {
            try {
              mapController.value!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: simulationState.simulatedPosition!,
                    zoom: BinConstants.navigationZoom,
                    bearing: smoothedBearing.value ?? rawBearing,
                    tilt: BinConstants
                        .navigationTilt, // 45° tilt with flat buildings (Google Maps style)
                  ),
                ),
              );
              // AppLogger.navigation('   ✅ Camera animation triggered');
            } catch (e) {
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Navigation'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: binsState.when(
          data: (bins) {
            return Stack(
              children: [
                // Google Map wrapped in Listener to detect user pan gestures
                Listener(
                  onPointerDown: (event) {
                    // User touched the screen - disable following mode (preserve current view mode)
                    if (simulationState.isFollowing &&
                        simulationState.isSimulating) {
                      // AppLogger.navigation('👆 User touched map - disabling following (preserving ${simulationState.isNavigationMode ? "3D" : "2D"} mode)');
                      ref
                          .read(simulationNotifierProvider.notifier)
                          .setFollowing(false);
                    }
                  },
                  child: GoogleMap(
                    key: const ValueKey('here_maps_test'),
                    initialCameraPosition: CameraPosition(
                      target: initialCenter,
                      zoom: 10.0,
                    ),
                    myLocationEnabled: !simulationState.isSimulating,
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                    trafficEnabled:
                        false, // Disabled to show our orange route clearly
                    buildingsEnabled:
                        false, // Disable 3D buildings (flat like Google Maps)
                    mapType: MapType.normal,
                    zoomControlsEnabled: false,
                    markers: markers.value,
                    polylines: polylines.value,
                    onMapCreated: (controller) {
                      mapController.value = controller;
                      AppLogger.map('🗺️  HERE Maps Test - Map created');
                    },
                    // Note: Listener.onPointerDown detects actual user touch, unlike onCameraMoveStarted
                    // which fires for both user gestures AND programmatic camera moves
                  ),
                ),
                // All overlays (no overlay needed - we use marker for blue dot now)
                SafeArea(
                  child: Stack(
                    children: [
                      // Notification bell button
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
                            color: simulationState.isFollowing
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
                                // Re-enable following (preserve current 2D/3D mode)
                                ref
                                    .read(simulationNotifierProvider.notifier)
                                    .enableFollowing();

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
                                                    simulationState.bearing)
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
                                  color: simulationState.isFollowing
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
                      if (simulationState.isSimulating)
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
                      // Stats card (admin only)
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
                      // Pre-shift overview card
                      if (shiftState.status == ShiftStatus.ready)
                        Positioned(
                          bottom: 80,
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
                              ),
                              totalBins: shiftState.totalBins,
                              totalDistanceKm: _calculateTotalDistance(
                                shiftState.routeBins,
                              ),
                              routeBins: shiftState.routeBins,
                              routeName:
                                  'Route ${shiftState.assignedRouteId ?? ''}',
                            ),
                            onStartShift: () async {
                              try {
                                await ref
                                    .read(shiftNotifierProvider.notifier)
                                    .startShift();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to start shift: $e',
                                      ),
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
                            // DEPRECATED: Using Mapbox instead of HERE
                            // preComputedPolyline: ref
                            //     .watch(hereRouteMetadataProvider)
                            //     ?.polyline,
                            preComputedPolyline: null,
                            onNavigateToNextBin: () {
                              final nextBin = shiftState.routeBins.firstWhere(
                                (bin) => bin.isCompleted == 0,
                                orElse: () => shiftState.routeBins.first,
                              );

                              if (mapController.value != null) {
                                try {
                                  mapController.value!.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                      CameraPosition(
                                        target: LatLng(
                                          nextBin.latitude,
                                          nextBin.longitude,
                                        ),
                                        zoom: 17.0,
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
  if (routeBins.isEmpty || routeBins.length == 1) {
    return 0.0;
  }

  double totalKm = 0.0;
  final distance = const latlong.Distance();

  for (int i = 0; i < routeBins.length - 1; i++) {
    final current = routeBins[i];
    final next = routeBins[i + 1];

    final currentPoint = latlong.LatLng(current.latitude, current.longitude);
    final nextPoint = latlong.LatLng(next.latitude, next.longitude);

    final segmentMeters = distance.distance(currentPoint, nextPoint);
    totalKm += segmentMeters / 1000.0;
  }

  return totalKm;
}
