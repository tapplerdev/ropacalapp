// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_task_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$routeTaskServiceHash() => r'6b66dd43918476f80058aa9badf839c2254e7a27';

/// Provider for RouteTaskService
///
/// Copied from [routeTaskService].
@ProviderFor(routeTaskService)
final routeTaskServiceProvider = AutoDisposeProvider<RouteTaskService>.internal(
  routeTaskService,
  name: r'routeTaskServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$routeTaskServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RouteTaskServiceRef = AutoDisposeProviderRef<RouteTaskService>;
String _$shiftTasksHash() => r'0ade3ad560188f965d34ac597bfb870ab2bae9cc';

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

/// Provider for fetching tasks for a specific shift
///
/// Copied from [shiftTasks].
@ProviderFor(shiftTasks)
const shiftTasksProvider = ShiftTasksFamily();

/// Provider for fetching tasks for a specific shift
///
/// Copied from [shiftTasks].
class ShiftTasksFamily extends Family<AsyncValue<List<RouteTask>>> {
  /// Provider for fetching tasks for a specific shift
  ///
  /// Copied from [shiftTasks].
  const ShiftTasksFamily();

  /// Provider for fetching tasks for a specific shift
  ///
  /// Copied from [shiftTasks].
  ShiftTasksProvider call(String shiftId) {
    return ShiftTasksProvider(shiftId);
  }

  @override
  ShiftTasksProvider getProviderOverride(
    covariant ShiftTasksProvider provider,
  ) {
    return call(provider.shiftId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'shiftTasksProvider';
}

/// Provider for fetching tasks for a specific shift
///
/// Copied from [shiftTasks].
class ShiftTasksProvider extends AutoDisposeFutureProvider<List<RouteTask>> {
  /// Provider for fetching tasks for a specific shift
  ///
  /// Copied from [shiftTasks].
  ShiftTasksProvider(String shiftId)
    : this._internal(
        (ref) => shiftTasks(ref as ShiftTasksRef, shiftId),
        from: shiftTasksProvider,
        name: r'shiftTasksProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$shiftTasksHash,
        dependencies: ShiftTasksFamily._dependencies,
        allTransitiveDependencies: ShiftTasksFamily._allTransitiveDependencies,
        shiftId: shiftId,
      );

  ShiftTasksProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.shiftId,
  }) : super.internal();

  final String shiftId;

  @override
  Override overrideWith(
    FutureOr<List<RouteTask>> Function(ShiftTasksRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShiftTasksProvider._internal(
        (ref) => create(ref as ShiftTasksRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        shiftId: shiftId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<RouteTask>> createElement() {
    return _ShiftTasksProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShiftTasksProvider && other.shiftId == shiftId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, shiftId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ShiftTasksRef on AutoDisposeFutureProviderRef<List<RouteTask>> {
  /// The parameter `shiftId` of this provider.
  String get shiftId;
}

class _ShiftTasksProviderElement
    extends AutoDisposeFutureProviderElement<List<RouteTask>>
    with ShiftTasksRef {
  _ShiftTasksProviderElement(super.provider);

  @override
  String get shiftId => (origin as ShiftTasksProvider).shiftId;
}

String _$shiftTasksDetailedHash() =>
    r'4b93052630985175f281eb54c310281c120ee92e';

/// Provider for fetching detailed tasks with JOINed data
///
/// Copied from [shiftTasksDetailed].
@ProviderFor(shiftTasksDetailed)
const shiftTasksDetailedProvider = ShiftTasksDetailedFamily();

/// Provider for fetching detailed tasks with JOINed data
///
/// Copied from [shiftTasksDetailed].
class ShiftTasksDetailedFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// Provider for fetching detailed tasks with JOINed data
  ///
  /// Copied from [shiftTasksDetailed].
  const ShiftTasksDetailedFamily();

  /// Provider for fetching detailed tasks with JOINed data
  ///
  /// Copied from [shiftTasksDetailed].
  ShiftTasksDetailedProvider call(String shiftId) {
    return ShiftTasksDetailedProvider(shiftId);
  }

  @override
  ShiftTasksDetailedProvider getProviderOverride(
    covariant ShiftTasksDetailedProvider provider,
  ) {
    return call(provider.shiftId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'shiftTasksDetailedProvider';
}

/// Provider for fetching detailed tasks with JOINed data
///
/// Copied from [shiftTasksDetailed].
class ShiftTasksDetailedProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// Provider for fetching detailed tasks with JOINed data
  ///
  /// Copied from [shiftTasksDetailed].
  ShiftTasksDetailedProvider(String shiftId)
    : this._internal(
        (ref) => shiftTasksDetailed(ref as ShiftTasksDetailedRef, shiftId),
        from: shiftTasksDetailedProvider,
        name: r'shiftTasksDetailedProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$shiftTasksDetailedHash,
        dependencies: ShiftTasksDetailedFamily._dependencies,
        allTransitiveDependencies:
            ShiftTasksDetailedFamily._allTransitiveDependencies,
        shiftId: shiftId,
      );

  ShiftTasksDetailedProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.shiftId,
  }) : super.internal();

  final String shiftId;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(
      ShiftTasksDetailedRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShiftTasksDetailedProvider._internal(
        (ref) => create(ref as ShiftTasksDetailedRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        shiftId: shiftId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _ShiftTasksDetailedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShiftTasksDetailedProvider && other.shiftId == shiftId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, shiftId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ShiftTasksDetailedRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `shiftId` of this provider.
  String get shiftId;
}

class _ShiftTasksDetailedProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with ShiftTasksDetailedRef {
  _ShiftTasksDetailedProviderElement(super.provider);

  @override
  String get shiftId => (origin as ShiftTasksDetailedProvider).shiftId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
