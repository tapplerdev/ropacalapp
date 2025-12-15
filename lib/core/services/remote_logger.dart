import 'dart:convert';
import 'package:ropacalapp/providers/api_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Remote logger that sends diagnostic logs to Railway backend
/// Use this for critical debugging when local logs aren't enough
class RemoteLogger {
  final ApiService _apiService;

  RemoteLogger(this._apiService);

  /// Send diagnostic log to backend
  /// Include timestamp, context, and all relevant state
  Future<void> log({
    required String context,
    required String message,
    Map<String, dynamic>? data,
    String level = 'INFO',
  }) async {
    try {
      final payload = {
        'timestamp': DateTime.now().toIso8601String(),
        'context': context,
        'level': level,
        'message': message,
        'data': data ?? {},
        'platform': 'flutter_ios', // Could make this dynamic
      };

      // Send to backend logging endpoint
      // Note: Don't await - fire and forget to avoid blocking UI
      _apiService.post('/api/logs/diagnostic', payload).catchError((e) {
        // Silently fail - we don't want logging to crash the app
        print('❌ Failed to send remote log: $e');
      });
    } catch (e) {
      // Silently fail
      print('❌ Remote logger error: $e');
    }
  }

  /// Log app lifecycle event (launch, resume, pause)
  Future<void> logLifecycle(String event, {Map<String, dynamic>? data}) async {
    await log(
      context: 'APP_LIFECYCLE',
      message: event,
      data: data,
      level: 'INFO',
    );
  }

  /// Log shift state change
  Future<void> logShiftState({
    required String status,
    required int routeBins,
    required int completedBins,
    required String? routeId,
    Map<String, dynamic>? additionalData,
  }) async {
    await log(
      context: 'SHIFT_STATE',
      message: 'Shift state update',
      data: {
        'status': status,
        'route_bins': routeBins,
        'completed_bins': completedBins,
        'route_id': routeId,
        ...?additionalData,
      },
      level: 'INFO',
    );
  }

  /// Log location state
  Future<void> logLocation({
    required bool hasValue,
    double? latitude,
    double? longitude,
    double? accuracy,
    int? ageSeconds,
    Map<String, dynamic>? additionalData,
  }) async {
    await log(
      context: 'LOCATION_STATE',
      message: 'Location state update',
      data: {
        'has_value': hasValue,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'age_seconds': ageSeconds,
        ...?additionalData,
      },
      level: 'INFO',
    );
  }

  /// Log navigation state
  Future<void> logNavigation({
    required String action,
    required String currentPage,
    Map<String, dynamic>? additionalData,
  }) async {
    await log(
      context: 'NAVIGATION',
      message: action,
      data: {
        'current_page': currentPage,
        ...?additionalData,
      },
      level: 'INFO',
    );
  }

  /// Log error with full context
  Future<void> logError({
    required String context,
    required String error,
    String? stackTrace,
    Map<String, dynamic>? additionalData,
  }) async {
    await log(
      context: context,
      message: error,
      data: {
        'stack_trace': stackTrace,
        ...?additionalData,
      },
      level: 'ERROR',
    );
  }
}

/// Provider for remote logger
final remoteLoggerProvider = Provider<RemoteLogger>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RemoteLogger(apiService);
});
