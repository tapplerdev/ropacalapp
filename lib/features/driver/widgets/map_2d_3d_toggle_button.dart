import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/utils/responsive.dart';
import 'package:ropacalapp/models/simulation_state.dart';
import 'package:ropacalapp/providers/simulation_provider.dart';

/// Circular button that toggles between 2D (map view) and 3D (navigation view)
/// Flips compass icon to indicate current mode
/// Updates camera tilt, bearing, and zoom when toggled
class Map2D3DToggleButton extends ConsumerWidget {
  const Map2D3DToggleButton({
    super.key,
    required this.simulationState,
    required this.locationState,
    required this.mapController,
  });

  final SimulationState simulationState;
  final AsyncValue<Position?> locationState;
  final GoogleMapViewController? mapController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(simulationNotifierProvider.notifier).toggleNavigationMode();

            // Immediately update camera to reflect new mode
            final location = simulationState.simulatedPosition ??
                (locationState.value != null
                    ? LatLng(
                        latitude: locationState.value!.latitude,
                        longitude: locationState.value!.longitude,
                      )
                    : null);

            if (location != null && mapController != null) {
              try {
                // Toggle between 2D and 3D
                final willBe3D =
                    !simulationState.isNavigationMode; // It will be toggled

                mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: location,
                      zoom: willBe3D ? BinConstants.navigationZoom : 15.0,
                      bearing: willBe3D
                          ? (simulationState.smoothedBearing ??
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
              scaleX: simulationState.isNavigationMode ? -1 : 1,
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
    );
  }
}
