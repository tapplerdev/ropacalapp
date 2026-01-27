import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/services/api_service.dart';
import 'package:ropacalapp/models/user.dart';
import 'package:ropacalapp/models/driver_location.dart';
import 'package:ropacalapp/models/move_request.dart';
import 'package:ropacalapp/core/enums/user_role.dart';
import 'package:ropacalapp/services/fcm_service.dart';
import 'package:ropacalapp/services/shift_service.dart';
import 'package:ropacalapp/services/websocket_service.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/providers/simulation_provider.dart';
import 'package:ropacalapp/providers/potential_locations_list_provider.dart';
import 'package:ropacalapp/providers/bins_provider.dart';
import 'package:ropacalapp/providers/move_request_provider.dart';
import 'package:ropacalapp/providers/move_request_notification_provider.dart';
import 'package:ropacalapp/core/services/location_tracking_service.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/services/session_manager.dart';

part 'auth_provider.g.dart';

/// Global singleton ApiService (keepAlive ensures single instance)
@Riverpod(keepAlive: true)
ApiService apiService(ApiServiceRef ref) {
  return ApiService();
}

/// WebSocket service provider (global singleton)
@Riverpod(keepAlive: true)
class WebSocketManager extends _$WebSocketManager {
  WebSocketService? _service;

  @override
  WebSocketService? build() {
    return null;
  }

