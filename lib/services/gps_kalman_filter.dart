import 'package:latlong2/latlong.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

/// Simplified 2D Kalman Filter for GPS position smoothing
/// Tracks position (lat, lng) and velocity (vLat, vLng) to smooth noisy GPS measurements
class GpsKalmanFilter {
  // State vector: [latitude, longitude, velocity_lat, velocity_lng]
  double _lat = 0.0;
  double _lng = 0.0;
  double _vLat = 0.0; // degrees per second
  double _vLng = 0.0; // degrees per second

  // State uncertainty (how confident we are in our estimate)
  double _pLat = 1.0; // position uncertainty
  double _pLng = 1.0;
  double _pvLat = 1.0; // velocity uncertainty
  double _pvLng = 1.0;

  // Filter parameters (tunable)
  final double _processNoise; // How much velocity can change (Q)
  final double _measurementNoise; // GPS accuracy in degrees (R)

  DateTime? _lastUpdateTime;
  bool _isInitialized = false;

  GpsKalmanFilter({
    double processNoise = 0.5,
    double measurementNoise = 0.0001, // ~10m at equator
  })  : _processNoise = processNoise,
        _measurementNoise = measurementNoise;

  /// Process a new GPS measurement and return filtered position
  LatLng update(LatLng rawPosition) {
    final now = DateTime.now();

    if (!_isInitialized) {
      // First measurement - initialize state
      _lat = rawPosition.latitude;
      _lng = rawPosition.longitude;
      _vLat = 0.0;
      _vLng = 0.0;
      _lastUpdateTime = now;
      _isInitialized = true;

      AppLogger.navigation('🎯 Kalman filter initialized at ($rawPosition)');
      return rawPosition;
    }

    // Calculate time delta
    final dt = (now.millisecondsSinceEpoch - _lastUpdateTime!.millisecondsSinceEpoch) / 1000.0;
    _lastUpdateTime = now;

    if (dt <= 0 || dt > 5.0) {
      // Skip if time delta is invalid or too large (GPS was off)
      AppLogger.navigation('⚠️  Kalman filter: invalid dt=$dt, resetting');
      _lat = rawPosition.latitude;
      _lng = rawPosition.longitude;
      _vLat = 0.0;
      _vLng = 0.0;
      return rawPosition;
    }

    // ====================
    // PREDICT STEP
    // ====================
    // Predict next position based on current velocity
    final predictedLat = _lat + (_vLat * dt);
    final predictedLng = _lng + (_vLng * dt);

    // Increase uncertainty due to process noise
    _pLat += _processNoise * dt;
    _pLng += _processNoise * dt;
    _pvLat += _processNoise * dt;
    _pvLng += _processNoise * dt;

    // ====================
    // UPDATE STEP
    // ====================
    // Kalman gain: how much to trust measurement vs prediction
    final kLat = _pLat / (_pLat + _measurementNoise);
    final kLng = _pLng / (_pLng + _measurementNoise);

    // Update position: blend prediction with measurement
    _lat = predictedLat + kLat * (rawPosition.latitude - predictedLat);
    _lng = predictedLng + kLng * (rawPosition.longitude - predictedLng);

    // Update velocity based on position change
    final measuredVLat = (rawPosition.latitude - predictedLat) / dt;
    final measuredVLng = (rawPosition.longitude - predictedLng) / dt;

    final kVLat = _pvLat / (_pvLat + _measurementNoise);
    final kVLng = _pvLng / (_pvLng + _measurementNoise);

    _vLat = _vLat + kVLat * measuredVLat;
    _vLng = _vLng + kVLng * measuredVLng;

    // Reduce uncertainty after incorporating measurement
    _pLat = (1 - kLat) * _pLat;
    _pLng = (1 - kLng) * _pLng;
    _pvLat = (1 - kVLat) * _pvLat;
    _pvLng = (1 - kVLng) * _pvLng;

    final filtered = LatLng(_lat, _lng);

    // Calculate distance between raw and filtered
    final distance = Distance().distance(rawPosition, filtered);

    AppLogger.navigation(
      '🎯 Kalman: Raw=${rawPosition.latitude.toStringAsFixed(6)},${rawPosition.longitude.toStringAsFixed(6)} → '
      'Filtered=${_lat.toStringAsFixed(6)},${_lng.toStringAsFixed(6)} '
      '(offset=${distance.toStringAsFixed(1)}m, v=${_vLat.toStringAsFixed(6)},${_vLng.toStringAsFixed(6)})',
    );

    return filtered;
  }

  /// Reset the filter (e.g., when navigation starts/stops)
  void reset() {
    _isInitialized = false;
    _lat = 0.0;
    _lng = 0.0;
    _vLat = 0.0;
    _vLng = 0.0;
    _pLat = 1.0;
    _pLng = 1.0;
    _pvLat = 1.0;
    _pvLng = 1.0;
    _lastUpdateTime = null;
    AppLogger.navigation('🔄 Kalman filter reset');
  }

  /// Get current velocity magnitude in m/s (approximate)
  double get speed {
    // Convert degrees/sec to m/s (rough approximation at equator)
    const metersPerDegree = 111320.0; // meters per degree latitude
    final vLatMs = _vLat * metersPerDegree;
    final vLngMs = _vLng * metersPerDegree;
    return (vLatMs * vLatMs + vLngMs * vLngMs).abs();
  }
}
