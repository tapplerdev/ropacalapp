import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/providers/bins_provider.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/providers/potential_locations_list_provider.dart';
import 'package:ropacalapp/providers/move_requests_list_provider.dart';
import 'package:ropacalapp/providers/route_update_notification_provider.dart';
import 'package:ropacalapp/providers/bin_marker_cache_provider.dart';
import 'package:ropacalapp/providers/centrifugo_provider.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/services/session_manager.dart';
import 'package:ropacalapp/core/enums/user_role.dart';

/// Splash screen shown on app startup
///
/// Shows the Binly logo with a pulsing animation while:
/// - Checking authentication status
/// - Pre-fetching data (bins, drivers, locations for managers)
/// - Restoring shift state (for drivers)
class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.general('🔷 SPLASH SCREEN: Building...');
    final authState = ref.watch(authNotifierProvider);
    final hasNavigated = useState(false);
    final isQuickRestoring = useState(false);

    // Pulse animation controller
    final pulseController = useAnimationController(
      duration: const Duration(milliseconds: 1500),
    );

    // Glow animation controller (slightly offset for organic feel)
    final glowController = useAnimationController(
      duration: const Duration(milliseconds: 2000),
    );

    // Scale animation: 1.0 → 1.06 → 1.0
    final scaleAnimation = useMemoized(
      () => Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
      ),
      [pulseController],
    );

    // Glow animation: 0.0 → 0.15 → 0.0
    final glowAnimation = useMemoized(
      () => Tween<double>(begin: 0.0, end: 0.15).animate(
        CurvedAnimation(parent: glowController, curve: Curves.easeInOut),
      ),
      [glowController],
    );

    // Start animations
    useEffect(() {
      pulseController.repeat(reverse: true);
      glowController.repeat(reverse: true);
      return null;
    }, []);

    // Pre-fetch manager data (bins, drivers, locations) in parallel and wait
    Future<void> prefetchManagerData() async {
      AppLogger.general('📦 SPLASH: Pre-fetching manager data...');

      // Invalidate stale session-data providers to ensure fresh data
      // (prevents showing cached data from a previous login session)
      ref.invalidate(driversNotifierProvider);
      ref.invalidate(binsListProvider);
      ref.invalidate(potentialLocationsListNotifierProvider);
      ref.invalidate(moveRequestsListNotifierProvider);
      ref.invalidate(routeUpdateNotificationNotifierProvider);
      ref.invalidate(binMarkerCacheNotifierProvider);
      AppLogger.general('🗑️  SPLASH: Invalidated stale session-data providers');

      // Wait for Centrifugo connection (CentrifugoManager auto-connects on auth change)
      final centrifugoStopwatch = Stopwatch()..start();
      const centrifugoTimeout = Duration(seconds: 5);
      while (centrifugoStopwatch.elapsed < centrifugoTimeout) {
        if (ref.read(centrifugoManagerProvider.notifier).isConnected) {
          AppLogger.general('✅ SPLASH: Centrifugo connected in ${centrifugoStopwatch.elapsedMilliseconds}ms');
          break;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (!ref.read(centrifugoManagerProvider.notifier).isConnected) {
        AppLogger.general('⚠️ SPLASH: Centrifugo not connected after ${centrifugoTimeout.inSeconds}s, continuing anyway');
      }

      // Kick off all fetches by reading the providers
      ref.read(binsListProvider);
      ref.read(driversNotifierProvider);
      ref.read(potentialLocationsListNotifierProvider);

      // Wait for bins and drivers to complete (required for map rendering)
      // Poll until both have values, with a timeout
      final dataStopwatch = Stopwatch()..start();
      const dataTimeout = Duration(seconds: 10);

      while (dataStopwatch.elapsed < dataTimeout) {
        final binsReady = ref.read(binsListProvider).hasValue;
        final driversReady = ref.read(driversNotifierProvider).hasValue;

        if (binsReady && driversReady) {
          AppLogger.general('✅ SPLASH: Manager data loaded in ${dataStopwatch.elapsedMilliseconds}ms');
          return;
        }

        // Wait a bit before checking again
        await Future.delayed(const Duration(milliseconds: 100));
      }

      AppLogger.general('⚠️ SPLASH: Manager data timeout after ${dataTimeout.inSeconds}s, navigating anyway');
    }

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
          if (context.mounted && !hasNavigated.value) {
            hasNavigated.value = true;

            // Pre-fetch location in background (don't wait)
            ref.read(currentLocationProvider);

            // Pre-fetch manager data and wait for it
            final user = authState.valueOrNull;
            if (user?.role == UserRole.admin) {
              await prefetchManagerData();
            }

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

    // Pre-load data and navigate to home
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
        } else {
          AppLogger.general('✅ Shift state restored from backend');
        }
      } else {
        AppLogger.general('👔 Manager startup - pre-fetching data...');
        await prefetchManagerData();
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ListenableBuilder(
          listenable: Listenable.merge([scaleAnimation, glowAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: scaleAnimation.value,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF5E9646), Color(0xFF4AA0B5)],
                ).createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'BINLY',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: const Color(0xFF569349)
                            .withValues(alpha: glowAnimation.value),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
