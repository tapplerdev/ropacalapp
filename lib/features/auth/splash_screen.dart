import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

/// Splash screen shown on app startup
///
/// Responsibilities:
/// - Display app logo and loading indicator
/// - Check authentication status
/// - If authenticated: Pre-load shift data and navigate to home
/// - If not authenticated: Navigate to login
class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.general('🔷 SPLASH SCREEN: Building...');
    final authState = ref.watch(authNotifierProvider);
    final hasNavigated = useState(false);

    // Pre-fetch location early for faster navigation startup
    useEffect(() {
      AppLogger.general('📍 SPLASH: Pre-fetching location for faster navigation...');
      // This triggers the location provider to start acquiring GPS fix
      ref.read(currentLocationProvider);
      return null;
    }, []);

    // Pre-load shift data and navigate to home
    Future<void> preloadAndNavigate() async {
      if (!context.mounted || hasNavigated.value) return;
      hasNavigated.value = true;

      // 🆕 Restore active shift from Go backend (SQLite database)
      AppLogger.general('🔄 Restoring shift from backend (SQLite)...');
      try {
        await ref.read(shiftNotifierProvider.notifier).fetchCurrentShift();
        AppLogger.general('✅ Shift state restored from backend');
      } catch (e) {
        AppLogger.general('⚠️  Could not restore shift: $e');
        // Continue anyway - user can start fresh shift if needed
      }

      // Navigate to home
      if (context.mounted) {
        AppLogger.general('➡️  Splash: Navigating to /home');
        context.go('/home');
      }
    }

    // Handle auth state changes
    useEffect(() {
      AppLogger.general(
        '🔷 SPLASH SCREEN: useEffect triggered, authState type: ${authState.runtimeType}',
      );

      authState.whenOrNull(
        data: (user) {
          AppLogger.general(
            '🔷 SPLASH SCREEN: Auth state = DATA, user: ${user != null ? user.email : "NULL"}',
          );
          if (hasNavigated.value) {
            AppLogger.general('🔷 SPLASH SCREEN: Already navigated, skipping');
            return;
          }

          if (user != null) {
            // User is authenticated - pre-load and navigate to home
            AppLogger.general('✅ Splash: User authenticated, pre-loading data');
            preloadAndNavigate();
          } else {
            // User not authenticated - navigate to login
            AppLogger.general('➡️  Splash: No user, navigating to /login');
            hasNavigated.value = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                AppLogger.general(
                  '➡️  Splash: Actually navigating to /login now',
                );
                context.go('/login');
              }
            });
          }
        },
        loading: () {
          AppLogger.general('🔷 SPLASH SCREEN: Auth state = LOADING');
        },
        error: (err, stack) {
          AppLogger.general('🔷 SPLASH SCREEN: Auth state = ERROR: $err');
        },
      );
      return null;
    }, [authState]);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon
              Icon(
                Icons.delete_outline_rounded,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // App title
              Text(
                'Bin Management',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),

              // Loading indicator
              authState.when(
                data: (_) => const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                loading: () => const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                error: (error, _) => Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 40,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error loading app',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
