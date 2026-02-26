// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warehouse_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$configServiceHash() => r'ef49861929f3f8f6591badbe4a479269900e26fe';

/// ConfigService provider
///
/// Copied from [configService].
@ProviderFor(configService)
final configServiceProvider = AutoDisposeProvider<ConfigService>.internal(
  configService,
  name: r'configServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$configServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConfigServiceRef = AutoDisposeProviderRef<ConfigService>;
String _$warehouseLocationNotifierHash() =>
    r'69a2d7612d92b1e103eb27e37f429770a0429813';

/// Warehouse location provider - fetches from backend config
///
/// Copied from [WarehouseLocationNotifier].
@ProviderFor(WarehouseLocationNotifier)
final warehouseLocationNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      WarehouseLocationNotifier,
      WarehouseLocation
    >.internal(
      WarehouseLocationNotifier.new,
      name: r'warehouseLocationNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$warehouseLocationNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$WarehouseLocationNotifier =
    AutoDisposeAsyncNotifier<WarehouseLocation>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
