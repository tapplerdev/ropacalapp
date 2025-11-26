import 'package:flutter_tts/flutter_tts.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

/// Service for announcing turn-by-turn voice instructions during navigation
/// Uses flutter_tts to speak Mapbox voice instruction announcements
class VoiceInstructionService {
  final FlutterTts _tts = FlutterTts();
  final Set<String> _announcedInstructions = {};
  bool _isInitialized = false;
  bool _isEnabled = true;

  VoiceInstructionService() {
    _initializeTts();
  }

  /// Initialize TTS engine with settings
  Future<void> _initializeTts() async {
    try {
      // Set language to English (US)
      await _tts.setLanguage('en-US');

      // Set speech rate (0.5 = slower, 1.0 = normal, 1.5 = faster)
      await _tts.setSpeechRate(0.5); // Slightly slower for clarity

      // Set volume (0.0 to 1.0)
      await _tts.setVolume(1.0);

      // Set pitch (0.5 to 2.0, 1.0 = normal)
      await _tts.setPitch(1.0);

      // iOS-specific settings
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );

      _isInitialized = true;
      AppLogger.navigation('✅ Voice instruction service initialized');
    } catch (e) {
      AppLogger.navigation('❌ Error initializing TTS: $e');
      _isInitialized = false;
    }
  }

  /// Announce a voice instruction
  /// [announcement] - Text to speak (from Mapbox voice instruction)
  /// [distanceToManeuver] - Distance in meters to the turn/maneuver
  /// [instructionId] - Unique ID to prevent duplicate announcements
  Future<void> announce({
    required String announcement,
    required double distanceToManeuver,
    required String instructionId,
  }) async {
    if (!_isInitialized || !_isEnabled) {
      AppLogger.navigation('⚠️  TTS not ready or disabled, skipping announcement');
      return;
    }

    // Check if we've already announced this instruction
    if (_announcedInstructions.contains(instructionId)) {
      return;
    }

    try {
      AppLogger.navigation('🔊 Announcing: "$announcement" (${distanceToManeuver.toStringAsFixed(0)}m away)');

      // Mark as announced before speaking (to prevent race conditions)
      _announcedInstructions.add(instructionId);

      // Speak the announcement
      await _tts.speak(announcement);
    } catch (e) {
      AppLogger.navigation('❌ Error speaking announcement: $e');
      // Remove from announced set if speaking failed
      _announcedInstructions.remove(instructionId);
    }
  }

  /// Enable voice announcements
  void enable() {
    _isEnabled = true;
    AppLogger.navigation('🔊 Voice instructions enabled');
  }

  /// Disable voice announcements (mute)
  void disable() {
    _isEnabled = false;
    _tts.stop();
    AppLogger.navigation('🔇 Voice instructions disabled');
  }

  /// Toggle voice announcements on/off
  void toggle() {
    if (_isEnabled) {
      disable();
    } else {
      enable();
    }
  }

  /// Check if voice instructions are enabled
  bool get isEnabled => _isEnabled;

  /// Clear announcement history (useful when starting a new route)
  void clearHistory() {
    _announcedInstructions.clear();
    AppLogger.navigation('🗑️  Cleared voice instruction history');
  }

  /// Stop any ongoing speech
  Future<void> stop() async {
    await _tts.stop();
  }

  /// Dispose of TTS resources
  Future<void> dispose() async {
    await _tts.stop();
    _announcedInstructions.clear();
    _isInitialized = false;
    AppLogger.navigation('🗑️  Voice instruction service disposed');
  }

  /// Process Mapbox voice instruction and announce if needed
  /// Called repeatedly as user moves along route
  ///
  /// [voiceInstruction] - Mapbox voice instruction object with:
  ///   - announcement: String to speak
  ///   - distanceAlongGeometry: Distance in meters from start of route to instruction
  /// [currentDistanceAlongRoute] - Driver's current distance along route in meters
  Future<void> processVoiceInstruction({
    required Map<String, dynamic> voiceInstruction,
    required double currentDistanceAlongRoute,
  }) async {
    try {
      final announcement = voiceInstruction['announcement'] as String?;
      final distanceAlongGeometry = voiceInstruction['distanceAlongGeometry'] as double?;

      if (announcement == null || distanceAlongGeometry == null) {
        return;
      }

      // Calculate distance to instruction
      final distanceToInstruction = distanceAlongGeometry - currentDistanceAlongRoute;

      // Only announce if instruction is ahead and within announcement range
      // Mapbox provides instructions at different distances (e.g., "In 500 meters, turn left")
      if (distanceToInstruction > 0 && distanceToInstruction <= 1000) {
        // Use distance and announcement as unique ID
        final instructionId = '${distanceAlongGeometry.toInt()}_${announcement.hashCode}';

        await announce(
          announcement: announcement,
          distanceToManeuver: distanceToInstruction,
          instructionId: instructionId,
        );
      }
    } catch (e) {
      AppLogger.navigation('❌ Error processing voice instruction: $e');
    }
  }
}
