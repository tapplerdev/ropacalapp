import 'dart:async';
import 'dart:developer';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/services/centrifugo_service.dart';
import 'package:ropacalapp/core/enums/user_role.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/providers/potential_locations_list_provider.dart';
import 'package:ropacalapp/providers/bins_provider.dart';

part 'centrifugo_provider.g.dart';

/// Centrifugo connection lifecycle manager
///
/// Automatically connects when ANY user logs in (drivers AND managers)
/// - Drivers: Publish location to driver:location:{id} channel
/// - Managers: Subscribe to driver location channels for real-time tracking
@riverpod
class CentrifugoManager extends _$CentrifugoManager {
  StreamSubscription? _locationSubscription;
  StreamSubscription? _companyEventsSubscription;
  bool _isConnected = false;

  @override
  FutureOr<void> build() async {
    log('🔵 [CentrifugoManager] build() called - Provider is being initialized!');

    // Watch auth state changes
    final authState = ref.watch(authNotifierProvider);

    log('🔵 [CentrifugoManager] Auth state check: hasValue=${authState.hasValue}, value=${authState.value?.id ?? "null"}');

    // Disconnect when user logs out
    ref.onDispose(() {
      log('🔵 [CentrifugoManager] Provider disposed - cleaning up');
      _disconnect();
    });

    // Connect for ALL authenticated users (drivers publish, managers subscribe)
    if (authState.hasValue && authState.value != null) {
      final user = authState.value!;
      log('🔌 [CentrifugoManager] User detected '
          '(role=${user.role}, id=${user.id}) - connecting to Centrifugo');
      await _connect();

      // Admins subscribe to company-wide events (potential location updates etc.)
      if (user.role == UserRole.admin) {
        await _subscribeToCompanyEvents();
      }
    } else {
      log('⚠️ [CentrifugoManager] No authenticated user - skipping connection');
      _disconnect();
    }
  }

  /// Connect to Centrifugo
  Future<void> _connect() async {
    if (_isConnected) {
      log('🔌 [CentrifugoManager] Already connected');
      return;
    }

    try {
      // CRITICAL: Wait for auth token to be ready before connecting
      // This prevents 401 "No authorization header" errors
      final apiService = ref.read(apiServiceProvider);

      if (!apiService.isAuthTokenReady) {
        log('⏳ [CentrifugoManager] Auth token not ready yet, waiting...');

        // Wait with timeout to prevent infinite hang
        int attempts = 0;
        const maxAttempts = 10; // 1 second total (10 * 100ms)

        while (!apiService.isAuthTokenReady && attempts < maxAttempts) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
          log('⏳ [CentrifugoManager] Waiting for auth token (attempt $attempts/$maxAttempts)');
        }

        if (!apiService.isAuthTokenReady) {
          log('❌ [CentrifugoManager] Auth token not ready after ${maxAttempts * 100}ms - aborting connection');
          throw Exception(
            'Auth token not loaded within timeout. Cannot connect to Centrifugo without authentication.',
          );
        }

        log('✅ [CentrifugoManager] Auth token ready after ${attempts * 100}ms');
      } else {
        log('✅ [CentrifugoManager] Auth token already ready');
      }

      log('🔌 [CentrifugoManager] Connecting to Centrifugo...');
      final centrifugoService = ref.read(centrifugoServiceProvider);
      await centrifugoService.connect();
      _isConnected = true;
      log('✅ [CentrifugoManager] Connected to Centrifugo successfully');
    } catch (e) {
      log('❌ [CentrifugoManager] Failed to connect: $e');
      log('💡 [CentrifugoManager] This is not critical - connection will retry automatically');
      // Don't rethrow - allow app to continue working, Centrifugo will retry
    }
  }

  /// Subscribe to company-wide events (managers/admins only)
  ///
  /// Handles: potential_location_created, potential_location_converted,
  ///          potential_location_deleted
  Future<void> _subscribeToCompanyEvents() async {
    if (_companyEventsSubscription != null) {
      log('⚠️ [CentrifugoManager] Already subscribed to company:events');
      return;
    }

    try {
      log('🔄 [CentrifugoManager] Subscribing to company:events...');
      final centrifugoService = ref.read(centrifugoServiceProvider);
      _companyEventsSubscription =
          await centrifugoService.subscribeToCompanyEvents((event) {
        final type = event['type'] as String?;
        log('📢 [CentrifugoManager] Company event: $type');

        switch (type) {
          case 'potential_location_created':
            log('📍 [CentrifugoManager] Potential location created - '
                'invalidating list');
            ref.invalidate(potentialLocationsListNotifierProvider);
          case 'potential_location_converted':
            log('🔄 [CentrifugoManager] Potential location converted - '
                'invalidating list + bins');
            ref.invalidate(potentialLocationsListNotifierProvider);
            ref.invalidate(binsListProvider);
          case 'potential_location_deleted':
            log('🗑️ [CentrifugoManager] Potential location deleted - '
                'invalidating list');
            ref.invalidate(potentialLocationsListNotifierProvider);
          default:
            log('⚠️ [CentrifugoManager] Unknown company event type: $type');
        }
      });
      log('✅ [CentrifugoManager] Subscribed to company:events');
    } catch (e) {
      log('❌ [CentrifugoManager] Failed to subscribe to company:events: $e');
      // Non-fatal — app continues without real-time potential location updates
    }
  }

  /// Disconnect from Centrifugo
  void _disconnect() {
    if (!_isConnected) return;

    log('🔌 [CentrifugoManager] Disconnecting from Centrifugo...');
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _companyEventsSubscription?.cancel();
    _companyEventsSubscription = null;

    final centrifugoService = ref.read(centrifugoServiceProvider);
    centrifugoService.disconnect();
    _isConnected = false;
    log('✅ [CentrifugoManager] Disconnected from Centrifugo');
  }

  /// Subscribe to driver location updates (managers only)
  Future<void> subscribeToDriverLocation(
    String driverId,
    void Function(Map<String, dynamic> locationData) onUpdate,
  ) async {
    if (!_isConnected) {
      await _connect();
    }

    try {
      log('🔄 [CentrifugoManager] Subscribing to driver location: $driverId');
      final centrifugoService = ref.read(centrifugoServiceProvider);
      _locationSubscription = await centrifugoService.subscribeToDriverLocation(
        driverId,
        onUpdate,
      );
      log('✅ [CentrifugoManager] Subscribed to driver:location:$driverId');
    } catch (e) {
      log('❌ [CentrifugoManager] Failed to subscribe: $e');
      rethrow;
    }
  }

  /// Unsubscribe from driver location
  void unsubscribeFromDriverLocation(String driverId) {
    log('🔄 [CentrifugoManager] Unsubscribing from driver location: $driverId');
    _locationSubscription?.cancel();
    _locationSubscription = null;

    final centrifugoService = ref.read(centrifugoServiceProvider);
    final channel = 'driver:location:$driverId';
    centrifugoService.unsubscribe(channel);
    log('✅ [CentrifugoManager] Unsubscribed from $channel');
  }

  /// Check if connected
  bool get isConnected => _isConnected;
}
