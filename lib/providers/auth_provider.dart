import 'dart:convert';
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:ropacalapp/core/services/api_service.dart';
import 'package:ropacalapp/models/user.dart';
import 'package:ropacalapp/core/enums/user_role.dart';
import 'package:ropacalapp/services/fcm_service.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/simulation_provider.dart';
import 'package:ropacalapp/core/services/location_tracking_service.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/services/session_manager.dart';
import 'package:ropacalapp/core/services/startup_cache.dart';
import 'package:ropacalapp/providers/focused_driver_provider.dart';
import 'package:ropacalapp/providers/route_polyline_provider.dart';

part 'auth_provider.g.dart';

/// Global singleton ApiService (keepAlive ensures single instance)
@Riverpod(keepAlive: true)
ApiService apiService(ApiServiceRef ref) {
  return ApiService();
}

/// Auth listener that triggers shift fetch when driver logs in.
/// Replaces the old WebSocketManager — all real-time events now flow through Centrifugo.
@Riverpod(keepAlive: true)
class AuthEventListener extends _$AuthEventListener {
  @override
  bool build() {
    // EVENT-DRIVEN: Listen to auth state changes and fetch shift when driver logs in
    ref.listen(authNotifierProvider, (previous, next) {
      AppLogger.general('🎯 [AUTH LISTENER] Auth state changed');

      next.whenData((user) {
        if (user != null && user.role == UserRole.driver) {
          AppLogger.general('   ✅ Driver logged in: ${user.email} — fetching shift...');
          ref.read(shiftNotifierProvider.notifier).fetchCurrentShiftWithRetry(
                maxAttempts: 3,
              ).then((success) {
            AppLogger.general(success
                ? '   ✅ Shift fetch completed'
                : '   ❌ Shift fetch failed after retries');
          });
        }
      });
    });

    return true;
  }
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<User?> build() async {
    AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    AppLogger.general('🚀 AUTH PROVIDER BUILD - APP STARTUP');

    // Load saved auth token from secure storage
    final apiService = ref.read(apiServiceProvider);
    AppLogger.general('   📂 Loading token from secure storage...');
    await apiService.loadAuthToken();

    // Check if user is already logged in with the loaded token
    AppLogger.general('   🔍 Checking if token exists...');
    AppLogger.general('   💾 hasToken: ${apiService.hasToken}');

    if (apiService.hasToken) {
      // OPTIMISTIC COLD START: with a locally-valid (non-expired) JWT and a
      // cached user snapshot, navigate immediately and validate against the
      // backend in the background — the network round-trip comes off the
      // critical path. A rejected session bounces to login within seconds;
      // a network error keeps the session (offline-tolerant).
      if (!_jwtExpired(apiService.currentAuthToken)) {
        final cachedUser = await _loadCachedUser();
        if (cachedUser != null) {
          AppLogger.general(
              '   ⚡ OPTIMISTIC: cached user + valid JWT — validating in background');
          _validateSessionInBackground();
          _postLoginSetup(cachedUser); // driver tracking + FCM, off-path
          return cachedUser;
        }
      }

      AppLogger.general('   ✅ Token found! Validating with backend...');
      try {
        final user = await apiService.getAuthStatus();
        if (user != null) {
          AppLogger.general('   ✅ User auto-logged in from saved token');
          AppLogger.general('   👤 User: ${user.email} (${user.role})');
          await _cacheUser(user);

          // Start background location tracking for drivers on auto-login
          if (user.role == UserRole.driver) {
            try {
              AppLogger.general('   📍 Starting background location tracking (driver auto-login)');
              await ref.read(locationTrackingServiceProvider).startBackgroundTracking();
            } catch (locationError) {
              // Log location permission errors but don't block login
              // User will be prompted for permissions when they try to start a shift
              AppLogger.general('   ⚠️  Failed to start background tracking: $locationError');
              if (locationError.toString().contains('LOCATION_PERMISSION_DENIED')) {
                AppLogger.general('   ℹ️  Location permissions not granted - driver will be prompted when starting shift');
              }
            }
          }

          // Re-register FCM token on auto-login (may have changed since last login)
          await _registerFCMToken();

          AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          return user;
        }
      } catch (e) {
        AppLogger.general('   ⚠️  Saved token invalid or expired: $e');
        await apiService.clearAuthToken();
      }
    } else {
      AppLogger.general('   ℹ️  No token found - user needs to login');
    }

    AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return null;
  }

  // ─── Optimistic cold-start helpers ─────────────────────────────────

