// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focused_driver_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$focusedDriverHash() => r'8505d45d792055788f2d7574a1b3e21f9cb77744';

/// Provider for tracking which driver should be focused/followed on the map
///
/// Copied from [FocusedDriver].
@ProviderFor(FocusedDriver)
final focusedDriverProvider =
    NotifierProvider<FocusedDriver, FocusedDriverState>.internal(
      FocusedDriver.new,
      name: r'focusedDriverProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$focusedDriverHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FocusedDriver = Notifier<FocusedDriverState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
