import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/features/driver/driver_map_page.dart';
import 'package:ropacalapp/features/driver/google_navigation_page.dart';
import 'package:ropacalapp/features/driver/widgets/dialogs/shift_summary_dialog.dart';
import 'package:ropacalapp/features/driver/widgets/dialogs/shift_cancellation_dialog.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/models/shift_state.dart';

/// Wrapper that automatically switches between map states based on shift status
/// - ready: Shows DriverMapPage with modal overlay (Uber/Lyft pattern)
/// - active: Shows GoogleNavigationPage (turn-by-turn navigation)
/// - inactive: Shows DriverMapPage (regular map)
class DriverMapWrapper extends HookConsumerWidget {
  const DriverMapWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftState = ref.watch(shiftNotifierProvider);
    final previousShift = usePrevious(shiftState);

    // Detect shift end and show dialog BEFORE switching pages
    useEffect(() {
      if (previousShift != null &&
          previousShift.status == ShiftStatus.active &&
          (shiftState.status == ShiftStatus.ended ||
           shiftState.status == ShiftStatus.cancelled ||
           shiftState.status == ShiftStatus.inactive)) {

        AppLogger.general('🛑 Shift ended - showing dialog from DriverMapWrapper');

        // Show dialog after current frame completes
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;

          if (shiftState.status == ShiftStatus.cancelled) {
            await showShiftCancellationDialog(context, previousShift);
          } else if (shiftState.status == ShiftStatus.inactive) {
            // Shift was deleted - no dialog, just log
            AppLogger.general('📤 Shift deleted - no dialog shown');
          } else {
            // Normal end - show summary dialog
            await showShiftSummaryDialog(context, previousShift);
          }
        });
      }
      return null;
    }, [shiftState.status]);

    // DIAGNOSTIC LOGGING - Track every rebuild
    AppLogger.general(
      '[DIAGNOSTIC] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );
    AppLogger.general(
      '[DIAGNOSTIC] 🗺️ DriverMapWrapper.build() called',
    );
    AppLogger.general(
      '[DIAGNOSTIC]    Status: ${shiftState.status}',
    );
    AppLogger.general(
      '[DIAGNOSTIC]    RouteID: ${shiftState.assignedRouteId}',
    );
    AppLogger.general(
      '[DIAGNOSTIC]    RouteBins: ${shiftState.routeBins.length}',
    );
    AppLogger.general(
      '[DIAGNOSTIC]    ShiftID: ${shiftState.shiftId}',
    );

    // When shift is active, automatically switch to navigation page
    // The modal overlay in DriverMapPage will handle shift acceptance (status: ready)
    // When driver accepts, status changes to active, triggering this auto-switch
    if (shiftState.status == ShiftStatus.active) {
      AppLogger.general(
        '[DIAGNOSTIC] ✅ Condition met: status=active',
      );
      AppLogger.general(
        '[DIAGNOSTIC] 🚀 SWITCHING TO: GoogleNavigationPage',
      );
      AppLogger.general(
        '[DIAGNOSTIC]    RouteBins: ${shiftState.routeBins.length} (for reference)',
      );
      AppLogger.general(
        '[DIAGNOSTIC] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      return const GoogleNavigationPage();
    }

    AppLogger.general(
      '[DIAGNOSTIC] ℹ️  Condition NOT met for navigation (status=${shiftState.status})',
    );
    AppLogger.general(
      '[DIAGNOSTIC] 📍 SHOWING: DriverMapPage (regular map)',
    );
    AppLogger.general(
      '[DIAGNOSTIC] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );

    // Default: Show regular map with overlays
    // When status is 'ready', DriverMapPage shows modal overlay for shift acceptance
    // When status is 'inactive', DriverMapPage shows regular map
    return Stack(
      children: [
        // Regular map view (shows modal overlay when shift is ready)
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
        //           color: Colors.black.withValues(alpha: 0.1),
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
        //                 color: AppColors.primaryGreen,
        //                 size: 20,
        //               ),
        //               const SizedBox(width: 8),
        //               Text(
        //                 useV2Design.value ? 'V2' : 'V1',
        //                 style: const TextStyle(
        //                   fontWeight: FontWeight.bold,
        //                   color: AppColors.primaryGreen,
        //                   fontSize: 14,
        //                 ),
        //               ),
        //               const SizedBox(width: 4),
        //               const Icon(
        //                 Icons.swap_horiz,
        //                 color: AppColors.primaryGreen,
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
