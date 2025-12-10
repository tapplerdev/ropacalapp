import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ropacalapp/features/driver/driver_map_wrapper.dart';
import 'package:ropacalapp/features/driver/bins_list_page.dart';
import 'package:ropacalapp/features/driver/account_page.dart';
import 'package:ropacalapp/features/manager/manager_map_page.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
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

        final pages = isManager
            ? [
                const ManagerMapPage(), // Manager sees fleet map
                const BinsListPage(), // Manager sees all bins
                const AccountPage(),
              ]
            : [
                const DriverMapWrapper(), // Driver sees route map
                const BinsListPage(),
                const AccountPage(),
              ];

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
              ];

        return Scaffold(
          body: IndexedStack(index: currentIndex.value, children: pages),
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
