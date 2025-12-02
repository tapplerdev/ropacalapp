// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_page_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$navigationPageNotifierHash() =>
    r'8e627111c2a71e277e45d360fe5e575d1ef85d60';

/// Provider for navigation page state
/// Manages all navigation-related state for the google_navigation_page
///
/// This follows the same pattern as SimulationNotifier and ShiftNotifier:
/// - Synchronous state initialization
/// - Mutable state via state = state.copyWith()
/// - Auto-dispose (will reset when page is disposed)
///
/// Copied from [NavigationPageNotifier].
@ProviderFor(NavigationPageNotifier)
final navigationPageNotifierProvider =
    AutoDisposeNotifierProvider<
      NavigationPageNotifier,
      NavigationPageState
    >.internal(
      NavigationPageNotifier.new,
      name: r'navigationPageNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$navigationPageNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NavigationPageNotifier = AutoDisposeNotifier<NavigationPageState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
