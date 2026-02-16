// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'centrifugo_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$centrifugoManagerHash() => r'5801e22f5292020717d899128be0eccecb09fed2';

/// Centrifugo connection lifecycle manager
///
/// Automatically connects when ANY user logs in (drivers AND managers)
/// - Drivers: Publish location to driver:location:{id} channel
/// - Managers: Subscribe to driver location channels for real-time tracking
///
/// Copied from [CentrifugoManager].
@ProviderFor(CentrifugoManager)
final centrifugoManagerProvider =
    AutoDisposeAsyncNotifierProvider<CentrifugoManager, void>.internal(
      CentrifugoManager.new,
      name: r'centrifugoManagerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$centrifugoManagerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CentrifugoManager = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
