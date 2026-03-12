/// The source transport that originated this event.
enum NotificationSource { centrifugo, fcm, local }

/// Priority levels mapping to awesome_notifications' NotificationImportance.
enum NotificationPriority { low, normal, high, critical }

/// The canonical event envelope. Every event source normalizes into this shape
/// before entering the notification pipeline.
class NotificationEvent {
  /// The backend event type string, e.g. 'shift_cancelled', 'move_request_created'.
  /// This is the key used to look up config in the NotificationRegistry.
  final String eventType;

  /// Which transport delivered this event.
  final NotificationSource source;

  /// Raw payload from the backend. Kept untyped so the registry's
  /// template functions can extract whatever fields they need.
  final Map<String, dynamic> payload;

  /// When the event was received (client-side timestamp).
  final DateTime receivedAt;

  /// Whether this notification has been read.
  final bool isRead;

  const NotificationEvent({
    required this.eventType,
    required this.source,
    required this.payload,
    required this.receivedAt,
    this.isRead = false,
  });

  /// Returns a copy with the given fields overridden.
  NotificationEvent copyWith({bool? isRead}) {
    return NotificationEvent(
      eventType: eventType,
      source: source,
      payload: payload,
      receivedAt: receivedAt,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Dedup key: '{eventType}:{primaryId}'. Used by the router to drop
  /// duplicate events arriving from multiple transports within a 10s window.
  String get dedupKey {
    final id = payload['id'] ??
        payload['shift_id'] ??
        payload['bin_id'] ??
        payload['move_request_id'] ??
        payload['location_id'] ??
        payload['zone_id'] ??
        payload['driver_id'] ??
        '';
    return '$eventType:$id';
  }

  @override
  String toString() =>
      'NotificationEvent($eventType, source: ${source.name})';
}
