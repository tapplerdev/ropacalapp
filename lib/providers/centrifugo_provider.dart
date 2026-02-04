import 'dart:async';
import 'dart:developer';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/services/centrifugo_service.dart';
import 'package:ropacalapp/core/enums/user_role.dart';
import 'package:ropacalapp/providers/auth_provider.dart';

part 'centrifugo_provider.g.dart';

/// Centrifugo connection lifecycle manager
///
/// Automatically connects when ANY user logs in (drivers AND managers)
/// - Drivers: Publish location to driver:location:{id} channel
/// - Managers: Subscribe to driver location channels for real-time tracking
@riverpod
class CentrifugoManager extends _$CentrifugoManager {
  StreamSubscription? _locationSubscription;
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
      log('🔌 [CentrifugoManager] User detected (role=${user.role}, id=${user.id}) - connecting to Centrifugo');
      await _connect();
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
      log('🔌 [CentrifugoManager] Connecting to Centrifugo...');
      final centrifugoService = ref.read(centrifugoServiceProvider);
      await centrifugoService.connect();
      _isConnected = true;
      log('✅ [CentrifugoManager] Connected to Centrifugo');
    } catch (e) {
      log('❌ [CentrifugoManager] Failed to connect: $e');
      rethrow;
    }
  }

  /// Disconnect from Centrifugo
  void _disconnect() {
    if (!_isConnected) return;

    log('🔌 [CentrifugoManager] Disconnecting from Centrifugo...');
    _locationSubscription?.cancel();
    _locationSubscription = null;

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
