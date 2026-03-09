import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/services/centrifugo_service.dart';
import 'package:ropacalapp/core/enums/user_role.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/providers/notification_provider.dart';
import 'package:ropacalapp/core/notifications/notification_adapters.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/providers/shift_provider.dart';

part 'centrifugo_provider.g.dart';

/// Centrifugo connection lifecycle manager
///
/// Automatically connects when ANY user logs in (drivers AND managers)
/// - Drivers: Subscribe to driver:events:{id} for shift_created, route_assigned, etc.
/// - Managers: Subscribe to company:events for real-time tracking
///
/// Returns [bool] indicating connection status. This makes the state reactive:
/// watchers (e.g. map page) automatically rebuild when connection transitions
/// from false → true (including after retry).
///
/// keepAlive: true prevents auto-disposal during tab switches while still
/// cleaning up properly on logout (watches authNotifierProvider)
@Riverpod(keepAlive: true)
class CentrifugoManager extends _$CentrifugoManager {
  StreamSubscription? _companyEventsSubscription;
  StreamSubscription? _driverEventsSubscription;
  Timer? _retryTimer;
  int _retryAttempts = 0;
  static const int _maxRetryAttempts = 10;

  @override
  FutureOr<bool> build() async {
    AppLogger.general('🔵 [CentrifugoManager] build() called');

    // Watch auth state changes
    final authState = ref.watch(authNotifierProvider);

    AppLogger.general('🔵 [CentrifugoManager] Auth state: '
        'hasValue=${authState.hasValue}, '
        'userId=${authState.value?.id ?? "null"}');

    // Clean up timers and subscriptions on dispose
    ref.onDispose(() {
      AppLogger.general('🔵 [CentrifugoManager] Provider disposed - cleaning up');
      _retryTimer?.cancel();
      _disconnect();
    });

    // Connect for ALL authenticated users (drivers publish, managers subscribe)
    if (authState.hasValue && authState.value != null) {
      final user = authState.value!;
      AppLogger.general('🔌 [CentrifugoManager] User detected '
          '(role=${user.role}, id=${user.id}) - connecting to Centrifugo');

      final connected = await _connect();

      if (connected) {
        // Admins/managers subscribe to company-wide events
        if (user.role == UserRole.admin) {
          await _subscribeToCompanyEvents();
        }

        // Drivers subscribe to their personal events channel
        if (user.role == UserRole.driver) {
          await _subscribeToDriverEvents(user.id);
        }
      }

      return connected;
    } else {
      AppLogger.general('⚠️ [CentrifugoManager] No authenticated user - skipping');
      _disconnect();
      return false;
    }
  }

