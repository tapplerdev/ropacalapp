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
String _$webSocketManagerHash() => r'625e9663e0974c1ce47bfaede4c589c89d25a7c0';

/// WebSocket service provider (global singleton)
///
/// Copied from [WebSocketManager].
@ProviderFor(WebSocketManager)
final webSocketManagerProvider =
    NotifierProvider<WebSocketManager, WebSocketService?>.internal(
      WebSocketManager.new,
      name: r'webSocketManagerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$webSocketManagerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$WebSocketManager = Notifier<WebSocketService?>;
String _$authNotifierHash() => r'02b0cf93c4052918a3643ab24b81d2fbca6e069e';

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
