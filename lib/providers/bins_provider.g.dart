// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bins_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$binDetailHash() => r'2cce136ed4bf0dfc1b1a01adc3ff7827db78bb18';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [binDetail].
@ProviderFor(binDetail)
const binDetailProvider = BinDetailFamily();

/// See also [binDetail].
class BinDetailFamily extends Family<AsyncValue<Bin>> {
  /// See also [binDetail].
  const BinDetailFamily();

  /// See also [binDetail].
  BinDetailProvider call(String id) {
    return BinDetailProvider(id);
  }

  @override
  BinDetailProvider getProviderOverride(covariant BinDetailProvider provider) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'binDetailProvider';
}

/// See also [binDetail].
class BinDetailProvider extends AutoDisposeFutureProvider<Bin> {
  /// See also [binDetail].
  BinDetailProvider(String id)
    : this._internal(
        (ref) => binDetail(ref as BinDetailRef, id),
        from: binDetailProvider,
        name: r'binDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$binDetailHash,
        dependencies: BinDetailFamily._dependencies,
        allTransitiveDependencies: BinDetailFamily._allTransitiveDependencies,
        id: id,
      );

  BinDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(FutureOr<Bin> Function(BinDetailRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: BinDetailProvider._internal(
        (ref) => create(ref as BinDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Bin> createElement() {
    return _BinDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BinDetailProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BinDetailRef on AutoDisposeFutureProviderRef<Bin> {
  /// The parameter `id` of this provider.
  String get id;
}

class _BinDetailProviderElement extends AutoDisposeFutureProviderElement<Bin>
    with BinDetailRef {
  _BinDetailProviderElement(super.provider);

  @override
  String get id => (origin as BinDetailProvider).id;
}

String _$binMoveHistoryHash() => r'ed4bda32bf3d0f03fdde7bb1a12c93f89475bfc1';

/// See also [binMoveHistory].
@ProviderFor(binMoveHistory)
const binMoveHistoryProvider = BinMoveHistoryFamily();

/// See also [binMoveHistory].
class BinMoveHistoryFamily extends Family<AsyncValue<List<BinMove>>> {
  /// See also [binMoveHistory].
  const BinMoveHistoryFamily();

  /// See also [binMoveHistory].
  BinMoveHistoryProvider call(String binId) {
    return BinMoveHistoryProvider(binId);
  }

  @override
  BinMoveHistoryProvider getProviderOverride(
    covariant BinMoveHistoryProvider provider,
  ) {
    return call(provider.binId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'binMoveHistoryProvider';
}

/// See also [binMoveHistory].
class BinMoveHistoryProvider extends AutoDisposeFutureProvider<List<BinMove>> {
  /// See also [binMoveHistory].
  BinMoveHistoryProvider(String binId)
    : this._internal(
        (ref) => binMoveHistory(ref as BinMoveHistoryRef, binId),
        from: binMoveHistoryProvider,
        name: r'binMoveHistoryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$binMoveHistoryHash,
        dependencies: BinMoveHistoryFamily._dependencies,
        allTransitiveDependencies:
            BinMoveHistoryFamily._allTransitiveDependencies,
        binId: binId,
      );

  BinMoveHistoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.binId,
  }) : super.internal();

  final String binId;

  @override
  Override overrideWith(
    FutureOr<List<BinMove>> Function(BinMoveHistoryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BinMoveHistoryProvider._internal(
        (ref) => create(ref as BinMoveHistoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        binId: binId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<BinMove>> createElement() {
    return _BinMoveHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BinMoveHistoryProvider && other.binId == binId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, binId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BinMoveHistoryRef on AutoDisposeFutureProviderRef<List<BinMove>> {
  /// The parameter `binId` of this provider.
  String get binId;
}

class _BinMoveHistoryProviderElement
    extends AutoDisposeFutureProviderElement<List<BinMove>>
    with BinMoveHistoryRef {
  _BinMoveHistoryProviderElement(super.provider);

  @override
  String get binId => (origin as BinMoveHistoryProvider).binId;
}

String _$binCheckHistoryHash() => r'150f7df7e4498aefad779460a54154d36038d25e';

/// See also [binCheckHistory].
@ProviderFor(binCheckHistory)
const binCheckHistoryProvider = BinCheckHistoryFamily();

/// See also [binCheckHistory].
class BinCheckHistoryFamily extends Family<AsyncValue<List<BinCheck>>> {
  /// See also [binCheckHistory].
  const BinCheckHistoryFamily();

  /// See also [binCheckHistory].
  BinCheckHistoryProvider call(String binId) {
    return BinCheckHistoryProvider(binId);
  }

  @override
  BinCheckHistoryProvider getProviderOverride(
    covariant BinCheckHistoryProvider provider,
  ) {
    return call(provider.binId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'binCheckHistoryProvider';
}

/// See also [binCheckHistory].
class BinCheckHistoryProvider
    extends AutoDisposeFutureProvider<List<BinCheck>> {
  /// See also [binCheckHistory].
  BinCheckHistoryProvider(String binId)
    : this._internal(
        (ref) => binCheckHistory(ref as BinCheckHistoryRef, binId),
        from: binCheckHistoryProvider,
        name: r'binCheckHistoryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$binCheckHistoryHash,
        dependencies: BinCheckHistoryFamily._dependencies,
        allTransitiveDependencies:
            BinCheckHistoryFamily._allTransitiveDependencies,
        binId: binId,
      );

  BinCheckHistoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.binId,
  }) : super.internal();

  final String binId;

  @override
  Override overrideWith(
    FutureOr<List<BinCheck>> Function(BinCheckHistoryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BinCheckHistoryProvider._internal(
        (ref) => create(ref as BinCheckHistoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        binId: binId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<BinCheck>> createElement() {
    return _BinCheckHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BinCheckHistoryProvider && other.binId == binId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, binId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BinCheckHistoryRef on AutoDisposeFutureProviderRef<List<BinCheck>> {
  /// The parameter `binId` of this provider.
  String get binId;
}

class _BinCheckHistoryProviderElement
    extends AutoDisposeFutureProviderElement<List<BinCheck>>
    with BinCheckHistoryRef {
  _BinCheckHistoryProviderElement(super.provider);

  @override
  String get binId => (origin as BinCheckHistoryProvider).binId;
}

String _$binsListHash() => r'cb5794f0a7949a91a8e0e51852441a119cb2b2ef';

/// See also [BinsList].
@ProviderFor(BinsList)
final binsListProvider =
    AutoDisposeAsyncNotifierProvider<BinsList, List<Bin>>.internal(
      BinsList.new,
      name: r'binsListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$binsListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BinsList = AutoDisposeAsyncNotifier<List<Bin>>;
String _$optimizedRouteHash() => r'677a300923abdf73c95fa6fc6378e10880e17e2c';

/// See also [OptimizedRoute].
@ProviderFor(OptimizedRoute)
final optimizedRouteProvider =
    AutoDisposeAsyncNotifierProvider<OptimizedRoute, List<Bin>?>.internal(
      OptimizedRoute.new,
      name: r'optimizedRouteProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$optimizedRouteHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OptimizedRoute = AutoDisposeAsyncNotifier<List<Bin>?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