  /// Connect to Centrifugo. Returns true on success, false on failure.
  /// On failure, schedules a retry with exponential backoff.
  Future<bool> _connect() async {
    try {
      // Wait for auth token to be ready before connecting
      final apiService = ref.read(apiServiceProvider);

      if (!apiService.isAuthTokenReady) {
        AppLogger.general('⏳ [CentrifugoManager] Auth token not ready, waiting...');

        int attempts = 0;
        const maxAttempts = 50; // 5 seconds total (50 * 100ms)

        while (!apiService.isAuthTokenReady && attempts < maxAttempts) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }

        if (!apiService.isAuthTokenReady) {
          AppLogger.general(
            '❌ [CentrifugoManager] Auth token not ready after ${maxAttempts * 100}ms',
          );
          _scheduleRetry();
          return false;
        }

        AppLogger.general('✅ [CentrifugoManager] Auth token ready after ${attempts * 100}ms');
      }

      AppLogger.general('🔌 [CentrifugoManager] Connecting to Centrifugo...');
      final centrifugoService = ref.read(centrifugoServiceProvider);

      // Set up reconnect handler to refresh shift data after connection loss
      centrifugoService.onReconnected = () {
        final authState = ref.read(authNotifierProvider);
        final user = authState.valueOrNull;
        if (user?.role == UserRole.driver) {
          AppLogger.general('🔄 [CentrifugoManager] Reconnected — fetching shift to catch missed updates');
          ref.read(shiftNotifierProvider.notifier).fetchCurrentShift();
        }
      };

      await centrifugoService.connect();

      _retryAttempts = 0; // Reset on success
      _retryTimer?.cancel();
      AppLogger.general('✅ [CentrifugoManager] Connected to Centrifugo successfully');
      return true;
    } catch (e) {
      AppLogger.general('❌ [CentrifugoManager] Failed to connect: $e');
      _scheduleRetry();
      return false;
    }
  }

  /// Schedule a retry with exponential backoff (3s, 6s, 12s, ... capped at 30s)
  void _scheduleRetry() {
    if (_retryAttempts >= _maxRetryAttempts) {
      AppLogger.general(
        '❌ [CentrifugoManager] Max retry attempts ($_maxRetryAttempts) reached. '
        'Centrifugo will reconnect on next auth state change.',
      );
      return;
    }

    _retryTimer?.cancel();
    _retryAttempts++;

    // Exponential backoff: 3s, 6s, 12s, 24s, 30s, 30s, ...
    final delaySeconds = (3 * (1 << (_retryAttempts - 1))).clamp(3, 30);

    AppLogger.general(
      '🔄 [CentrifugoManager] Scheduling retry #$_retryAttempts '
      'in ${delaySeconds}s...',
    );

    _retryTimer = Timer(Duration(seconds: delaySeconds), () async {
      AppLogger.general('🔄 [CentrifugoManager] Retry #$_retryAttempts starting...');
      final connected = await _connect();
      if (connected) {
        AppLogger.general('✅ [CentrifugoManager] Retry succeeded! Updating state...');
        // Update provider state to true so watchers (map page) rebuild
        state = const AsyncData(true);

        // Re-subscribe after retry
        final authState = ref.read(authNotifierProvider);
        if (authState.hasValue && authState.value != null) {
          final user = authState.value!;
          if (user.role == UserRole.admin) {
            await _subscribeToCompanyEvents();
          }
          if (user.role == UserRole.driver) {
            await _subscribeToDriverEvents(user.id);
          }
        }
      }
    });
  }

  /// Subscribe to company-wide events (managers/admins only)
  Future<void> _subscribeToCompanyEvents() async {
    if (_companyEventsSubscription != null) {
      AppLogger.general('⚠️ [CentrifugoManager] Already subscribed to company:events');
      return;
    }

    try {
      AppLogger.general('🔄 [CentrifugoManager] Subscribing to company:events...');
      final centrifugoService = ref.read(centrifugoServiceProvider);
      _companyEventsSubscription =
          await centrifugoService.subscribeToCompanyEvents((event) {
        final type = event['type'] as String?;
        AppLogger.general('📢 [CentrifugoManager] Company event: $type');

        // Route through unified notification pipeline
        final notifEvent =
            NotificationAdapters.fromCentrifugoCompanyEvent(event);
        ref.read(notificationRouterProvider).receive(notifEvent);
      });
      AppLogger.general('✅ [CentrifugoManager] Subscribed to company:events');
    } catch (e) {
      AppLogger.general('❌ [CentrifugoManager] Failed to subscribe to company:events: $e');
    }
  }

  /// Subscribe to driver-specific events (drivers only)
  /// Channel: driver:events:{driverId}
  /// Events: shift_created, route_assigned, etc.
  Future<void> _subscribeToDriverEvents(String driverId) async {
    if (_driverEventsSubscription != null) {
      AppLogger.general('⚠️ [CentrifugoManager] Already subscribed to driver:events');
      return;
    }

    try {
      AppLogger.general('🔄 [CentrifugoManager] Subscribing to driver:events:$driverId...');
      final centrifugoService = ref.read(centrifugoServiceProvider);
      _driverEventsSubscription =
          await centrifugoService.subscribeToDriverEvents(driverId, (event) {
        final type = event['type'] as String?;
        AppLogger.general('🔔 [CentrifugoManager] Driver event: $type');

        // Route through unified notification pipeline
        final notifEvent =
            NotificationAdapters.fromCentrifugoCompanyEvent(event);
        ref.read(notificationRouterProvider).receive(notifEvent);

        // For shift_created: trigger fetchCurrentShift so the UI updates
        if (type == 'shift_created') {
          AppLogger.general('🔔 [CentrifugoManager] shift_created — fetching shift...');
          ref.read(shiftNotifierProvider.notifier).fetchCurrentShift();
        }
      });
      AppLogger.general('✅ [CentrifugoManager] Subscribed to driver:events:$driverId');
    } catch (e) {
      AppLogger.general('❌ [CentrifugoManager] Failed to subscribe to driver:events: $e');
    }
  }

  /// Disconnect from Centrifugo
  void _disconnect() {
    _companyEventsSubscription?.cancel();
    _companyEventsSubscription = null;

    _driverEventsSubscription?.cancel();
    _driverEventsSubscription = null;

    final centrifugoService = ref.read(centrifugoServiceProvider);
    if (centrifugoService.isConnected) {
      AppLogger.general('🔌 [CentrifugoManager] Disconnecting from Centrifugo...');
      centrifugoService.disconnect();
      AppLogger.general('✅ [CentrifugoManager] Disconnected');
    }
  }

  /// Check if connected (reads actual service state, not stale bool)
  bool get isConnected {
    final centrifugoService = ref.read(centrifugoServiceProvider);
    return centrifugoService.isConnected;
  }
}
