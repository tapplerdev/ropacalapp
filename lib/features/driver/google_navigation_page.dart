import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/google_navigation_helpers.dart';
import 'package:ropacalapp/core/utils/responsive.dart';
import 'package:ropacalapp/core/services/google_navigation_marker_service.dart';
import 'package:ropacalapp/core/services/google_navigation_service.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/providers/navigation_page_provider.dart';
import 'package:ropacalapp/providers/centrifugo_provider.dart';
import 'package:ropacalapp/features/driver/widgets/turn_by_turn_navigation_card.dart';
import 'package:ropacalapp/features/driver/widgets/navigation_bottom_panel.dart';
import 'package:ropacalapp/features/driver/widgets/check_in_dialog_v2.dart';
import 'package:ropacalapp/features/driver/widgets/circular_map_button.dart';
import 'package:ropacalapp/features/driver/widgets/dialogs/shift_summary_dialog.dart';
import 'package:ropacalapp/features/driver/widgets/dialogs/shift_cancellation_dialog.dart';
import 'package:ropacalapp/features/driver/widgets/move_request_notification_dialog.dart';
import 'package:ropacalapp/providers/move_request_notification_provider.dart';
import 'package:ropacalapp/features/driver/widgets/route_update_notification_dialog.dart';
import 'package:ropacalapp/providers/route_update_notification_provider.dart';
import 'package:ropacalapp/features/driver/notifications_page.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/models/route_step.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/features/driver/widgets/potential_location_form_dialog.dart';
import 'package:latlong2/latlong.dart' as latlong;

/// Google Maps Navigation page with turn-by-turn navigation for bin collection routes
class GoogleNavigationPage extends HookConsumerWidget {
  const GoogleNavigationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ CRITICAL: Keep Centrifugo connected during active navigation
    // This ensures location tracking can publish to WebSocket while navigating
    ref.watch(centrifugoManagerProvider);
    // AppLogger.general('🔵 [GoogleNavigationPage] Watching centrifugoManagerProvider'); // Commented out - too verbose

    // Local UI-only state (keep as hooks)
    final navigationController = useState<GoogleNavigationViewController?>(null);

    // CarPlay controller - automatically shows navigation on CarPlay when connected
    final autoViewController = useMemoized(() => GoogleMapsAutoViewController());

    final userLocation = useState<LatLng?>(null);
    final isDarkMode = useState(false); // UNUSED - Dark mode toggle (custom map style disabled)
    final navigationSessionInitialized = useState(false); // NEW: Track session initialization
    final locationPermissionGranted = useState(false); // NEW: Track location permissions
    final navigatorInitialized = useState(false);
    final initializationError = useState<String?>(null);
    final isHandlingShiftEnd = useRef(false); // Prevent duplicate cleanup calls
    final hasReceivedFirstNavInfo = useRef(false); // Keep as ref for listener

    // Navigation state from provider (all navigation state now managed by provider)
    final navState = ref.watch(navigationPageNotifierProvider);
    final navNotifier = ref.read(navigationPageNotifierProvider.notifier);
    final shift = ref.watch(shiftNotifierProvider);

