import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/potential_location.dart';
import 'package:ropacalapp/providers/api_provider.dart';

part 'converted_locations_list_provider.g.dart';

/// Provider for managing converted (history) locations list
@riverpod
class ConvertedLocationsListNotifier
    extends _$ConvertedLocationsListNotifier {
  @override
  Future<List<PotentialLocation>> build() async {
    AppLogger.general('🗺️ ConvertedLocationsListNotifier: Building');
    return _fetchConvertedLocations();
  }

  Future<List<PotentialLocation>> _fetchConvertedLocations() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final locations =
          await apiService.getPotentialLocations(status: 'converted');
      AppLogger.general(
        '🗺️ ConvertedLocationsListNotifier: Fetched ${locations.length} converted locations',
      );
      return locations;
    } catch (e) {
      AppLogger.e(
        'ConvertedLocationsListNotifier: Error fetching converted locations',
        error: e,
      );
      rethrow;
    }
  }

  /// Refresh the converted locations list
  Future<void> refresh() async {
    AppLogger.general('🗺️ ConvertedLocationsListNotifier: Refreshing');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchConvertedLocations());
  }
}
