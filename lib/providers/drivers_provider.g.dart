// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drivers_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$driversNotifierHash() => r'fb5b3a1eb055b1a4d7647a8a53066e4124c3563f';

/// Provider for managing list of drivers (for manager dashboard)
///
/// Copied from [DriversNotifier].
@ProviderFor(DriversNotifier)
final driversNotifierProvider =
    AsyncNotifierProvider<DriversNotifier, List<DriverStatus>>.internal(
      DriversNotifier.new,
      name: r'driversNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$driversNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DriversNotifier = AsyncNotifier<List<DriverStatus>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
