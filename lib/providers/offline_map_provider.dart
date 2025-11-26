import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/services/offline_map_service.dart';

part 'offline_map_provider.g.dart';

/// Provides singleton instance of offline map service
@riverpod
OfflineMapService offlineMapService(OfflineMapServiceRef ref) {
  final service = OfflineMapService();
  // Initialize service on first access
  service.initialize();

  // Cleanup on dispose
  ref.onDispose(() async {
    await service.dispose();
  });

  return service;
}
