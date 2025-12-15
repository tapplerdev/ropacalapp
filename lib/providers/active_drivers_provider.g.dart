// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_drivers_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$managerServiceHash() => r'2939770aa35f1d54d98c74c0aa5f4a6d375863b8';

/// Provider for ManagerService
///
/// Copied from [managerService].
@ProviderFor(managerService)
final managerServiceProvider = AutoDisposeProvider<ManagerService>.internal(
  managerService,
  name: r'managerServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$managerServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ManagerServiceRef = AutoDisposeProviderRef<ManagerService>;
String _$activeDriversHash() => r'4b22eef723e814c85cc40387ca9a12b62674bfa2';

/// Provider for active drivers list
///
/// Copied from [ActiveDrivers].
@ProviderFor(ActiveDrivers)
final activeDriversProvider =
    AutoDisposeAsyncNotifierProvider<
      ActiveDrivers,
      List<ActiveDriver>
    >.internal(
      ActiveDrivers.new,
      name: r'activeDriversProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeDriversHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ActiveDrivers = AutoDisposeAsyncNotifier<List<ActiveDriver>>;
String _$driverShiftDetailHash() => r'e6587bebfc07811aa5fad171ee0d5b22506a4ce1';

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

abstract class _$DriverShiftDetail
    extends BuildlessAutoDisposeAsyncNotifier<DriverShiftDetailData> {
  late final String driverId;

  FutureOr<DriverShiftDetailData> build(String driverId);
}

/// Provider for a single driver's detailed shift information
///
/// Copied from [DriverShiftDetail].
@ProviderFor(DriverShiftDetail)
const driverShiftDetailProvider = DriverShiftDetailFamily();

/// Provider for a single driver's detailed shift information
///
/// Copied from [DriverShiftDetail].
class DriverShiftDetailFamily
    extends Family<AsyncValue<DriverShiftDetailData>> {
  /// Provider for a single driver's detailed shift information
  ///
  /// Copied from [DriverShiftDetail].
  const DriverShiftDetailFamily();

  /// Provider for a single driver's detailed shift information
  ///
  /// Copied from [DriverShiftDetail].
  DriverShiftDetailProvider call(String driverId) {
    return DriverShiftDetailProvider(driverId);
  }

  @override
  DriverShiftDetailProvider getProviderOverride(
    covariant DriverShiftDetailProvider provider,
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
  String? get name => r'driverShiftDetailProvider';
}

/// Provider for a single driver's detailed shift information
///
/// Copied from [DriverShiftDetail].
class DriverShiftDetailProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          DriverShiftDetail,
          DriverShiftDetailData
        > {
  /// Provider for a single driver's detailed shift information
  ///
  /// Copied from [DriverShiftDetail].
  DriverShiftDetailProvider(String driverId)
    : this._internal(
        () => DriverShiftDetail()..driverId = driverId,
        from: driverShiftDetailProvider,
        name: r'driverShiftDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$driverShiftDetailHash,
        dependencies: DriverShiftDetailFamily._dependencies,
        allTransitiveDependencies:
            DriverShiftDetailFamily._allTransitiveDependencies,
        driverId: driverId,
      );

  DriverShiftDetailProvider._internal(
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
  FutureOr<DriverShiftDetailData> runNotifierBuild(
    covariant DriverShiftDetail notifier,
  ) {
    return notifier.build(driverId);
  }

  @override
  Override overrideWith(DriverShiftDetail Function() create) {
    return ProviderOverride(
      origin: this,
      override: DriverShiftDetailProvider._internal(
        () => create()..driverId = driverId,
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
  AutoDisposeAsyncNotifierProviderElement<
    DriverShiftDetail,
    DriverShiftDetailData
  >
  createElement() {
    return _DriverShiftDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DriverShiftDetailProvider && other.driverId == driverId;
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
mixin DriverShiftDetailRef
    on AutoDisposeAsyncNotifierProviderRef<DriverShiftDetailData> {
  /// The parameter `driverId` of this provider.
  String get driverId;
}

class _DriverShiftDetailProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          DriverShiftDetail,
          DriverShiftDetailData
        >
    with DriverShiftDetailRef {
  _DriverShiftDetailProviderElement(super.provider);

  @override
  String get driverId => (origin as DriverShiftDetailProvider).driverId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
