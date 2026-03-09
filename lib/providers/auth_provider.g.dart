// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$apiServiceHash() => r'03cbd33147a7058d56175e532ac47e1aa4858c6d';

/// Global singleton ApiService (keepAlive ensures single instance)
///
/// Copied from [apiService].
@ProviderFor(apiService)
final apiServiceProvider = Provider<ApiService>.internal(
  apiService,
  name: r'apiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$apiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ApiServiceRef = ProviderRef<ApiService>;
String _$authEventListenerHash() => r'7e79cbd141959e8044bf688a648c5b2ff74894cf';

/// Auth listener that triggers shift fetch when driver logs in.
/// Replaces the old WebSocketManager — all real-time events now flow through Centrifugo.
///
/// Copied from [AuthEventListener].
@ProviderFor(AuthEventListener)
final authEventListenerProvider =
    NotifierProvider<AuthEventListener, bool>.internal(
      AuthEventListener.new,
      name: r'authEventListenerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authEventListenerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AuthEventListener = Notifier<bool>;
String _$authNotifierHash() => r'2b2f71806168a18c975d884609798fdee31d1a48';

/// See also [AuthNotifier].
@ProviderFor(AuthNotifier)
final authNotifierProvider =
    AutoDisposeAsyncNotifierProvider<AuthNotifier, User?>.internal(
      AuthNotifier.new,
      name: r'authNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AuthNotifier = AutoDisposeAsyncNotifier<User?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
