import 'package:ropacalapp/core/notifications/notification_event.dart';

/// Adapters that convert raw events from each transport into NotificationEvent.
class NotificationAdapters {
  NotificationAdapters._();

  /// Convert a Centrifugo company:events publication into a NotificationEvent.
  static NotificationEvent fromCentrifugoCompanyEvent(
    Map<String, dynamic> rawEvent,
  ) {
    final type = rawEvent['type'] as String? ?? 'unknown';
    final data = rawEvent['data'] as Map<String, dynamic>? ?? rawEvent;

    return NotificationEvent(
      eventType: type,
      source: NotificationSource.centrifugo,
      payload: data,
      receivedAt: DateTime.now(),
    );
  }

  /// Convert a Centrifugo shift:updates:{id} publication.
  static NotificationEvent fromCentrifugoShiftEvent(
    Map<String, dynamic> rawEvent,
  ) {
    final type = rawEvent['type'] as String? ?? 'unknown';

    return NotificationEvent(
      eventType: type,
      source: NotificationSource.centrifugo,
      payload: rawEvent,
      receivedAt: DateTime.now(),
    );
  }

  /// Convert an FCM RemoteMessage data into a NotificationEvent.
  static NotificationEvent fromFCM(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'unknown';

    return NotificationEvent(
      eventType: type,
      source: NotificationSource.fcm,
      payload: data,
      receivedAt: DateTime.now(),
    );
  }

  /// Create a local notification event (e.g., shift progress, geofence).
  static NotificationEvent local({
    required String eventType,
    required Map<String, dynamic> payload,
  }) {
    return NotificationEvent(
      eventType: eventType,
      source: NotificationSource.local,
      payload: payload,
      receivedAt: DateTime.now(),
    );
  }
}
