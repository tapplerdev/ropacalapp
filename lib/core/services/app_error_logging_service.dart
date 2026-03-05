import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Service for logging app errors to the backend for diagnostics
/// Handles navigation errors, GPS issues, and other critical failures
class AppErrorLoggingService {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// Log an error to the backend
  ///
  /// [context] - Error context (e.g., "navigation", "gps", "sync", "map_load")
  /// [errorType] - Categorized error type (e.g., "invalid_waypoints", "gps_unavailable")
  /// [errorMessage] - Human-readable error description
  /// [severity] - Error severity: "critical", "error", "warning", or "info"
  /// [driverId] - Optional driver ID
  /// [shiftId] - Optional shift ID
  /// [taskId] - Optional task ID
  /// [lastGPSLatitude] - Optional last known GPS latitude
  /// [lastGPSLongitude] - Optional last known GPS longitude
  /// [stackTrace] - Optional stack trace for debugging
  /// [metadata] - Optional additional context (waypoints, route details, etc.)
  static Future<void> logError({
    required String context,
    required String errorType,
    required String errorMessage,
    required String severity,
    String? driverId,
    String? shiftId,
    String? taskId,
    double? lastGPSLatitude,
    double? lastGPSLongitude,
    String? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get device info
      final deviceInfo = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();

      // Prepare request body
      final requestBody = {
        'driver_id': driverId,
        'shift_id': shiftId,
        'task_id': taskId,
        'log_timestamp': DateTime.now().millisecondsSinceEpoch,
        'context': context,
        'error_type': errorType,
        'error_message': errorMessage,
        'severity': severity,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'app_version': packageInfo.version,
        'os_version': deviceInfo['os_version'],
        'device_info': deviceInfo['device_model'],
        'last_gps_latitude': lastGPSLatitude,
        'last_gps_longitude': lastGPSLongitude,
        'stack_trace': stackTrace,
        'metadata': metadata,
      };

      // Remove null values
      requestBody.removeWhere((key, value) => value == null);

      // Send to backend
      final response = await http.post(
        Uri.parse('$_baseUrl/api/logs/app-error'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        debugPrint('✅ Error logged successfully: $errorType');
      } else {
        debugPrint('⚠️ Failed to log error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // Don't throw - logging errors shouldn't crash the app
      debugPrint('❌ Error logging service failed: $e');
    }
  }

  /// Convenience method for logging navigation errors
  static Future<void> logNavigationError({
    required String errorType,
    required String errorMessage,
    String? driverId,
    String? shiftId,
    String? taskId,
    double? lastGPSLatitude,
    double? lastGPSLongitude,
    List<Map<String, dynamic>>? waypoints,
    String? routeStatus,
    String? stackTrace,
  }) async {
    final metadata = <String, dynamic>{};
    if (waypoints != null) metadata['waypoints'] = waypoints;
    if (routeStatus != null) metadata['route_status'] = routeStatus;

    await logError(
      context: 'navigation',
      errorType: errorType,
      errorMessage: errorMessage,
      severity: 'error',
      driverId: driverId,
      shiftId: shiftId,
      taskId: taskId,
      lastGPSLatitude: lastGPSLatitude,
      lastGPSLongitude: lastGPSLongitude,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Convenience method for logging critical navigation errors
  static Future<void> logCriticalNavigationError({
    required String errorType,
    required String errorMessage,
    String? driverId,
    String? shiftId,
    String? taskId,
    double? lastGPSLatitude,
    double? lastGPSLongitude,
    List<Map<String, dynamic>>? waypoints,
    String? routeStatus,
    String? stackTrace,
  }) async {
    final metadata = <String, dynamic>{};
    if (waypoints != null) metadata['waypoints'] = waypoints;
    if (routeStatus != null) metadata['route_status'] = routeStatus;

    await logError(
      context: 'navigation',
      errorType: errorType,
      errorMessage: errorMessage,
      severity: 'critical',
      driverId: driverId,
      shiftId: shiftId,
      taskId: taskId,
      lastGPSLatitude: lastGPSLatitude,
      lastGPSLongitude: lastGPSLongitude,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Convenience method for logging GPS errors
  static Future<void> logGPSError({
    required String errorType,
    required String errorMessage,
    String severity = 'error',
    String? driverId,
    String? shiftId,
    double? lastGPSLatitude,
    double? lastGPSLongitude,
    String? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    await logError(
      context: 'gps',
      errorType: errorType,
      errorMessage: errorMessage,
      severity: severity,
      driverId: driverId,
      shiftId: shiftId,
      lastGPSLatitude: lastGPSLatitude,
      lastGPSLongitude: lastGPSLongitude,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Get device information for error logging
  static Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();

    if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      return {
        'device_model': '${iosInfo.name} ${iosInfo.model}',
        'os_version': 'iOS ${iosInfo.systemVersion}',
      };
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      return {
        'device_model': '${androidInfo.manufacturer} ${androidInfo.model}',
        'os_version': 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})',
      };
    }

    return {
      'device_model': 'Unknown',
      'os_version': 'Unknown',
    };
  }
}
