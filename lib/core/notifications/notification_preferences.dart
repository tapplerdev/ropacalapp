import 'package:shared_preferences/shared_preferences.dart';

/// User notification preferences.
/// Persists per-channel enabled/disabled state and quiet hours.
class NotificationPreferences {
  static const String _prefix = 'notif_pref_';
  static const String _quietStartKey = '${_prefix}quiet_start';
  static const String _quietEndKey = '${_prefix}quiet_end';
  static const String _quietEnabledKey = '${_prefix}quiet_enabled';
  static const String _soundEnabledKey = '${_prefix}sound_enabled';
  static const String _vibrationEnabledKey = '${_prefix}vibration_enabled';

  /// Check if a notification channel is enabled.
  Future<bool> isChannelEnabled(String channelKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${_prefix}channel_$channelKey') ?? true;
  }

  /// Enable or disable a notification channel.
  Future<void> setChannelEnabled(String channelKey, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefix}channel_$channelKey', enabled);
  }

  /// Check if currently in quiet hours.
  Future<bool> isInQuietHours() async {
    final prefs = await SharedPreferences.getInstance();
    final quietEnabled = prefs.getBool(_quietEnabledKey) ?? false;
    if (!quietEnabled) return false;

    final startHour = prefs.getInt(_quietStartKey) ?? 22;
    final endHour = prefs.getInt(_quietEndKey) ?? 6;
    final now = DateTime.now().hour;

    if (startHour <= endHour) {
      return now >= startHour && now < endHour;
    } else {
      // Overnight range (e.g., 22-6)
      return now >= startHour || now < endHour;
    }
  }

  /// Set quiet hours range.
  Future<void> setQuietHours({
    required bool enabled,
    int startHour = 22,
    int endHour = 6,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quietEnabledKey, enabled);
    await prefs.setInt(_quietStartKey, startHour);
    await prefs.setInt(_quietEndKey, endHour);
  }

  /// Get quiet hours settings.
  Future<({bool enabled, int startHour, int endHour})> getQuietHours() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      enabled: prefs.getBool(_quietEnabledKey) ?? false,
      startHour: prefs.getInt(_quietStartKey) ?? 22,
      endHour: prefs.getInt(_quietEndKey) ?? 6,
    );
  }

  /// Check if notification sound is enabled globally.
  Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  /// Set global sound preference.
  Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  /// Check if vibration is enabled globally.
  Future<bool> isVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationEnabledKey) ?? true;
  }

  /// Set global vibration preference.
  Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, enabled);
  }
}
