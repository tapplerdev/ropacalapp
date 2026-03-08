// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_live_position_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$driverLivePositionsHash() =>
    r'9b833fc8fdf887bb638493a0898f6188216c8f69';

/// Stores the latest GPS position for every driver, updated on EVERY
/// WebSocket `driver_location_update` event.
///
/// Unlike [DriversNotifier] (which skips state updates after the first GPS
/// fix to prevent cascading rebuilds), this provider captures every single
/// coordinate — used by the polyline trimming system and the follow-mode
/// camera so they always have the driver's real-time position.
///
/// Copied from [DriverLivePositions].
@ProviderFor(DriverLivePositions)
final driverLivePositionsProvider =
    NotifierProvider<DriverLivePositions, Map<String, DriverLocation>>.internal(
      DriverLivePositions.new,
      name: r'driverLivePositionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$driverLivePositionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DriverLivePositions = Notifier<Map<String, DriverLocation>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
