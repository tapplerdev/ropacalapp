import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ropacalapp/features/driver/driver_map_wrapper.dart';
import 'package:ropacalapp/features/driver/bins_list_page.dart';
import 'package:ropacalapp/features/driver/shifts_page.dart';
import 'package:ropacalapp/features/driver/account_page.dart';
import 'package:ropacalapp/features/manager/manager_map_page.dart';
import 'package:ropacalapp/features/manager/manager_operations_tab.dart';
import 'package:ropacalapp/features/manager/manager_shifts_tab.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/providers/focused_driver_provider.dart';
import 'package:ropacalapp/core/enums/user_role.dart';

class DriverHomeScaffold extends HookConsumerWidget {
  const DriverHomeScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = useState(0);
    final userAsync = ref.watch(authNotifierProvider);
    final focusedDriverState = ref.watch(focusedDriverProvider);

    // Auto-switch to map tab when a driver is focused or followed
    useEffect(() {
      if (focusedDriverState.driverId != null) {
        // Switch to map tab (index 0)
        currentIndex.value = 0;
      }
      return null;
    }, [focusedDriverState.driverId]);

    return userAsync.when(
      data: (user) {
        final isManager = user?.role == UserRole.admin;

        // Build pages based on role
        // Driver: DriverMapWrapper auto-switches between DriverMapPage and GoogleNavigationPage
        // Manager: Map-first design with Operations, Shifts, Account
        final pages = isManager
            ? [
                const ManagerMapPage(), // Manager: Live ops center with map
                const ManagerOperationsTab(), // Manager: Drivers, bins, locations, requests
                const ManagerShiftsTab(), // Manager: Today's shifts and operations
                const AccountPage(), // Manager: Profile and settings
              ]
            : [
                const DriverMapWrapper(), // Driver: auto-switches to navigation when shift active
                const ShiftsPage(), // Driver sees active, upcoming, and past shifts
                const AccountPage(),
              ];

        // Hybrid approach: Map page always mounted (Offstage), other tabs use AnimatedSwitcher
        final bodyWidget = Stack(
          children: [
            // Map page ALWAYS mounted (hidden when not active)
            // This ensures WebSocket updates continue and state is preserved
            Offstage(
              offstage: currentIndex.value != 0,
              child: pages[0], // ManagerMapPage or DriverMapWrapper stays alive
            ),

            // AnimatedSwitcher ALWAYS in tree (shows empty when on map, animates when switching between other tabs)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.02),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: currentIndex.value > 0
                  ? KeyedSubtree(
                      key: ValueKey<int>(currentIndex.value),
                      child: pages[currentIndex.value],
                    )
                  : const SizedBox.shrink(
                      key: ValueKey<int>(0),
                    ), // Empty widget when showing map
            ),
          ],
        );

        final destinations = isManager
            ? [
                const NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Map',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Operations',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.event_note_outlined),
                  selectedIcon: Icon(Icons.event_note),
                  label: 'Shifts',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Account',
                ),
              ]
            : [
                const NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Map',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.work_history_outlined),
                  selectedIcon: Icon(Icons.work_history),
                  label: 'Shifts',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Account',
                ),
              ];

        return Scaffold(
          body: bodyWidget,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade300,
                  width: 0.5,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: currentIndex.value,
              onDestinationSelected: (index) {
                currentIndex.value = index;
              },
              backgroundColor: Colors.white,
              indicatorColor: AppColors.primaryGreen.withValues(alpha: 0.1),
              destinations: destinations,
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error loading user: $error')),
      ),
    );
  }
}
