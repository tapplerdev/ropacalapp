import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:centrifuge/centrifuge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ropacalapp/core/services/api_service.dart';
import 'package:ropacalapp/providers/api_provider.dart';

/// Centrifugo real-time messaging service for driver location streaming
///
/// Architecture:
/// - WebSocket connection to Centrifugo server
/// - JWT token authentication (fetched from /api/centrifugo/token)
/// - Three namespaces: driver, shift, manager
/// - Channel patterns:
///   - driver:location:{driverId} - Driver location updates
///   - shift:updates:{shiftId} - Shift status updates
///   - manager:notifications:{managerId} - Manager notifications
class CentrifugoService {
  static const String _websocketUrl =
      'wss://binly-centrifugo-service-production.up.railway.app/connection/websocket';

  Client? _client;
  final Map<String, Subscription> _subscriptions = {};
  final ApiService _apiService;

  CentrifugoService(this._apiService);

  /// Initialize Centrifugo client and establish WebSocket connection
  Future<void> connect() async {
    log('🔵 [Centrifugo] connect() called');

    if (_client != null) {
      log('🔌 [Centrifugo] Already connected (client exists)');
      return;
    }

    try {
      log('🔌 [Centrifugo] Fetching connection token from backend...');

      // Fetch JWT token from backend
      final tokenResponse = await _apiService.getCentrifugoToken();
      final token = tokenResponse['token'] as String;
      final expiresAt = tokenResponse['expires_at'] as int;

      log('🔑 [Centrifugo] Token received (expires: ${DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000)})');

      // Create Centrifuge client with production configuration
      _client = createClient(
        _websocketUrl,
        ClientConfig(
          token: token,
          timeout: const Duration(seconds: 30),
          // Reconnection settings (exponential backoff with jitter)
          minReconnectDelay: const Duration(milliseconds: 500), // Start fast
          maxReconnectDelay: const Duration(seconds: 20), // Cap at 20s
          // Ping configuration for faster dead connection detection
          maxServerPingDelay: const Duration(seconds: 10),
          // Token refresh callback - called when token is expiring
          getToken: (event) async {
            log('🔑 [Centrifugo] Token expiring, fetching fresh token from backend...');
            log('🔑 [Centrifugo] Refresh attempt triggered by SDK');

            try {
              final response = await _apiService.getCentrifugoToken();
              final newToken = response['token'] as String;
              final expiresAt = response['expires_at'] as int;

              log('✅ [Centrifugo] Token refreshed successfully');
              log('🔑 [Centrifugo] New token expires: ${DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000)}');

              return newToken;
            } catch (e) {
              log('❌ [Centrifugo] Token refresh FAILED: $e');

              // Check if it's an authentication error (401)
              if (e.toString().contains('Authentication expired') ||
                  e.toString().contains('401')) {
                log('🔴 [Centrifugo] JWT token is expired - user needs to re-login');
                log('💡 [Centrifugo] WebSocket will disconnect and wait for user re-authentication');
              } else if (e.toString().contains('Auth token not ready')) {
                log('⚠️  [Centrifugo] Auth token not loaded - possible race condition');
              } else {
                log('⚠️  [Centrifugo] Network or server error - will retry with backoff');
              }

              // Rethrow to let Centrifuge SDK handle reconnection with exponential backoff
              rethrow;
            }
          },
        ),
      );

      // Setup state change listeners
      _client!.connecting.listen((event) {
        log('🟡 [Centrifugo] Connecting... (${event.code}: ${event.reason})');
      });

      _client!.connected.listen((event) {
        log('🟢 [Centrifugo] Connected! (client: ${event.client})');
      });

      _client!.disconnected.listen((event) {
        log('⚫ [Centrifugo] Disconnected (code: ${event.code}, reason: ${event.reason})');
      });

      _client!.error.listen((event) {
        log('❌ [Centrifugo] Error: ${event.error}');
      });

      // Connect to Centrifugo
      await _client!.connect();

      log('✅ [Centrifugo] Connection initiated');
    } catch (e) {
      log('❌ [Centrifugo] Failed to connect: $e');
      rethrow;
    }
  }

