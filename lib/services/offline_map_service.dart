import 'dart:async';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

/// DEPRECATED: Mapbox-specific offline map service (app now uses Google Maps)
/// This file is not used and can be deleted in future cleanup.
/// NOTE: Mapbox offline API has changed in v2.12.0
/// This is a stub implementation until the new API is documented
class OfflineMapService {
  bool _isInitialized = false;

  /// Initialize offline map components
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.map('🗺️  Initializing offline map service...');

      // TODO: Implement when Mapbox offline API is documented for v2.12.0
      AppLogger.map('⚠️  Offline maps not yet supported in Mapbox SDK v2.12.0');

      _isInitialized = true;
      AppLogger.map('✅ Offline map service initialized (stub mode)');
    } catch (e) {
      AppLogger.map('❌ Failed to initialize offline map service: $e');
    }
  }

  /// Download map tiles for a route area
  /// [bounds] - Geographic bounding box for the route
  /// [onProgress] - Callback for download progress (0.0 to 1.0)
  Future<void> downloadRouteRegion({
    required CoordinateBounds bounds,
    required String routeId,
    Function(double progress)? onProgress,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      AppLogger.map(
        '📥 Offline download requested for route: $routeId\n'
        '   Bounds: ${bounds.southwest.coordinates.lng},${bounds.southwest.coordinates.lat} to '
        '${bounds.northeast.coordinates.lng},${bounds.northeast.coordinates.lat}',
      );

      AppLogger.map('⚠️  Offline tile download not yet implemented for Mapbox SDK v2.12.0');
      AppLogger.map('💡 Map tiles will be cached automatically during online usage');

      // Simulate progress for now
      onProgress?.call(1.0);
    } catch (e) {
      AppLogger.map('❌ Error in offline download stub: $e');
    }
  }

  /// Remove downloaded tiles for a route (free up storage)
  Future<void> removeRouteRegion(String routeId) async {
    AppLogger.map('🗑️  Remove offline tiles not yet implemented: $routeId');
  }

  /// Dispose resources
  Future<void> dispose() async {
    _isInitialized = false;
    AppLogger.map('🗺️  Offline map service disposed');
  }
}
