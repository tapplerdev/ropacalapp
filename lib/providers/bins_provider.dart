import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/data/mock_bins.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/models/bin_check.dart';
import 'package:ropacalapp/models/bin_move.dart';
import 'package:ropacalapp/providers/auth_provider.dart';

part 'bins_provider.g.dart';

@riverpod
class BinsList extends _$BinsList {
  @override
  Future<List<Bin>> build() async {
    AppLogger.bins('📦 BinsList: Loading bins from Golang backend...');

    final apiService = ref.read(apiServiceProvider);
    final bins = await apiService.getBins();

    AppLogger.bins(
      '📦 BinsList: Successfully loaded ${bins.length} bins from backend',
    );
    return bins;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.getBins();
    });
  }

  Future<void> updateBin(String id, Map<String, dynamic> updates) async {
    final apiService = ref.read(apiServiceProvider);

    try {
      final updatedBin = await apiService.updateBin(id, updates);

      // Update the bin in the list
      state = state.whenData((bins) {
        return bins.map((bin) {
          if (bin.id == id) {
            return updatedBin;
          }
          return bin;
        }).toList();
      });
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  /// Add a new bin to the list locally (for optimistic updates)
  void addBin(Bin newBin) {
    AppLogger.bins('📦 BinsList: Adding new bin #${newBin.binNumber} locally');

    // Extract current data
    final currentBins = state.valueOrNull;
    if (currentBins == null) {
      AppLogger.bins('   ⚠️ No data to add to');
      return;
    }

    AppLogger.bins('   Current bins: ${currentBins.length}');

    // Create new list with added bin
    final updatedBins = [...currentBins, newBin];

    AppLogger.bins('   Updated bins: ${updatedBins.length}');

    // Explicitly set new state with AsyncValue.data to force update
    state = AsyncValue.data(updatedBins);

    AppLogger.bins('   ✅ State updated, triggering rebuild');
  }

  Future<void> createCheck({
    required String binId,
    required String checkedFrom,
    required int fillPercentage,
  }) async {
    final apiService = ref.read(apiServiceProvider);

    try {
      await apiService.createCheck(
        binId: binId,
        checkedFrom: checkedFrom,
        fillPercentage: fillPercentage,
      );

      // Update the bin's fill percentage and last checked time
      await updateBin(binId, {
        'fill_percentage': fillPercentage,
        'last_checked': DateTime.now().toIso8601String(),
        'checked': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createMove({
    required String binId,
    required String toStreet,
    required String toCity,
    required String toZip,
  }) async {
    final apiService = ref.read(apiServiceProvider);

    try {
      // The Golang backend handles updating the bin location automatically
      await apiService.createMove(
        binId: binId,
        toStreet: toStreet,
        toCity: toCity,
        toZip: toZip,
      );

      // Refresh the bins list to get the updated bin
      await refresh();
    } catch (e) {
      rethrow;
    }
  }
}

@riverpod
Future<Bin> binDetail(BinDetailRef ref, String id) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getBinById(id);
}

@riverpod
Future<List<BinMove>> binMoveHistory(
  BinMoveHistoryRef ref,
  String binId,
) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getMoveHistory(binId);
}

@riverpod
Future<List<BinCheck>> binCheckHistory(
  BinCheckHistoryRef ref,
  String binId,
) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getCheckHistory(binId);
}

@riverpod
class OptimizedRoute extends _$OptimizedRoute {
  @override
  Future<List<Bin>?> build() async {
    // Initially null, no route optimized
    return null;
  }

  Future<void> optimize({
    required double latitude,
    required double longitude,
    int limit = 5,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      AppLogger.bins(
        '🚗 Optimizing route from ($latitude, $longitude) with limit $limit',
      );
      final route = await apiService.getOptimizedRoute(
        latitude: latitude,
        longitude: longitude,
        limit: limit,
      );
      AppLogger.bins('🚗 Route optimized: ${route.length} bins');
      return route;
    });
  }

  void clearRoute() {
    state = const AsyncValue.data(null);
  }
}