  /// Subscribe to driver location updates
  ///
  /// Channel: driver:location:{driverId}
  ///
  /// Authorization:
  /// - Driver can subscribe to their own location channel
  /// - Managers can subscribe to any driver's location channel
  Future<StreamSubscription> subscribeToDriverLocation(
    String driverId,
    void Function(Map<String, dynamic> data) onLocationUpdate,
  ) async {
    final channel = 'driver:location:$driverId';

    if (_client == null) {
      throw StateError('Centrifugo client not connected. Call connect() first.');
    }

    // Check if already subscribed
    if (_subscriptions.containsKey(channel)) {
      log('⚠️ [Centrifugo] Already subscribed to $channel');
      return _subscriptions[channel]!.publication.listen((event) {
        final data = jsonDecode(utf8.decode(event.data));
        onLocationUpdate(data as Map<String, dynamic>);
      });
    }

    log('🔄 [Centrifugo] Subscribing to $channel...');

    // Create subscription
    final subscription = _client!.newSubscription(channel);

    // Setup state listeners
    subscription.subscribing.listen((event) {
      log('🔄 [Centrifugo] Subscribing to $channel... (${event.code}: ${event.reason})');
    });

    subscription.subscribed.listen((event) {
      log('✅ [Centrifugo] Subscribed to $channel');
    });

    subscription.unsubscribed.listen((event) {
      log('❌ [Centrifugo] Unsubscribed from $channel (${event.code}: ${event.reason})');
      _subscriptions.remove(channel);
    });

    subscription.error.listen((event) {
      log('❌ [Centrifugo] Subscription error on $channel: ${event.error}');
    });

    // Store subscription
    _subscriptions[channel] = subscription;

    // Subscribe
    await subscription.subscribe();

    // Return stream subscription for location updates
    return subscription.publication.listen((event) {
      log('📍 [Centrifugo] Location update received on $channel');
      final data = jsonDecode(utf8.decode(event.data));
      onLocationUpdate(data as Map<String, dynamic>);
    });
  }

  /// Subscribe to shift updates
  ///
  /// Channel: shift:updates:{shiftId}
  ///
  /// Authorization:
  /// - Driver assigned to shift can subscribe
  /// - Managers can subscribe to any shift
  Future<StreamSubscription> subscribeToShiftUpdates(
    String shiftId,
    void Function(Map<String, dynamic> data) onUpdate,
  ) async {
    final channel = 'shift:updates:$shiftId';

    if (_client == null) {
      throw StateError('Centrifugo client not connected. Call connect() first.');
    }

    if (_subscriptions.containsKey(channel)) {
      log('⚠️ [Centrifugo] Already subscribed to $channel');
      return _subscriptions[channel]!.publication.listen((event) {
        final data = jsonDecode(utf8.decode(event.data));
        onUpdate(data as Map<String, dynamic>);
      });
    }

    log('🔄 [Centrifugo] Subscribing to $channel...');

    final subscription = _client!.newSubscription(channel);

    subscription.subscribing.listen((event) {
      log('🔄 [Centrifugo] Subscribing to $channel...');
    });

    subscription.subscribed.listen((event) {
      log('✅ [Centrifugo] Subscribed to $channel');
    });

    subscription.unsubscribed.listen((event) {
      log('❌ [Centrifugo] Unsubscribed from $channel');
      _subscriptions.remove(channel);
    });

    _subscriptions[channel] = subscription;
    await subscription.subscribe();

    return subscription.publication.listen((event) {
      log('🔔 [Centrifugo] Shift update received on $channel');
      final data = jsonDecode(utf8.decode(event.data));
      onUpdate(data as Map<String, dynamic>);
    });
  }

