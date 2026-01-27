import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'route_update_notification_provider.g.dart';

/// Notification state for route updates (manager changed driver's route)
class RouteUpdateNotification {
  final String managerName;
  final String actionType; // 'removed', 'added', 'updated'
  final int binNumber;
  final String moveRequestId;
  final DateTime timestamp;

  RouteUpdateNotification({
    required this.managerName,
    required this.actionType,
    required this.binNumber,
    required this.moveRequestId,
    required this.timestamp,
  });

  /// Get a human-readable description of the action
  String get actionDescription {
    switch (actionType) {
      case 'removed':
        return 'removed Bin #$binNumber from your route';
      case 'added':
        return 'added Bin #$binNumber to your route';
      case 'updated':
        return 'updated Bin #$binNumber in your route';
      default:
        return 'modified your route';
    }
  }

  /// Get a detailed description including manager name
  String get detailedDescription {
    final String action;
    switch (actionType) {
      case 'removed':
        action = 'has been removed from your route by';
        break;
      case 'added':
        action = 'has been added to your route by';
        break;
      case 'updated':
        action = 'has been updated in your route by';
        break;
      default:
        action = 'has been modified in your route by';
    }
    return 'Bin #$binNumber $action $managerName';
  }
}

/// Provider for route update notifications
/// Used to trigger UI notifications when a manager changes the driver's route
@Riverpod(keepAlive: true)
class RouteUpdateNotificationNotifier
    extends _$RouteUpdateNotificationNotifier {
  @override
  RouteUpdateNotification? build() => null;

  /// Trigger a notification for a route update
  void notify({
    required String managerName,
    required String actionType,
    required int binNumber,
    required String moveRequestId,
  }) {
    state = RouteUpdateNotification(
      managerName: managerName,
      actionType: actionType,
      binNumber: binNumber,
      moveRequestId: moveRequestId,
      timestamp: DateTime.now(),
    );
  }

  /// Clear the notification after it has been shown
  void clear() {
    state = null;
  }
}
