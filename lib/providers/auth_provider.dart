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
      AppLogger.general('   ✅ Token found! Validating with backend...');
      try {
        final user = await apiService.getAuthStatus();
        if (user != null) {
          AppLogger.general('   ✅ User auto-logged in from saved token');
          AppLogger.general('   👤 User: ${user.email} (${user.role})');

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
        return User.fromJson(userData);
      }

      throw 'Invalid login response';
    });
  }

  Future<void> _registerFCMToken() async {
    final fcmToken = FCMService.token;
    if (fcmToken == null) {
      AppLogger.general('No FCM token available', level: AppLogger.warning);
      return;
    }

    try {
      final deviceType = Platform.isIOS ? 'ios' : 'android';
      final shiftService = ref.read(shiftServiceProvider);

      await shiftService.registerFCMToken(fcmToken, deviceType);
      AppLogger.general('✅ FCM token registered with backend');
    } catch (e) {
      AppLogger.general(
        '⚠️  Failed to register FCM token: $e',
        level: AppLogger.warning,
      );
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();

    final apiService = ref.read(apiServiceProvider);
    await apiService.clearAuthToken();

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
