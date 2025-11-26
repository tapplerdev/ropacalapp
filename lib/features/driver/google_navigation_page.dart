import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/features/driver/widgets/check_in_dialog.dart';
import 'package:ropacalapp/features/driver/widgets/bin_details_bottom_sheet.dart';
import 'package:ropacalapp/features/driver/widgets/turn_by_turn_navigation_card.dart';
import 'package:ropacalapp/features/driver/widgets/pin_marker_painter.dart';
import 'package:ropacalapp/features/driver/widgets/active_shift_bottom_sheet.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/models/route_step.dart';
import 'package:ropacalapp/core/enums/bin_status.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:latlong2/latlong.dart' as latlong;

/// Google Maps Navigation page with turn-by-turn navigation for bin collection routes
class GoogleNavigationPage extends HookConsumerWidget {
  const GoogleNavigationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationController = useState<GoogleNavigationViewController?>(null);
    final isAudioMuted = useState(false);
    final userLocation = useState<LatLng?>(null);

    // Navigation state
    final isNavigationReady = useState(false);
    final isNavigating = useState(false);
    final currentBinIndex = useState(0);
    final isExpanded = useState(false); // Expandable bottom panel state
    final markerToBinMap = useState<Map<String, RouteBin>>({});

    // Turn-by-turn navigation state for custom UI
    final currentStep = useState<RouteStep?>(null);
    final distanceToNextManeuver = useState<double>(0.0); // meters
    final remainingTime = useState<Duration?>(null);
    final totalDistanceRemaining = useState<double?>(null); // meters

