/// Constants related to bin thresholds, simulation parameters, and navigation settings
class BinConstants {
  // Prevent instantiation
  BinConstants._();

  // ==================== BIN FILL THRESHOLDS ====================

  /// High fill threshold (red alert) - bins above this percentage need urgent attention
  static const int highFillThreshold = 75;

  /// Medium fill threshold (orange warning) - bins above this percentage should be monitored
  static const int mediumFillThreshold = 50;

  /// Critical fill threshold used in statistics - bins needing immediate service
  static const int criticalFillThreshold = 80;

  /// Urgent fill threshold for priority sorting
  static const int urgentFillThreshold = 90;

  // ==================== NAVIGATION THRESHOLDS ====================

  /// Distance threshold in meters for completing a navigation step
  static const double stepCompleteThreshold = 30.0;

  /// Distance threshold in meters for detecting off-route navigation
  static const double offRouteThreshold = 50.0;

  /// Distance threshold in meters for wrong turn simulation
  static const double wrongTurnDistance = 75.0;

  /// Minimum proximity in meters required to complete a bin (driver must be within this range)
  static const double binCompletionProximity = 100.0;

  // ==================== SIMULATION PARAMETERS ====================

  /// Simulation speed in m/s (15 m/s = 54 km/h = 33.5 mph)
  static const double simulationSpeed = 15.0;

  /// Average driving speed in km/h for estimated time calculations
  static const double averageDrivingSpeed = 30.0;

  /// Frames per second for smooth simulation animation
  static const int simulationFPS = 60;

  // ==================== MAP CAMERA SETTINGS ====================

  /// Zoom level for navigation mode (close-up 3D view)
  /// Recommended range: 15-18 for street-level with buildings/POIs visible
  static const double navigationZoom = 19.0;

  /// Zoom level for overview/map mode (2D view)
  static const double mapOverviewZoom = 14.0;

  /// Default zoom level for map initialization
  static const double defaultMapZoom = 15.0;

  /// Camera tilt angle for 3D navigation mode (degrees) - street-level, first-person view
  /// 0° = perpendicular/top-down, 45-60° = forward-looking perspective
  /// Set to 68.4° based on user testing for optimal road-ahead visibility
  static const double navigationTilt = 68.4;

  /// Camera tilt for flat 2D map mode (degrees)
  static const double mapModeTilt = 0.0;

  /// Camera padding for navigation mode (positions marker lower on screen for better forward visibility)
  /// Set based on user testing - high top padding shows maximum road ahead
  /// Right padding compensates for UI elements
  static const double navigationPaddingTop = 500.0;
  static const double navigationPaddingBottom = 0.0;
  static const double navigationPaddingLeft = 0.0;
  static const double navigationPaddingRight = 135.0;

  // ==================== CAMERA UPDATE THROTTLING ====================

  /// Minimum milliseconds between camera position updates to prevent animation conflicts
  /// Reduced to 50ms (20 FPS) for smoother following
  static const int cameraUpdateThrottleMs = 50;

  /// Bearing smoothing factor (0.0 = instant, 1.0 = never change)
  /// Higher values = smoother but slower response to direction changes
  static const double bearingSmoothingFactor = 0.7;

  // ==================== MARKER SIZES ====================

  /// Size of bin markers on map (logical pixels)
  static const double binMarkerSize = 100.0;

  /// Size of route number markers on map (logical pixels)
  static const double routeMarkerSize = 100.0;

  /// Size of current location blue dot marker (logical pixels)
  static const double blueDotMarkerSize = 80.0;

  /// Icon scale for bin markers (0.4 = 40% of original 100px = 40px display)
  static const double binMarkerIconScale = 0.4;

  // ==================== UI SPACING ====================

  /// Bottom padding for map overlay widgets
  static const double mapOverlayBottomPadding = 280.0;

  /// Spacing between floating action buttons
  static const double fabSpacing = 60.0;
}
