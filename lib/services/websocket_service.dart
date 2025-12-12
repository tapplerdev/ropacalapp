import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/constants/api_constants.dart';

/// WebSocket Service for real-time shift updates
class WebSocketService {
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _reconnectDelay = Duration(seconds: 5);

  // Callbacks for handling messages
  Function(Map<String, dynamic>)? onRouteAssigned;
  Function(Map<String, dynamic>)? onShiftUpdate;
  Function(Map<String, dynamic>)? onShiftDeleted;
  Function(Map<String, dynamic>)? onDriverLocationUpdate;
  Function(Map<String, dynamic>)? onDriverShiftChange;
  Function()? onConnected;
  Function()? onDisconnected;

  /// Connect to WebSocket server
  Future<void> connect(String token) async {
    if (_isConnected) {
      AppLogger.general(
        'WebSocket already connected',
        level: AppLogger.warning,
      );
      return;
    }

    try {
      // Auto-derived from ApiConstants.baseUrl
      // Automatically converts http/https to ws/wss
      final wsUrl = '${ApiConstants.wsUrl}?token=$token';

      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.general('🔌 WEBSOCKET CONNECTION ATTEMPT');
      AppLogger.general('   URL: $wsUrl');
      AppLogger.general('   Token preview: ${token.substring(0, 20)}...');
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: () {
          AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          AppLogger.general('🔴 WEBSOCKET DISCONNECTED');
          AppLogger.general('   Reason: Server closed connection (onDone called)');
          AppLogger.general('   Was connected: $_isConnected');
          AppLogger.general('   Close code: ${_channel?.closeCode}');
          AppLogger.general('   Close reason: ${_channel?.closeReason}');
          AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          _handleDisconnect();
        },
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      onConnected?.call();

      // Register AppLogger remote logging callback
      AppLogger.setRemoteLogging(sendMessage);
      AppLogger.general('✅ Remote logging enabled - logs will stream to backend');

      // Start heartbeat
      _startHeartbeat();

      AppLogger.general('✅ WebSocket stream listener attached');
      AppLogger.general('   Waiting for messages from server...');
    } catch (e) {
      AppLogger.general(
        '❌ WebSocket connection error: $e',
        level: AppLogger.error,
      );
      _scheduleReconnect(token);
    }
  }

  /// Handle incoming WebSocket message
  void _handleMessage(dynamic message) {
    try {
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      AppLogger.general('🔵 RAW WEBSOCKET MESSAGE RECEIVED');
      AppLogger.general('   Raw message type: ${message.runtimeType}');
      AppLogger.general('   Raw message preview: ${message.toString().substring(0, message.toString().length > 100 ? 100 : message.toString().length)}...');

      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      AppLogger.general('   Parsed message type: $type');
      AppLogger.general('   Full data keys: ${data.keys.toList()}');

      switch (type) {
        case 'pong':
          // Heartbeat response - do nothing
          AppLogger.general('   ✅ Pong received (heartbeat)');
          break;
        case 'route_assigned':
          AppLogger.general('   📨 Route assigned callback: ${onRouteAssigned != null ? "SET" : "NULL"}');
          onRouteAssigned?.call(data['data'] as Map<String, dynamic>);
          break;
        case 'shift_update':
          AppLogger.general('   📨 Shift update callback: ${onShiftUpdate != null ? "SET" : "NULL"}');
          onShiftUpdate?.call(data['data'] as Map<String, dynamic>);
          break;
        case 'shift_deleted':
          AppLogger.general('   🗑️  Shift deleted callback: ${onShiftDeleted != null ? "SET" : "NULL"}');
          onShiftDeleted?.call(data['data'] as Map<String, dynamic>);
          break;
        case 'driver_location_update':
          // Manager-only: Update driver location on map
          AppLogger.general('   📍 DRIVER LOCATION UPDATE MESSAGE');
          AppLogger.general('   Callback status: ${onDriverLocationUpdate != null ? "✅ SET" : "❌ NULL"}');
          AppLogger.general('   Location data: ${data['data']}');

          if (onDriverLocationUpdate == null) {
            AppLogger.general('   ❌❌❌ CRITICAL: onDriverLocationUpdate callback is NULL!');
            AppLogger.general('   ❌ This means the callback was never registered!');
          } else {
            AppLogger.general('   ✅ Calling onDriverLocationUpdate callback...');
            onDriverLocationUpdate?.call(data['data'] as Map<String, dynamic>);
            AppLogger.general('   ✅ Callback executed');
          }
          break;
        case 'driver_shift_change':
          // Manager-only: Driver shift state changed (started, ended, assigned)
          AppLogger.general('   🚦 DRIVER SHIFT CHANGE MESSAGE');
          AppLogger.general('   Callback status: ${onDriverShiftChange != null ? "✅ SET" : "❌ NULL"}');
          AppLogger.general('   Shift change data: ${data['data']}');
          onDriverShiftChange?.call(data['data'] as Map<String, dynamic>);
          break;
        default:
          AppLogger.general(
            '   ⚠️  Unknown WebSocket message type: $type',
            level: AppLogger.warning,
          );
      }
      AppLogger.general('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e, stack) {
      AppLogger.general(
        '❌ Error parsing WebSocket message: $e',
        level: AppLogger.error,
      );
      AppLogger.general('   Stack trace: $stack');
    }
  }

  /// Handle WebSocket error
  void _handleError(dynamic error) {
    AppLogger.general('WebSocket error: $error', level: AppLogger.error);
    _isConnected = false;
    onDisconnected?.call();
  }

  /// Handle WebSocket disconnect
  void _handleDisconnect() {
    final wasConnected = _isConnected;
    _isConnected = false;
    _stopHeartbeat();
    onDisconnected?.call();

    // Auto-reconnect if we were previously connected
    // This handles server-initiated disconnects
    if (wasConnected) {
      AppLogger.general('⚠️  Auto-reconnect scheduled after unexpected disconnect');
      // Note: We need the token to reconnect, but we don't have it here
      // The auth provider should handle reconnection
    }
  }

  /// Start heartbeat timer to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_isConnected) {
        _sendPing();
      }
    });
  }

  /// Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Send ping to server
  void _sendPing() {
    try {
      final message = jsonEncode({
        'type': 'ping',
        'timestamp': DateTime.now().toIso8601String(),
      });
      _channel?.sink.add(message);
    } catch (e) {
      AppLogger.general('Error sending ping: $e', level: AppLogger.error);
    }
  }

  /// Send a message through WebSocket
  void sendMessage(String message) {
    if (!_isConnected || _channel == null) {
      AppLogger.general(
        'Cannot send message: WebSocket not connected',
        level: AppLogger.warning,
      );
      return;
    }

    try {
      _channel!.sink.add(message);
    } catch (e) {
      AppLogger.general(
        'Error sending WebSocket message: $e',
        level: AppLogger.error,
      );
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect(String token) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      AppLogger.general(
        'Max reconnect attempts reached',
        level: AppLogger.error,
      );
      return;
    }

    _reconnectAttempts++;
    AppLogger.general(
      'Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      connect(token);
    });
  }

  /// Disconnect from WebSocket
  void disconnect() {
    AppLogger.general('Disconnecting WebSocket');
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;

    // Clear remote logging callback
    AppLogger.clearRemoteLogging();
  }

  /// Check if connected
  bool get isConnected => _isConnected;
}
