import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/features/driver/driver_map_page.dart';
import 'package:ropacalapp/features/driver/widgets/shift_acceptance_bottom_sheet.dart';
import 'package:ropacalapp/models/shift_overview.dart';
import 'package:ropacalapp/providers/shift_provider.dart';

/// Full-page shift acceptance view shown when shift status is "ready"
/// Displays map in background with acceptance card at bottom (Uber/Lyft pattern)
class ShiftAcceptancePage extends ConsumerWidget {
  const ShiftAcceptancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftState = ref.watch(shiftNotifierProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background: Map view (still visible)
          const DriverMapPage(),

          // Dark overlay to focus attention on acceptance card
          Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),

          // Shift acceptance card at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ShiftAcceptanceBottomSheet(
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
                routeName: 'Route ${shiftState.assignedRouteId ?? ''}',
              ),
              onAccept: () async {
                AppLogger.general('🚀 SHIFT ACCEPTED - Starting shift');

                // Show loading overlay
                EasyLoading.show(
                  status: 'Starting shift...',
                  maskType: EasyLoadingMaskType.black,
                );

                try {
                  // Start the shift via HTTP
                  await ref.read(shiftNotifierProvider.notifier).startShift();

                  AppLogger.general('✅ Shift started successfully via HTTP');

                  // Hide loading
                  await EasyLoading.dismiss();

                  // Navigate to navigation page after successful HTTP response
                  // No race condition since WebSocket shift_update is disabled
                  if (context.mounted) {
                    AppLogger.general('🧭 Navigating to /navigation...');
                    context.push('/navigation');
                  }
                } catch (e) {
                  AppLogger.general('❌ SHIFT START ERROR: $e');

                  // Hide loading
                  await EasyLoading.dismiss();

                  // Show error
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to start shift: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              onDecline: () {
                AppLogger.general('❌ SHIFT DECLINED');

                // TODO: Implement backend API call to decline shift
                // For now, just log the decline. The shift will timeout
                // on the backend after a certain period, and the status
                // will automatically change to inactive.

                // Show confirmation message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shift declined'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate total distance from route bins
  double _calculateTotalDistance(List<dynamic> routeBins) {
    if (routeBins.isEmpty) return 0.0;

    double totalDistance = 0.0;

    for (int i = 0; i < routeBins.length - 1; i++) {
      final current = routeBins[i];
      final next = routeBins[i + 1];

      final currentLat = current.latitude;
      final currentLng = current.longitude;
      final nextLat = next.latitude;
      final nextLng = next.longitude;

      final distanceInMeters = Geolocator.distanceBetween(
        currentLat,
        currentLng,
        nextLat,
        nextLng,
      );

      totalDistance += distanceInMeters;
    }

    return totalDistance / 1000; // Convert to kilometers
  }
}
