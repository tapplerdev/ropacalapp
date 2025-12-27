import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/enums/user_role.dart';
import 'package:ropacalapp/features/auth/splash_screen.dart';
import 'package:ropacalapp/features/auth/login_page.dart';
import 'package:ropacalapp/features/driver/driver_home_scaffold.dart';
import 'package:ropacalapp/features/driver/bin_detail_page.dart';
import 'package:ropacalapp/features/driver/google_navigation_page.dart';
import 'package:ropacalapp/features/driver/shift_demo_page.dart';
import 'package:ropacalapp/features/driver/routes_list_page.dart';
import 'package:ropacalapp/features/driver/route_detail_page.dart';
import 'package:ropacalapp/features/manager/active_drivers_list_page.dart';
import 'package:ropacalapp/features/manager/driver_shift_detail_page.dart';
import 'package:ropacalapp/features/manager/driver_detail_page.dart';
import 'package:ropacalapp/providers/auth_provider.dart';

// Placeholder page for admin dashboard (will be implemented in Phase 4)
class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Admin Dashboard',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming in Phase 4',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Features:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('• View all bins on map'),
                    const SizedBox(height: 8),
                    const Text('• Analytics & performance metrics'),
                    const SizedBox(height: 8),
                    const Text('• Add/edit/delete bin information'),
                    const SizedBox(height: 8),
                    const Text('• Manage user accounts'),
                    const SizedBox(height: 8),
                    const Text('• Alerts for missing bins'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Create router provider
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Splash screen - shown on app startup
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authNotifierProvider);

              return authState.when(
                data: (user) {
                  if (user == null) {
                    return const LoginPage();
                  }

                  // DriverHomeScaffold handles both driver and admin roles
                  // (shows different tabs based on role)
                  return const DriverHomeScaffold();
                },
                loading: () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 48),
                        const SizedBox(height: 16),
                        Text('Error: $error'),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/driver',
        name: 'driver',
        builder: (context, state) => const DriverHomeScaffold(),
      ),
      GoRoute(
        path: '/bin/:id',
        name: 'bin-detail',
        builder: (context, state) {
          final binId = state.pathParameters['id']!;
          return BinDetailPage(binId: binId);
        },
      ),
      GoRoute(
        path: '/navigation',
        name: 'navigation',
        builder: (context, state) => const GoogleNavigationPage(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/routes',
        name: 'routes',
        builder: (context, state) => const RoutesListPage(),
      ),
      GoRoute(
        path: '/routes/:shiftId',
        name: 'route-detail',
        builder: (context, state) {
          final shiftId = state.pathParameters['shiftId']!;
          return RouteDetailPage(shiftId: shiftId);
        },
      ),
      GoRoute(
        path: '/manager/active-drivers',
        name: 'active-drivers',
        builder: (context, state) => const ActiveDriversListPage(),
      ),
      GoRoute(
        path: '/manager/drivers/:driverId',
        name: 'driver-detail',
        builder: (context, state) {
          final driverId = state.pathParameters['driverId']!;
          return DriverDetailPage(driverId: driverId);
        },
      ),
      GoRoute(
        path: '/shift-demo',
        name: 'shift-demo',
        builder: (context, state) => const ShiftDemoPage(),
      ),
    ],
  );
});
