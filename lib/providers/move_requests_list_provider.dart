import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';

part 'move_requests_list_provider.g.dart';

/// Provider for manager move requests list (keepAlive for caching)
@Riverpod(keepAlive: true)
class MoveRequestsListNotifier extends _$MoveRequestsListNotifier {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    AppLogger.general('🚚 MoveRequestsListNotifier: Building');
    return _fetchMoveRequests();
  }

  Future<List<Map<String, dynamic>>> _fetchMoveRequests() async {
    try {
      final managerService = ref.read(managerServiceProvider);
      final requests = await managerService.getAllMoveRequests();
      AppLogger.general(
        '🚚 MoveRequestsListNotifier: Fetched ${requests.length} move requests',
      );
      return requests;
    } catch (e) {
      AppLogger.e(
        'MoveRequestsListNotifier: Error fetching move requests',
        error: e,
      );
      rethrow;
    }
  }

  /// Refresh the move requests list
  Future<void> refresh() async {
    AppLogger.general('🚚 MoveRequestsListNotifier: Refreshing');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchMoveRequests());
  }
}
