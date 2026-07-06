/// Constants for map defaults shared across all map surfaces
class MapConstants {
  // Prevent instantiation
  MapConstants._();

  // ==================== DEFAULT CAMERA FALLBACK ====================

  /// Default map center when nothing better is known (no GPS fix, warehouse
  /// config not yet loaded, no bins). San Jose — the middle of the service
  /// area. Every map fallback should use this instead of hardcoding coords.
  static const double defaultLatitude = 37.3382;
  static const double defaultLongitude = -121.8863;
}