    final isDarkMode = useState(false); // Dark mode toggle for map style
    final navigationLocation = useState<LatLng?>(null);
    final geofenceCircles = useState<List<CircleOptions>>([]);
    final completedRoutePolyline = useState<PolylineOptions?>(null);
    final isMounted = useRef(true);
    final hasReceivedFirstNavInfo = useRef(false);
    final navigatorInitialized = useState(false);
    final initializationError = useState<String?>(null);
    final isHandlingShiftEnd = useRef(false); // Prevent duplicate cleanup calls

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
          navigationController.value,
          ref,
          next,
          currentBinIndex,
          geofenceCircles,
          completedRoutePolyline,
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
          geofenceCircles,
          completedRoutePolyline,
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
          geofenceCircles,
          completedRoutePolyline,
          isDeleted: true, // Auto-pop without dialog for deleted shifts
        );
      }
    });

    // Initialize navigator BEFORE view creation (following official SDK pattern)
    useEffect(() {
      Future<void> initializeNavigator() async {
        AppLogger.general('🚀 [EARLY INIT] Starting navigator initialization (before view creation)...');

        try {
          await _initializeNavigation(context, ref);
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
            // Use city center default (Bogotá, Colombia)
            userLocation.value = const LatLng(
              latitude: 4.6097,
              longitude: -74.0817,
            );
            AppLogger.general('⚠️  [EARLY INIT] GPS not available (emulator?), using Bogotá city center: ${userLocation.value}');
            AppLogger.general('   Navigation will start from default location');
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

    // Safety timeout
    useEffect(() {
      final timer = Timer(const Duration(seconds: 15), () {
        if (!navigatorInitialized.value) {
          AppLogger.general('⏱️  Navigator initialization timeout');
          navigatorInitialized.value = true;
        }
      });
      return timer.cancel;
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
          if (isNavigating.value) {
            GoogleMapsNavigator.stopGuidance();
            AppLogger.general('   ⏹️  Stopped navigation guidance');
          }
        } catch (e) {
          AppLogger.general('   ⚠️  Error stopping guidance: $e');
        }

        try {
          GoogleMapsNavigator.clearDestinations();
          AppLogger.general('   🗑️  Cleared destinations');
        } catch (e) {
          AppLogger.general('   ⚠️  Error clearing destinations: $e');
        }

        try {
          GoogleMapsNavigator.cleanup();
          AppLogger.general('   ✅ Navigation cleanup complete');
        } catch (e) {
          AppLogger.general('   ⚠️  Error during cleanup: $e');
        }
      };
    }, []);

    return Scaffold(
      body: Stack(
        children: [
          // Google Maps Navigation view
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
          else if (userLocation.value != null)
            GoogleMapsNavigationView(
              onMarkerClicked: (String markerId) {
                AppLogger.general('🎯 Marker clicked: $markerId');
                final bin = markerToBinMap.value[markerId];
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

                try {
                  await _setupNavigationAfterViewCreated(
                    controller,
                    context,
                    ref,
                    shift,
                    isNavigationReady,
                    isNavigating,
                    currentBinIndex,
                    markerToBinMap,
                    currentStep,
                    distanceToNextManeuver,
                    remainingTime,
                    totalDistanceRemaining,
                    navigationLocation,
                    geofenceCircles,
                    completedRoutePolyline,
                    hasReceivedFirstNavInfo,
                    isDarkMode.value,
                  );
                } catch (e) {
                  AppLogger.general('❌ [VIEW CREATED] Setup failed: $e');
                }
              },
              initialCameraPosition: CameraPosition(
                target: userLocation.value!,
                zoom: 15,
              ),
            )
          else
            // Loading while initializing
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Turn-by-turn navigation card
          if (isNavigating.value && currentStep.value != null)
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: TurnByTurnNavigationCard(
                currentStep: currentStep.value!,
                distanceToNextManeuver: distanceToNextManeuver.value,
                estimatedTimeRemaining: remainingTime.value,
                totalDistanceRemaining: totalDistanceRemaining.value,
              ),
            ),

          // Map control buttons - positioned top-right
          Positioned(
            top: 50,
            right: 16,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Notifications button
                  _buildCircularButton(
                    icon: Icons.notifications_outlined,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Current location button
                  _buildCircularButton(
                    icon: Icons.my_location,
                    onTap: () async {
                      if (navigationController.value != null) {
                        final location = await navigationController.value!.getMyLocation();
                        if (location != null) {
                          await navigationController.value!.animateCamera(
                            CameraUpdate.newLatLng(location),
                          );
                          AppLogger.general('📍 Centered on location');
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Audio button
                  _buildCircularButton(
                    icon: isAudioMuted.value ? Icons.volume_off : Icons.volume_up,
                    onTap: () => _toggleAudio(isAudioMuted),
                  ),
                ],
              ),
            ),
          ),

          // Bottom panel - expandable bin details
          if (isNavigationReady.value && shift.remainingBins.isNotEmpty)
            _buildBottomPanel(
              context,
              ref,
              shift,
              currentBinIndex.value,
              isExpanded,
              remainingTime.value,
              totalDistanceRemaining.value,
            ),
        ],
      ),
    );
  }

  /// Initialize navigation session and show T&C dialog if needed
  static Future<void> _initializeNavigation(BuildContext context, WidgetRef ref) async {
    AppLogger.general('🚀 Initializing Google Maps Navigator...');

    try {
      // Check if T&C dialog needs to be shown
      final termsAccepted = await GoogleMapsNavigator.areTermsAccepted();
      AppLogger.general('📋 Terms accepted: $termsAccepted');

      if (!termsAccepted) {
        AppLogger.general('📋 Showing terms and conditions dialog...');
        await GoogleMapsNavigator.showTermsAndConditionsDialog(
          'Navigation Terms',
          'Ropacal Navigation',
        );
        AppLogger.general('✅ Terms accepted');
      }

      // Initialize navigation session
      await GoogleMapsNavigator.initializeNavigationSession();
      AppLogger.general('✅ Navigation session initialized');

      // Set audio guidance to enabled by default
      await GoogleMapsNavigator.setAudioGuidance(
        NavigationAudioGuidanceSettings(
          guidanceType: NavigationAudioGuidanceType.alertsAndGuidance,
        ),
      );
      AppLogger.general('🔊 Audio guidance enabled');
    } catch (e) {
      AppLogger.general('❌ Navigation initialization error: $e');
      rethrow;
    }
  }

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
    ValueNotifier<int> currentBinIndex,
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

      if (result == NavigationRouteStatus.statusOk) {
        AppLogger.general('✅ Route calculated successfully');

        // Start navigation guidance
        await GoogleMapsNavigator.startGuidance();
        AppLogger.general('🎯 Navigation guidance started');

        // Reset current bin index
        currentBinIndex.value = 0;
      } else {
        AppLogger.general('❌ Route calculation failed: $result');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to calculate route: $result'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.general('❌ Error setting destinations: $e');
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
    GoogleNavigationViewController? controller,
    WidgetRef ref,
    ShiftState shift,
    ValueNotifier<int> currentBinIndex,
    ValueNotifier<List<CircleOptions>> geofenceCircles,
    ValueNotifier<PolylineOptions?> completedRoutePolyline,
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

      // Recreate markers and circles for remaining bins
      final tempMarkerMap = <String, RouteBin>{};
      final markers = await _createCustomBinMarkers(shift.remainingBins, tempMarkerMap);
      await controller.clearMarkers();
      await controller.addMarkers(markers);
      AppLogger.general('📍 Updated ${markers.length} markers');

      // Recreate geofence circles
      final circles = await _createGeofenceCircles(shift.remainingBins);
      await controller.clearCircles();
      await controller.addCircles(circles);
      geofenceCircles.value = circles;
      AppLogger.general('⭕ Updated ${circles.length} geofence circles');

      // Update completed route polyline
      final completedBinsList = shift.routeBins.where((bin) => bin.isCompleted == 1).toList();
      final polyline = await _createCompletedRoutePolyline(completedBinsList);
      await controller.clearPolylines();
      if (polyline != null) {
        await controller.addPolylines([polyline]);
        completedRoutePolyline.value = polyline;
        AppLogger.general('📏 Updated completed route polyline');
      }

      // If there are remaining bins, set new destinations
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
          currentBinIndex.value = 0;
          AppLogger.general('✅ Route recalculated successfully');
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
          // Loading will auto-dismiss when listener detects status change
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
    ValueNotifier<List<CircleOptions>> geofenceCircles,
    ValueNotifier<PolylineOptions?> completedRoutePolyline, {
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
        geofenceCircles.value = [];
        AppLogger.general('   ✅ Cleared geofence circles');
      } catch (e) {
        AppLogger.general('   ⚠️  Error clearing geofence circles (likely disposed): $e');
      }

      // 6. Clear completed route polyline
      try {
        completedRoutePolyline.value = null;
        AppLogger.general('   ✅ Cleared completed route');
      } catch (e) {
        AppLogger.general('   ⚠️  Error clearing completed route (likely disposed): $e');
      }

      AppLogger.general('✅ Navigation cleanup complete');

      // 7. Dismiss any loading overlays
      await EasyLoading.dismiss();
      AppLogger.general('   ✅ Dismissed loading overlay');

      // 8. Handle navigation based on scenario
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

  /// Setup navigation after view is created (5-step process)
  static Future<void> _setupNavigationAfterViewCreated(
    GoogleNavigationViewController controller,
    BuildContext context,
    WidgetRef ref,
    ShiftState shift,
    ValueNotifier<bool> isNavigationReady,
    ValueNotifier<bool> isNavigating,
    ValueNotifier<int> currentBinIndex,
    ValueNotifier<Map<String, RouteBin>> markerToBinMap,
    ValueNotifier<RouteStep?> currentStep,
    ValueNotifier<double> distanceToNextManeuver,
    ValueNotifier<Duration?> remainingTime,
    ValueNotifier<double?> totalDistanceRemaining,
    ValueNotifier<LatLng?> navigationLocation,
    ValueNotifier<List<CircleOptions>> geofenceCircles,
    ValueNotifier<PolylineOptions?> completedRoutePolyline,
    ObjectRef<bool> hasReceivedFirstNavInfo,
    bool isDark,
  ) async {
    AppLogger.general('🚀 [SETUP] Starting 5-step navigation setup...');

    try {
      // STEP 1: Configure map settings
      AppLogger.general('📱 [STEP 1/5] Configuring map settings...');
      await controller.setMyLocationEnabled(true);
      await controller.settings.setCompassEnabled(false);
      await controller.settings.setMyLocationButtonEnabled(false);
      await controller.settings.setZoomControlsEnabled(false);
      await controller.settings.setTrafficEnabled(false);

      // Hide Google's navigation header (green banner) and footer (ETA card)
      // Keep navigation UI enabled for route/puck rendering, but hide the UI components
      await controller.setNavigationHeaderEnabled(false);
      await controller.setNavigationFooterEnabled(false);
      AppLogger.general('   🎨 Disabled Google navigation header & footer');

      AppLogger.general('✅ [STEP 1/5] Map settings configured');

      // STEP 2: Apply map style
      AppLogger.general('🎨 [STEP 2/5] Applying map style...');
      await _applyMapStyle(controller, isDark);
      AppLogger.general('✅ [STEP 2/5] Map style applied');

      // STEP 3: Create and add custom markers
      AppLogger.general('📍 [STEP 3/5] Creating custom bin markers...');
      final markers = await _createCustomBinMarkers(shift.remainingBins, markerToBinMap.value);
      await controller.addMarkers(markers);
      AppLogger.general('✅ [STEP 3/5] Added ${markers.length} custom markers');

      // STEP 4: Create geofence circles
      AppLogger.general('⭕ [STEP 4/5] Creating geofence circles...');
      final circles = await _createGeofenceCircles(shift.remainingBins);
      await controller.addCircles(circles);
      geofenceCircles.value = circles;
      AppLogger.general('✅ [STEP 4/5] Added ${circles.length} geofence circles');

      // Add completed route polyline if there are completed bins
      if (shift.completedBins > 0) {
        final completedBinsList = shift.routeBins.where((bin) => bin.isCompleted == 1).toList();
        final polyline = await _createCompletedRoutePolyline(completedBinsList);
        if (polyline != null) {
          await controller.addPolylines([polyline]);
          completedRoutePolyline.value = polyline;
          AppLogger.general('📏 Added completed route polyline');
        }
      }

      // STEP 5: Set destinations and start navigation
      AppLogger.general('🗺️  [STEP 5/5] Setting destinations and starting navigation...');
      await _setDestinationsFromShift(context, ref, shift, currentBinIndex);

      // Setup navigation listeners
      _setupNavigationListeners(
        currentStep,
        distanceToNextManeuver,
        remainingTime,
        totalDistanceRemaining,
        navigationLocation,
        hasReceivedFirstNavInfo,
      );

      isNavigationReady.value = true;
      isNavigating.value = true;
      AppLogger.general('✅ [STEP 5/5] Navigation started');

      AppLogger.general('🎉 [SETUP] All 5 steps completed successfully!');
    } catch (e) {
      AppLogger.general('❌ [SETUP] Error during setup: $e');
      rethrow;
    }
  }

  /// Create custom bin markers with numbered pins
  static Future<List<MarkerOptions>> _createCustomBinMarkers(
    List<RouteBin> bins,
    Map<String, RouteBin> markerToBinMap,
  ) async {
    final markers = <MarkerOptions>[];

    for (int i = 0; i < bins.length; i++) {
      final bin = bins[i];
      final binNumber = i + 1;

      // Create custom marker icon
      final icon = await _createBinMarkerIcon(bin.binNumber, bin.fillPercentage);

      final markerId = 'bin_${bin.id}';
      markerToBinMap[markerId] = bin;

      final markerOptions = MarkerOptions(
        position: LatLng(
          latitude: bin.latitude,
          longitude: bin.longitude,
        ),
        icon: icon,
        anchor: const MarkerAnchor(u: 0.5, v: 0.5), // Center
        zIndex: binNumber.toDouble(),
        consumeTapEvents: true,
      );

      markers.add(markerOptions);
    }

    return markers;
  }

  /// Create geofence circles around bins (50m radius)
  static Future<List<CircleOptions>> _createGeofenceCircles(List<RouteBin> bins) async {
    final circles = <CircleOptions>[];

    for (int i = 0; i < bins.length; i++) {
      final bin = bins[i];

      final circleOptions = CircleOptions(
        position: LatLng(
          latitude: bin.latitude,
          longitude: bin.longitude,
        ),
        radius: 50, // 50 meters
        strokeWidth: 2,
        strokeColor: Colors.blue.withOpacity(0.6),
        fillColor: Colors.blue.withOpacity(0.1),
        zIndex: 1,
        clickable: false,
      );

      circles.add(circleOptions);
    }

    return circles;
  }

  /// Create polyline for completed route segments
  static Future<PolylineOptions?> _createCompletedRoutePolyline(List<RouteBin> completedBins) async {
    if (completedBins.length < 2) {
      return null; // Need at least 2 points for a line
    }

    final points = completedBins.map((bin) {
      return LatLng(
        latitude: bin.latitude,
        longitude: bin.longitude,
      );
    }).toList();

    return PolylineOptions(
      points: points,
      strokeWidth: 6,
      strokeColor: Colors.grey.withOpacity(0.6),
      geodesic: true,
      zIndex: 0,
      clickable: false,
    );
  }

  /// Create custom bin marker icon with number badge
  static Future<ImageDescriptor> _createBinMarkerIcon(int binNumber, int fillPercentage) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Determine fill color based on fill percentage
    final fillColor = _getFillColor(fillPercentage);

    // Use PinMarkerPainter to draw the marker
    final painter = PinMarkerPainter(
      binNumber: binNumber,
      fillPercentage: fillPercentage,
      fillColor: fillColor,
    );
    painter.paint(canvas, const Size(120, 120));

    final picture = recorder.endRecording();
    final image = await picture.toImage(120, 120);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    if (bytes == null) {
      throw Exception('Failed to create marker icon');
    }

    final registeredImage = await registerBitmapImage(
      bitmap: bytes,
      imagePixelRatio: 1.0,
      width: 120,
      height: 120,
    );

    return registeredImage;
  }

  /// Get fill color based on fill percentage
  static Color _getFillColor(int fillPercentage) {
    if (fillPercentage >= 80) {
      return Colors.red;
    } else if (fillPercentage >= 50) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  /// Setup navigation event listeners
  static void _setupNavigationListeners(
    ValueNotifier<RouteStep?> currentStep,
    ValueNotifier<double> distanceToNextManeuver,
    ValueNotifier<Duration?> remainingTime,
    ValueNotifier<double?> totalDistanceRemaining,
    ValueNotifier<LatLng?> navigationLocation,
    ObjectRef<bool> hasReceivedFirstNavInfo,
  ) {
    AppLogger.general('👂 Setting up navigation listeners...');

    // Listen to NavInfo updates (turn-by-turn data)
    GoogleMapsNavigator.setNavInfoListener((navInfoEvent) {
      if (!hasReceivedFirstNavInfo.value) {
        AppLogger.general('📍 First NavInfo received');
        hasReceivedFirstNavInfo.value = true;
      }

      final navInfo = navInfoEvent.navInfo;

      // Update current step
      if (navInfo.currentStep != null) {
        final step = navInfo.currentStep!;
        currentStep.value = RouteStep(
          maneuverType: _convertManeuverType(step.maneuver),
          instruction: step.fullInstructions,
          distance: step.distanceFromPrevStepMeters.toDouble(),
          duration: navInfo.timeToCurrentStepSeconds?.toDouble() ?? 0.0,
          location: latlong.LatLng(0, 0), // Location not available in StepInfo
          modifier: _extractModifier(step.fullInstructions),
        );
      }

      // Update distance to next maneuver
      distanceToNextManeuver.value = navInfo.distanceToCurrentStepMeters?.toDouble() ?? 0;

      // Update remaining time and distance
      remainingTime.value = navInfo.timeToCurrentStepSeconds != null
          ? Duration(seconds: navInfo.timeToCurrentStepSeconds!)
          : null;

      totalDistanceRemaining.value = navInfo.distanceToFinalDestinationMeters?.toDouble();
    });

    // Listen to location updates
    GoogleMapsNavigator.setRoadSnappedLocationUpdatedListener((location) {
      navigationLocation.value = location.location;
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

  /// Convert Maneuver enum to string representation
  static String _convertManeuverType(Maneuver? maneuver) {
    if (maneuver == null) return 'UNKNOWN';

    switch (maneuver) {
      case Maneuver.destination:
        return 'DESTINATION';
      case Maneuver.depart:
        return 'DEPART';
      case Maneuver.destinationLeft:
        return 'DESTINATION_LEFT';
      case Maneuver.destinationRight:
        return 'DESTINATION_RIGHT';
      case Maneuver.ferryBoat:
        return 'FERRY_BOAT';
      case Maneuver.ferryTrain:
        return 'FERRY_TRAIN';
      case Maneuver.forkLeft:
        return 'FORK_LEFT';
      case Maneuver.forkRight:
        return 'FORK_RIGHT';
      case Maneuver.mergeLeft:
        return 'MERGE_LEFT';
      case Maneuver.mergeRight:
        return 'MERGE_RIGHT';
      case Maneuver.mergeUnspecified:
        return 'MERGE_UNSPECIFIED';
      case Maneuver.nameChange:
        return 'NAME_CHANGE';
      case Maneuver.offRampUnspecified:
        return 'OFF_RAMP_UNSPECIFIED';
      case Maneuver.offRampKeepLeft:
        return 'OFF_RAMP_KEEP_LEFT';
      case Maneuver.offRampKeepRight:
        return 'OFF_RAMP_KEEP_RIGHT';
      case Maneuver.offRampLeft:
        return 'OFF_RAMP_LEFT';
      case Maneuver.offRampRight:
        return 'OFF_RAMP_RIGHT';
      case Maneuver.offRampSharpLeft:
        return 'OFF_RAMP_SHARP_LEFT';
      case Maneuver.offRampSharpRight:
        return 'OFF_RAMP_SHARP_RIGHT';
      case Maneuver.offRampSlightLeft:
        return 'OFF_RAMP_SLIGHT_LEFT';
      case Maneuver.offRampSlightRight:
        return 'OFF_RAMP_SLIGHT_RIGHT';
      case Maneuver.offRampUTurnClockwise:
        return 'OFF_RAMP_U_TURN_CLOCKWISE';
      case Maneuver.offRampUTurnCounterclockwise:
        return 'OFF_RAMP_U_TURN_COUNTERCLOCKWISE';
      case Maneuver.onRampUnspecified:
        return 'ON_RAMP_UNSPECIFIED';
      case Maneuver.onRampKeepLeft:
        return 'ON_RAMP_KEEP_LEFT';
      case Maneuver.onRampKeepRight:
        return 'ON_RAMP_KEEP_RIGHT';
      case Maneuver.onRampLeft:
        return 'ON_RAMP_LEFT';
      case Maneuver.onRampRight:
        return 'ON_RAMP_RIGHT';
      case Maneuver.onRampSharpLeft:
        return 'ON_RAMP_SHARP_LEFT';
      case Maneuver.onRampSharpRight:
        return 'ON_RAMP_SHARP_RIGHT';
      case Maneuver.onRampSlightLeft:
        return 'ON_RAMP_SLIGHT_LEFT';
      case Maneuver.onRampSlightRight:
        return 'ON_RAMP_SLIGHT_RIGHT';
      case Maneuver.onRampUTurnClockwise:
        return 'ON_RAMP_U_TURN_CLOCKWISE';
      case Maneuver.onRampUTurnCounterclockwise:
        return 'ON_RAMP_U_TURN_COUNTERCLOCKWISE';
      case Maneuver.roundaboutClockwise:
        return 'ROUNDABOUT_CLOCKWISE';
      case Maneuver.roundaboutCounterclockwise:
        return 'ROUNDABOUT_COUNTERCLOCKWISE';
      case Maneuver.roundaboutExitClockwise:
        return 'ROUNDABOUT_EXIT_CLOCKWISE';
      case Maneuver.roundaboutExitCounterclockwise:
        return 'ROUNDABOUT_EXIT_COUNTERCLOCKWISE';
      case Maneuver.roundaboutLeftClockwise:
        return 'ROUNDABOUT_LEFT_CLOCKWISE';
      case Maneuver.roundaboutLeftCounterclockwise:
        return 'ROUNDABOUT_LEFT_COUNTERCLOCKWISE';
      case Maneuver.roundaboutRightClockwise:
        return 'ROUNDABOUT_RIGHT_CLOCKWISE';
      case Maneuver.roundaboutRightCounterclockwise:
        return 'ROUNDABOUT_RIGHT_COUNTERCLOCKWISE';
      case Maneuver.roundaboutSharpLeftClockwise:
        return 'ROUNDABOUT_SHARP_LEFT_CLOCKWISE';
      case Maneuver.roundaboutSharpLeftCounterclockwise:
        return 'ROUNDABOUT_SHARP_LEFT_COUNTERCLOCKWISE';
      case Maneuver.roundaboutSharpRightClockwise:
        return 'ROUNDABOUT_SHARP_RIGHT_CLOCKWISE';
      case Maneuver.roundaboutSharpRightCounterclockwise:
        return 'ROUNDABOUT_SHARP_RIGHT_COUNTERCLOCKWISE';
      case Maneuver.roundaboutSlightLeftClockwise:
        return 'ROUNDABOUT_SLIGHT_LEFT_CLOCKWISE';
      case Maneuver.roundaboutSlightLeftCounterclockwise:
        return 'ROUNDABOUT_SLIGHT_LEFT_COUNTERCLOCKWISE';
      case Maneuver.roundaboutSlightRightClockwise:
        return 'ROUNDABOUT_SLIGHT_RIGHT_CLOCKWISE';
      case Maneuver.roundaboutSlightRightCounterclockwise:
        return 'ROUNDABOUT_SLIGHT_RIGHT_COUNTERCLOCKWISE';
      case Maneuver.roundaboutStraightClockwise:
        return 'ROUNDABOUT_STRAIGHT_CLOCKWISE';
      case Maneuver.roundaboutStraightCounterclockwise:
        return 'ROUNDABOUT_STRAIGHT_COUNTERCLOCKWISE';
      case Maneuver.roundaboutUTurnClockwise:
        return 'ROUNDABOUT_U_TURN_CLOCKWISE';
      case Maneuver.roundaboutUTurnCounterclockwise:
        return 'ROUNDABOUT_U_TURN_COUNTERCLOCKWISE';
      case Maneuver.straight:
        return 'STRAIGHT';
      case Maneuver.turnKeepLeft:
        return 'TURN_KEEP_LEFT';
      case Maneuver.turnKeepRight:
        return 'TURN_KEEP_RIGHT';
      case Maneuver.turnLeft:
        return 'TURN_LEFT';
      case Maneuver.turnRight:
        return 'TURN_RIGHT';
      case Maneuver.turnSharpLeft:
        return 'TURN_SHARP_LEFT';
      case Maneuver.turnSharpRight:
        return 'TURN_SHARP_RIGHT';
      case Maneuver.turnSlightLeft:
        return 'TURN_SLIGHT_LEFT';
      case Maneuver.turnSlightRight:
        return 'TURN_SLIGHT_RIGHT';
      case Maneuver.turnUTurnClockwise:
        return 'TURN_U_TURN_CLOCKWISE';
      case Maneuver.turnUTurnCounterclockwise:
        return 'TURN_U_TURN_COUNTERCLOCKWISE';
      case Maneuver.unknown:
        return 'UNKNOWN';
    }
  }

  /// Extract modifier (left/right/slight/sharp) from instruction text
  static String _extractModifier(String instruction) {
    final lowerInstruction = instruction.toLowerCase();

    if (lowerInstruction.contains('sharp left')) return 'sharp left';
    if (lowerInstruction.contains('sharp right')) return 'sharp right';
    if (lowerInstruction.contains('slight left')) return 'slight left';
    if (lowerInstruction.contains('slight right')) return 'slight right';
    if (lowerInstruction.contains('left')) return 'left';
    if (lowerInstruction.contains('right')) return 'right';
    if (lowerInstruction.contains('straight')) return 'straight';
    if (lowerInstruction.contains('u-turn')) return 'u-turn';

    return '';
  }

  /// Calculate distance between two coordinates using Haversine formula
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371000.0; // meters

    final lat1 = _degreesToRadians(point1.latitude);
    final lat2 = _degreesToRadians(point2.latitude);
    final deltaLat = _degreesToRadians(point2.latitude - point1.latitude);
    final deltaLon = _degreesToRadians(point2.longitude - point1.longitude);

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Apply branded map style (light or dark mode)
  static Future<void> _applyMapStyle(GoogleNavigationViewController controller, bool isDark) async {
    try {
      final stylePath = isDark
          ? 'assets/map_styles/dark_style.json'
          : 'assets/map_styles/light_style.json';

      final styleJson = await rootBundle.loadString(stylePath);
      await controller.setMapStyle(styleJson);

      AppLogger.general('🎨 Applied ${isDark ? "dark" : "light"} map style');
    } catch (e) {
      AppLogger.general('⚠️  Failed to apply map style: $e');
      // Fallback to default style
      await controller.setMapStyle(null);
    }
  }

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
              'In ${_formatDistance(distanceToNextManeuver)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
          if (remainingTime != null && totalDistanceRemaining != null) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDistance(totalDistanceRemaining),
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  _formatETA(remainingTime),
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

  /// Build expandable bottom panel with bin details
  Widget _buildBottomPanel(
    BuildContext context,
    WidgetRef ref,
    ShiftState shift,
    int currentIndex,
    ValueNotifier<bool> isExpanded,
    Duration? remainingTime,
    double? totalDistanceRemaining,
  ) {
    final currentBin = shift.remainingBins.isNotEmpty && currentIndex < shift.remainingBins.length
        ? shift.remainingBins[currentIndex]
        : null;

    if (currentBin == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {
          isExpanded.value = !isExpanded.value;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: isExpanded.value ? 320 : 85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: isExpanded.value
                    ? _buildExpandedContent(context, ref, shift, currentBin, currentIndex, remainingTime, totalDistanceRemaining)
                    : _buildCollapsedContent(currentBin, currentIndex, shift.remainingBins.length, remainingTime),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build collapsed panel content (compact bar) - matching screenshot design
  Widget _buildCollapsedContent(
    RouteBin currentBin,
    int currentIndex,
    int totalBins,
    Duration? remainingTime,
  ) {
    final progressPercentage = totalBins > 0 ? currentIndex / totalBins : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Green status dot
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              // Bin number badge (blue square)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${currentBin.binNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Address
              Expanded(
                child: Text(
                  currentBin.currentStreet,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              // Progress count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${currentIndex}/$totalBins',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Up arrow icon
              Icon(
                Icons.keyboard_arrow_up,
                color: Colors.grey.shade500,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Thin progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progressPercentage,
              minHeight: 4,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
    );
  }

  /// Build expanded panel content (full bin details) - matching screenshot design
  Widget _buildExpandedContent(
    BuildContext context,
    WidgetRef ref,
    ShiftState shift,
    RouteBin currentBin,
    int currentIndex,
    Duration? remainingTime,
    double? totalDistanceRemaining,
  ) {
    final progressPercentage = shift.totalBins > 0 ? shift.completedBins / shift.totalBins : 0.0;
    final upcomingBins = _getUpcomingBins(shift.remainingBins, currentIndex);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with progress and est. finish time
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                // Green dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                // Progress text
                Text(
                  '${shift.completedBins} of ${shift.totalBins} complete',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                // Est. finish time badge
                if (remainingTime != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppColors.primaryBlue,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Est. finish: ${_calculateEstimatedFinishTime(remainingTime)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                // Down arrow
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade500,
                  size: 24,
                ),
              ],
            ),
          ),
          // Thin progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progressPercentage,
                minHeight: 4,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Current bin card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Bin number badge (44px blue square - more compact)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${currentBin.binNumber}',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bin info
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Address as title
                          Text(
                            currentBin.currentStreet,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Badges row (fill % + distance + ETA)
                          Row(
                            children: [
                              // Fill percentage badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: GoogleNavigationPage._getFillColor(currentBin.fillPercentage).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${currentBin.fillPercentage}% full',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: GoogleNavigationPage._getFillColor(currentBin.fillPercentage),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Distance badge
                              if (totalDistanceRemaining != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _formatDistance(totalDistanceRemaining),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              // ETA badge
                              if (remainingTime != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'ETA ${_formatETA(remainingTime)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Complete Bin button (simple green button)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      AppLogger.general('Complete Bin button pressed for Bin #${currentBin.binNumber}');
                      _showCheckInDialog(context, ref, currentBin);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 54),
                    ),
                    child: const Text(
                      'Complete Bin',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // UP NEXT section
          if (upcomingBins.isNotEmpty) ...[
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'UP NEXT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${upcomingBins.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable list of upcoming bins - shows first bin, scroll for more
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 60), // Show only 1 bin
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: upcomingBins.length,
                itemBuilder: (context, index) {
                  final bin = upcomingBins[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        // Bin number badge (slightly grey background)
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${bin.binNumber}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Address (darker text)
                        Expanded(
                          child: Text(
                            bin.currentStreet,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Fill percentage badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: GoogleNavigationPage._getFillColor(bin.fillPercentage).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${bin.fillPercentage}% full',
                            style: TextStyle(
                              fontSize: 12,
                              color: GoogleNavigationPage._getFillColor(bin.fillPercentage),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
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

  /// Format distance in meters to km/m
  static String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${meters.round()} m';
    }
  }

  /// Format ETA duration
  static String _formatETA(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
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

  /// Calculate estimated finish time
  static String _calculateEstimatedFinishTime(Duration remainingTime) {
    final now = DateTime.now();
    final estimatedFinish = now.add(remainingTime);

    final hour = estimatedFinish.hour;
    final minute = estimatedFinish.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Get upcoming bins (next 2-3 bins)
  static List<RouteBin> _getUpcomingBins(List<RouteBin> allBins, int currentIndex) {
    if (currentIndex >= allBins.length - 1) {
      return [];
    }

    final startIndex = currentIndex + 1;
    final endIndex = min(startIndex + 3, allBins.length);

    return allBins.sublist(startIndex, endIndex);
  }

  /// Build circular map control button
  static Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.grey.shade700,
          size: 24,
        ),
      ),
    );
  }

  /// Toggle audio guidance on/off
  static void _toggleAudio(ValueNotifier<bool> isAudioMuted) {
    isAudioMuted.value = !isAudioMuted.value;

    // Update Google Maps audio guidance
    GoogleMapsNavigator.setAudioGuidance(
      NavigationAudioGuidanceSettings(
        guidanceType: isAudioMuted.value
            ? NavigationAudioGuidanceType.silent
            : NavigationAudioGuidanceType.alertsAndGuidance,
      ),
    );

    AppLogger.general(
      isAudioMuted.value
          ? '🔇 Audio guidance muted'
          : '🔊 Audio guidance enabled',
    );
  }

  /// Show check-in dialog for completing a bin
  static void _showCheckInDialog(BuildContext context, WidgetRef ref, RouteBin bin) {
    final fillPercentageNotifier = ValueNotifier<int>(bin.fillPercentage);
    final isSubmittingNotifier = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Check In - Bin #${bin.binNumber}'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current fill level: ${bin.fillPercentage}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Text(
                  'New fill level: ${fillPercentageNotifier.value}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Slider(
                  value: fillPercentageNotifier.value.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${fillPercentageNotifier.value}%',
                  onChanged: (value) {
                    setState(() {
                      fillPercentageNotifier.value = value.round();
                    });
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will update the bin\'s fill level and record a check-in.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: isSubmittingNotifier.value ? null : () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isSubmittingNotifier,
            builder: (context, isSubmitting, child) {
              return ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        isSubmittingNotifier.value = true;
                        try {
                          // Complete bin via shift provider
                          await ref.read(shiftNotifierProvider.notifier).completeBin(bin.binId);

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bin completed successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          isSubmittingNotifier.value = false;
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              );
            },
          ),
        ],
      ),
    );
  }
}
