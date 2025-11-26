import 'package:flutter/foundation.dart';

/// Application-wide logging utility
///
/// Uses debugPrint() to show logs in terminal and console
/// Logs can be filtered by name prefix
class AppLogger {
  // Prevent instantiation
  AppLogger._();

  // Log levels (matching dart:developer conventions)
  static const int debug = 500;
  static const int info = 800;
  static const int warning = 900;
  static const int error = 1000;

  /// Navigation-related logs (route calculation, simulation, camera updates)
  static void navigation(String message, {int level = info}) {
    debugPrint('[Navigation] $message');
  }

  /// API call logs (HTTP requests, responses, errors)
  static void api(String message, {int level = info}) {
    debugPrint('[API] $message');
  }

  /// Bin management logs (bin updates, status changes)
  static void bins(String message, {int level = info}) {
    debugPrint('[Bins] $message');
  }

  /// Authentication logs (login, logout, session management)
  static void auth(String message, {int level = info}) {
    debugPrint('[Auth] $message');
  }

  /// Location services logs (GPS updates, permissions)
  static void location(String message, {int level = info}) {
    debugPrint('[Location] $message');
  }

  /// Route calculation and optimization logs
  static void routing(String message, {int level = info}) {
    debugPrint('[Routing] $message');
  }

  /// Map rendering and marker updates
  static void map(String message, {int level = info}) {
    debugPrint('[Map] $message');
  }

  /// General application logs
  static void general(String message, {int level = info}) {
    debugPrint('[App] $message');
  }

  /// Debug-level log (lowest priority, most verbose)
  static void d(String message, {String name = 'App'}) {
    debugPrint('[$name] [DEBUG] $message');
  }

  /// Info-level log (normal priority)
  static void i(String message, {String name = 'App'}) {
    debugPrint('[$name] [INFO] $message');
  }

  /// Warning-level log (higher priority)
  static void w(String message, {String name = 'App'}) {
    debugPrint('[$name] [WARN] $message');
  }

  /// Error-level log (highest priority)
  static void e(
    String message, {
    String name = 'App',
    Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint('[$name] [ERROR] $message');
    if (error != null) debugPrint('  Error: $error');
    if (stackTrace != null) debugPrint('  Stack: $stackTrace');
  }
}
