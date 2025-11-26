import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/features/driver/driver_map_page.dart';
import 'package:ropacalapp/features/driver/driver_map_page_v2.dart';

/// Wrapper page that allows switching between V1 (current) and V2 (new) designs
class DriverMapWrapper extends HookWidget {
  const DriverMapWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final useV2Design = useState(false);

    return Stack(
      children: [
        // Render selected version
        useV2Design.value ? const DriverMapPageV2() : const DriverMapPage(),

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
