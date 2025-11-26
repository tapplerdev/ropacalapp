import 'package:flutter/material.dart';

/// Custom blue dot overlay that appears at screen center in 3D navigation mode
/// Represents current user position when camera is locked to location
class NavigationBlueDotOverlay extends StatelessWidget {
  const NavigationBlueDotOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IgnorePointer(
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
