import 'package:audioplayers/audioplayers.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

/// Service for playing notification sounds
class NotificationSoundService {
  static final NotificationSoundService _instance = NotificationSoundService._internal();
  factory NotificationSoundService() => _instance;
  NotificationSoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isEnabled = true; // Can be controlled by user settings

  /// Play notification bell sound for route updates
  Future<void> playRouteUpdateSound() async {
    if (!_isEnabled) {
      AppLogger.general('🔇 Notification sound disabled in settings');
      return;
    }

    try {
      AppLogger.general('🔔 Playing route update notification sound');

      // Set audio mode for notifications (short sound, normal priority)
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.setVolume(1.0);

      // Play the notification sound from assets
      // Note: The actual sound file needs to be added to assets/sounds/
      await _audioPlayer.play(
        AssetSource('sounds/notification_bell.mp3'),
        mode: PlayerMode.lowLatency,
      );

      AppLogger.general('✅ Notification sound played successfully');
    } catch (e) {
      // Don't crash the app if sound fails to play
      AppLogger.general('⚠️  Failed to play notification sound: $e');

      // If the asset doesn't exist, try to play system notification sound
      // as fallback (this will work on most devices)
      try {
        await _audioPlayer.play(AssetSource('sounds/notification_bell.wav'));
      } catch (fallbackError) {
        AppLogger.general('⚠️  Fallback sound also failed: $fallbackError');
      }
    }
  }

  /// Enable or disable notification sounds
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    AppLogger.general('🔔 Notification sounds ${enabled ? "enabled" : "disabled"}');
  }

  /// Check if notification sounds are enabled
  bool get isEnabled => _isEnabled;

  /// Dispose audio player resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
