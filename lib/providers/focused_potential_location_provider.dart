import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'focused_potential_location_provider.g.dart';

/// Focused potential location state
class FocusedPotentialLocationState {
  final String? locationId;

  const FocusedPotentialLocationState({
    this.locationId,
  });

  FocusedPotentialLocationState copyWith({
    String? locationId,
  }) {
    return FocusedPotentialLocationState(
      locationId: locationId ?? this.locationId,
    );
  }
}

/// Provider for managing focused potential location
@riverpod
class FocusedPotentialLocation extends _$FocusedPotentialLocation {
  @override
  FocusedPotentialLocationState build() {
    return const FocusedPotentialLocationState();
  }

  /// Focus on a potential location
  void focusLocation(String locationId) {
    state = FocusedPotentialLocationState(locationId: locationId);
  }

  /// Clear focused location
  void clearFocus() {
    state = const FocusedPotentialLocationState();
  }
}
