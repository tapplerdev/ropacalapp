// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$locationServiceHash() => r'f7b3dbe3e362693a99dbd0c857f576f80a3f5f74';

/// See also [locationService].
@ProviderFor(locationService)
final locationServiceProvider = AutoDisposeProvider<LocationService>.internal(
  locationService,
  name: r'locationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$locationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationServiceRef = AutoDisposeProviderRef<LocationService>;
String _$locationStreamHash() => r'2af7002c047c75124cb1eb3c476b3e2b7ef72bd7';

/// ⚠️ DEPRECATED: Location stream provider
///
/// This is kept for backwards compatibility but now uses locationTrackingService
///
/// MIGRATION: Access location through locationTrackingServiceProvider instead
///
/// Copied from [locationStream].
@ProviderFor(locationStream)
final locationStreamProvider =
    AutoDisposeStreamProvider<geolocator.Position>.internal(
      locationStream,
      name: r'locationStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$locationStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationStreamRef = AutoDisposeStreamProviderRef<geolocator.Position>;
String _$currentLocationHash() => r'9eada40ed60e869b3618395e204032a4c61eaa14';

/// ⚠️ DEPRECATED: Legacy location provider for backwards compatibility
///
/// This provider is now a WRAPPER around locationTrackingServiceProvider.
/// It no longer starts its own GPS stream - instead it reads from the
/// modern FusedLocation-based tracking service.
///
/// MIGRATION PATH:
/// - For location tracking: Use locationTrackingServiceProvider directly
/// - For UI location display: Continue using this provider (it proxies to service)
/// - For new features: Use locationTrackingServiceProvider
///
/// This wrapper exists only for backwards compatibility with existing UI code.
/// It will be removed in a future release once all code is migrated.
///
/// Copied from [CurrentLocation].
@ProviderFor(CurrentLocation)
final currentLocationProvider =
    AsyncNotifierProvider<CurrentLocation, geolocator.Position?>.internal(
      CurrentLocation.new,
      name: r'currentLocationProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentLocationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CurrentLocation = AsyncNotifier<geolocator.Position?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
