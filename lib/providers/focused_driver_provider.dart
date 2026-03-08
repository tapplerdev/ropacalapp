import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'focused_driver_provider.g.dart';

/// Following mode for driver tracking
enum FollowMode {
  none,       // No focus — no card, no polyline
  focused,    // Focused — floating card + polyline, camera centered once
  following,  // Following — banner + polyline, continuous camera centering
}

/// State for focused/following driver
class FocusedDriverState {
  final String? driverId;
  final FollowMode mode;

  const FocusedDriverState({
    this.driverId,
    this.mode = FollowMode.none,
  });

  FocusedDriverState copyWith({
    String? driverId,
    FollowMode? mode,
  }) {
    return FocusedDriverState(
      driverId: driverId ?? this.driverId,
      mode: mode ?? this.mode,
    );
  }
}

/// Provider for tracking which driver should be focused/followed on the map
@Riverpod(keepAlive: true)
class FocusedDriver extends _$FocusedDriver {
  @override
  FocusedDriverState build() {
    return const FocusedDriverState();
  }

  /// Start following a driver (continuous auto-center with banner)
  void startFollowing(String driverId) {
    state = FocusedDriverState(
      driverId: driverId,
      mode: FollowMode.following,
    );
  }

  /// Stop following (user panned away or clicked close)
  void stopFollowing() {
    state = const FocusedDriverState(
      driverId: null,
      mode: FollowMode.none,
    );
  }

  /// Focus on a driver — shows floating card + polyline, centers camera once.
  /// Persists until the user explicitly dismisses.
  void setFocusedDriver(String? driverId) {
    if (driverId == null) {
      state = const FocusedDriverState();
    } else {
      state = FocusedDriverState(
        driverId: driverId,
        mode: FollowMode.focused,
      );
    }
  }

  /// Clear all focus/following state.
  void clearFocus() {
    state = const FocusedDriverState();
  }
}
