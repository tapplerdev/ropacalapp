// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'centrifugo_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$centrifugoManagerHash() => r'1f821c3a2cb6f210cdd397072aba7169f68fee3a';

/// Centrifugo connection lifecycle manager
///
/// Automatically connects when ANY user logs in (drivers AND managers)
/// - Drivers: Subscribe to driver:events:{id} for shift_created, route_assigned, etc.
/// - Managers: Subscribe to company:events for real-time tracking
///
/// Returns [bool] indicating connection status. This makes the state reactive:
/// watchers (e.g. map page) automatically rebuild when connection transitions
/// from false → true (including after retry).
///
/// keepAlive: true prevents auto-disposal during tab switches while still
/// cleaning up properly on logout (watches authNotifierProvider)
///
/// Copied from [CentrifugoManager].
@ProviderFor(CentrifugoManager)
final centrifugoManagerProvider =
    AsyncNotifierProvider<CentrifugoManager, bool>.internal(
      CentrifugoManager.new,
      name: r'centrifugoManagerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$centrifugoManagerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CentrifugoManager = AsyncNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
