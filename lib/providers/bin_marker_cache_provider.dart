import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/utils/map_marker_utils.dart';
import 'package:ropacalapp/providers/bins_provider.dart';

part 'bin_marker_cache_provider.g.dart';

/// Cache state for bin markers
class BinMarkerCache {
  final Map<String, ImageDescriptor> binMarkers;
  final Map<int, ImageDescriptor> routeMarkers;
  final ImageDescriptor? blueDotMarker;
  final bool isLoading;

  const BinMarkerCache({
    required this.binMarkers,
    required this.routeMarkers,
    this.blueDotMarker,
    required this.isLoading,
  });

  const BinMarkerCache.empty()
    : binMarkers = const {},
      routeMarkers = const {},
      blueDotMarker = null,
      isLoading = false;

  const BinMarkerCache.loading()
    : binMarkers = const {},
      routeMarkers = const {},
      blueDotMarker = null,
      isLoading = true;

  BinMarkerCache copyWith({
    Map<String, ImageDescriptor>? binMarkers,
    Map<int, ImageDescriptor>? routeMarkers,
    ImageDescriptor? blueDotMarker,
    bool? isLoading,
  }) {
    return BinMarkerCache(
      binMarkers: binMarkers ?? this.binMarkers,
      routeMarkers: routeMarkers ?? this.routeMarkers,
      blueDotMarker: blueDotMarker ?? this.blueDotMarker,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Global marker cache provider
/// Pre-generates custom markers for all bins when bins are loaded
/// Provides instant access to markers across all pages
@Riverpod(keepAlive: true)
class BinMarkerCacheNotifier extends _$BinMarkerCacheNotifier {
  @override
  BinMarkerCache build() {
    // Watch bins and regenerate markers when bins change
    final binsAsync = ref.watch(binsListProvider);

    binsAsync.whenData((bins) {
      if (bins != null && bins.isNotEmpty) {
        _generateMarkersForBins(bins);
      }
    });

    return const BinMarkerCache.empty();
  }

  /// Generate markers for all bins asynchronously
  Future<void> _generateMarkersForBins(List<dynamic> bins) async {
    AppLogger.map('🎨 Generating marker cache for ${bins.length} bins...');
    state = const BinMarkerCache.loading();

    final binMarkers = <String, ImageDescriptor>{};

    // Generate bin markers in parallel for better performance
    await Future.wait(
      bins.map((bin) async {
        final binId = bin.id as String;
        final binNumber = bin.binNumber as int? ?? 0;
        final fillPercentage = bin.fillPercentage as int? ?? 0;

        try {
          final marker = await MapMarkerUtils.createBinMarker(
            binNumber: binNumber,
            fillPercentage: fillPercentage,
          );
          binMarkers[binId] = marker;
        } catch (e) {
          AppLogger.map(
            '❌ Failed to generate marker for bin $binId: $e',
            level: AppLogger.error,
          );
        }
      }),
    );

    // Pre-generate route markers 1-20 (common route sizes)
    final routeMarkers = <int, ImageDescriptor>{};
    await Future.wait(
      List.generate(20, (i) => i + 1).map((routeNumber) async {
        try {
          final marker = await MapMarkerUtils.createRouteMarker(
            routeNumber: routeNumber,
          );
          routeMarkers[routeNumber] = marker;
        } catch (e) {
          AppLogger.map(
            '❌ Failed to generate route marker $routeNumber: $e',
            level: AppLogger.error,
          );
        }
      }),
    );

    // Pre-generate blue dot marker for current location
    ImageDescriptor? blueDot;
    try {
      blueDot = await MapMarkerUtils.createBlueDotMarker();
      AppLogger.map('🔵 Blue dot marker generated');
    } catch (e) {
      AppLogger.map(
        '❌ Failed to generate blue dot marker: $e',
        level: AppLogger.error,
      );
    }

    state = BinMarkerCache(
      binMarkers: binMarkers,
      routeMarkers: routeMarkers,
      blueDotMarker: blueDot,
      isLoading: false,
    );

    AppLogger.map(
      '✅ Marker cache ready: ${binMarkers.length} bins, ${routeMarkers.length} route markers, blue dot: ${blueDot != null}',
    );
  }

  /// Get bin marker by bin ID
  /// Returns null if not in cache (shouldn't happen if bins are loaded)
  ImageDescriptor? getBinMarker(String binId) {
    return state.binMarkers[binId];
  }

  /// Get route marker by route number
  /// Returns null if number > 20 (will need to generate on demand)
  ImageDescriptor? getRouteMarker(int routeNumber) {
    return state.routeMarkers[routeNumber];
  }

  /// Check if marker exists in cache
  bool hasBinMarker(String binId) {
    return state.binMarkers.containsKey(binId);
  }

  /// Check if route marker exists in cache
  bool hasRouteMarker(int routeNumber) {
    return state.routeMarkers.containsKey(routeNumber);
  }

  /// Get blue dot marker for current location
  /// Returns null if not yet generated
  ImageDescriptor? getBlueDotMarker() {
    return state.blueDotMarker;
  }

  /// Force regenerate markers (useful if bin data changes)
  Future<void> regenerateMarkers() async {
    final binsAsync = ref.read(binsListProvider);
    final bins = binsAsync.value;
    if (bins != null && bins.isNotEmpty) {
      await _generateMarkersForBins(bins);
    }
  }
}
