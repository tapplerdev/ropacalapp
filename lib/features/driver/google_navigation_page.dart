import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/google_navigation_helpers.dart';
import 'package:ropacalapp/core/services/google_navigation_marker_service.dart';
import 'package:ropacalapp/core/services/google_navigation_service.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/providers/navigation_page_provider.dart';
import 'package:ropacalapp/features/driver/widgets/turn_by_turn_navigation_card.dart';
import 'package:ropacalapp/features/driver/widgets/navigation_bottom_panel.dart';
import 'package:ropacalapp/features/driver/widgets/check_in_dialog_v2.dart';
import 'package:ropacalapp/features/driver/notifications_page.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/models/route_step.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:latlong2/latlong.dart' as latlong;

/// Google Maps Navigation page with turn-by-turn navigation for bin collection routes
class GoogleNavigationPage extends HookConsumerWidget {
  const GoogleNavigationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Local UI-only state (keep as hooks)
    final navigationController = useState<GoogleNavigationViewController?>(null);
    final userLocation = useState<LatLng?>(null);
    final isDarkMode = useState(false); // UNUSED - Dark mode toggle (custom map style disabled)
    final navigatorInitialized = useState(false);
    final initializationError = useState<String?>(null);
    final isHandlingShiftEnd = useRef(false); // Prevent duplicate cleanup calls
    final hasReceivedFirstNavInfo = useRef(false); // Keep as ref for listener

    // Navigation state from provider (all navigation state now managed by provider)
    final navState = ref.watch(navigationPageNotifierProvider);
    final navNotifier = ref.read(navigationPageNotifierProvider.notifier);
    final shift = ref.watch(shiftNotifierProvider);

    // Guard: If no active shift exists on mount, navigate back to home
    // This only runs once when the page is first created
    useEffect(() {
      final initialShift = ref.read(shiftNotifierProvider);
      if (initialShift.status == ShiftStatus.inactive) {
        AppLogger.general('⚠️  No active shift on mount - navigating back to home');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
      }
      return null;
    }, []); // Empty deps - only runs once on mount

    // Listen for shift changes (bin completed) and recalculate route
    ref.listen(shiftNotifierProvider, (previous, next) {
      // Handle bin completion - recalculate route
      if (previous != null && next != null && previous.completedBins != next.completedBins) {
        AppLogger.general('🔄 Bins changed: ${previous.completedBins} → ${next.completedBins}');
        AppLogger.general('   Remaining bins: ${next.remainingBins.length}');
        AppLogger.general('   Triggering route recalculation...');
        _recalculateNavigationRoute(
          context,
          navigationController.value,
          ref,
          next,
          navNotifier,
        );
      }

      // Handle shift ended/cancelled - cleanup and show summary
      if (previous != null && next != null &&
          previous.status != next.status &&
          (next.status == ShiftStatus.ended ||
              next.status == ShiftStatus.cancelled) &&
          !isHandlingShiftEnd.value) {
        AppLogger.general('🛑 Shift ${next.status.name}, stopping navigation...');
        isHandlingShiftEnd.value = true;
        _handleShiftEnded(
          context,
          navigationController.value,
          next,
          navNotifier,
        );
      }

      // Handle shift deleted (nuke endpoint) - cleanup and navigate back
      // When shift is deleted via nuke, it becomes inactive from an active/ready state
      if (previous != null && next != null &&
          (previous.status == ShiftStatus.active ||
           previous.status == ShiftStatus.ready ||
           previous.status == ShiftStatus.paused) &&
          next.status == ShiftStatus.inactive &&
          !isHandlingShiftEnd.value) {
        AppLogger.general('🛑 Shift deleted (became inactive), stopping navigation...');
        isHandlingShiftEnd.value = true;
        _handleShiftEnded(
          context,
          navigationController.value,
          previous, // Use previous shift data to show stats
          navNotifier,
          isDeleted: true, // Auto-pop without dialog for deleted shifts
        );
      }
    });

