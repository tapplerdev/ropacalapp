// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'here_route_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$hereRouteMetadataHash() => r'5a993287794be092b082a982dc7d8879eccb87fb';

/// Provider to store HERE Maps route metadata including traffic-aware durations
///
/// Copied from [HereRouteMetadata].
@ProviderFor(HereRouteMetadata)
final hereRouteMetadataProvider =
    NotifierProvider<HereRouteMetadata, HereRouteData?>.internal(
      HereRouteMetadata.new,
      name: r'hereRouteMetadataProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$hereRouteMetadataHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$HereRouteMetadata = Notifier<HereRouteData?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
