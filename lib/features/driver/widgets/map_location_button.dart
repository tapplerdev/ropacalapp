import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/utils/responsive.dart';

/// Circular button that centers the map on user's current location
/// Shows my_location icon, positioned above route summary card
class MapLocationButton extends StatelessWidget {
  const MapLocationButton({
    super.key,
    required this.mapController,
  });

  final GoogleMapViewController? mapController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (mapController != null) {
              final location = await mapController!.getMyLocation();
              if (location != null) {
                await mapController!.animateCamera(
                  CameraUpdate.newLatLng(location),
                );
                AppLogger.map('📍 Centered on user location');
              }
            }
          },
          customBorder: const CircleBorder(),
          child: Container(
            width: Responsive.iconSize(
              context,
              mobile: 42,
            ),
            height: Responsive.iconSize(
              context,
              mobile: 42,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.my_location,
              color: AppColors.primaryBlue,
              size: Responsive.iconSize(
                context,
                mobile: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
