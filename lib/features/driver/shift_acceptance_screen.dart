import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
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
    final markers = useState<Set<Marker>>({});
    final polylines = useState<Set<Polyline>>({});

    // Initialize map markers and polyline
    useEffect(() {
      Future<void> initializeMapData() async {
        final binMarkers = <Marker>{};
        final routePoints = <LatLng>[];

        // Create markers for each bin
        for (var i = 0; i < shiftOverview.routeBins.length; i++) {
          final bin = shiftOverview.routeBins[i];
          final position = LatLng(
            latitude: bin.latitude,
            longitude: bin.longitude,
          );

          routePoints.add(position);

          // Determine marker color based on fill percentage
          BitmapDescriptor markerIcon;
          if (bin.fillPercentage > 80) {
            markerIcon = BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            );
          } else if (bin.fillPercentage > 50) {
            markerIcon = BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            );
          } else {
            markerIcon = BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            );
          }

          binMarkers.add(
            Marker(
              markerId: MarkerId('bin_${bin.id}'),
              position: position,
              icon: markerIcon,
              infoWindow: InfoWindow(
                title: bin.currentStreet,
                snippet: '${bin.fillPercentage}% full',
              ),
            ),
          );
        }

        markers.value = binMarkers;

        // Create polyline connecting all bins
        if (routePoints.isNotEmpty) {
          polylines.value = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: routePoints,
              color: AppColors.primaryBlue,
              width: 4,
              patterns: [
                PatternItem.dash(20),
                PatternItem.gap(10),
              ],
            ),
          };
        }

        // Fit camera to show all bins
        if (mapController.value != null && routePoints.length >= 2) {
          try {
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

            // Add padding to bounds
            await mapController.value!.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 80),
            );
          } catch (e) {
            // Ignore camera errors
          }
        }
      }

      initializeMapData();
      return null;
    }, []);

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
            initialMarkers: markers.value,
            initialPolylines: polylines.value,
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
