import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/navigation_state.dart';

/// Floating action buttons for navigation controls
class NavigationActionButtons extends StatelessWidget {
  final bool isNavigationMode;
  final bool isSimulating;
  final Position? currentLocation;
  final NavigationState? navigationState;
  final double userZoomLevel;
  final GoogleMapController? mapController;
  final VoidCallback onToggleNavigationMode;
  final VoidCallback onToggleSimulation;
  final VoidCallback onRecenter;

  const NavigationActionButtons({
    super.key,
    required this.isNavigationMode,
    required this.isSimulating,
    required this.currentLocation,
    required this.navigationState,
    required this.userZoomLevel,
    required this.mapController,
    required this.onToggleNavigationMode,
    required this.onToggleSimulation,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Navigation mode toggle - 3D vs 2D
        Positioned(
          bottom: 340,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            heroTag: 'navigation_mode',
            onPressed: onToggleNavigationMode,
            tooltip: isNavigationMode ? '3D Navigation Mode' : '2D Map Mode',
            child: Transform.scale(
              scaleX: isNavigationMode ? -1 : 1,
              child: const Icon(Icons.explore, size: 20),
            ),
          ),
        ),

        // Simulate route button
        Positioned(
          bottom: 460,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'simulate_route',
            backgroundColor: isSimulating ? Colors.red : AppColors.primaryBlue,
            onPressed: onToggleSimulation,
            child: Icon(
              isSimulating ? Icons.stop : Icons.play_arrow,
              color: Colors.white,
            ),
          ),
        ),

        // Recenter button
        Positioned(
          bottom: 280,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            heroTag: 'recenter',
            onPressed: () => _handleRecenter(),
            child: const Icon(Icons.my_location, size: 20),
          ),
        ),
      ],
    );
  }

  void _handleRecenter() async {
    if (currentLocation != null && mapController != null) {
      final zoom = isNavigationMode
          ? BinConstants.navigationZoom
          : userZoomLevel;
      final tilt = isNavigationMode
          ? BinConstants.navigationTilt
          : BinConstants.mapModeTilt;
      final bearing = isNavigationMode
          ? (navigationState?.currentBearing ?? 0.0)
          : 0.0;

      AppLogger.map('🎯 Recenter button clicked');
      AppLogger.map(
        '   Mode: ${isNavigationMode ? "NAVIGATION (3D)" : "MAP (2D)"}',
      );
      AppLogger.map('   Zoom: $zoom');
      AppLogger.map('   Tilt: $tilt°');
      AppLogger.map('   Bearing: ${bearing.toStringAsFixed(1)}°');
      AppLogger.map(
        '   Target: ${currentLocation!.latitude}, ${currentLocation!.longitude}',
      );

      try {
        await mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                currentLocation!.latitude,
                currentLocation!.longitude,
              ),
              zoom: zoom,
              bearing: bearing,
              tilt: tilt,
            ),
          ),
        );
        AppLogger.map('✅ Recenter completed');
      } catch (e) {
        // Controller was disposed - ignore error
        AppLogger.map(
          'Recenter skipped - controller disposed',
          level: AppLogger.debug,
        );
      }
    }
  }
}
