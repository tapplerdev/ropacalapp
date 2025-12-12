import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

/// Manages app session state for smart initialization and instant resume
///
/// Tracks when the app was last active to determine appropriate startup behavior:
/// - < 2 min: Instant resume (skip validation)
/// - 2-10 min: Fast validation with timeout
/// - > 10 min: Full validation
class SessionManager {
  SessionManager._();

  static const _storage = FlutterSecureStorage();
  static const _lastActiveKey = 'session_last_active';

  // Session timeouts
  static const _instantResumeTimeout = Duration(minutes: 2);
  static const _quickRestoreTimeout = Duration(minutes: 10);

  static DateTime? _lastActiveTime;
  static bool _initialized = false;

  /// Initialize session manager by loading last active time
  static Future<void> initialize() async {
    if (_initialized) return;

    final lastActiveStr = await _storage.read(key: _lastActiveKey);
    if (lastActiveStr != null) {
      try {
        _lastActiveTime = DateTime.parse(lastActiveStr);
        AppLogger.general(
          '📅 Session restored: Last active ${_formatDuration(DateTime.now().difference(_lastActiveTime!))} ago',
        );
      } catch (e) {
        AppLogger.general(
          '⚠️  Failed to parse last active time: $e',
          level: AppLogger.warning,
        );
        _lastActiveTime = null;
      }
    } else {
      AppLogger.general('📅 No previous session found (first launch)');
    }

    _initialized = true;
  }

  /// Check if app has an active session (< 2 minutes since last active)
  /// Returns true if we can skip validation and resume instantly
  static bool get hasActiveSession {
    if (_lastActiveTime == null) return false;

    final timeSinceActive = DateTime.now().difference(_lastActiveTime!);
    final isActive = timeSinceActive < _instantResumeTimeout;

    if (isActive) {
      AppLogger.general(
        '✅ Active session detected (${_formatDuration(timeSinceActive)} old)',
      );
    }

    return isActive;
  }

  /// Check if app can do quick restore (< 10 minutes since last active)
  /// Returns true if we should try fast validation with timeout
  static bool get canQuickRestore {
    if (_lastActiveTime == null) return false;

    final timeSinceActive = DateTime.now().difference(_lastActiveTime!);
    final canRestore = timeSinceActive < _quickRestoreTimeout;

    if (canRestore && !hasActiveSession) {
      AppLogger.general(
        '⚡ Quick restore available (${_formatDuration(timeSinceActive)} old)',
      );
    }

    return canRestore;
  }

  /// Get session age category for logging
  static SessionAge get sessionAge {
    if (_lastActiveTime == null) {
      return SessionAge.none;
    }

    final timeSinceActive = DateTime.now().difference(_lastActiveTime!);

    if (timeSinceActive < _instantResumeTimeout) {
      return SessionAge.instant;
    } else if (timeSinceActive < _quickRestoreTimeout) {
      return SessionAge.quick;
    } else {
      return SessionAge.cold;
    }
  }

  /// Update last active timestamp
  static Future<void> updateLastActive() async {
    _lastActiveTime = DateTime.now();
    await _storage.write(
      key: _lastActiveKey,
      value: _lastActiveTime!.toIso8601String(),
    );

    AppLogger.general('📅 Session timestamp updated');
  }

  /// Clear session (call on logout)
  static Future<void> clearSession() async {
    _lastActiveTime = null;
    await _storage.delete(key: _lastActiveKey);
    AppLogger.general('📅 Session cleared');
  }

  /// Format duration for human-readable logs
  static String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
  }
}

/// Session age categories
enum SessionAge {
  none, // No previous session
  instant, // < 2 min: Instant resume
  quick, // 2-10 min: Quick restore
  cold, // > 10 min: Cold start
}
