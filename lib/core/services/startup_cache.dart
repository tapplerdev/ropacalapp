import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny JSON snapshot cache backing the cache-first startup path: the last
/// good bins/drivers/user payloads are persisted so a returning launch can
/// render instantly and refresh in the background, instead of blocking the
/// first useful frame on the network.
class StartupCache {
  StartupCache._();

  static const userKey = 'startup_cache_user';
  static const binsKey = 'startup_cache_bins';
  static const driversKey = 'startup_cache_drivers';

  /// Snapshots older than this are ignored — stale enough that rendering
  /// them first would mislead more than it helps.
  static const _maxAge = Duration(hours: 24);

  static Future<void> save(String key, Object jsonValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode({
        'ts': DateTime.now().millisecondsSinceEpoch,
        'data': jsonValue,
      }),
    );
  }

  /// Returns the cached JSON value, or null when missing/stale/corrupt.
  static Future<dynamic> load(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final wrapped = jsonDecode(raw) as Map<String, dynamic>;
      final ts = wrapped['ts'] as int?;
      if (ts == null ||
          DateTime.now().millisecondsSinceEpoch - ts >
              _maxAge.inMilliseconds) {
        return null;
      }
      return wrapped['data'];
    } catch (_) {
      return null; // corrupt cache is the same as no cache
    }
  }

  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
