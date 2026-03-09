import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/features/driver/notifications_page.dart';
import 'package:ropacalapp/features/driver/widgets/circular_map_button.dart';
import 'package:ropacalapp/models/bin.dart';

/// Circular notification button with badge showing high-fill bin count
/// Styled identically to the manager map page notification button
class MapNotificationButton extends ConsumerWidget {
  const MapNotificationButton({
    super.key,
    required this.binsState,
  });

  final AsyncValue<List<Bin>> binsState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircularMapButton(
          icon: Icons.notifications,
          backgroundColor: AppColors.primaryGreen,
          iconColor: Colors.white,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
            );
          },
        ),
        // Badge indicator
        if (binsState.valueOrNull != null)
          Builder(builder: (context) {
            final count = binsState.valueOrNull!
                .where(
                  (b) =>
                      (b.fillPercentage ?? 0) >
                      BinConstants.criticalFillThreshold,
                )
                .length;
            if (count == 0) return const SizedBox.shrink();
            return Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.alertRed,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }),
      ],
    );
  }
}
