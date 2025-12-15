import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ropacalapp/features/driver/driver_map_wrapper.dart';
import 'package:ropacalapp/features/driver/bins_list_page.dart';
import 'package:ropacalapp/features/driver/routes_list_page.dart';
import 'package:ropacalapp/features/driver/account_page.dart';
import 'package:ropacalapp/features/driver/google_navigation_page.dart';
import 'package:ropacalapp/features/manager/manager_map_page.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/core/enums/user_role.dart';

class DriverHomeScaffold extends HookConsumerWidget {
  const DriverHomeScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = useState(0);
    final userAsync = ref.watch(authNotifierProvider);

    return userAsync.when(
      data: (user) {
        final isManager = user?.role == UserRole.admin;

        // Determine body widget based on shift status (for drivers only)
        Widget bodyWidget;

        if (!isManager) {
          final shiftState = ref.watch(shiftNotifierProvider);
          final locationState = ref.watch(currentLocationProvider);

          AppLogger.general(
            '🏠 DriverHomeScaffold: Checking navigation state - '
            'Status: ${shiftState.status}, '
            'Bins: ${shiftState.routeBins.length}, '
            'Location: ${locationState.hasValue}',
          );

          // Show navigation page when shift is active
          if (shiftState.status == ShiftStatus.active &&
              shiftState.routeBins.isNotEmpty &&
              locationState.hasValue) {
            AppLogger.general('✅ DriverHomeScaffold: Showing GoogleNavigationPage with bottom tabs');
            bodyWidget = const GoogleNavigationPage();
          }
          // Show loading screen if shift is active but GPS not ready
          else if (shiftState.status == ShiftStatus.active &&
              shiftState.routeBins.isNotEmpty &&
              !locationState.hasValue) {
            AppLogger.general('⏳ DriverHomeScaffold: Waiting for location...');
            bodyWidget = const Center(
              child: CircularProgressIndicator(),
            );
          }
          // Default: Show regular tabs
          else {
            bodyWidget = IndexedStack(
              index: currentIndex.value,
              children: const [
                DriverMapWrapper(), // Driver sees route map
                RoutesListPage(), // Driver sees shift history
                AccountPage(),
              ],
            );
          }
        } else {
          // Manager: Always use IndexedStack
          bodyWidget = IndexedStack(
            index: currentIndex.value,
            children: const [
              ManagerMapPage(), // Manager sees fleet map
              BinsListPage(), // Manager sees all bins
              AccountPage(),
            ],
          );
        }

        final destinations = isManager
            ? [
                const NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Fleet',
                ),
                NavigationDestination(
                  icon: SvgPicture.asset(
                    'assets/icons/bin-trash.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      Colors.grey.shade600,
                      BlendMode.srcIn,
                    ),
                  ),
                  selectedIcon: SvgPicture.asset(
                    'assets/icons/bin-trash.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.onSurface,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'Bins',
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
                  icon: Icon(Icons.route_outlined),
                  selectedIcon: Icon(Icons.route),
                  label: 'Routes',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Account',
                ),
              ];

        return Scaffold(
          body: bodyWidget,
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex.value,
            onDestinationSelected: (index) {
              currentIndex.value = index;
            },
            backgroundColor: Colors.white,
            indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.1),
            destinations: destinations,
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
