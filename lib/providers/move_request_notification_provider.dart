import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/models/move_request.dart';

part 'move_request_notification_provider.g.dart';

/// Notification state for new move request assignments
class MoveRequestNotification {
  final MoveRequest moveRequest;
  final DateTime timestamp;

  MoveRequestNotification({
    required this.moveRequest,
    required this.timestamp,
  });
}

/// Provider for move request notifications
/// Used to trigger UI notifications when a new move request is assigned
@Riverpod(keepAlive: true)
class MoveRequestNotificationNotifier
    extends _$MoveRequestNotificationNotifier {
  @override
  MoveRequestNotification? build() => null;

  /// Trigger a notification for a new move request
  void notify(MoveRequest moveRequest) {
    state = MoveRequestNotification(
      moveRequest: moveRequest,
      timestamp: DateTime.now(),
    );
  }

  /// Clear the notification after it has been shown
  void clear() {
    state = null;
  }
}