    // Guard: Wait for route bins to be populated via WebSocket
    // Show loading screen while waiting
    if (shift.status == ShiftStatus.active && shift.routeBins.isEmpty) {
      AppLogger.general('⏳ Navigation page: Waiting for route bins...');
      AppLogger.general('   Status: ${shift.status}');
      AppLogger.general('   Route bins length: ${shift.routeBins.length}');
      AppLogger.general('   Total bins: ${shift.totalBins}');
      AppLogger.general('   Route ID: ${shift.assignedRouteId}');

      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading route...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Guard: If no active shift exists on mount, navigate back to home
    // This only runs once when the page is first created
    useEffect(() {
      final initialShift = ref.read(shiftNotifierProvider);
      if (initialShift.status == ShiftStatus.inactive) {
        AppLogger.general('⚠️  No active shift on mount - navigating back to home');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else if (context.mounted) {
            context.go('/driver');
          }
        });
      }
      return null;
    }, []); // Empty deps - only runs once on mount

    // Keep screen awake during navigation
    useEffect(() {
      AppLogger.general('📱 Enabling wake lock - screen will stay on during navigation');
      WakelockPlus.enable();

      return () {
        AppLogger.general('📱 Disabling wake lock - screen can sleep normally');
        WakelockPlus.disable();
      };
    }, []); // Empty deps - enable on mount, disable on unmount

    // Listen for move request notifications and show dialog
    final moveRequestNotification = ref.watch(moveRequestNotificationNotifierProvider);

    useEffect(() {
      if (moveRequestNotification != null) {
        AppLogger.general('🔔 Move request notification received in google_navigation_page - showing dialog');

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

    // Listen for route update notifications and show dialog
    final routeUpdateNotification = ref.watch(routeUpdateNotificationNotifierProvider);

    useEffect(() {
      if (routeUpdateNotification != null) {
        AppLogger.general('🔔 Route update notification received in google_navigation_page - showing dialog');
        AppLogger.general('   Manager: ${routeUpdateNotification.managerName}');
        AppLogger.general('   Action: ${routeUpdateNotification.actionType}');
        AppLogger.general('   Bin: #${routeUpdateNotification.binNumber}');

        // Show dialog on next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => RouteUpdateNotificationDialog(
                notification: routeUpdateNotification,
                onClose: () {
                  Navigator.of(dialogContext).pop();
                  ref.read(routeUpdateNotificationNotifierProvider.notifier).clear();
                  AppLogger.general('✅ Route update notification dialog closed');
                },
              ),
            );
          }
        });
      }
      return null;
    }, [routeUpdateNotification]);

    // Listen for automatic rerouting (when driver goes off-route)
    // Android only - SDK automatically recalculates route when driver deviates
    useEffect(() {
      StreamSubscription? subscription;

      // Only set up listener if on Android and navigation is initialized
      if (Platform.isAndroid && navigatorInitialized.value) {
        try {
          subscription = GoogleMapsNavigator.setOnReroutingListener(() {
            AppLogger.general('🔄 SDK automatic reroute detected (driver went off-route)');
            AppLogger.general('   Route automatically recalculated by Navigation SDK');
            // SDK already handled the reroute - no action needed
            // This is just for logging/analytics
          });
          AppLogger.general('✅ Automatic rerouting listener registered (Android)');
        } catch (e) {
          AppLogger.general('⚠️  Failed to register rerouting listener: $e');
        }
      } else if (!Platform.isAndroid) {
        AppLogger.general('ℹ️  Automatic rerouting listener not available on iOS');
      }

      return () {
        subscription?.cancel();
        if (Platform.isAndroid) {
          AppLogger.general('🔕 Automatic rerouting listener unregistered');
        }
      };
    }, [navigatorInitialized.value]);

    // Listen for shift changes (bin completed) and recalculate route
    ref.listen(shiftNotifierProvider, (previous, next) {
      // Handle bin completion - recalculate route
      // Check if either completedBins changed OR next waypoint changed
      final bool completedBinsChanged = previous != null && next != null &&
          previous.completedBins != next.completedBins;

      // Check if next waypoint changed (important for move requests where pickup→dropoff doesn't change completedBins)
      // Use unique identifier: bin_id + stop_type + sequence_order (since id is always 0)
      final String? previousNextWaypointId = previous?.remainingBins.isNotEmpty == true
          ? '${previous!.remainingBins.first.binId}_${previous!.remainingBins.first.stopType}_${previous!.remainingBins.first.sequenceOrder}'
          : null;
      final String? nextNextWaypointId = next?.remainingBins.isNotEmpty == true
          ? '${next!.remainingBins.first.binId}_${next!.remainingBins.first.stopType}_${next!.remainingBins.first.sequenceOrder}'
          : null;
      final bool nextWaypointChanged = previousNextWaypointId != nextNextWaypointId;

      if (completedBinsChanged || nextWaypointChanged) {
        if (completedBinsChanged) {
          AppLogger.general('🔄 Bins changed: ${previous?.completedBins} → ${next?.completedBins}');
        }
        if (nextWaypointChanged) {
          AppLogger.general('🔄 Next waypoint changed: $previousNextWaypointId → $nextNextWaypointId');
        }
        AppLogger.general('   Remaining bins: ${next?.remainingBins.length}');
        AppLogger.general('   Advancing to next bin...');
        _advanceToNextBin(
          context,
          navigationController.value,
          ref,
          next!,
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

    // PHASE 1 & 2 & 3: Initialize navigator following official SDK pattern
    // Step 1: Check permissions → Step 2: Wait for GPS → Step 3: Initialize session → Step 4: Show view
    useEffect(() {
      var isMounted = true;

      Future<void> initializeNavigator() async {
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        AppLogger.general('🚀 [INIT] Starting navigation initialization');
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        try {
          // STEP 1: Check location permissions FIRST (Phase 3)
          AppLogger.general('📍 [STEP 1/4] Checking location permissions...');
          final locationService = ref.read(locationServiceProvider);
          final hasPermission = await locationService.checkPermissions();

          if (!isMounted) return;

          if (!hasPermission) {
            AppLogger.general('❌ [STEP 1/4] Location permission denied');
            initializationError.value = 'Location permission is required for navigation';
            return;
          }

          locationPermissionGranted.value = true;
          AppLogger.general('✅ [STEP 1/4] Location permissions granted');

          // STEP 2: Wait for GPS location (Phase 2 - No fallbacks!)
          AppLogger.general('📍 [STEP 2/4] Waiting for GPS location...');
          final currentLocation = ref.read(currentLocationProvider).valueOrNull;

          if (currentLocation == null) {
            AppLogger.general('⏳ [STEP 2/4] GPS not ready yet, waiting...');
            initializationError.value = 'Waiting for GPS location...';
            // Don't proceed - user must have GPS ready
            return;
          }

          userLocation.value = LatLng(
            latitude: currentLocation.latitude,
            longitude: currentLocation.longitude,
          );
          AppLogger.general('✅ [STEP 2/4] GPS location ready: ${userLocation.value}');
          AppLogger.general('   Accuracy: ${currentLocation.accuracy}m');
          AppLogger.general('   Age: ${DateTime.now().difference(currentLocation.timestamp).inSeconds}s');

          // STEP 3: Initialize navigation session (Phase 1)
          AppLogger.general('🗺️  [STEP 3/4] Initializing navigation session...');
          await GoogleNavigationService.initializeNavigation(context, ref);

          if (!isMounted) {
            AppLogger.general('⚠️  [STEP 3/4] Widget disposed, stopping initialization');
            return;
          }

          navigationSessionInitialized.value = true;
          navigatorInitialized.value = true;
          AppLogger.general('✅ [STEP 3/4] Navigation session initialized');

          // STEP 4: View will be created now (controlled by navigationSessionInitialized flag)
          AppLogger.general('✅ [STEP 4/4] Ready to create map view');
          AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          AppLogger.general('🎉 Navigation initialization complete!');
          AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        } catch (e) {
          if (!isMounted) return;
          AppLogger.general('❌ [INIT] Navigation initialization failed: $e');
          initializationError.value = e.toString();
        }
      }

      initializeNavigator();
      return () {
        isMounted = false;
      };
    }, []);

    // PHASE 7: Cleanup navigation (simplified - cleanup() handles everything)
    useEffect(() {
      return () {
        AppLogger.general('🧹 GoogleNavigationPage disposing - cleaning up navigation');

        // Only cleanup if navigation session was initialized
        if (!navigationSessionInitialized.value) {
          AppLogger.general('   ⏭️  Skipping cleanup - session not initialized');
          return;
        }

        // cleanup() handles everything: stop guidance, clear destinations, terminate session
        // Following official SDK pattern - no manual teardown needed
        try {
          GoogleMapsNavigator.cleanup();
          AppLogger.general('   ✅ Navigation session cleaned up (T&C state preserved)');
        } catch (e) {
          AppLogger.general('   ⚠️  Error cleaning up navigation session: $e');
        }

        AppLogger.general('   ✅ Disposal complete');
      };
    }, []);

    return Scaffold(
      body: Stack(
        children: [
          // PHASE 1: Show map view ONLY when navigation session is initialized
          if (initializationError.value != null)
            // Show error message if initialization failed
            Center(
              child: Padding(
                padding: Responsive.padding(context, mobile: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: Responsive.iconSize(
                        context,
                        mobile: 64,
                      ),
                      color: Colors.red,
                    ),
                    SizedBox(
                      height: Responsive.spacing(
                        context,
                        mobile: 16,
                      ),
                    ),
                    Text(
                      'Navigation Initialization Failed',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(
                          context,
                          mobile: 20,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: Responsive.spacing(
                        context,
                        mobile: 8,
                      ),
                    ),
                    Text(
                      initializationError.value!,
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: Responsive.spacing(
                        context,
                        mobile: 24,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          context.go('/driver');
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Home'),
                    ),
                  ],
                ),
              ),
            )
          else if (!navigationSessionInitialized.value)
            // Show loading while initializing (permissions, GPS, session)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: Responsive.spacing(context, mobile: 16)),
                  Text(
                    'Initializing Navigation...',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 18),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: Responsive.spacing(context, mobile: 8)),
                  Text(
                    userLocation.value == null ? 'Getting GPS location...' : 'Setting up map...',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else if (userLocation.value != null && navigationSessionInitialized.value)
            GoogleMapsNavigationView(
                // CRITICAL iOS FIX: Always enable navigation UI for bin collection routes
                // This must be set at view creation - cannot be changed later on iOS
                initialNavigationUIEnabledPreference: NavigationUIEnabledPreference.automatic,
                // Add bottom padding to prevent map content from being hidden behind bottom nav bar and panel
                // Increased bottom padding to move recenter button above the modal (was 100, now 200)
                initialPadding: EdgeInsets.only(
                  bottom: kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom + 200,
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

                // PHASE 6: Animate camera to user's GPS location immediately
                if (userLocation.value != null) {
                  try {
                    await controller.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: userLocation.value!,
                          zoom: 17,
                          tilt: 0,
                          bearing: 0,
                        ),
                      ),
                    );
                    AppLogger.general('✅ [VIEW CREATED] Camera animated to GPS location');
                  } catch (e) {
                    AppLogger.general('⚠️  [VIEW CREATED] Failed to animate camera: $e');
                  }
                }

                // Enable native Google Maps recenter button
                await controller.setRecenterButtonEnabled(true);
                AppLogger.general('✅ [VIEW CREATED] Recenter button enabled');

                // Disable the my-location button (grey button below audio button)
                await controller.settings.setMyLocationButtonEnabled(false);
                AppLogger.general('✅ [VIEW CREATED] My location button disabled');

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

                // PHASE 8: Removed iOS simulator fallback code
                // Let SDK handle simulator vs physical device naturally
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
              top: Responsive.spacing(context, mobile: 120),
              left: Responsive.spacing(context, mobile: 16),
              right: Responsive.spacing(context, mobile: 16),
              child: TurnByTurnNavigationCard(
                currentStep: navState.currentStep!,
                distanceToNextManeuver: navState.distanceToNextManeuver,
                estimatedTimeRemaining: navState.remainingTime,
                totalDistanceRemaining: navState.totalDistanceRemaining,
              ),
            ),

          // Notification button - positioned top-left
          Positioned(
            top: Responsive.spacing(context, mobile: 16),
            left: Responsive.spacing(context, mobile: 16),
            child: SafeArea(
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
          ),

          // Audio button - positioned above recenter button
          Positioned(
            bottom: Responsive.spacing(context, mobile: 360),
            right: Responsive.spacing(context, mobile: 16),
            child: CircularMapButton(
              icon: navState.isAudioMuted ? Icons.volume_off : Icons.volume_up,
              onTap: () => GoogleNavigationService.toggleAudio(
                navState.isAudioMuted,
                navNotifier.setAudioMuted,
              ),
            ),
          ),

          // Potential Location button - positioned above audio button
          Positioned(
            bottom: Responsive.spacing(context, mobile: 420),
            right: Responsive.spacing(context, mobile: 16),
            child: CircularMapButton(
              icon: Icons.add_location_alt_outlined,
              iconColor: AppColors.primaryGreen,
              onTap: () => _showPotentialLocationMenu(context, ref),
            ),
          ),

          // Custom recenter button - COMMENTED OUT (using native Google Maps button instead)
          // Positioned(
          //   bottom: Responsive.spacing(context, mobile: 340),
          //   right: Responsive.spacing(context, mobile: 16),
          //   child: CircularMapButton(
          //     icon: Icons.my_location,
          //     onTap: () async {
          //       if (navigationController.value != null) {
          //         // Use followMyLocation with tilted perspective for navigation-aware recentering
          //         await navigationController.value!.followMyLocation(
          //           CameraPerspective.tilted,
          //           zoomLevel: 17,
          //         );
          //         AppLogger.general('📍 Re-enabled camera following mode with tilted perspective');
          //       }
          //     },
          //   ),
          // ),

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

  /// Advance navigation to next bin after completing current bin
  /// Uses efficient updates - SDK auto-replaces route when setDestinations() is called
  static Future<void> _advanceToNextBin(
    BuildContext context,
    GoogleNavigationViewController? controller,
    WidgetRef ref,
    ShiftState shift,
    NavigationPageNotifier navNotifier,
  ) async {
    if (controller == null) {
      AppLogger.general('⚠️  Cannot advance: controller is null');
      return;
    }

    AppLogger.general('🚀 Advancing to next bin...');
    AppLogger.general('   Completed bins: ${shift.completedBins}');
    AppLogger.general('   Remaining bins: ${shift.remainingBins.length}');

    try {
      // If there are remaining bins, update destinations
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
          ),
          routingOptions: RoutingOptions(
            travelMode: NavigationTravelMode.driving,
            alternateRoutesStrategy: NavigationAlternateRoutesStrategy.none,
          ),
        );

        // Update destinations - SDK automatically:
        // 1. Replaces old route with new route
        // 2. Continues guidance automatically (no need to call startGuidance!)
        // 3. Recalculates turn-by-turn directions
        final result = await GoogleMapsNavigator.setDestinations(destinations);

        if (result == NavigationRouteStatus.statusOk) {
          navNotifier.setCurrentBinIndex(0);
          AppLogger.general('✅ Navigation updated to next bin - guidance continues automatically');

          // Clear and recreate custom markers for remaining bins
          await controller.clearMarkers();
          final tempMarkerMap = <String, RouteBin>{};
          final markers = await GoogleNavigationMarkerService.createCustomBinMarkers(shift.remainingBins, tempMarkerMap);
          await controller.addMarkers(markers);
          navNotifier.updateMarkerToBinMap(tempMarkerMap);
          AppLogger.general('📍 Updated ${markers.length} custom markers');

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

          // Animate camera to next bin (especially important for move requests)
          final nextBin = shift.remainingBins.first;
          try {
            await controller.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(
                  latitude: nextBin.latitude,
                  longitude: nextBin.longitude,
                ),
                17, // Zoom level
              ),
            );
            AppLogger.general('📹 Camera animated to next bin: #${nextBin.binNumber}');

            // Auto re-center back to driver position after showing drop-off location
            AppLogger.general('⏱️  Waiting 5 seconds before re-centering to driver position...');
            await Future.delayed(const Duration(seconds: 5));

            // Re-center camera to driver's position with navigation mode
            try {
              await controller.followMyLocation(
                CameraPerspective.tilted,  // iOS default: 3D perspective
                zoomLevel: null,  // Auto zoom: SDK adjusts based on navigation
              );
              AppLogger.general('📹 Auto re-centered to driver position');
            } catch (e) {
              AppLogger.general('⚠️  Failed to auto re-center: $e');
            }
          } catch (e) {
            AppLogger.general('⚠️  Failed to animate camera to next bin: $e');
          }

          AppLogger.general('✅ Navigation advance complete');
        } else {
          AppLogger.general('❌ Navigation advance failed: $result');
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

        // Small delay to let stop guidance animations complete
        // Prevents visual flicker when clearing destinations immediately
        await Future.delayed(const Duration(milliseconds: 500));
        AppLogger.general('   ⏱️  Waited 500ms for guidance animations to complete');
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
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          AppLogger.general('   ⚠️  Cannot pop - already at root, using context.go()');
          context.go('/driver');
        }
      } else if (shift.status == ShiftStatus.cancelled) {
        // Scenario 2: Cancelled → Show brief dialog, auto-dismiss, then pop
        AppLogger.general('   📤 Showing cancellation notice (auto-dismiss)');
        await showShiftCancellationDialog(context, shift);
      } else {
        // Scenario 1: Normal end → Show dialog, wait for user to click
        AppLogger.general('   📤 Showing shift summary dialog (user interaction)');
        await showShiftSummaryDialog(context, shift);
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


  /// Setup navigation after view is created (6-step process)
  static Future<void> _setupNavigationAfterViewCreated(
    GoogleNavigationViewController controller,
    BuildContext context,
    WidgetRef ref,
    ShiftState shift,
    NavigationPageNotifier navNotifier,
    bool isDark,
  ) async {
    AppLogger.general('🚀 [SETUP] Starting navigation setup...');

    try {
      // STEP 0: Check if guidance is already running (app reopen scenario)
      AppLogger.general('🔍 [STEP 0/7] Checking if navigation is already running...');
      final bool isGuidanceAlreadyRunning = await GoogleMapsNavigator.isGuidanceRunning();

      if (isGuidanceAlreadyRunning) {
        AppLogger.general('✅ [STEP 0/7] Navigation is ALREADY RUNNING (app was reopened)');
        AppLogger.general('ℹ️  Skipping route setup - will restore UI state only');

        // Configure map settings (needed even for restored session)
        await controller.settings.setCompassEnabled(false);
        await controller.settings.setTrafficEnabled(true);

        // Enable navigation UI (REQUIRED for camera following and route rendering)
        await controller.setNavigationUIEnabled(true);
        AppLogger.general('✅ Navigation UI enabled');

        // Disable Google's navigation header and footer (we use custom UI)
        await controller.setNavigationHeaderEnabled(false);
        await controller.setNavigationFooterEnabled(false);

        // Setup listeners (needed for UI updates)
        _setupNavigationListeners(context, ref, shift, navNotifier);

        // Restore markers for remaining bins
        final tempMarkerMap = <String, RouteBin>{};
        final markers = await GoogleNavigationMarkerService.createCustomBinMarkers(
          shift.remainingBins,
          tempMarkerMap,
        );
        await controller.addMarkers(markers);
        navNotifier.updateMarkerToBinMap(tempMarkerMap);
        AppLogger.general('📍 Restored ${markers.length} custom markers');

        // Restore geofence circles
        final circles = await GoogleNavigationMarkerService.createGeofenceCircles(
          shift.remainingBins,
        );
        await controller.addCircles(circles);
        navNotifier.updateGeofenceCircles(circles);
        AppLogger.general('⭕ Restored ${circles.length} geofence circles');

        // Enable camera following mode with platform default perspective
        await controller.followMyLocation(
          CameraPerspective.tilted,  // iOS default: 3D perspective
          zoomLevel: null,  // Auto zoom: SDK adjusts based on navigation
        );
        AppLogger.general('📹 Camera following restored with default perspective');

        // Mark navigation as ready
        navNotifier.setNavigationReady(true);
        navNotifier.setNavigating(true);

        AppLogger.general('🎉 [RESTORE] Navigation session restored successfully!');
        return;
      }

      AppLogger.general('✅ [STEP 0/7] Navigation not running - will perform full setup');

      // STEP 1: Configure map settings
      AppLogger.general('📱 [STEP 1/7] Configuring map settings...');

      await controller.settings.setCompassEnabled(false);
      await controller.settings.setTrafficEnabled(true);

      // Enable navigation UI (REQUIRED for camera following, route rendering, and puck movement)
      await controller.setNavigationUIEnabled(true);
      AppLogger.general('   ✅ Navigation UI enabled (required for camera following)');

      // Disable Google's navigation header (green banner) and footer (ETA card)
      // We use custom UI instead
      await controller.setNavigationHeaderEnabled(false);
      await controller.setNavigationFooterEnabled(false);
      AppLogger.general('   🎨 Disabled Google navigation header & footer (using custom UI)');

      AppLogger.general('✅ [STEP 1/7] Map settings configured');

      // STEP 2: Apply map style (COMMENTED OUT - using default Google Maps style)
      // AppLogger.general('🎨 [STEP 2/7] Applying map style...');
      // await _applyMapStyle(controller, isDark);
      // AppLogger.general('✅ [STEP 2/7] Map style applied');
      AppLogger.general('✅ [STEP 2/7] Using default Google Maps style (custom style disabled)');

      // STEP 3: Setup navigation listeners (for location updates, turn-by-turn, etc.)
      AppLogger.general('👂 [STEP 3/7] Setting up navigation listeners...');

      // Wait for first road-snapped location before calculating route (SDK best practice)
      final locationReceived = Completer<void>();
      _setupNavigationListeners(
        context,
        ref,
        shift,
        navNotifier,
        onFirstLocationReceived: () {
          if (!locationReceived.isCompleted) {
            locationReceived.complete();
          }
        },
      );
      AppLogger.general('✅ [STEP 3/7] Listeners configured');

      // PHASE 4: Wait for first location - DON'T proceed without it (SDK requirement)
      AppLogger.general('📍 [STEP 4/7] Waiting for first road-snapped location...');
      try {
        await locationReceived.future.timeout(
          const Duration(seconds: 30), // Longer timeout for GPS acquisition
        );
        AppLogger.general('✅ [STEP 4/7] Road-snapped location acquired');
      } catch (e) {
        // SDK documentation: "Route calculation is only available after location acquired"
        AppLogger.general('❌ [STEP 4/7] Location timeout - cannot start navigation without GPS');
        throw Exception('Unable to acquire GPS location for navigation. Please ensure location services are enabled.');
      }

      AppLogger.general('🗺️  [STEP 4/7] Calculating route to destinations...');
      await _setDestinationsFromShift(context, ref, shift, navNotifier);
      AppLogger.general('✅ [STEP 4/7] Route calculation initiated');

      // STEP 5: Add custom markers
      AppLogger.general('📍 [STEP 5/7] Creating and adding custom bin markers...');
      final tempMarkerMap = <String, RouteBin>{};
      final markers = await GoogleNavigationMarkerService.createCustomBinMarkers(shift.remainingBins, tempMarkerMap);
      await controller.addMarkers(markers);
      navNotifier.updateMarkerToBinMap(tempMarkerMap);
      AppLogger.general('✅ [STEP 5/7] Added ${markers.length} custom markers');

      // STEP 6: Create geofence circles and completed route polyline
      AppLogger.general('⭕ [STEP 6/7] Adding geofence circles and polylines...');
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
      AppLogger.general('✅ [STEP 6/7] Circles and polylines added');

      // STEP 7: Enable camera following mode with platform default perspective
      AppLogger.general('📹 [STEP 7/7] Enabling camera following mode...');
      await controller.followMyLocation(
        CameraPerspective.tilted,  // iOS default: 3D perspective
        zoomLevel: null,  // Auto zoom: SDK adjusts based on navigation
      );
      AppLogger.general('✅ [STEP 7/7] Camera following enabled with default perspective');

      navNotifier.setNavigationReady(true);
      navNotifier.setNavigating(true);
      AppLogger.general('✅ Navigation ready');

      AppLogger.general('🎉 [SETUP] All 7 steps completed successfully!');
    } catch (e) {
      AppLogger.general('❌ [SETUP] Error during setup: $e');
      rethrow;
    }
  }

  /// Setup navigation event listeners
  ///
  /// Note on Listener Lifecycle:
  /// All listeners are automatically cancelled when GoogleMapsNavigator.cleanup() is called.
  /// This is the official SDK pattern - no need for explicit subscription.cancel() calls.
  /// cleanup() is called in two places:
  /// 1. useEffect disposal (line 345) - when navigation page unmounts
  /// 2. logout() (auth_provider.dart:516) - when user logs out
  static void _setupNavigationListeners(
    BuildContext context,
    WidgetRef ref,
    ShiftState shift,
    NavigationPageNotifier navNotifier, {
    VoidCallback? onFirstLocationReceived,
  }) {
    AppLogger.general('👂 Setting up navigation listeners...');

    // Track if we've received the first location (for route calculation timing)
    bool hasReceivedFirstLocation = false;

    // Session Recreation Listener
    // Called when Android kills the app in background and session is recreated
    // Reapply all user preferences (audio settings, etc.)
    GoogleMapsNavigator.setOnNewNavigationSessionListener(() {
      AppLogger.general('🔄 Navigation session recreated - reapplying settings');

      // Reapply audio settings from state
      final currentAudioMuted = navNotifier.state.isAudioMuted;
      GoogleMapsNavigator.setAudioGuidance(
        NavigationAudioGuidanceSettings(
          guidanceType: currentAudioMuted
            ? NavigationAudioGuidanceType.silent
            : NavigationAudioGuidanceType.alertsAndGuidance,
        ),
      );
      AppLogger.general('   ✅ Audio settings reapplied: ${currentAudioMuted ? "muted" : "unmuted"}');
    });

    // Listen to NavInfo updates (turn-by-turn data)
    GoogleMapsNavigator.setNavInfoListener((navInfoEvent) {
      if (!navNotifier.state.hasReceivedFirstNavInfo) {
        AppLogger.general('📍 First NavInfo received');
        navNotifier.setHasReceivedFirstNavInfo(true);
      }

      final navInfo = navInfoEvent.navInfo;

      // Update current step (with null checks for SDK 0.8.0+ compatibility)
      if (navInfo.currentStep != null) {
        final step = navInfo.currentStep!;
        // SDK 0.8.0+: Most StepInfo fields are now nullable
        if (step.maneuver != null && step.fullInstructions != null) {
          navNotifier.updateCurrentStep(RouteStep(
            maneuverType: GoogleNavigationHelpers.convertManeuverType(step.maneuver!),
            instruction: step.fullInstructions!,
            distance: step.distanceFromPrevStepMeters?.toDouble() ?? 0.0,
            duration: navInfo.timeToCurrentStepSeconds?.toDouble() ?? 0.0,
            location: latlong.LatLng(0, 0), // Location not available in StepInfo
            modifier: GoogleNavigationHelpers.extractModifier(step.fullInstructions!),
          ));
        }
      }

      // Update distance to next maneuver
      navNotifier.updateDistanceToNextManeuver(navInfo.distanceToCurrentStepMeters?.toDouble() ?? 0);

      // DEBUG: Comprehensive NavInfo logging
      AppLogger.general('🔍 NavInfo Debug - COMPLETE DUMP:');
      AppLogger.general('   ⏱️  Time to Next Destination: ${navInfo.timeToNextDestinationSeconds} seconds');
      AppLogger.general('   ⏱️  Time to Final Destination: ${navInfo.timeToFinalDestinationSeconds} seconds');
      AppLogger.general('   📏 Distance to Next Destination: ${navInfo.distanceToNextDestinationMeters} meters');
      AppLogger.general('   📏 Distance to Final Destination: ${navInfo.distanceToFinalDestinationMeters} meters');
      AppLogger.general('   📏 Distance to Current Step: ${navInfo.distanceToCurrentStepMeters} meters');
      AppLogger.general('   ⏱️  Time to Current Step: ${navInfo.timeToCurrentStepSeconds} seconds');

      // Convert to readable format
      final distanceToNext = navInfo.distanceToNextDestinationMeters?.toDouble();
      final distanceToFinal = navInfo.distanceToFinalDestinationMeters?.toDouble();
      final timeToNext = navInfo.timeToNextDestinationSeconds;
      final timeToFinal = navInfo.timeToFinalDestinationSeconds;

      AppLogger.general('   📊 Readable Format:');
      AppLogger.general('      Next: ${distanceToNext != null ? "${(distanceToNext / 1609.0).toStringAsFixed(1)} mi" : "null"} / ${timeToNext != null ? "${timeToNext ~/ 60}m ${timeToNext % 60}s" : "null"}');
      AppLogger.general('      Final: ${distanceToFinal != null ? "${(distanceToFinal / 1609.0).toStringAsFixed(1)} mi" : "null"} / ${timeToFinal != null ? "${timeToFinal ~/ 60}m ${timeToFinal % 60}s" : "null"}');

      // Update remaining time and distance
      // iOS SDK bug: timeToNextDestinationSeconds and distanceToNextDestinationMeters are often null
      // Fallback to Final Destination values when Next Destination is null
      final timeSeconds = navInfo.timeToNextDestinationSeconds ?? navInfo.timeToFinalDestinationSeconds;
      final distanceMeters = navInfo.distanceToNextDestinationMeters ?? navInfo.distanceToFinalDestinationMeters;

      navNotifier.updateRemainingTime(timeSeconds != null
          ? Duration(seconds: timeSeconds)
          : null);

      navNotifier.updateTotalDistanceRemaining(distanceMeters?.toDouble());

      // Log what we're actually setting in state
      AppLogger.general('   ✅ State Updated:');
      AppLogger.general('      remainingTime: ${navNotifier.state.remainingTime}');
      AppLogger.general('      totalDistanceRemaining: ${navNotifier.state.totalDistanceRemaining}');
      AppLogger.general('      (Using ${navInfo.timeToNextDestinationSeconds != null ? "Next" : "Final"} Destination values)');
    });

    // Listen to location updates (SDK best practice: wait for first location before route calculation)
    GoogleMapsNavigator.setRoadSnappedLocationUpdatedListener((location) {
      // Call callback on first location received (allows route calculation to proceed)
      if (!hasReceivedFirstLocation && onFirstLocationReceived != null) {
        hasReceivedFirstLocation = true;
        AppLogger.general('📍 First road-snapped location received - ready for route calculation');
        onFirstLocationReceived();
      }

      // Update navigation location for display
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

  /// Show bottom sheet menu for potential location options
  static void _showPotentialLocationMenu(BuildContext context, WidgetRef ref) {
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
  static Future<void> _suggestCurrentLocation(BuildContext context, WidgetRef ref) async {
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
  static void _openManualForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PotentialLocationFormDialog(),
    );
  }
}
