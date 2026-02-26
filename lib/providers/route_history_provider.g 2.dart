// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$routeHistoryHash() => r'41aa8ce1483ccc96e88d4c6c8242d566c229c51c';

/// Provider for shift history data
///
/// Copied from [RouteHistory].
@ProviderFor(RouteHistory)
final routeHistoryProvider =
    AutoDisposeAsyncNotifierProvider<RouteHistory, List<ShiftHistory>>.internal(
      RouteHistory.new,
      name: r'routeHistoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$routeHistoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RouteHistory = AutoDisposeAsyncNotifier<List<ShiftHistory>>;
String _$shiftDetailHash() => r'b11a660d13e78f33413db6d4dae27c1e7b02af0b';

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

abstract class _$ShiftDetail
    extends BuildlessAutoDisposeAsyncNotifier<ShiftDetailData> {
  late final String shiftId;

  FutureOr<ShiftDetailData> build(String shiftId);
}

/// Provider for a single shift's detailed information
///
/// Copied from [ShiftDetail].
@ProviderFor(ShiftDetail)
const shiftDetailProvider = ShiftDetailFamily();

/// Provider for a single shift's detailed information
///
/// Copied from [ShiftDetail].
class ShiftDetailFamily extends Family<AsyncValue<ShiftDetailData>> {
  /// Provider for a single shift's detailed information
  ///
  /// Copied from [ShiftDetail].
  const ShiftDetailFamily();

  /// Provider for a single shift's detailed information
  ///
  /// Copied from [ShiftDetail].
  ShiftDetailProvider call(String shiftId) {
    return ShiftDetailProvider(shiftId);
  }

  @override
  ShiftDetailProvider getProviderOverride(
    covariant ShiftDetailProvider provider,
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
  String? get name => r'shiftDetailProvider';
}

/// Provider for a single shift's detailed information
///
/// Copied from [ShiftDetail].
class ShiftDetailProvider
    extends AutoDisposeAsyncNotifierProviderImpl<ShiftDetail, ShiftDetailData> {
  /// Provider for a single shift's detailed information
  ///
  /// Copied from [ShiftDetail].
  ShiftDetailProvider(String shiftId)
    : this._internal(
        () => ShiftDetail()..shiftId = shiftId,
        from: shiftDetailProvider,
        name: r'shiftDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$shiftDetailHash,
        dependencies: ShiftDetailFamily._dependencies,
        allTransitiveDependencies: ShiftDetailFamily._allTransitiveDependencies,
        shiftId: shiftId,
      );

  ShiftDetailProvider._internal(
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
  FutureOr<ShiftDetailData> runNotifierBuild(covariant ShiftDetail notifier) {
    return notifier.build(shiftId);
  }

  @override
  Override overrideWith(ShiftDetail Function() create) {
    return ProviderOverride(
      origin: this,
      override: ShiftDetailProvider._internal(
        () => create()..shiftId = shiftId,
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
  AutoDisposeAsyncNotifierProviderElement<ShiftDetail, ShiftDetailData>
  createElement() {
    return _ShiftDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShiftDetailProvider && other.shiftId == shiftId;
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
mixin ShiftDetailRef on AutoDisposeAsyncNotifierProviderRef<ShiftDetailData> {
  /// The parameter `shiftId` of this provider.
  String get shiftId;
}

class _ShiftDetailProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<ShiftDetail, ShiftDetailData>
    with ShiftDetailRef {
  _ShiftDetailProviderElement(super.provider);

  @override
  String get shiftId => (origin as ShiftDetailProvider).shiftId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
