// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manager_shift_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$managerShiftHistoryNotifierHash() =>
    r'c7f4cb66d9ee5bd1f1a56706ec2adff7b4eef3a8';

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
