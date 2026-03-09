import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:ropacalapp/core/notifications/notification_channels.dart';
import 'package:ropacalapp/core/notifications/notification_event.dart';
import 'package:ropacalapp/core/notifications/notification_registry.dart';

/// Core service wrapping awesome_notifications.
/// Singleton — initialized once at app startup.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Internal incrementing ID for notifications.
  int _nextId = 1;

  /// Stream controller for in-app notification events.
  final StreamController<NotificationEvent> _inAppStream =
      StreamController<NotificationEvent>.broadcast();

  /// Stream of events that should trigger in-app overlays.
  Stream<NotificationEvent> get inAppNotifications => _inAppStream.stream;

  /// Stream controller for notification feed updates.
  final StreamController<NotificationEvent> _feedStream =
      StreamController<NotificationEvent>.broadcast();

  /// Stream of events to be persisted in the notification feed.
  Stream<NotificationEvent> get feedUpdates => _feedStream.stream;

  /// GoRouter reference for deep-linking from notification taps.
  static GoRouter? router;

  /// Initialize awesome_notifications.
  /// Call once in main() before runApp().
  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // Use default app icon
      NotificationChannels.allChannels,
      channelGroups: NotificationChannels.channelGroups,
      debug: false,
    );

    // Set up action listeners
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceived,
      onNotificationCreatedMethod: _onNotificationCreated,
      onNotificationDisplayedMethod: _onNotificationDisplayed,
      onDismissActionReceivedMethod: _onDismissReceived,
    );
  }

  /// Request notification permissions.
  Future<bool> requestPermissions() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      return await AwesomeNotifications()
          .requestPermissionToSendNotifications();
    }
    return true;
  }

  /// Whether the app is currently in the foreground.
  bool get _isAppInForeground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == AppLifecycleState.resumed;
  }

  /// Display a notification for a given event.
  /// When the app is in the foreground and the event has showInAppOverlay,
  /// only the custom in-app banner is shown (no OS notification).
  /// When the app is in the background, the OS notification is shown.
  Future<void> showNotification(NotificationEvent event) async {
    final config = NotificationRegistry.getConfig(event.eventType);
    if (config == null) {
      // Unknown event type — still emit to feed
      _feedStream.add(event);
      return;
    }

    final isForeground = _isAppInForeground;
    final hasInAppOverlay = config.showInAppOverlay;

    // Only show OS notification if app is NOT in foreground,
    // or if this event type doesn't have an in-app overlay.
    if (!isForeground || !hasInAppOverlay) {
      final id = _nextId++;
      final payload = event.payload;

      final content = NotificationContent(
        id: id,
        channelKey: config.channelKey,
        title: config.titleBuilder(payload),
        body: config.bodyBuilder(payload),
        notificationLayout: config.layout,
        bigPicture: config.bigPictureBuilder?.call(payload),
        progress: (config.progressBuilder?.call(payload) ?? 0).toDouble(),
        groupKey: config.groupKey,
        payload: {
          'eventType': event.eventType,
          'deepLink': config.deepLinkBuilder?.call(payload) ?? '',
          ...Map.fromEntries(
            payload.entries
                .where((e) =>
                    e.value is String || e.value is int || e.value is double)
                .map((e) => MapEntry(e.key, e.value.toString())),
          ),
        },
      );

      final actionButtons = config.actionButtonsBuilder?.call(payload);

      await AwesomeNotifications().createNotification(
        content: content,
        actionButtons: actionButtons,
      );
    }

    // Emit to in-app stream if configured (foreground only)
    if (hasInAppOverlay) {
      _inAppStream.add(event);
    }

    // Emit to feed stream if configured
    if (config.addToFeed) {
      _feedStream.add(event);
    }
  }

  /// Update badge count.
  Future<void> updateBadge(int count) async {
    await AwesomeNotifications().setGlobalBadgeCounter(count);
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
  }

  /// Dispose streams.
  void dispose() {
    _inAppStream.close();
    _feedStream.close();
  }

  // =========================================================================
  // Static callback methods (required by awesome_notifications)
  // =========================================================================

  @pragma('vm:entry-point')
  static Future<void> _onActionReceived(ReceivedAction action) async {
    final deepLink = action.payload?['deepLink'] ?? '';
    final buttonKey = action.buttonKeyPressed;

    if (buttonKey == 'ACKNOWLEDGE') {
      return; // Just dismiss
    }

    if (deepLink.isNotEmpty) {
      router?.go(deepLink);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationCreated(
      ReceivedNotification notification) async {}

  @pragma('vm:entry-point')
  static Future<void> _onNotificationDisplayed(
      ReceivedNotification notification) async {}

  @pragma('vm:entry-point')
  static Future<void> _onDismissReceived(ReceivedAction action) async {}
}
