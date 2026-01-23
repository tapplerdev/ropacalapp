// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$shiftServiceHash() => r'ebd69db2da0737025ac449ffa726b0b8c66ebba2';

/// Provider for ShiftService
///
/// Copied from [shiftService].
@ProviderFor(shiftService)
final shiftServiceProvider = AutoDisposeProvider<ShiftService>.internal(
  shiftService,
  name: r'shiftServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$shiftServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ShiftServiceRef = AutoDisposeProviderRef<ShiftService>;
String _$shiftNotifierHash() => r'8a1941477729b33cb732c7f2097dc6c753d30af4';

/// See also [ShiftNotifier].
@ProviderFor(ShiftNotifier)
final shiftNotifierProvider =
    NotifierProvider<ShiftNotifier, ShiftState>.internal(
      ShiftNotifier.new,
      name: r'shiftNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$shiftNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ShiftNotifier = Notifier<ShiftState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
