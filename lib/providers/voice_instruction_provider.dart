import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/services/voice_instruction_service.dart';

part 'voice_instruction_provider.g.dart';

/// Provider for voice instruction service (singleton)
@Riverpod(keepAlive: true)
VoiceInstructionService voiceInstructionService(
  VoiceInstructionServiceRef ref,
) {
  final service = VoiceInstructionService();

  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
}