    // Initialize navigator BEFORE view creation (following official SDK pattern)
    useEffect(() {
      Future<void> initializeNavigator() async {
        AppLogger.general('🚀 [EARLY INIT] Starting navigator initialization (before view creation)...');

        try {
          await GoogleNavigationService.initializeNavigation(context, ref);
          navigatorInitialized.value = true;
          AppLogger.general('✅ [EARLY INIT] Navigator initialized successfully');

          // Location should already be tracking in background since shift is active!
          AppLogger.general('📍 [EARLY INIT] Reading background-tracked location...');
          final currentLocation = ref.read(currentLocationProvider).valueOrNull;

          if (currentLocation != null) {
            userLocation.value = LatLng(
              latitude: currentLocation.latitude,
              longitude: currentLocation.longitude,
            );
            AppLogger.general('✅ [EARLY INIT] Using background-tracked GPS location: ${userLocation.value}');
            AppLogger.general('   Accuracy: ${currentLocation.accuracy}m, Age: ${DateTime.now().difference(currentLocation.timestamp).inSeconds}s');
          } else {
            // Fallback only for emulator or if GPS fails
            // Use first bin's location as starting point (better than random city center)
            final firstBin = shift.remainingBins.isNotEmpty ? shift.remainingBins.first : null;

            if (firstBin != null) {
              // Start from first bin location
              userLocation.value = LatLng(
                latitude: firstBin.latitude,
                longitude: firstBin.longitude,
              );
              AppLogger.general('⚠️  [EARLY INIT] GPS not available (emulator?), using first bin location: ${userLocation.value}');
              AppLogger.general('   Starting from Bin #${firstBin.binNumber}: ${firstBin.currentStreet}');
            } else {
              // Last resort: Use San Jose city center (where most bins are)
              userLocation.value = const LatLng(
                latitude: 37.3382,
                longitude: -121.8863,
              );
              AppLogger.general('⚠️  [EARLY INIT] GPS not available, using San Jose city center: ${userLocation.value}');
            }
            // Note: Simulator location will be set in onViewCreated (after SDK is ready)
          }
        } catch (e) {
          AppLogger.general('❌ [EARLY INIT] Navigator initialization failed: $e');
          initializationError.value = e.toString();
          navigatorInitialized.value = true; // Set to true to stop loading spinner
        }
      }

      initializeNavigator();
      return null;
    }, []);

    // Cleanup navigation
    useEffect(() {
      return () {
        AppLogger.general('🧹 GoogleNavigationPage disposing - cleaning up navigation');

        // Only cleanup if navigator was successfully initialized
        if (!navigatorInitialized.value) {
          AppLogger.general('   ⏭️  Skipping cleanup - navigator not initialized');
          return;
        }

        try {
          if (navState.isNavigating) {
            GoogleMapsNavigator.stopGuidance();
            AppLogger.general('   ⏹️  Stopped navigation guidance');
          }
        } catch (e) {
          AppLogger.general('   ⚠️  Error stopping guidance (likely already stopped): $e');
        }

        try {
          GoogleMapsNavigator.clearDestinations();
          AppLogger.general('   🗑️  Cleared destinations');
        } catch (e) {
          AppLogger.general('   ⚠️  Error clearing destinations (likely already cleared): $e');
        }

        try {
          GoogleMapsNavigator.cleanup();
          AppLogger.general('   ✅ Disposal cleanup complete');
        } catch (e) {
          AppLogger.general('   ℹ️  Cleanup already done or session doesn\'t exist: $e');
        }
      };
    }, []);

