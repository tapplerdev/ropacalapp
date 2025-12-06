import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/services/google_navigation_marker_service.dart';
import 'package:ropacalapp/features/driver/widgets/shift_acceptance_bottom_sheet.dart';
import 'package:ropacalapp/models/shift_overview.dart';

/// Lyft-style full-screen shift acceptance view
/// Shows route on map with draggable bottom sheet
class ShiftAcceptanceScreen extends HookConsumerWidget {
  const ShiftAcceptanceScreen({
    super.key,
    required this.shiftOverview,
    required this.onAccept,
    required this.onDecline,
  });

  final ShiftOverview shiftOverview;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapController = useState<GoogleMapViewController?>(null);

    // Initialize map markers and polyline when controller is available
    useEffect(() {
      Future<void> initializeMapData() async {
        if (mapController.value == null) return;

        try {
          // Create custom markers for each bin
          final markers = <MarkerOptions>[];
          for (var i = 0; i < shiftOverview.routeBins.length; i++) {
            final bin = shiftOverview.routeBins[i];

            // Use GoogleNavigationMarkerService to create custom icon
            final icon = await GoogleNavigationMarkerService.createBinMarkerIcon(
              i + 1, // bin number
              bin.fillPercentage,
            );

            final markerOptions = MarkerOptions(
              position: LatLng(
                latitude: bin.latitude,
                longitude: bin.longitude,
              ),
              icon: icon,
              anchor: const MarkerAnchor(u: 0.5, v: 0.5),
              zIndex: 100.0 + i.toDouble(),
              consumeTapEvents: false,
            );

            markers.add(markerOptions);
          }

          // Add markers to map
          if (markers.isNotEmpty) {
            await mapController.value!.addMarkers(markers);
          }

          // Create polyline connecting all bins
          if (shiftOverview.routeBins.length >= 2) {
            final points = shiftOverview.routeBins.map((bin) {
              return LatLng(
                latitude: bin.latitude,
                longitude: bin.longitude,
              );
            }).toList();

            final polylineOptions = PolylineOptions(
              points: points,
              strokeWidth: 4,
              strokeColor: AppColors.primaryBlue,
              geodesic: true,
              zIndex: 50,
              clickable: false,
            );

            await mapController.value!.addPolylines([polylineOptions]);
          }

          // Fit camera to show all bins
          if (shiftOverview.routeBins.length >= 2) {
            try {
              final routePoints = shiftOverview.routeBins.map((bin) {
                return LatLng(
                  latitude: bin.latitude,
                  longitude: bin.longitude,
                );
              }).toList();

              // Calculate bounds
              double minLat = routePoints.first.latitude;
              double maxLat = routePoints.first.latitude;
              double minLng = routePoints.first.longitude;
              double maxLng = routePoints.first.longitude;

              for (final point in routePoints) {
                if (point.latitude < minLat) minLat = point.latitude;
                if (point.latitude > maxLat) maxLat = point.latitude;
                if (point.longitude < minLng) minLng = point.longitude;
                if (point.longitude > maxLng) maxLng = point.longitude;
              }

              final bounds = LatLngBounds(
                southwest: LatLng(latitude: minLat, longitude: minLng),
                northeast: LatLng(latitude: maxLat, longitude: maxLng),
              );

              // Animate camera to fit bounds with padding
              await mapController.value!.animateCamera(
                CameraUpdate.newLatLngBounds(bounds),
              );
            } catch (e) {
              // Ignore camera errors
            }
          }
        } catch (e) {
          // Ignore initialization errors
        }
      }

      // Run initialization when controller becomes available
      if (mapController.value != null) {
        initializeMapData();
      }

      return null;
    }, [mapController.value]);

    return Scaffold(
      body: Stack(
        children: [
          // Google Maps View (full screen)
          GoogleMapsMapView(
            initialCameraPosition: CameraPosition(
              target: shiftOverview.routeBins.isNotEmpty
                  ? LatLng(
                      latitude: shiftOverview.routeBins.first.latitude,
                      longitude: shiftOverview.routeBins.first.longitude,
                    )
                  : const LatLng(
                      latitude: 37.7749,
                      longitude: -122.4194,
                    ), // Default to SF
              zoom: 12,
            ),
            onViewCreated: (controller) {
              mapController.value = controller;
            },
          ),

          // Close button (top-left)
          Positioned(
            top: 50,
            left: 16,
            child: SafeArea(
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
                child: IconButton(
                  onPressed: onDecline,
                  icon: const Icon(Icons.close),
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),

          // Bottom sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ShiftAcceptanceBottomSheet(
              shiftOverview: shiftOverview,
              onAccept: onAccept,
              onDecline: onDecline,
            ),
          ),
        ],
      ),
    );
  }
}
