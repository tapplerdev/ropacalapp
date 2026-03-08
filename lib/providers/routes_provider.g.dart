// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$routesNotifierHash() => r'16e2851df96a4f61c6cde1aef788353f1cda26c5';

/// Provider for fetching route templates from the backend.
/// Routes are blueprints that define a sequence of bins to visit.
///
/// Copied from [RoutesNotifier].
@ProviderFor(RoutesNotifier)
final routesNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      RoutesNotifier,
      List<RouteTemplate>
    >.internal(
      RoutesNotifier.new,
      name: r'routesNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$routesNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RoutesNotifier = AutoDisposeAsyncNotifier<List<RouteTemplate>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
