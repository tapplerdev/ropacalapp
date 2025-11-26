import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/services/websocket_service.dart';
import 'package:ropacalapp/providers/shift_provider.dart';

part 'websocket_provider.g.dart';

/// Provider for WebSocket service
@riverpod
WebSocketService webSocketService(WebSocketServiceRef ref) {
  final service = WebSocketService();

  // Set up callbacks to update shift state when WebSocket messages arrive
  service.onRouteAssigned = (data) {
    final shiftNotifier = ref.read(shiftNotifierProvider.notifier);
    // Refresh shift from backend when route is assigned
    shiftNotifier.refreshShift();
  };

  service.onShiftUpdate = (data) {
    final shiftNotifier = ref.read(shiftNotifierProvider.notifier);
    // Update shift state directly from WebSocket data (faster and more reliable)
    shiftNotifier.updateFromWebSocket(data);
  };

  return service;
}
