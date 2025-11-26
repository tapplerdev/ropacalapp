import 'package:flutter/services.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

/// Platform bridge for calling native navigation SDK methods not exposed in Flutter
class NavigationPlatformBridge {
  static const MethodChannel _channel =
      MethodChannel('com.ropacal.app/navigation');

  /// Force the navigation map to always use day mode (light theme)
  /// This bypasses the automatic night mode switching
  static Future<bool> forceDayMode() async {
    try {
      AppLogger.general('🔧 [PLATFORM] Calling native forceDayMode...');
      final result = await _channel.invokeMethod<bool>('forceDayMode');
      AppLogger.general('🔧 [PLATFORM] forceDayMode result: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      AppLogger.general('❌ [PLATFORM] forceDayMode failed: ${e.message}');
      return false;
    } catch (e) {
      AppLogger.general('❌ [PLATFORM] forceDayMode error: $e');
      return false;
    }
  }

  /// Check if the native platform bridge is available
  static Future<bool> isPlatformBridgeAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
