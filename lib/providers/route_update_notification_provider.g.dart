// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_update_notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$routeUpdateNotificationNotifierHash() =>
    r'70ac0163de7664b9ad3898237b3ab71503fa05a1';

/// Provider for route update notifications
/// Used to trigger UI notifications when a manager changes the driver's route
///
/// Copied from [RouteUpdateNotificationNotifier].
@ProviderFor(RouteUpdateNotificationNotifier)
final routeUpdateNotificationNotifierProvider =
    NotifierProvider<
      RouteUpdateNotificationNotifier,
      RouteUpdateNotification?
    >.internal(
      RouteUpdateNotificationNotifier.new,
      name: r'routeUpdateNotificationNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$routeUpdateNotificationNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RouteUpdateNotificationNotifier = Notifier<RouteUpdateNotification?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
