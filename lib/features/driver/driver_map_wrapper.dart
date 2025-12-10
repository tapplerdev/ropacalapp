import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/features/driver/driver_map_page.dart';
import 'package:ropacalapp/features/driver/google_navigation_page.dart';
import 'package:ropacalapp/features/driver/shift_acceptance_page.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/models/shift_state.dart';

/// Wrapper that automatically switches between map states based on shift status
/// - ready: Shows shift acceptance page (Uber/Lyft pattern)
/// - active: Shows Google Navigation
/// - inactive: Shows regular map
class DriverMapWrapper extends ConsumerWidget {
  const DriverMapWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftState = ref.watch(shiftNotifierProvider);

    // Priority 1: Shift ready → Show acceptance page
    if (shiftState.status == ShiftStatus.ready) {
      return const ShiftAcceptancePage();
    }

    // Priority 2: Shift active → Show navigation page
    if (shiftState.status == ShiftStatus.active &&
        shiftState.routeBins.isNotEmpty) {
      return const GoogleNavigationPage();
    }

    // Priority 3: Default → Show regular map
    return Stack(
      children: [
        // Regular map view when no active shift
        const DriverMapPage(),

        // COMMENTED OUT: Floating toggle button in top-left
        // Positioned(
        //   top: MediaQuery.of(context).padding.top + 16,
        //   left: 16,
        //   child: Container(
        //     decoration: BoxDecoration(
        //       color: Colors.white,
        //       borderRadius: BorderRadius.circular(12),
        //       boxShadow: [
        //         BoxShadow(
        //           color: Colors.black.withOpacity(0.1),
        //           blurRadius: 10,
        //           offset: const Offset(0, 2),
        //         ),
        //       ],
        //     ),
        //     child: Material(
        //       color: Colors.transparent,
        //       child: InkWell(
        //         onTap: () {
        //           useV2Design.value = !useV2Design.value;
        //
        //           // Show snackbar to indicate switch
        //           ScaffoldMessenger.of(context).showSnackBar(
        //             SnackBar(
        //               content: Text(
        //                 useV2Design.value
        //                     ? '✨ Switched to V2 Design (New)'
        //                     : '📱 Switched to V1 Design (Current)',
        //               ),
        //               duration: const Duration(seconds: 2),
        //               backgroundColor: AppColors.primaryBlue,
        //               behavior: SnackBarBehavior.floating,
        //             ),
        //           );
        //         },
        //         borderRadius: BorderRadius.circular(12),
        //         child: Padding(
        //           padding: const EdgeInsets.symmetric(
        //             horizontal: 16,
        //             vertical: 12,
        //           ),
        //           child: Row(
        //             mainAxisSize: MainAxisSize.min,
        //             children: [
        //               Icon(
        //                 useV2Design.value
        //                     ? Icons.auto_awesome
        //                     : Icons.phonelink_setup,
        //                 color: AppColors.primaryBlue,
        //                 size: 20,
        //               ),
        //               const SizedBox(width: 8),
        //               Text(
        //                 useV2Design.value ? 'V2' : 'V1',
        //                 style: const TextStyle(
        //                   fontWeight: FontWeight.bold,
        //                   color: AppColors.primaryBlue,
        //                   fontSize: 14,
        //                 ),
        //               ),
        //               const SizedBox(width: 4),
        //               const Icon(
        //                 Icons.swap_horiz,
        //                 color: AppColors.primaryBlue,
        //                 size: 16,
        //               ),
        //             ],
        //           ),
        //         ),
        //       ),
        //     ),
        //   ),
        // ),

        // COMMENTED OUT: Info chip showing which version is active
        // Positioned(
        //   bottom: MediaQuery.of(context).padding.bottom + 100,
        //   left: 16,
        //   child: AnimatedOpacity(
        //     opacity: 1.0,
        //     duration: const Duration(milliseconds: 300),
        //     child: Container(
        //       padding: const EdgeInsets.symmetric(
        //         horizontal: 12,
        //         vertical: 6,
        //       ),
        //       decoration: BoxDecoration(
        //         color: useV2Design.value
        //             ? AppColors.successGreen
        //             : Colors.grey.shade700,
        //         borderRadius: BorderRadius.circular(20),
        //       ),
        //       child: Row(
        //         mainAxisSize: MainAxisSize.min,
        //         children: [
        //           Icon(
        //             useV2Design.value ? Icons.stars : Icons.check_circle,
        //             color: Colors.white,
        //             size: 14,
        //           ),
        //           const SizedBox(width: 6),
        //           Text(
        //             useV2Design.value
        //                 ? 'New Design - DoorDash Style'
        //                 : 'Current Design',
        //             style: const TextStyle(
        //               color: Colors.white,
        //               fontSize: 12,
        //               fontWeight: FontWeight.w600,
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