  void connect(String token) {
    if (_service != null) {
      AppLogger.general('WebSocket already connected');
      return;
    }

    _service = WebSocketService();

    // Set up callbacks
    _service!.onRouteAssigned = (data) {
      AppLogger.general('📨 Route assigned via WebSocket: ${data['route_id']}');
      AppLogger.general('   Using updateFromWebSocket (no full refresh)');
      ref.read(shiftNotifierProvider.notifier).updateFromWebSocket(data);
    };

    // ✅ RESTORED: onShiftUpdate callback
    // Needed because startShift() HTTP response doesn't include route_bins
    // WebSocket shift_update includes full shift data with bins array
    _service!.onShiftUpdate = (data) {
      AppLogger.general('📨 Shift update via WebSocket');
      AppLogger.general('   Using updateFromWebSocket (includes route bins)');
      ref.read(shiftNotifierProvider.notifier).updateFromWebSocket(data);
    };

    _service!.onShiftDeleted = (data) {
      AppLogger.general(
        '🗑️  Shift deleted via WebSocket: ${data['shift_id']}',
      );
      AppLogger.general('   Resetting to inactive (no full refresh)');
      ref.read(shiftNotifierProvider.notifier).resetToInactive();
    };

    _service!.onShiftCancelled = (data) {
      AppLogger.general('❌ Shift cancelled via WebSocket: ${data['shift_id']}');
      AppLogger.general('   Refetching from backend (single source of truth)');
      // Refetch from backend - backend will return null since shift is cancelled
      // Existing logic in fetchCurrentShift() will handle setting state to inactive
      ref.read(shiftNotifierProvider.notifier).fetchCurrentShift();
      // TODO: Consider showing cancellation dialog with manager info
      // Currently just refetches and lets navigation page handle home navigation
    };

    _service!.onDriverLocationUpdate = (data) {
      try {
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        AppLogger.general('🟢 AUTH_PROVIDER: onDriverLocationUpdate CALLBACK TRIGGERED');
        AppLogger.general('   Raw data: $data');
        AppLogger.general('   Data type: ${data.runtimeType}');
        AppLogger.general('   Data keys: ${data.keys.toList()}');

        AppLogger.general('   📊 Getting driversNotifier...');
        final driversNotifier = ref.read(driversNotifierProvider.notifier);
        AppLogger.general('   ✅ Got driversNotifier: ${driversNotifier.runtimeType}');

        AppLogger.general('   🔄 Parsing DriverLocation from JSON...');
        final location = DriverLocation.fromJson(data);
        AppLogger.general('   ✅ Parsed location:');
        AppLogger.general('      Driver ID: ${location.driverId}');
        AppLogger.general('      Lat: ${location.latitude}, Lng: ${location.longitude}');
        AppLogger.general('      Timestamp: ${location.timestamp}');

        AppLogger.general('   📍 Calling driversNotifier.updateDriverLocation()...');
        driversNotifier.updateDriverLocation(location);
        AppLogger.general('   ✅ Called updateDriverLocation successfully');
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      } catch (e, stack) {
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        AppLogger.general('❌❌❌ ERROR in AUTH_PROVIDER callback');
        AppLogger.general('   Error: $e');
        AppLogger.general('   Stack: $stack');
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
    };

    _service!.onDriverShiftChange = (data) {
      try {
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        AppLogger.general('🚦 AUTH_PROVIDER: onDriverShiftChange CALLBACK TRIGGERED');
        final driverId = data['driver_id'] as String;
        final status = data['status'] as String;
        final shiftId = data['shift_id'] as String?;

        AppLogger.general('   Driver ID: $driverId');
        AppLogger.general('   Status: $status');
        AppLogger.general('   Shift ID: $shiftId');

        AppLogger.general('   🔄 Updating driver status (granular update, no full refresh)...');
        final driversNotifier = ref.read(driversNotifierProvider.notifier);
        driversNotifier.updateDriverStatus(driverId, status, shiftId);
        AppLogger.general('   ✅ Driver status update triggered');
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      } catch (e, stack) {
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        AppLogger.general('❌❌❌ ERROR in onDriverShiftChange callback');
        AppLogger.general('   Error: $e');
        AppLogger.general('   Stack: $stack');
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
    };

    _service!.onMoveRequestAssigned = (data) {
      try {
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        AppLogger.general('📦 AUTH_PROVIDER: onMoveRequestAssigned CALLBACK TRIGGERED');
        AppLogger.general('   Move request assigned to shift - processing...');
        AppLogger.general('   Data keys: ${data.keys.toList()}');

        // Parse move request from WebSocket data
        if (data['move_request'] != null) {
          final moveRequestData = data['move_request'] as Map<String, dynamic>;
          final moveRequest = MoveRequest.fromJson(moveRequestData);

          AppLogger.general('   📦 Move Request: ${moveRequest.id}');
          AppLogger.general('   Bin: ${moveRequest.binId}');
          AppLogger.general('   Pickup: ${moveRequest.pickupAddress}');
          AppLogger.general('   Dropoff: ${moveRequest.dropoffAddress}');

          // Set active move request
          ref.read(activeMoveRequestProvider.notifier).setMoveRequest(moveRequest);
          AppLogger.general('   ✅ Active move request set');

          // Trigger notification for UI
          ref
              .read(moveRequestNotificationNotifierProvider.notifier)
              .notify(moveRequest);
          AppLogger.general('   🔔 Move request notification triggered');
        } else {
          AppLogger.general('   ⚠️  No move_request field in data');
        }

        // Update shift with new route (includes pickup & dropoff waypoints)
        if (data['updated_route'] != null) {
          AppLogger.general('   🔄 Updating shift with new route...');
          ref.read(shiftNotifierProvider.notifier).updateFromWebSocket(data);
          AppLogger.general('   ✅ Shift updated with new route');
        } else {
          AppLogger.general('   🔄 Fetching current shift to get updated route...');
          ref.read(shiftNotifierProvider.notifier).fetchCurrentShift();
          AppLogger.general('   ✅ Shift refresh triggered');
        }

        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      } catch (e, stack) {
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        AppLogger.general('❌❌❌ ERROR in onMoveRequestAssigned callback');
        AppLogger.general('   Error: $e');
        AppLogger.general('   Stack: $stack');
        AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
    };

    // Potential locations events - invalidate provider to trigger refetch
    _service!.onPotentialLocationCreated = (data) {
      AppLogger.general('📡 WebSocket: Potential location created, invalidating provider');
      ref.invalidate(potentialLocationsListNotifierProvider);
    };

    _service!.onPotentialLocationConverted = (data) {
      AppLogger.general('📡 WebSocket: Potential location converted, invalidating both providers');
      ref.invalidate(potentialLocationsListNotifierProvider);
      ref.invalidate(binsListProvider);
    };

    _service!.onPotentialLocationDeleted = (data) {
      AppLogger.general('📡 WebSocket: Potential location deleted, invalidating provider');
      ref.invalidate(potentialLocationsListNotifierProvider);
    };

    // Bin events - invalidate provider to trigger refetch
    _service!.onBinCreated = (data) {
      AppLogger.general('📡 WebSocket: Bin created, invalidating provider');
      ref.invalidate(binsListProvider);
    };

    _service!.onBinUpdated = (data) {
      AppLogger.general('📡 WebSocket: Bin updated, invalidating provider');
      ref.invalidate(binsListProvider);
    };

    _service!.onBinDeleted = (data) {
      AppLogger.general('📡 WebSocket: Bin deleted, invalidating provider');
      ref.invalidate(binsListProvider);
    };

    _service!.onConnected = () {
      AppLogger.general('✅ WebSocket connected');

      // Immediately check for new shift assignments after reconnection
      // This catches any assignments that happened while disconnected
      AppLogger.general('📊 WebSocket reconnected - checking for new shift assignments');
      ref.read(shiftNotifierProvider.notifier).fetchCurrentShift().catchError((e) {
        AppLogger.general('📊 Error fetching shift after reconnect: $e');
      });
    };

    _service!.onDisconnected = () {
      AppLogger.general('🔌 WebSocket disconnected');

      // Auto-reconnect after 5 seconds if we have a valid token
      Future.delayed(const Duration(seconds: 5), () {
        final apiService = ref.read(apiServiceProvider);
        final currentToken = apiService.authToken;

        if (currentToken != null && _service != null) {
          AppLogger.general('🔄 Auto-reconnecting WebSocket after disconnect...');
          _service!.connect(currentToken);
        } else {
          AppLogger.general('⚠️  Cannot reconnect: No token available');
        }
      });
    };

    _service!.connect(token);
    state = _service;
  }

  void disconnect() {
    _service?.disconnect();
    _service = null;
    state = null;
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

          // Reconnect WebSocket with saved token
          final token = apiService.authToken;
          if (token != null) {
            AppLogger.general('   🔌 Reconnecting WebSocket...');
            ref.read(webSocketManagerProvider.notifier).connect(token);
          }

          // Start background location tracking for drivers on auto-login
          if (user.role == UserRole.driver) {
            AppLogger.general('   📍 Starting background location tracking (driver auto-login)');
            await ref.read(locationTrackingServiceProvider).startBackgroundTracking();
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

        // Connect WebSocket with JWT token
        AppLogger.general('🔌 Connecting WebSocket...');
        ref.read(webSocketManagerProvider.notifier).connect(token);

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

    // Disconnect WebSocket
    ref.read(webSocketManagerProvider.notifier).disconnect();

    // Stop background location tracking
    ref.read(locationTrackingServiceProvider).stopTracking();
    AppLogger.general('🗑️  Stopped background location tracking on logout');

    // Reset simulation state
    ref.read(simulationNotifierProvider.notifier).reset();
    AppLogger.general('🗑️  Reset simulation state on logout');

    // Clear session timestamp
    await SessionManager.clearSession();
    AppLogger.general('🗑️  Session cleared on logout');

    state = const AsyncValue.data(null);
  }
}
