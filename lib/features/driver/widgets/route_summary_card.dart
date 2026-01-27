import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/core/services/geofence_service.dart';

class RouteSummaryCard extends StatelessWidget {
  final List<Bin> routeBins;
  final WidgetRef ref;
  final VoidCallback onClearRoute;
  final latlong.LatLng? currentLocation;

  const RouteSummaryCard({
    super.key,
    required this.routeBins,
    required this.ref,
    required this.onClearRoute,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate estimated distance (rough approximation)
    double estimatedDistance = 0;
    for (int i = 0; i < routeBins.length - 1; i++) {
      if (routeBins[i].latitude != null &&
          routeBins[i].longitude != null &&
          routeBins[i + 1].latitude != null &&
          routeBins[i + 1].longitude != null) {
        final lat1 = routeBins[i].latitude!;
        final lon1 = routeBins[i].longitude!;
        final lat2 = routeBins[i + 1].latitude!;
        final lon2 = routeBins[i + 1].longitude!;

        // Simple distance calculation (Euclidean approximation)
        // For small distances, this is reasonable
        final latDiff = (lat2 - lat1) * 111.0; // 1 degree lat ≈ 111 km
        final lonDiff = (lon2 - lon1) * 111.0 * 0.85; // Adjusted for latitude
        estimatedDistance += (latDiff * latDiff + lonDiff * lonDiff).abs();
      }
    }
    estimatedDistance = estimatedDistance.abs();

    // Estimate time (assuming 30 km/h average speed + 5 min per stop)
    final drivingTime =
        (estimatedDistance / BinConstants.averageDrivingSpeed) * 60; // minutes
    final stopTime = routeBins.length * 5; // 5 min per stop
    final totalTime = (drivingTime + stopTime).round();

    return Card(
      color: AppColors.primaryGreen,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Optimized Route',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: onClearRoute,
                  icon: const Icon(Icons.close, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RouteInfoItem(
                    icon: Icons.location_on,
                    label: 'Stops',
                    value: routeBins.length.toString(),
                  ),
                ),
                Expanded(
                  child: RouteInfoItem(
                    icon: Icons.route,
                    label: 'Distance',
                    value: GeofenceService.formatDistance(estimatedDistance * 1000),
                  ),
                ),
                Expanded(
                  child: RouteInfoItem(
                    icon: Icons.access_time,
                    label: 'Est. Time',
                    value: '$totalTime min',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (routeBins.isEmpty) return;

                  AppLogger.map('🚀 Starting Google Navigation...');

                  // Navigate to Google Navigation page
                  // Note: GoogleNavigationPage handles route setup using Google Navigation SDK
                  if (context.mounted) {
                    context.push('/navigation');
                  }
                },
                icon: const Icon(Icons.navigation),
                label: const Text('Start Navigation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RouteInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const RouteInfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
