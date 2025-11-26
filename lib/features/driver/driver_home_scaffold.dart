import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ropacalapp/features/driver/driver_map_wrapper.dart';
import 'package:ropacalapp/features/driver/bins_list_page.dart';
import 'package:ropacalapp/features/driver/account_page.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';

class DriverHomeScaffold extends HookConsumerWidget {
  const DriverHomeScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = useState(0);

    final pages = [
      const DriverMapWrapper(),
      const BinsListPage(),
      const AccountPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex.value, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex.value,
        onDestinationSelected: (index) {
          currentIndex.value = index;
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primaryBlue.withOpacity(0.1),
        destinations: [
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
        ],
      ),
    );
  }
}
