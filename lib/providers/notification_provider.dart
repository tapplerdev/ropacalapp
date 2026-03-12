import 'dart:async';
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ropacalapp/core/enums/user_role.dart';
import 'package:ropacalapp/core/notifications/notifications.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/services/fcm_service.dart';

part 'notification_provider.g.dart';

/// Singleton provider for NotificationPreferences.
@Riverpod(keepAlive: true)
NotificationPreferences notificationPreferences(
    NotificationPreferencesRef ref) {
  return NotificationPreferences();
}

/// Singleton provider for NotificationService.
@Riverpod(keepAlive: true)
NotificationService notificationService(NotificationServiceRef ref) {
  return NotificationService();
}

/// Singleton provider for NotificationSideEffects.
@Riverpod(keepAlive: true)
NotificationSideEffects notificationSideEffects(
    NotificationSideEffectsRef ref) {
  return NotificationSideEffects();
}

/// The notification router — central pipeline.
/// Watches auth state to set the current user's role for filtering.
@Riverpod(keepAlive: true)
NotificationRouter notificationRouter(NotificationRouterRef ref) {
  final service = ref.read(notificationServiceProvider);
  final preferences = ref.read(notificationPreferencesProvider);
  final sideEffects = ref.read(notificationSideEffectsProvider);

  final router = NotificationRouter(
    service: service,
    preferences: preferences,
    sideEffects: sideEffects,
    ref: ref,
  );

  // Load dedup keys persisted by the FCM background handler
  router.loadPersistedDedupKeys();

  // Watch auth state to keep role updated
  final authState = ref.watch(authNotifierProvider);
  authState.whenData((user) {
    if (user != null) {
      router.currentUserRole =
          user.role == UserRole.admin ? 'admin' : 'driver';
    } else {
      router.currentUserRole = null;
    }
  });

  // Wire FCM to route through the full pipeline
  FCMService.router = router;

  return router;
}

/// Provider that exposes the in-app notification stream.
/// Widgets watch this to display overlays/dialogs/snackbars.
@Riverpod(keepAlive: true)
class InAppNotificationStream extends _$InAppNotificationStream {
  StreamSubscription<NotificationEvent>? _subscription;

  @override
  NotificationEvent? build() {
    final service = ref.read(notificationServiceProvider);

    _subscription?.cancel();
    _subscription = service.inAppNotifications.listen((event) {
      state = event;
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return null;
  }

  /// Clear after showing.
  void clear() {
    state = null;
  }
}

/// Notification feed (list of recent notifications).
/// Fetches persisted notifications from the backend on startup,
/// then merges real-time events on top.
@Riverpod(keepAlive: true)
class NotificationFeed extends _$NotificationFeed {
  StreamSubscription<NotificationEvent>? _subscription;

  @override
  List<NotificationEvent> build() {
    final service = ref.read(notificationServiceProvider);

    // Listen for real-time events and prepend them
    _subscription?.cancel();
    _subscription = service.feedUpdates.listen((event) {
      // Skip if already in feed (same dedupKey = same event from another transport)
      if (state.any((e) => e.dedupKey == event.dedupKey)) return;
      // Prepend new events (most recent first), cap at 100
      state = [event, ...state].take(100).toList();
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    // Fetch persisted notifications from backend
    _loadFromBackend();

    return [];
  }

  /// Fetch persisted notifications from the backend API.
  Future<void> _loadFromBackend() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/api/notifications?limit=50');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final notifications = data['notifications'] as List<dynamic>? ?? [];

        final events = notifications.map<NotificationEvent>((n) {
          final map = n as Map<String, dynamic>;
          // Parse the data field — may be a string or already a map
          Map<String, dynamic> payload;
          if (map['data'] is String) {
            payload = jsonDecode(map['data'] as String) as Map<String, dynamic>;
          } else {
            payload = Map<String, dynamic>.from(map['data'] as Map? ?? {});
          }

          return NotificationEvent(
            eventType: map['type'] as String? ?? 'unknown',
            source: NotificationSource.local,
            payload: {
              ...payload,
              'title': map['title'],
              'body': map['body'],
              'id': map['id'],
            },
            receivedAt: DateTime.fromMillisecondsSinceEpoch(
              ((map['created_at'] as num?) ?? 0).toInt() * 1000,
            ),
          );
        }).toList();

        // Merge with any real-time events already in state (deduplicate)
        final existingKeys = state.map((e) => e.dedupKey).toSet();
        final newEvents = events.where((e) => !existingKeys.contains(e.dedupKey)).toList();
        state = [...state, ...newEvents].take(100).toList();

        AppLogger.general('📬 [NotificationFeed] Loaded ${events.length} notifications from backend');
      }
    } catch (e) {
      AppLogger.general('⚠️ [NotificationFeed] Failed to load from backend: $e');
    }
  }

  /// Refresh from backend (pull-to-refresh or manual).
  Future<void> refresh() async {
    await _loadFromBackend();
  }

  /// Clear all feed items.
  void clearAll() {
    state = [];
  }
}

/// Unread notification count for badge display.
@riverpod
int unreadNotificationCount(UnreadNotificationCountRef ref) {
  final feed = ref.watch(notificationFeedProvider);
  return feed.length;
}
