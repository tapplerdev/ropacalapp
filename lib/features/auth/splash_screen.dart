import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/services/session_manager.dart';
import 'package:ropacalapp/core/enums/user_role.dart';

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
    final isQuickRestoring = useState(false);

    // Initialize session manager and handle smart navigation
    useEffect(() {
      Future<void> initializeSession() async {
        await SessionManager.initialize();

        final sessionAge = SessionManager.sessionAge;
        AppLogger.general('📅 Session age: $sessionAge');

        // INSTANT RESUME: < 2 minutes since last active
        if (SessionManager.hasActiveSession) {
          AppLogger.general(
            '⚡ INSTANT RESUME: Skipping validation, navigating to home',
          );
          AppLogger.general(
            '   📊 Shift fetch will be handled by event-driven listener',
          );
          if (context.mounted && !hasNavigated.value) {
            hasNavigated.value = true;

            // Pre-fetch location in background (don't wait)
            ref.read(currentLocationProvider);

            // NOTE: Shift fetch is now handled by event-driven listener in auth_provider
            // No need to manually fetch here - prevents duplicate fetches

            // Defer navigation to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.go('/home');
              }
            });
          }
          return;
        }

        // QUICK RESTORE: 2-10 minutes since last active
        if (SessionManager.canQuickRestore) {
          AppLogger.general(
            '⚡ QUICK RESTORE: Fast validation with timeout',
          );
          isQuickRestoring.value = true;
          // Continue to normal auth flow with fast validation
        }

        // COLD START: > 10 minutes or first launch
        // Continue to normal auth flow (full validation)
        AppLogger.general('❄️  COLD START: Full validation required');

        // Pre-fetch location early for faster navigation startup
        AppLogger.general(
          '📍 SPLASH: Pre-fetching location for faster navigation...',
        );
        ref.read(currentLocationProvider);
      }

      initializeSession();
      return null;
    }, []);

    // Pre-load shift data and navigate to home
    Future<void> preloadAndNavigate() async {
      if (!context.mounted || hasNavigated.value) return;
      hasNavigated.value = true;

      // Get user data to check role
      final user = authState.valueOrNull;

      // Restore active shift from backend (ONLY for drivers)
      // Managers don't have shifts, so skip this API call for them
      if (user?.role == UserRole.driver) {
        AppLogger.general('🔄 Driver startup - restoring shift from backend with retry logic...');
        final success = await ref.read(shiftNotifierProvider.notifier).fetchCurrentShiftWithRetry(maxAttempts: 3);

        if (!success) {
          AppLogger.general('⚠️ Failed to fetch shift after 3 attempts');
          // Polling will continue to check in background
        } else {
          AppLogger.general('✅ Shift state restored from backend');
        }
      } else {
        AppLogger.general('👔 Manager startup - skipping shift fetch (managers don\'t have shifts)');
      }

      // Navigate to home (defer to avoid setState during build)
      if (context.mounted) {
        AppLogger.general('➡️  Splash: Navigating to /home');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go('/home');
          }
        });
      }
    }

    // Handle auth state changes
    useEffect(() {
      AppLogger.general(
        '🔷 SPLASH SCREEN: useEffect triggered, authState type: ${authState.runtimeType}',
      );

      // Skip if already navigated via instant resume
      if (hasNavigated.value) {
        AppLogger.general('🔷 SPLASH SCREEN: Already navigated, skipping');
        return null;
      }

      authState.whenOrNull(
        data: (user) {
          AppLogger.general(
            '🔷 SPLASH SCREEN: Auth state = DATA, user: ${user != null ? user.email : "NULL"}',
          );

          if (user != null) {
            // User is authenticated - pre-load and navigate to home
            AppLogger.general('✅ Splash: User authenticated, pre-loading data');

            // For quick restore, add slight delay for better UX
            if (isQuickRestoring.value) {
              Future.delayed(const Duration(milliseconds: 300), () {
                preloadAndNavigate();
              });
            } else {
              preloadAndNavigate();
            }
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
          // On error, navigate to login
          if (!hasNavigated.value) {
            hasNavigated.value = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.go('/login');
              }
            });
          }
        },
      );
      return null;
    }, [authState]);

    // Determine if we should show branded splash or clean loader
    // Show branded splash only if going to login (user not authenticated)
    final showBrandedSplash = authState.whenOrNull(
      data: (user) => user == null, // No user = going to login
    ) ?? true; // Default to branded while loading

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: showBrandedSplash
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App icon (only for login flow)
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
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ],
                )
              : const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
        ),
      ),
    );
  }
}
