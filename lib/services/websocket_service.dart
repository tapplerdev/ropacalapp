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

      AppLogger.general('Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      onConnected?.call();

      // Start heartbeat
      _startHeartbeat();

      AppLogger.general('WebSocket connected successfully');
    } catch (e) {
      AppLogger.general(
        'WebSocket connection error: $e',
        level: AppLogger.error,
      );
      _scheduleReconnect(token);
    }
  }

  /// Handle incoming WebSocket message
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      AppLogger.general('WebSocket message received: $type');

      switch (type) {
        case 'pong':
          // Heartbeat response - do nothing
          break;
        case 'route_assigned':
          onRouteAssigned?.call(data['data'] as Map<String, dynamic>);
          break;
        case 'shift_update':
          onShiftUpdate?.call(data['data'] as Map<String, dynamic>);
          break;
        case 'shift_deleted':
          onShiftDeleted?.call(data['data'] as Map<String, dynamic>);
          break;
        default:
          AppLogger.general(
            'Unknown WebSocket message type: $type',
            level: AppLogger.warning,
          );
      }
    } catch (e) {
      AppLogger.general(
        'Error parsing WebSocket message: $e',
        level: AppLogger.error,
      );
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
    AppLogger.general('WebSocket disconnected');
    _isConnected = false;
    _stopHeartbeat();
    onDisconnected?.call();
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
  }

  /// Check if connected
  bool get isConnected => _isConnected;
}
