// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationPreferencesHash() =>
    r'f52285f2508c57d345757408da3355b6df1ad9b2';

/// Singleton provider for NotificationPreferences.
///
/// Copied from [notificationPreferences].
@ProviderFor(notificationPreferences)
final notificationPreferencesProvider =
    Provider<NotificationPreferences>.internal(
      notificationPreferences,
      name: r'notificationPreferencesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationPreferencesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationPreferencesRef = ProviderRef<NotificationPreferences>;
String _$notificationServiceHash() =>
    r'015117d47fe71bf44664bf802ad1290b1e2492d4';

/// Singleton provider for NotificationService.
///
/// Copied from [notificationService].
@ProviderFor(notificationService)
final notificationServiceProvider = Provider<NotificationService>.internal(
  notificationService,
  name: r'notificationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationServiceRef = ProviderRef<NotificationService>;
String _$notificationSideEffectsHash() =>
    r'06f235ce8510d214529f0aec1cbf7401db0767c0';

/// Singleton provider for NotificationSideEffects.
///
/// Copied from [notificationSideEffects].
@ProviderFor(notificationSideEffects)
final notificationSideEffectsProvider =
    Provider<NotificationSideEffects>.internal(
      notificationSideEffects,
      name: r'notificationSideEffectsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationSideEffectsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationSideEffectsRef = ProviderRef<NotificationSideEffects>;
String _$notificationRouterHash() =>
    r'7ad38fdf8af8dd36814638a3a3203ace2c2003b8';

/// The notification router — central pipeline.
/// Watches auth state to set the current user's role for filtering.
///
/// Copied from [notificationRouter].
@ProviderFor(notificationRouter)
final notificationRouterProvider = Provider<NotificationRouter>.internal(
  notificationRouter,
  name: r'notificationRouterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationRouterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationRouterRef = ProviderRef<NotificationRouter>;
String _$unreadNotificationCountHash() =>
    r'c0e72e5e901b56a4f1eed6b14516c4262021686c';

/// Unread notification count for badge display.
///
/// Copied from [unreadNotificationCount].
@ProviderFor(unreadNotificationCount)
final unreadNotificationCountProvider = AutoDisposeProvider<int>.internal(
  unreadNotificationCount,
  name: r'unreadNotificationCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadNotificationCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnreadNotificationCountRef = AutoDisposeProviderRef<int>;
String _$inAppNotificationStreamHash() =>
    r'3e73765a9af4da80198c2f06fcd845fce6e96cb7';

/// Provider that exposes the in-app notification stream.
/// Widgets watch this to display overlays/dialogs/snackbars.
///
/// Copied from [InAppNotificationStream].
@ProviderFor(InAppNotificationStream)
final inAppNotificationStreamProvider =
    NotifierProvider<InAppNotificationStream, NotificationEvent?>.internal(
      InAppNotificationStream.new,
      name: r'inAppNotificationStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$inAppNotificationStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$InAppNotificationStream = Notifier<NotificationEvent?>;
String _$notificationFeedHash() => r'cb40e9becb4ffeec498904084fb1fb642644970c';

/// Notification feed (list of recent notifications).
///
/// Copied from [NotificationFeed].
@ProviderFor(NotificationFeed)
final notificationFeedProvider =
    NotifierProvider<NotificationFeed, List<NotificationEvent>>.internal(
      NotificationFeed.new,
      name: r'notificationFeedProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationFeedHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NotificationFeed = Notifier<List<NotificationEvent>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