  /// Subscribe to manager notifications
  ///
  /// Channel: manager:notifications:{managerId}
  ///
  /// Authorization:
  /// - Only the manager themselves can subscribe
  Future<StreamSubscription> subscribeToManagerNotifications(
    String managerId,
    void Function(Map<String, dynamic> data) onNotification,
  ) async {
    final channel = 'manager:notifications:$managerId';

    if (_client == null) {
      throw StateError('Centrifugo client not connected. Call connect() first.');
    }

    if (_subscriptions.containsKey(channel)) {
      log('⚠️ [Centrifugo] Already subscribed to $channel');
      return _subscriptions[channel]!.publication.listen((event) {
        final data = jsonDecode(utf8.decode(event.data));
        onNotification(data as Map<String, dynamic>);
      });
    }

    log('🔄 [Centrifugo] Subscribing to $channel...');

    final subscription = _client!.newSubscription(channel);

    subscription.subscribing.listen((event) {
      log('🔄 [Centrifugo] Subscribing to $channel...');
    });

    subscription.subscribed.listen((event) {
      log('✅ [Centrifugo] Subscribed to $channel');
    });

    subscription.unsubscribed.listen((event) {
      log('❌ [Centrifugo] Unsubscribed from $channel');
      _subscriptions.remove(channel);
    });

    _subscriptions[channel] = subscription;
    await subscription.subscribe();

    return subscription.publication.listen((event) {
      log('🔔 [Centrifugo] Manager notification received on $channel');
      final data = jsonDecode(utf8.decode(event.data));
      onNotification(data as Map<String, dynamic>);
    });
  }

  /// Unsubscribe from a channel
  void unsubscribe(String channel) {
    final subscription = _subscriptions[channel];
    if (subscription != null) {
      log('🔄 [Centrifugo] Unsubscribing from $channel...');
      subscription.unsubscribe();
      _subscriptions.remove(channel);
    } else {
      log('⚠️ [Centrifugo] No subscription found for $channel');
    }
  }

  /// Unsubscribe from all channels
  void unsubscribeAll() {
    log('🔄 [Centrifugo] Unsubscribing from all channels...');
    for (final subscription in _subscriptions.values) {
      subscription.unsubscribe();
    }
    _subscriptions.clear();
    log('✅ [Centrifugo] Unsubscribed from all channels');
  }

  /// Disconnect from Centrifugo
  void disconnect() {
    if (_client == null) {
      log('⚠️ [Centrifugo] Not connected');
      return;
    }

    log('🔌 [Centrifugo] Disconnecting...');
    unsubscribeAll();
    _client!.disconnect();
    _client = null;
    log('✅ [Centrifugo] Disconnected');
  }

  /// Get connection state
  State? get state => _client?.state;

  /// Check if connected
  bool get isConnected => _client?.state == State.connected;

  /// Get list of active subscriptions
  List<String> get activeChannels => _subscriptions.keys.toList();

  /// Publish location data to Centrifugo channel
  /// This publishes directly to Centrifugo, which triggers the publish proxy
  /// Backend flow: Centrifugo receives → calls publish proxy → saves to Redis → snaps to roads → broadcasts
  Future<void> publish(String channel, Map<String, dynamic> data) async {
    if (_client == null) {
      log('❌ [Centrifugo] Cannot publish - client is null!');
      throw StateError('Centrifugo client not connected. Call connect() first.');
    }

    log('🔌 [Centrifugo] Client state: ${_client!.state}');

    try {
      log('📤 [Centrifugo] Publishing to $channel...');
      log('📦 [Centrifugo] Data: $data');
      await _client!.publish(channel, utf8.encode(jsonEncode(data)));
      log('✅ [Centrifugo] Published to $channel successfully');
    } catch (e) {
      log('❌ [Centrifugo] Failed to publish to $channel: $e');
      rethrow;
    }
  }

  /// DEPRECATED: Location publishing now handled by backend
  /// Driver sends location to backend via POST /api/driver/location
  /// Backend handles: DB save → OSRM snap → Centrifugo publish
  ///
  /// This method is kept for backwards compatibility but should not be used.
  @Deprecated('Use POST /api/driver/location instead')
  Future<void> publishDriverLocation(
    String driverId,
    Map<String, dynamic> locationData,
  ) async {
    log('⚠️ [Centrifugo] publishDriverLocation is deprecated. Use backend endpoint instead.');
    // No-op - backend handles this now
  }
}

/// Riverpod provider for CentrifugoService
final centrifugoServiceProvider = Provider<CentrifugoService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CentrifugoService(apiService);
});
