import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/models/driver_location.dart';

part 'driver_live_position_provider.g.dart';

/// Stores the latest GPS position for every driver, updated on EVERY
/// WebSocket `driver_location_update` event.
///
/// Unlike [DriversNotifier] (which skips state updates after the first GPS
/// fix to prevent cascading rebuilds), this provider captures every single
/// coordinate — used by the polyline trimming system and the follow-mode
/// camera so they always have the driver's real-time position.
@Riverpod(keepAlive: true)
class DriverLivePositions extends _$DriverLivePositions {
  @override
  Map<String, DriverLocation> build() => {};

  /// Update (or insert) the latest position for a driver.
  void updatePosition(DriverLocation location) {
    if (location.driverId == null) return;
    state = {...state, location.driverId!: location};
  }

  /// Remove a driver's position (e.g. when their shift ends).
  void removeDriver(String driverId) {
    final updated = Map<String, DriverLocation>.from(state);
    updated.remove(driverId);
    state = updated;
  }
}