  /// Local JWT expiry check — no signature verification (the backend does
  /// that), just enough to avoid optimistically resuming a session that is
  /// guaranteed to bounce.
  bool _jwtExpired(String? token) {
    if (token == null) return true;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final exp = payload['exp'] as int?;
      if (exp == null) return false; // no expiry claim — let the backend say
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= exp;
    } catch (_) {
      return true; // unparseable — take the safe validated path
    }
  }

  Future<User?> _loadCachedUser() async {
    final json = await StartupCache.load(StartupCache.userKey);
    if (json is Map<String, dynamic>) {
      try {
        return User.fromJson(json);
      } catch (_) {}
    }
    return null;
  }

  Future<void> _cacheUser(User user) =>
      StartupCache.save(StartupCache.userKey, user.toJson());

  /// Background session validation for the optimistic path. An explicit
  /// auth rejection signs out; a network error keeps the session so the
  /// app still works offline.
  Future<void> _validateSessionInBackground() async {
    try {
      final user = await ref.read(apiServiceProvider).getAuthStatus();
      if (user != null) {
        await _cacheUser(user);
        state = AsyncData(user); // pick up any profile changes
        AppLogger.general('✅ Background session validation OK');
      } else {
        await _forceSignOut('session no longer valid');
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized')) {
        await _forceSignOut('token rejected (401)');
      } else {
        AppLogger.general(
            '⚠️ Background validation network error — keeping session: $e');
      }
    }
  }

  Future<void> _forceSignOut(String reason) async {
    AppLogger.general('🚪 Signing out: $reason');
    await ref.read(apiServiceProvider).clearAuthToken();
    await StartupCache.clear(StartupCache.userKey);
    state = const AsyncData(null); // router redirects to login
  }

  /// Post-login side effects (driver tracking + FCM registration) — fired
  /// without awaiting on the optimistic path so they stay off the critical
  /// render path.
  Future<void> _postLoginSetup(User user) async {
    if (user.role == UserRole.driver) {
      try {
        await ref.read(locationTrackingServiceProvider).startBackgroundTracking();
      } catch (e) {
        AppLogger.general('⚠️ Background tracking start failed: $e');
      }
    }
    await _registerFCMToken();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();

    final apiService = ref.read(apiServiceProvider);

    state = await AsyncValue.guard(() async {
      final response = await apiService.login(email: email, password: password);

      // Extract token from response
      final token = response['token'] as String?;
      if (token != null) {
        AppLogger.general('🔑 Setting auth token...');
        await apiService.setAuthToken(token);
        AppLogger.general('✅ Auth token set successfully');

        // Register FCM token with backend
        AppLogger.general('📱 Registering FCM token...');
        await _registerFCMToken();

        // NOTE: Shift pre-loading is now handled in login_page.dart
        // This ensures shift data and location are ready before navigating to the map screen
      }

      // Extract user from response
      final userData = response['user'] as Map<String, dynamic>?;
      if (userData != null) {
        final user = User.fromJson(userData);
        await _cacheUser(user); // enables optimistic cold start next launch
        return user;
      }

      throw 'Invalid login response';
    });
  }

  Future<void> _registerFCMToken() async {
    // FCM init is deferred past the first frame — join it so the token is
    // ready instead of silently skipping registration.
    await FCMService.initialize();
    final fcmToken = FCMService.token;
    if (fcmToken == null) {
      AppLogger.general('No FCM token available', level: AppLogger.warning);
      return;
    }

    final deviceType = Platform.isIOS ? 'ios' : 'android';
    final shiftService = ref.read(shiftServiceProvider);

    // Retry up to 3 times with exponential backoff
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        await shiftService.registerFCMToken(fcmToken, deviceType);
        AppLogger.general('✅ FCM token registered with backend (attempt $attempt)');

        // Wire up token refresh callback so future token changes auto-register
        FCMService.setTokenRefreshCallback((newToken) async {
          final dt = Platform.isIOS ? 'ios' : 'android';
          final svc = ref.read(shiftServiceProvider);
          await svc.registerFCMToken(newToken, dt);
        });

        return;
      } catch (e) {
        AppLogger.general(
          '⚠️  Failed to register FCM token (attempt $attempt/3): $e',
          level: AppLogger.warning,
        );
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    AppLogger.general('❌ FCM token registration failed after 3 attempts', level: AppLogger.warning);
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();

    final apiService = ref.read(apiServiceProvider);
    await apiService.clearAuthToken();
    await StartupCache.clear(StartupCache.userKey);

    // Stop background location tracking
    ref.read(locationTrackingServiceProvider).stopTracking();
    AppLogger.general('🗑️  Stopped background location tracking on logout');

    // Reset simulation state
    ref.read(simulationNotifierProvider.notifier).reset();
    AppLogger.general('🗑️  Reset simulation state on logout');

    // Clear map focus + polyline state
    ref.read(focusedDriverProvider.notifier).clearFocus();
    ref.read(routePolylineProvider.notifier).clear();
    AppLogger.general('🗑️  Cleared map focus + polyline state on logout');

    // Reset shift state
    ref.read(shiftNotifierProvider.notifier).reset();
    AppLogger.general('🗑️  Reset shift state on logout');

    // Clear session timestamp
    await SessionManager.clearSession();
    AppLogger.general('🗑️  Session cleared on logout');

    // CRITICAL: Clean up Google Maps Navigation session
    // Prevents navigation state from persisting between users
    // cleanup() stops guidance, clears destinations, and terminates the session
    // T&C acceptance state is preserved (user won't need to accept again)
    try {
      await GoogleMapsNavigator.cleanup();
      AppLogger.general('🗑️  Navigation session cleaned up on logout');
    } catch (e) {
      // Don't fail logout if navigation cleanup fails (might not be initialized)
      AppLogger.general(
        '⚠️  Navigation cleanup failed (likely not initialized): $e',
        level: AppLogger.warning,
      );
    }

    state = const AsyncValue.data(null);
  }
}
