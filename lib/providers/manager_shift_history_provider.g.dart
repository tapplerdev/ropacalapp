// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manager_shift_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$driverShiftHistoryHash() =>
    r'17af8d585061f4b14fdde95e9c67659ded758497';

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

/// Per-driver shift history (newest first, up to 100 shifts). Powers the
/// Driver Details recent-shifts card, its 30-day stats, and the full
/// per-driver history page.
///
/// Copied from [driverShiftHistory].
@ProviderFor(driverShiftHistory)
const driverShiftHistoryProvider = DriverShiftHistoryFamily();

/// Per-driver shift history (newest first, up to 100 shifts). Powers the
/// Driver Details recent-shifts card, its 30-day stats, and the full
/// per-driver history page.
///
/// Copied from [driverShiftHistory].
class DriverShiftHistoryFamily
    extends Family<AsyncValue<List<ManagerShiftHistory>>> {
  /// Per-driver shift history (newest first, up to 100 shifts). Powers the
  /// Driver Details recent-shifts card, its 30-day stats, and the full
  /// per-driver history page.
  ///
  /// Copied from [driverShiftHistory].
  const DriverShiftHistoryFamily();

  /// Per-driver shift history (newest first, up to 100 shifts). Powers the
  /// Driver Details recent-shifts card, its 30-day stats, and the full
  /// per-driver history page.
  ///
  /// Copied from [driverShiftHistory].
  DriverShiftHistoryProvider call(String driverId) {
    return DriverShiftHistoryProvider(driverId);
  }

  @override
  DriverShiftHistoryProvider getProviderOverride(
    covariant DriverShiftHistoryProvider provider,
  ) {
    return call(provider.driverId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'driverShiftHistoryProvider';
}

/// Per-driver shift history (newest first, up to 100 shifts). Powers the
/// Driver Details recent-shifts card, its 30-day stats, and the full
/// per-driver history page.
///
/// Copied from [driverShiftHistory].
class DriverShiftHistoryProvider
    extends AutoDisposeFutureProvider<List<ManagerShiftHistory>> {
  /// Per-driver shift history (newest first, up to 100 shifts). Powers the
  /// Driver Details recent-shifts card, its 30-day stats, and the full
  /// per-driver history page.
  ///
  /// Copied from [driverShiftHistory].
  DriverShiftHistoryProvider(String driverId)
    : this._internal(
        (ref) => driverShiftHistory(ref as DriverShiftHistoryRef, driverId),
        from: driverShiftHistoryProvider,
        name: r'driverShiftHistoryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$driverShiftHistoryHash,
        dependencies: DriverShiftHistoryFamily._dependencies,
        allTransitiveDependencies:
            DriverShiftHistoryFamily._allTransitiveDependencies,
        driverId: driverId,
      );

  DriverShiftHistoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.driverId,
  }) : super.internal();

  final String driverId;

  @override
  Override overrideWith(
    FutureOr<List<ManagerShiftHistory>> Function(DriverShiftHistoryRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DriverShiftHistoryProvider._internal(
        (ref) => create(ref as DriverShiftHistoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        driverId: driverId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ManagerShiftHistory>> createElement() {
    return _DriverShiftHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DriverShiftHistoryProvider && other.driverId == driverId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, driverId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DriverShiftHistoryRef
    on AutoDisposeFutureProviderRef<List<ManagerShiftHistory>> {
  /// The parameter `driverId` of this provider.
  String get driverId;
}

class _DriverShiftHistoryProviderElement
    extends AutoDisposeFutureProviderElement<List<ManagerShiftHistory>>
    with DriverShiftHistoryRef {
  _DriverShiftHistoryProviderElement(super.provider);

  @override
  String get driverId => (origin as DriverShiftHistoryProvider).driverId;
}

String _$managerShiftHistoryNotifierHash() =>
    r'c7f4cb66d9ee5bd1f1a56706ec2adff7b4eef3a8';

abstract class _$ManagerShiftHistoryNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<ManagerShiftHistory>> {
  late final int daysBack;

  FutureOr<List<ManagerShiftHistory>> build({int daysBack = 7});
}

/// Provider for manager shift history with date filtering.
/// Fetches from GET /api/manager/shifts/history.
///
/// Copied from [ManagerShiftHistoryNotifier].
@ProviderFor(ManagerShiftHistoryNotifier)
const managerShiftHistoryNotifierProvider = ManagerShiftHistoryNotifierFamily();

/// Provider for manager shift history with date filtering.
/// Fetches from GET /api/manager/shifts/history.
///
/// Copied from [ManagerShiftHistoryNotifier].
class ManagerShiftHistoryNotifierFamily
    extends Family<AsyncValue<List<ManagerShiftHistory>>> {
  /// Provider for manager shift history with date filtering.
  /// Fetches from GET /api/manager/shifts/history.
  ///
  /// Copied from [ManagerShiftHistoryNotifier].
  const ManagerShiftHistoryNotifierFamily();

  /// Provider for manager shift history with date filtering.
  /// Fetches from GET /api/manager/shifts/history.
  ///
  /// Copied from [ManagerShiftHistoryNotifier].
  ManagerShiftHistoryNotifierProvider call({int daysBack = 7}) {
    return ManagerShiftHistoryNotifierProvider(daysBack: daysBack);
  }

  @override
  ManagerShiftHistoryNotifierProvider getProviderOverride(
    covariant ManagerShiftHistoryNotifierProvider provider,
  ) {
    return call(daysBack: provider.daysBack);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'managerShiftHistoryNotifierProvider';
}

/// Provider for manager shift history with date filtering.
/// Fetches from GET /api/manager/shifts/history.
///
/// Copied from [ManagerShiftHistoryNotifier].
class ManagerShiftHistoryNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          ManagerShiftHistoryNotifier,
          List<ManagerShiftHistory>
        > {
  /// Provider for manager shift history with date filtering.
  /// Fetches from GET /api/manager/shifts/history.
  ///
  /// Copied from [ManagerShiftHistoryNotifier].
  ManagerShiftHistoryNotifierProvider({int daysBack = 7})
    : this._internal(
        () => ManagerShiftHistoryNotifier()..daysBack = daysBack,
        from: managerShiftHistoryNotifierProvider,
        name: r'managerShiftHistoryNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$managerShiftHistoryNotifierHash,
        dependencies: ManagerShiftHistoryNotifierFamily._dependencies,
        allTransitiveDependencies:
            ManagerShiftHistoryNotifierFamily._allTransitiveDependencies,
        daysBack: daysBack,
      );

  ManagerShiftHistoryNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.daysBack,
  }) : super.internal();

  final int daysBack;

  @override
  FutureOr<List<ManagerShiftHistory>> runNotifierBuild(
    covariant ManagerShiftHistoryNotifier notifier,
  ) {
    return notifier.build(daysBack: daysBack);
  }

  @override
  Override overrideWith(ManagerShiftHistoryNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ManagerShiftHistoryNotifierProvider._internal(
        () => create()..daysBack = daysBack,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        daysBack: daysBack,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    ManagerShiftHistoryNotifier,
    List<ManagerShiftHistory>
  >
  createElement() {
    return _ManagerShiftHistoryNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ManagerShiftHistoryNotifierProvider &&
        other.daysBack == daysBack;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, daysBack.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ManagerShiftHistoryNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<ManagerShiftHistory>> {
  /// The parameter `daysBack` of this provider.
  int get daysBack;
}

class _ManagerShiftHistoryNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          ManagerShiftHistoryNotifier,
          List<ManagerShiftHistory>
        >
    with ManagerShiftHistoryNotifierRef {
  _ManagerShiftHistoryNotifierProviderElement(super.provider);

  @override
  int get daysBack => (origin as ManagerShiftHistoryNotifierProvider).daysBack;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
