import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
        final status = await apiService.getAuthStatusRaw();
        final user = (status != null && status['user'] != null)
            ? User.fromJson(status['user'] as Map<String, dynamic>)
            : null;
        if (user != null) {
          AppLogger.general('   ✅ User auto-logged in from saved token');
          AppLogger.general('   👤 User: ${user.email} (${user.role})');
          await _cacheUser(user);

          // Backfill the org slug for users who were ALREADY signed in when
          // this shipped. The slug is otherwise only learned at login, so
          // anyone holding a valid 7-day token when a second organization is
          // provisioned would land on an empty, now-mandatory field with no way
          // to know what to type. This is the path every signed-in launch takes.
          await _rememberOrganization(status!);

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

  /// Named parameters are deliberate. This used to take (email, password)
  /// POSITIONALLY, so adding an optional `organization` would have compiled at
  /// every existing call site while silently sending no slug — and there are
  /// three call sites in login_page.dart alone. Named parameters force each one
  /// to be visited.
  Future<void> login({
    required String email,
    required String password,
    String? organization,
  }) async {
    state = const AsyncValue.loading();

    final apiService = ref.read(apiServiceProvider);

    state = await AsyncValue.guard(() async {
      final response = await apiService.login(
        email: email,
        password: password,
        organization: organization,
      );

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
        // Remember the org AFTER the session is established. It is a
        // convenience, and must never be able to turn a server-side success
        // into an app-side failure.
        await _rememberOrganization(response);
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

  static const _organizationKey = 'remembered_organization';
  /// The org UUID. Persisted separately from the slug because the per-tenant
  /// Centrifugo channel `company:{orgID}:events` keys on the ID, while the
  /// login form needs the human-typeable slug. Both come from the same server
  /// response.
  static const _organizationIdKey = 'remembered_organization_id';
  /// 'true' / 'false': the org's AirTag tracking flag, as the server last
  /// said.
  static const _organizationAirtagKey =
      'remembered_organization_airtag_tracking';

  /// Reads the remembered organization UUID, or null if unknown.
  static Future<String?> currentOrganizationId() async {
    try {
      return await const FlutterSecureStorage().read(key: _organizationIdKey);
    } catch (e) {
      AppLogger.general('⚠️  Could not read organization id: $e');
      return null;
    }
  }

  /// Persists the org SLUG the SERVER resolved (never what the user typed) so
  /// the login form can pre-fill it.
  ///
  /// Wholly defensive. The casts are inside the try, not just the storage
  /// write: this used to run BEFORE the token was stored, with unguarded casts,
  /// so an unexpected `organization` shape would have thrown past
  /// AsyncValue.guard and turned an HTTP 200 that minted a real session into a
  /// login failure showing a raw Dart type error. A convenience must not be
  /// able to do that.
  Future<void> _rememberOrganization(Map<String, dynamic> response) async {
    try {
      final orgData = response['organization'];
      if (orgData is! Map) return;
      final slug = orgData['slug'];
      if (slug is String && slug.isNotEmpty) {
        await const FlutterSecureStorage()
            .write(key: _organizationKey, value: slug);
      }
      final id = orgData['id'];
      if (id is String && id.isNotEmpty) {
        await const FlutterSecureStorage()
            .write(key: _organizationIdKey, value: id);
      }
      // Re-written on every launch (this runs on the auth-status restore too),
      // so turning the flag on or off reaches drivers without a re-login.
      final airtag = orgData['airtag_tracking'];
      if (airtag is bool) {
        await const FlutterSecureStorage().write(
            key: _organizationAirtagKey, value: airtag ? 'true' : 'false');
        ref.invalidate(airtagTrackingProvider);
      }
    } catch (e) {
      AppLogger.general('⚠️  Could not persist organization slug: $e');
    }
  }

  /// Clears the remembered org slug. Called on logout — see logout() for why
  /// leaving it behind is actively harmful on a shared device.
  Future<void> _forgetOrganization() async {
    try {
      const storage = FlutterSecureStorage();
      await storage.delete(key: _organizationKey);
      await storage.delete(key: _organizationIdKey);
      await storage.delete(key: _organizationAirtagKey);
      ref.invalidate(airtagTrackingProvider);
    } catch (e) {
      AppLogger.general('⚠️  Could not clear organization slug: $e');
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();

    final apiService = ref.read(apiServiceProvider);
    await apiService.clearAuthToken();
    await StartupCache.clear(StartupCache.userKey);

    // Clear the remembered organization. Leaving it strands the NEXT person on
    // this device — a real scenario on a shared work phone. They would get the
    // previous driver's slug pre-filled, the backend resolves that tenant,
    // their email is not in it, and the response is the same opaque 401 it
    // returns for a wrong password. Correct credentials, "Unauthorized. Please
    // log in again.", and no way to discover the cause. The slug is a
    // convenience, not a credential, so re-typing it once after a logout is the
    // cheap side of this trade.
    await _forgetOrganization();

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

/// Whether the signed-in user's organization uses AirTag tracking
/// (organizations.airtag_tracking — on for ropacal only, since the FindMy
/// bridge serves one company). AirTag-only settings render only when this is
/// true.
///
/// Read from what the server said at login or on the last launch's auth status.
/// Unknown counts as off: nothing AirTag-related shows rather than showing to
/// the wrong company.
final airtagTrackingProvider = FutureProvider<bool>((ref) async {
  try {
    return await const FlutterSecureStorage()
            .read(key: AuthNotifier._organizationAirtagKey) ==
        'true';
  } catch (_) {
    return false;
  }
});
