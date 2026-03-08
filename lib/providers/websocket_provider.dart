import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/services/websocket_service.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/providers/driver_live_position_provider.dart';
import 'package:ropacalapp/models/driver_location.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

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

  // Manager-only: Update driver location on map
  service.onDriverLocationUpdate = (data) {
    try {
      AppLogger.general('📡 WebSocket Provider: onDriverLocationUpdate callback fired');
      AppLogger.general('   Raw data: $data');

      final driversNotifier = ref.read(driversNotifierProvider.notifier);
      final location = DriverLocation.fromJson(data);

      AppLogger.general('   Parsed location: driver=${location.driverId}, lat=${location.latitude}, lng=${location.longitude}');
      AppLogger.general('   Calling driversNotifier.updateDriverLocation()...');

      driversNotifier.updateDriverLocation(location);

      // Also broadcast raw position for polyline system + follow-mode camera
      ref.read(driverLivePositionsProvider.notifier).updatePosition(location);

      AppLogger.general('   ✅ updateDriverLocation() call completed');
    } catch (e, stack) {
      AppLogger.general('   ❌ Error in onDriverLocationUpdate callback: $e', level: AppLogger.error);
      AppLogger.general('   Stack trace: $stack');
    }
  };

  return service;
}