    return Scaffold(
      body: Stack(
        children: [
          // Google Maps Navigation view (with bottom padding for navigation bar)
          if (initializationError.value != null)
            // Show error message if initialization failed
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Navigation Initialization Failed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      initializationError.value!,
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Home'),
                    ),
                  ],
                ),
              ),
            )
          else if (navigatorInitialized.value && userLocation.value != null)
            GoogleMapsNavigationView(
                // Add bottom padding to prevent map content from being hidden behind bottom nav bar and panel
                initialPadding: EdgeInsets.only(
                  bottom: kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom + 100,
                ),
                onMarkerClicked: (String markerId) {
                AppLogger.general('🎯 Marker clicked: $markerId');
                final bin = navState.markerToBinMap[markerId];
                if (bin != null) {
                  AppLogger.general('   Bin #${bin.binNumber} at ${bin.currentStreet}');
                  // TODO: Show bin details dialog (needs RouteBin support)
                  // showModalBottomSheet(
                  //   context: context,
                  //   isScrollControlled: true,
                  //   backgroundColor: Colors.transparent,
                  //   builder: (context) => BinDetailsBottomSheet(bin: bin),
                  // );
                }
              },
              onViewCreated: (controller) async {
                navigationController.value = controller;
                AppLogger.general('📍 [VIEW CREATED] Google Maps navigation view created');

                // Enable MyLocation to show the blue dot/puck (Google's official pattern)
                await controller.setMyLocationEnabled(true);
                AppLogger.general('✅ [VIEW CREATED] My location enabled');

                // Disable native Google Maps recenter button (using custom button instead)
                await controller.setRecenterButtonEnabled(false);
                AppLogger.general('✅ [VIEW CREATED] Recenter button disabled');

                await controller.setReportIncidentButtonEnabled(false);
                AppLogger.general('✅ [VIEW CREATED] Report incident button disabled');

                try {
                  await _setupNavigationAfterViewCreated(
                    controller,
                    context,
                    ref,
                    shift,
                    navNotifier,
                    isDarkMode.value,
                  );
                } catch (e) {
                  AppLogger.general('❌ [VIEW CREATED] Setup failed: $e');
                }

                // iOS simulator fallback: Set default location after timeout if GPS unavailable
                // This follows Google's official example pattern (navigation.dart:269-283)
                if (Platform.isIOS) {
                  Future.delayed(const Duration(milliseconds: 1500), () async {
                    if (navState.navigationLocation == null) {
                      AppLogger.general('⚠️  [iOS] GPS location unavailable after 1.5s timeout');

                      // Try to get location from map controller first
                      final LatLng? currentLocation = await controller.getMyLocation();
                      final LatLng fallbackLocation = currentLocation ?? userLocation.value ?? const LatLng(
                        latitude: 37.3382, // San Jose city center
                        longitude: -121.8863,
                      );

                      try {
                        await GoogleMapsNavigator.simulator.setUserLocation(fallbackLocation);
                        AppLogger.general('✅ [iOS] Fallback simulator location set: $fallbackLocation');
                      } catch (e) {
                        AppLogger.general('⚠️  [iOS] Failed to set simulator location: $e');
                      }
                    } else {
                      AppLogger.general('✅ [iOS] GPS location acquired, no simulator fallback needed');
                    }
                  });
                }
              },
              initialCameraPosition: CameraPosition(
                target: userLocation.value!,
                zoom: 15,
              ),
              // Disable zoom controls (+ and - buttons) - Android only feature
              initialZoomControlsEnabled: false,
            )
          else
            // Loading while initializing
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Turn-by-turn navigation card
          if (navState.isNavigating && navState.currentStep != null)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: TurnByTurnNavigationCard(
                currentStep: navState.currentStep!,
                distanceToNextManeuver: navState.distanceToNextManeuver,
                estimatedTimeRemaining: navState.remainingTime,
                totalDistanceRemaining: navState.totalDistanceRemaining,
              ),
            ),

          // Notification button - positioned top-left
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: _buildCircularButton(
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
          ),

          // Audio button - positioned above recenter button
          Positioned(
            bottom: 400,
            right: 16,
            child: _buildCircularButton(
              icon: navState.isAudioMuted ? Icons.volume_off : Icons.volume_up,
              onTap: () => GoogleNavigationService.toggleAudio(
                navState.isAudioMuted,
                navNotifier.setAudioMuted,
              ),
            ),
          ),

          // Custom recenter button - positioned just above bottom panel
          Positioned(
            bottom: 340,
            right: 16,
            child: _buildCircularButton(
              icon: Icons.my_location,
              onTap: () async {
                if (navigationController.value != null) {
                  // Use followMyLocation with tilted perspective for navigation-aware recentering
                  await navigationController.value!.followMyLocation(
                    CameraPerspective.tilted,
                    zoomLevel: 17,
                  );
                  AppLogger.general('📍 Re-enabled camera following mode with tilted perspective');
                }
              },
            ),
          ),

          // Bottom panel - expandable bin details
          if (navState.isNavigationReady && shift.remainingBins.isNotEmpty)
            NavigationBottomPanel(
              shift: shift,
              currentIndex: navState.currentBinIndex,
            ),
        ],
      ),
    );
  }

  /// Initialize navigation session and show T&C dialog if needed
  /// Wait for location to be ready before proceeding
  static Future<void> _waitForLocationReady(WidgetRef ref) async {
    AppLogger.general('📍 Waiting for location to be ready...');

    int attempts = 0;
    const maxAttempts = 10;

    while (attempts < maxAttempts) {
      final location = ref.read(currentLocationProvider).valueOrNull;
      if (location != null) {
        AppLogger.general('✅ Location ready after $attempts attempts');
        return;
      }

      attempts++;
      AppLogger.general('⏳ Location not ready, attempt $attempts/$maxAttempts');
      await Future.delayed(const Duration(seconds: 1));
    }

    AppLogger.general('⚠️  Location timeout after $maxAttempts attempts, proceeding anyway');
  }

  /// Set destinations from shift bins and calculate route
  static Future<void> _setDestinationsFromShift(
    BuildContext context,
    WidgetRef ref,
    ShiftState shift,
    NavigationPageNotifier navNotifier,
  ) async {
    AppLogger.general('🗺️  Setting destinations from shift...');

    try {
      // Get remaining bins (uncompleted bins)
      final remainingBins = shift.remainingBins;

      if (remainingBins.isEmpty) {
        AppLogger.general('⚠️  No remaining bins to navigate to');
        return;
      }

      AppLogger.general('📍 Found ${remainingBins.length} remaining bins');

      // Convert bins to waypoints
      final waypoints = remainingBins.map((bin) {
        return NavigationWaypoint.withLatLngTarget(
          title: 'Bin #${bin.binNumber}',
          target: LatLng(
            latitude: bin.latitude,
            longitude: bin.longitude,
          ),
        );
      }).toList();

      // Create destinations
      final destinations = Destinations(
        waypoints: waypoints,
        displayOptions: NavigationDisplayOptions(
          showDestinationMarkers: false, // We'll use custom markers
          showStopSigns: false,
          showTrafficLights: false,
        ),
        routingOptions: RoutingOptions(
          travelMode: NavigationTravelMode.driving,
          alternateRoutesStrategy: NavigationAlternateRoutesStrategy.none,
        ),
      );

      AppLogger.general('🚗 Setting ${waypoints.length} waypoints...');

      // Set destinations
      final result = await GoogleMapsNavigator.setDestinations(destinations);

      AppLogger.general('📊 Route calculation result: $result');

      // Handle route calculation result (Google's comprehensive error handling pattern)
      switch (result) {
        case NavigationRouteStatus.statusOk:
          AppLogger.general('✅ Route calculated successfully');

          // Start navigation guidance
          await GoogleMapsNavigator.startGuidance();
          AppLogger.general('🎯 Navigation guidance started');

          // Reset current bin index
          navNotifier.setCurrentBinIndex(0);
          break;

        case NavigationRouteStatus.internalError:
          AppLogger.general('❌ Internal error calculating route');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unexpected internal error. Please restart the app.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;

        case NavigationRouteStatus.routeNotFound:
          AppLogger.general('❌ Route not found');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No route could be calculated to these destinations.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;

        case NavigationRouteStatus.networkError:
          AppLogger.general('❌ Network error calculating route');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Network connection required to calculate route.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;

        case NavigationRouteStatus.quotaExceeded:
          AppLogger.general('❌ API quota exceeded');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('API quota exceeded. Please contact support.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;

        case NavigationRouteStatus.apiKeyNotAuthorized:
          AppLogger.general('❌ API key not authorized');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Navigation API key not authorized.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;

        case NavigationRouteStatus.locationUnavailable:
          AppLogger.general('❌ Location unavailable');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your location is unavailable. Please check permissions.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;

        case NavigationRouteStatus.locationUnknown:
          AppLogger.general('❌ Location unknown');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to determine your current location.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;

        case NavigationRouteStatus.waypointError:
          AppLogger.general('❌ Invalid waypoints');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid destination waypoints provided.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;

        case NavigationRouteStatus.duplicateWaypointsError:
          AppLogger.general('❌ Duplicate waypoints');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Route contains duplicate waypoints.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;

        case NavigationRouteStatus.noWaypointsError:
          AppLogger.general('❌ No waypoints provided');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No destinations provided for navigation.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;

        case NavigationRouteStatus.travelModeUnsupported:
          AppLogger.general('❌ Travel mode unsupported');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Travel mode not supported for this route.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;

        case NavigationRouteStatus.statusCanceled:
          AppLogger.general('⚠️  Route calculation canceled');
          // Don't show error for cancellation (happens when a new calculation starts)
          break;

        case NavigationRouteStatus.quotaCheckFailed:
        case NavigationRouteStatus.unknown:
          AppLogger.general('❌ Unknown error: $result');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Unable to calculate route: $result'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;
      }
    } catch (e) {
      AppLogger.general('❌ Exception setting destinations: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Recalculate navigation route when bins are completed
  static Future<void> _recalculateNavigationRoute(
    BuildContext context,
    GoogleNavigationViewController? controller,
    WidgetRef ref,
    ShiftState shift,
    NavigationPageNotifier navNotifier,
  ) async {
    if (controller == null) {
      AppLogger.general('⚠️  Cannot recalculate: controller is null');
      return;
    }

    AppLogger.general('🔄 Recalculating navigation route...');
    AppLogger.general('   Completed bins: ${shift.completedBins}');
    AppLogger.general('   Remaining bins: ${shift.remainingBins.length}');

    try {
      // Clear existing destinations
      await GoogleMapsNavigator.clearDestinations();
      AppLogger.general('🗑️  Cleared existing destinations');

      // Stop current guidance
      await GoogleMapsNavigator.stopGuidance();
      AppLogger.general('⏹️  Stopped current guidance');

      // Clear existing markers first
      await controller.clearMarkers();
      AppLogger.general('🗑️  Cleared existing markers');

      // If there are remaining bins, set new destinations FIRST
      if (shift.remainingBins.isNotEmpty) {
        final waypoints = shift.remainingBins.map((bin) {
          return NavigationWaypoint.withLatLngTarget(
            title: 'Bin #${bin.binNumber}',
            target: LatLng(
              latitude: bin.latitude,
              longitude: bin.longitude,
            ),
          );
        }).toList();

        final destinations = Destinations(
          waypoints: waypoints,
          displayOptions: NavigationDisplayOptions(
            showDestinationMarkers: false,
            showStopSigns: false,
            showTrafficLights: false,
          ),
          routingOptions: RoutingOptions(
            travelMode: NavigationTravelMode.driving,
            alternateRoutesStrategy: NavigationAlternateRoutesStrategy.none,
          ),
        );

        final result = await GoogleMapsNavigator.setDestinations(destinations);

        if (result == NavigationRouteStatus.statusOk) {
          await GoogleMapsNavigator.startGuidance();
          navNotifier.setCurrentBinIndex(0);
          AppLogger.general('✅ Route set with destinations hidden');

          // NOW add custom markers AFTER destinations are set
          final tempMarkerMap = <String, RouteBin>{};
          final markers = await GoogleNavigationMarkerService.createCustomBinMarkers(shift.remainingBins, tempMarkerMap);
          await controller.addMarkers(markers);
          navNotifier.updateMarkerToBinMap(tempMarkerMap);
          AppLogger.general('📍 Added ${markers.length} custom markers');

          // Add geofence circles
          final circles = await GoogleNavigationMarkerService.createGeofenceCircles(shift.remainingBins);
          await controller.clearCircles();
          await controller.addCircles(circles);
          navNotifier.updateGeofenceCircles(circles);
          AppLogger.general('⭕ Added ${circles.length} geofence circles');

          // Update completed route polyline
          final completedBinsList = shift.routeBins.where((bin) => bin.isCompleted == 1).toList();
          final polyline = await GoogleNavigationMarkerService.createCompletedRoutePolyline(completedBinsList);
          await controller.clearPolylines();
          if (polyline != null) {
            await controller.addPolylines([polyline]);
            navNotifier.updateCompletedRoutePolyline(polyline);
            AppLogger.general('📏 Added completed route polyline');
          }

          AppLogger.general('✅ Route recalculation complete');
        } else {
          AppLogger.general('❌ Route recalculation failed: $result');
        }
      } else {
        AppLogger.general('🎉 All bins completed! Navigation finished.');
        AppLogger.general('🏁 Auto-ending shift...');

        // Show loading overlay
        EasyLoading.show(
          status: 'All bins collected! Ending shift...',
          maskType: EasyLoadingMaskType.black,
        );

        // Auto-end shift when all bins are completed
        try {
          await ref.read(shiftNotifierProvider.notifier).endShift();
          AppLogger.general('✅ Shift auto-ended successfully');

          // Dismiss loading
          await EasyLoading.dismiss();

          // Navigate back to home page
          if (context.mounted) {
            AppLogger.general('🏠 Navigating back to home page...');
            context.pop();
          }
        } catch (e) {
          AppLogger.general('⚠️  Failed to auto-end shift: $e');
          AppLogger.general('   Shift may need to be ended manually');
          // Dismiss loading on error
          await EasyLoading.dismiss();
          // Don't crash - driver can end manually from home page
        }
      }
    } catch (e) {
      AppLogger.general('❌ Error recalculating route: $e');
    }
  }

  /// Handle shift ended or cancelled - cleanup navigation and show summary
  static Future<void> _handleShiftEnded(
    BuildContext context,
    GoogleNavigationViewController? controller,
    ShiftState shift,
    NavigationPageNotifier navNotifier, {
    bool isDeleted = false, // True when shift was deleted/nuked
  }) async {
    try {
      AppLogger.general('🛑 Starting shift end cleanup...');

      // 1. Stop navigation guidance
      try {
        await GoogleMapsNavigator.stopGuidance();
        AppLogger.general('   ✅ Stopped guidance');
      } catch (e) {
        AppLogger.general('   ⚠️  Error stopping guidance: $e');
      }

      // 2. Clear destinations
      try {
        await GoogleMapsNavigator.clearDestinations();
        AppLogger.general('   ✅ Cleared destinations');
      } catch (e) {
        AppLogger.general('   ⚠️  Error clearing destinations: $e');
      }

      // 3. Clear markers (bins)
      if (controller != null) {
        try {
          await controller.clearMarkers();
          AppLogger.general('   ✅ Cleared markers');
        } catch (e) {
          AppLogger.general('   ⚠️  Error clearing markers: $e');
        }
      }

      // 4. Clear polylines (route)
      if (controller != null) {
        try {
          await controller.clearPolylines();
          AppLogger.general('   ✅ Cleared polylines');
        } catch (e) {
          AppLogger.general('   ⚠️  Error clearing polylines: $e');
        }
      }

      // 5. Clear geofence circles
      try {
        navNotifier.updateGeofenceCircles([]);
        AppLogger.general('   ✅ Cleared geofence circles');
      } catch (e) {
        AppLogger.general('   ⚠️  Error clearing geofence circles (likely disposed): $e');
      }

      // 6. Clear completed route polyline
      try {
        navNotifier.updateCompletedRoutePolyline(null);
        AppLogger.general('   ✅ Cleared completed route');
      } catch (e) {
        AppLogger.general('   ⚠️  Error clearing completed route (likely disposed): $e');
      }

      // 7. Cleanup navigation session
      try {
        await GoogleMapsNavigator.cleanup();
        AppLogger.general('   ✅ Navigation session cleaned up');
      } catch (e) {
        AppLogger.general('   ⚠️  Error cleaning up navigation session: $e');
      }

      AppLogger.general('✅ Navigation cleanup complete');

      // 8. Dismiss any loading overlays
      await EasyLoading.dismiss();
      AppLogger.general('   ✅ Dismissed loading overlay');

      // 9. Handle navigation based on scenario
      if (!context.mounted) {
        AppLogger.general('   ⚠️  Context unmounted, skipping navigation');
        return;
      }

      if (isDeleted) {
        // Scenario 3: Deleted/nuked → Just pop immediately, no dialog
        AppLogger.general('   📤 Auto-popping to home (shift deleted)');
        Navigator.of(context).pop();
      } else if (shift.status == ShiftStatus.cancelled) {
        // Scenario 2: Cancelled → Show brief dialog, auto-dismiss, then pop
        AppLogger.general('   📤 Showing cancellation notice (auto-dismiss)');
        await _showCancellationNotice(context, shift);
      } else {
        // Scenario 1: Normal end → Show dialog, wait for user to click
        AppLogger.general('   📤 Showing shift summary dialog (user interaction)');
        await _showShiftSummaryDialog(context, shift);
      }
    } catch (e) {
      AppLogger.general('❌ Error during shift end cleanup: $e');
      // Ensure loading is dismissed even on error
      try {
        await EasyLoading.dismiss();
      } catch (_) {
        // Ignore if EasyLoading also fails
      }
    }
  }

  /// Show brief cancellation notice that auto-dismisses
  static Future<void> _showCancellationNotice(
    BuildContext context,
    ShiftState shift,
  ) async {
    // Show dialog and capture the context
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.cancel,
              color: Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            const Text('Shift Cancelled'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This shift has been cancelled by your manager.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            if (shift.completedBins > 0) ...[
              const SizedBox(height: 12),
              Text(
                'You completed ${shift.completedBins} of ${shift.totalBins} bins.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // Auto-dismiss after 2.5 seconds and pop back to home
    await Future.delayed(const Duration(milliseconds: 2500));
    if (context.mounted) {
      Navigator.of(context).pop(); // Close dialog
      if (context.mounted) {
        Navigator.of(context).pop(); // Pop navigation page with animation
      }
    }
  }

  /// Show shift summary dialog with stats (for normal end only)
  static Future<void> _showShiftSummaryDialog(
    BuildContext context,
    ShiftState shift,
  ) async {
    final isCompleted = shift.completedBins >= shift.totalBins;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              isCompleted ? 'Shift Completed!' : 'Shift Ended',
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bins Completed',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${shift.completedBins} of ${shift.totalBins}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (shift.completedBins > 0)
              Text(
                isCompleted
                    ? '🎉 Great job! All bins collected!'
                    : '👍 Good work today!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Navigate back to driver home with reverse slide animation
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  /// Setup navigation after view is created (6-step process)
  static Future<void> _setupNavigationAfterViewCreated(
    GoogleNavigationViewController controller,
    BuildContext context,
    WidgetRef ref,
    ShiftState shift,
    NavigationPageNotifier navNotifier,
    bool isDark,
  ) async {
    AppLogger.general('🚀 [SETUP] Starting 6-step navigation setup...');

    try {
      // STEP 1: Configure map settings
      AppLogger.general('📱 [STEP 1/6] Configuring map settings...');

      await controller.settings.setCompassEnabled(false);
      await controller.settings.setTrafficEnabled(false);

      // Hide Google's navigation header (green banner) and footer (ETA card)
      // Keep navigation UI enabled for route/puck rendering, but hide the UI components
      await controller.setNavigationHeaderEnabled(false);
      await controller.setNavigationFooterEnabled(false);
      AppLogger.general('   🎨 Disabled Google navigation header & footer');

      AppLogger.general('✅ [STEP 1/6] Map settings configured');

      // STEP 2: Apply map style (COMMENTED OUT - using default Google Maps style)
      // AppLogger.general('🎨 [STEP 2/6] Applying map style...');
      // await _applyMapStyle(controller, isDark);
      // AppLogger.general('✅ [STEP 2/6] Map style applied');
      AppLogger.general('✅ [STEP 2/6] Using default Google Maps style (custom style disabled)');

      // STEP 3: Setup navigation listeners (for location updates, turn-by-turn, etc.)
      AppLogger.general('👂 [STEP 3/6] Setting up navigation listeners...');
      _setupNavigationListeners(
        context,
        ref,
        shift,
        navNotifier,
      );
      AppLogger.general('✅ [STEP 3/6] Listeners configured');

      // STEP 4: Calculate route immediately (Google's recommended pattern)
      AppLogger.general('🗺️  [STEP 4/6] Calculating route to destinations...');
      await _setDestinationsFromShift(context, ref, shift, navNotifier);
      AppLogger.general('✅ [STEP 4/6] Route calculation initiated');

      // STEP 5: Add custom markers
      AppLogger.general('📍 [STEP 5/6] Creating and adding custom bin markers...');
      final tempMarkerMap = <String, RouteBin>{};
      final markers = await GoogleNavigationMarkerService.createCustomBinMarkers(shift.remainingBins, tempMarkerMap);
      await controller.addMarkers(markers);
      navNotifier.updateMarkerToBinMap(tempMarkerMap);
      AppLogger.general('✅ [STEP 5/6] Added ${markers.length} custom markers');

      // STEP 6: Create geofence circles and completed route polyline
      AppLogger.general('⭕ [STEP 6/6] Adding geofence circles and polylines...');
      final circles = await GoogleNavigationMarkerService.createGeofenceCircles(shift.remainingBins);
      await controller.addCircles(circles);
      navNotifier.updateGeofenceCircles(circles);
      AppLogger.general('   Added ${circles.length} geofence circles');

      // Add completed route polyline if there are completed bins
      if (shift.completedBins > 0) {
        final completedBinsList = shift.routeBins.where((bin) => bin.isCompleted == 1).toList();
        final polyline = await GoogleNavigationMarkerService.createCompletedRoutePolyline(completedBinsList);
        if (polyline != null) {
          await controller.addPolylines([polyline]);
          navNotifier.updateCompletedRoutePolyline(polyline);
          AppLogger.general('   Added completed route polyline');
        }
      }
      AppLogger.general('✅ [STEP 6/6] Circles and polylines added');

      navNotifier.setNavigationReady(true);
      navNotifier.setNavigating(true);
      AppLogger.general('✅ Navigation ready');

      AppLogger.general('🎉 [SETUP] All 6 steps completed successfully!');
    } catch (e) {
      AppLogger.general('❌ [SETUP] Error during setup: $e');
      rethrow;
    }
  }

  /// Setup navigation event listeners
  static void _setupNavigationListeners(
    BuildContext context,
    WidgetRef ref,
    ShiftState shift,
    NavigationPageNotifier navNotifier,
  ) {
    AppLogger.general('👂 Setting up navigation listeners...');

    // Listen to NavInfo updates (turn-by-turn data)
    GoogleMapsNavigator.setNavInfoListener((navInfoEvent) {
      if (!navNotifier.state.hasReceivedFirstNavInfo) {
        AppLogger.general('📍 First NavInfo received');
        navNotifier.setHasReceivedFirstNavInfo(true);
      }

      final navInfo = navInfoEvent.navInfo;

      // Update current step
      if (navInfo.currentStep != null) {
        final step = navInfo.currentStep!;
        navNotifier.updateCurrentStep(RouteStep(
          maneuverType: GoogleNavigationHelpers.convertManeuverType(step.maneuver),
          instruction: step.fullInstructions,
          distance: step.distanceFromPrevStepMeters.toDouble(),
          duration: navInfo.timeToCurrentStepSeconds?.toDouble() ?? 0.0,
          location: latlong.LatLng(0, 0), // Location not available in StepInfo
          modifier: GoogleNavigationHelpers.extractModifier(step.fullInstructions),
        ));
      }

      // Update distance to next maneuver
      navNotifier.updateDistanceToNextManeuver(navInfo.distanceToCurrentStepMeters?.toDouble() ?? 0);

      // Update remaining time and distance to final destination
      navNotifier.updateRemainingTime(navInfo.timeToFinalDestinationSeconds != null
          ? Duration(seconds: navInfo.timeToFinalDestinationSeconds!)
          : null);

      navNotifier.updateTotalDistanceRemaining(navInfo.distanceToFinalDestinationMeters?.toDouble());
    });

    // Listen to location updates (for display purposes only)
    GoogleMapsNavigator.setRoadSnappedLocationUpdatedListener((location) {
      navNotifier.updateNavigationLocation(location.location);
    });

    // Listen to arrival events
    GoogleMapsNavigator.setOnArrivalListener((event) {
      AppLogger.general('🎯 Arrived at waypoint!');
      AppLogger.general('   Waypoint: ${event.waypoint?.title}');

      // Play arrival sound or vibration
      HapticFeedback.mediumImpact();
    });

    // Listen to route changes
    GoogleMapsNavigator.setOnRouteChangedListener(() {
      AppLogger.general('🔄 Route changed');
    });

    AppLogger.general('✅ Navigation listeners setup complete');
  }

  /// Apply branded map style (light or dark mode)
  /// COMMENTED OUT - Using default Google Maps style instead
  // static Future<void> _applyMapStyle(GoogleNavigationViewController controller, bool isDark) async {
  //   try {
  //     final stylePath = isDark
  //         ? 'assets/map_styles/dark_style.json'
  //         : 'assets/map_styles/light_style.json';
  //
  //     final styleJson = await rootBundle.loadString(stylePath);
  //     await controller.setMapStyle(styleJson);
  //
  //     AppLogger.general('🎨 Applied ${isDark ? "dark" : "light"} map style');
  //   } catch (e) {
  //     AppLogger.general('⚠️  Failed to apply map style: $e');
  //     // Fallback to default style
  //     await controller.setMapStyle(null);
  //   }
  // }

  /// Build navigation info card (unused, kept for reference)
  Widget _buildNavigationInfoCard({
    required RouteStep? currentStep,
    required double distanceToNextManeuver,
    required Duration? remainingTime,
    required double? totalDistanceRemaining,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currentStep != null) ...[
            Text(
              currentStep.instruction,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'In ${GoogleNavigationHelpers.formatDistance(distanceToNextManeuver)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
          if (remainingTime != null && totalDistanceRemaining != null) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  GoogleNavigationHelpers.formatDistance(totalDistanceRemaining),
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  GoogleNavigationHelpers.formatETA(remainingTime),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build control buttons (unused, kept for reference)
  Widget _buildControlButtons({
    required BuildContext context,
    required WidgetRef ref,
    required ValueNotifier<bool> isNavigating,
    required ValueNotifier<int> currentBinIndex,
    required ShiftState shift,
  }) {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () async {
              if (isNavigating.value) {
                await GoogleMapsNavigator.stopGuidance();
                isNavigating.value = false;
              } else {
                await GoogleMapsNavigator.startGuidance();
                isNavigating.value = true;
              }
            },
            child: Text(isNavigating.value ? 'Stop' : 'Start'),
          ),
          ElevatedButton(
            onPressed: () {
              // Skip to next bin
              if (currentBinIndex.value < shift.remainingBins.length - 1) {
                currentBinIndex.value++;
              }
            },
            child: const Text('Skip Bin'),
          ),
        ],
      ),
    );
  }


  /// Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Build skeleton loader for loading state
  Widget _buildSkeletonLoader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 150,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// Build circular map control button
  static Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    final bgColor = backgroundColor ?? Colors.white;
    final isWhiteBg = bgColor == Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isWhiteBg
                  ? Colors.black.withOpacity(0.12)
                  : bgColor.withOpacity(0.2),
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
        child: Icon(
          icon,
          color: iconColor ?? (isWhiteBg ? AppColors.primaryBlue : Colors.white),
          size: 22,
        ),
      ),
    );
  }

}
