// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'move_request_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeMoveRequestHash() => r'7a67592d27ed1d4a61125b97a188dc28737ade1b';

/// Provider for the currently active move request
///
/// Manages the lifecycle of bin relocation requests:
/// 1. pending → Driver navigates to pickup location
/// 2. pickedUp → Driver transports bin to drop-off location
/// 3. completed → Bin placed at new location
///
/// Copied from [ActiveMoveRequest].
@ProviderFor(ActiveMoveRequest)
final activeMoveRequestProvider =
    NotifierProvider<ActiveMoveRequest, MoveRequest?>.internal(
      ActiveMoveRequest.new,
      name: r'activeMoveRequestProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeMoveRequestHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ActiveMoveRequest = Notifier<MoveRequest?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
