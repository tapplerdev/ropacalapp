import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/potential_location.dart';
import 'package:ropacalapp/providers/api_provider.dart';
import 'package:ropacalapp/providers/bins_provider.dart';

part 'potential_locations_list_provider.g.dart';

/// Provider for managing potential locations list (manager view)
@Riverpod(keepAlive: true)
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

  /// Remove a potential location from the list locally (for optimistic updates)
  void removePotentialLocation(String potentialLocationId) {
    AppLogger.general(
      '🗺️ PotentialLocationsListNotifier: Removing location $potentialLocationId locally',
    );

    // Extract current data
    final currentLocations = state.valueOrNull;
    if (currentLocations == null) {
      AppLogger.general('   ⚠️ No data to remove from');
      return;
    }

    AppLogger.general('   Current locations: ${currentLocations.length}');

    // Create new filtered list
    final updatedLocations = currentLocations
        .where((location) => location.id != potentialLocationId)
        .toList();

    AppLogger.general('   Updated locations: ${updatedLocations.length}');

    // Explicitly set new state with AsyncValue.data to force update
    state = AsyncValue.data(updatedLocations);

    AppLogger.general('   ✅ State updated, triggering rebuild');
  }

  /// Convert a potential location to a bin
  /// Updates both providers locally without full refresh for smooth UX
  /// If binNumber is provided, uses that; otherwise auto-assigns next available
  Future<void> convertToBin({
    required String potentialLocationId,
    int? binNumber,
  }) async {
    try {
      AppLogger.general(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      AppLogger.general(
        '🔄 CONVERTING LOCATION TO BIN',
      );
      AppLogger.general(
        '   Location ID: $potentialLocationId',
      );
      AppLogger.general(
        '   Bin Number: ${binNumber ?? "auto-assign"}',
      );

      // Log current state before conversion
      final currentLocations = state.valueOrNull ?? [];
      AppLogger.general(
        '   Current locations count: ${currentLocations.length}',
      );
      AppLogger.general(
        '   Location IDs before: ${currentLocations.map((l) => l.id).join(", ")}',
      );

      final apiService = ref.read(apiServiceProvider);

      // Call API and get the newly created bin
      AppLogger.general('   📡 Calling API...');
      final newBin = await apiService.convertPotentialLocationToBin(
        potentialLocationId: potentialLocationId,
        binNumber: binNumber,
      );
      AppLogger.general('   ✅ API returned new bin #${newBin.binNumber}');

      // Remove the potential location from this provider
      AppLogger.general('   🗑️ Removing location from provider...');
      removePotentialLocation(potentialLocationId);

      // Check state after removal
      final locationsAfterRemoval = state.valueOrNull ?? [];
      AppLogger.general(
        '   Locations count after removal: ${locationsAfterRemoval.length}',
      );
      AppLogger.general(
        '   Location IDs after: ${locationsAfterRemoval.map((l) => l.id).join(", ")}',
      );

      // Add the new bin to the bins provider
      AppLogger.general('   ➕ Adding bin to bins provider...');
      ref.read(binsListProvider.notifier).addBin(newBin);
      AppLogger.general('   ✅ Bin added to provider');

      AppLogger.general(
        '✅ CONVERSION COMPLETE - UI should update now',
      );
      AppLogger.general(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
    } catch (e) {
      AppLogger.e(
        '❌ CONVERSION FAILED: $e',
        error: e,
      );
      AppLogger.general(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      rethrow;
    }
  }
}
