import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Application-wide logging utility
///
/// Uses debugPrint() to show logs in terminal and console
/// Optionally streams logs to backend via WebSocket for debugging
class AppLogger {
  // Prevent instantiation
  AppLogger._();

  // Log levels (matching dart:developer conventions)
  static const int debug = 500;
  static const int info = 800;
  static const int warning = 900;
  static const int error = 1000;

  // WebSocket callback for remote logging (set by WebSocketService)
  static void Function(String)? _sendLogCallback;

  /// Register WebSocket callback for remote logging
  /// Call this from main() or when WebSocket connects
  static void setRemoteLogging(void Function(String) callback) {
    _sendLogCallback = callback;
  }

  /// Clear remote logging callback (when WebSocket disconnects)
  static void clearRemoteLogging() {
    _sendLogCallback = null;
  }

  /// Send log to backend via WebSocket
  static void _sendToBackend(String category, String message, int level) {
    if (_sendLogCallback == null) return;

    try {
      final logData = jsonEncode({
        'type': 'driver_log',
        'data': {
          'category': category,
          'message': message,
          'level': level,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      });
      _sendLogCallback!(logData);
    } catch (e) {
      // Silently fail - don't break app if logging fails
      debugPrint('[AppLogger] Failed to send log to backend: $e');
    }
  }

  /// Navigation-related logs (route calculation, simulation, camera updates)
  static void navigation(String message, {int level = info}) {
    debugPrint('[Navigation] $message');
    _sendToBackend('Navigation', message, level);
  }

  /// API call logs (HTTP requests, responses, errors)
  static void api(String message, {int level = info}) {
    debugPrint('[API] $message');
    _sendToBackend('API', message, level);
  }

  /// Bin management logs (bin updates, status changes)
  static void bins(String message, {int level = info}) {
    debugPrint('[Bins] $message');
    _sendToBackend('Bins', message, level);
  }

  /// Authentication logs (login, logout, session management)
  static void auth(String message, {int level = info}) {
    debugPrint('[Auth] $message');
    _sendToBackend('Auth', message, level);
  }

  /// Location services logs (GPS updates, permissions)
  static void location(String message, {int level = info}) {
    debugPrint('[Location] $message');
    _sendToBackend('Location', message, level);
  }

  /// Route calculation and optimization logs
  static void routing(String message, {int level = info}) {
    debugPrint('[Routing] $message');
    _sendToBackend('Routing', message, level);
  }

  /// Map rendering and marker updates
  static void map(String message, {int level = info}) {
    debugPrint('[Map] $message');
    _sendToBackend('Map', message, level);
  }

  /// General application logs
  static void general(String message, {int level = info}) {
    debugPrint('[App] $message');
    _sendToBackend('App', message, level);
  }

  /// Debug-level log (lowest priority, most verbose)
  static void d(String message, {String name = 'App'}) {
    debugPrint('[$name] [DEBUG] $message');
    _sendToBackend(name, '[DEBUG] $message', debug);
  }

  /// Info-level log (normal priority)
  static void i(String message, {String name = 'App'}) {
    debugPrint('[$name] [INFO] $message');
    _sendToBackend(name, '[INFO] $message', info);
  }

  /// Warning-level log (higher priority)
  static void w(String message, {String name = 'App'}) {
    debugPrint('[$name] [WARN] $message');
    _sendToBackend(name, '[WARN] $message', warning);
  }

  /// Error-level log (highest priority)
  static void e(
    String message, {
    String name = 'App',
    Object? error,
    StackTrace? stackTrace,
  }) {
    final fullMessage = error != null
        ? '$message | Error: $error'
        : message;
    debugPrint('[$name] [ERROR] $message');
    if (error != null) debugPrint('  Error: $error');
    if (stackTrace != null) debugPrint('  Stack: $stackTrace');
    _sendToBackend(name, '[ERROR] $fullMessage', AppLogger.error);
  }
}
