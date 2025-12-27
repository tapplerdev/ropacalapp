import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/responsive.dart';
import 'package:ropacalapp/features/driver/notifications_page.dart';
import 'package:ropacalapp/models/bin.dart';

/// Circular notification button with badge showing high-fill bin count
/// Positioned at top-left of map, opens notifications page on tap
class MapNotificationButton extends ConsumerWidget {
  const MapNotificationButton({
    super.key,
    required this.binsState,
  });

  final AsyncValue<List<Bin>> binsState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
            );
          },
          customBorder: const CircleBorder(),
          child: Padding(
            padding: Responsive.padding(
              context,
              mobile: 10.0,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primaryGreen,
                  size: Responsive.iconSize(
                    context,
                    mobile: 22,
                  ),
                ),
                // Notification badge
                binsState.whenOrNull(
                      data: (bins) {
                        final highFillCount = bins
                            .where(
                              (b) =>
                                  (b.fillPercentage ?? 0) >
                                  BinConstants.criticalFillThreshold,
                            )
                            .length;
                        if (highFillCount == 0) {
                          return const SizedBox.shrink();
                        }

                        return Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: Responsive.padding(
                              context,
                              mobile: 3,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.alertRed,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: Responsive.spacing(
                                context,
                                mobile: 16,
                              ),
                              minHeight: Responsive.spacing(
                                context,
                                mobile: 16,
                              ),
                            ),
                            child: Text(
                              highFillCount > 9 ? '9+' : '$highFillCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Responsive.fontSize(
                                  context,
                                  mobile: 9,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ) ??
                    const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
