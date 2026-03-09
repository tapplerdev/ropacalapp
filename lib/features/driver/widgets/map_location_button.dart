import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/features/driver/widgets/circular_map_button.dart';

/// Circular button that centers the map on user's current location
/// Styled identically to the manager map page recenter button
class MapLocationButton extends StatelessWidget {
  const MapLocationButton({
    super.key,
    required this.mapController,
  });

  final GoogleMapViewController? mapController;

  @override
  Widget build(BuildContext context) {
    return CircularMapButton(
      icon: Icons.my_location,
      backgroundColor: AppColors.primaryGreen,
      iconColor: Colors.white,
      onTap: () async {
        if (mapController == null) {
          AppLogger.map('⚠️  Map controller not ready');
          return;
        }

        try {
          final location = await mapController!.getMyLocation();
          if (location != null) {
            await mapController!.animateCamera(
              CameraUpdate.newLatLng(location),
            );
            AppLogger.map('📍 Centered on user location');
          } else {
            AppLogger.map('⚠️  Location not available yet');
          }
        } on PlatformException catch (e) {
          if (e.code == 'viewNotFound') {
            AppLogger.map('⚠️  Map view not ready yet - please wait a moment');
          } else {
            AppLogger.map('❌ Error getting location: ${e.code} - ${e.message}');
          }
        } catch (e) {
          AppLogger.map('❌ Unexpected error getting location: $e');
        }
      },
    );
  }
}
