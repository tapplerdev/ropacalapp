import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/potential_location.dart';
import 'package:ropacalapp/providers/api_provider.dart';

part 'potential_locations_list_provider.g.dart';

/// Provider for managing potential locations list (manager view)
@riverpod
class PotentialLocationsListNotifier
    extends _$PotentialLocationsListNotifier {
  @override
  Future<List<PotentialLocation>> build() async {
    AppLogger.general('🗺️ PotentialLocationsListNotifier: Building');
    return _fetchPotentialLocations();
  }

  Future<List<PotentialLocation>> _fetchPotentialLocations() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final locations = await apiService.getPotentialLocations();
      AppLogger.general(
        '🗺️ PotentialLocationsListNotifier: Fetched ${locations.length} locations',
      );
      return locations;
    } catch (e) {
      AppLogger.e(
        'PotentialLocationsListNotifier: Error fetching locations',
        error: e,
      );
      rethrow;
    }
  }

  /// Refresh the potential locations list
  Future<void> refresh() async {
    AppLogger.general('🗺️ PotentialLocationsListNotifier: Refreshing');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPotentialLocations());
  }

  /// Convert a potential location to a bin
  Future<void> convertToBin({
    required String potentialLocationId,
    required int binNumber,
  }) async {
    try {
      AppLogger.general(
        '🗺️ PotentialLocationsListNotifier: Converting location $potentialLocationId to bin $binNumber',
      );
      final apiService = ref.read(apiServiceProvider);
      await apiService.convertPotentialLocationToBin(
        potentialLocationId: potentialLocationId,
        binNumber: binNumber,
      );

      // Refresh the list after conversion
      await refresh();
    } catch (e) {
      AppLogger.e(
        'PotentialLocationsListNotifier: Error converting location',
        error: e,
      );
      rethrow;
    }
  }
}
