import 'dart:convert';
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/notifications/notification_service.dart';
import 'package:ropacalapp/core/notifications/notification_router.dart';
import 'package:ropacalapp/core/notifications/notification_adapters.dart';
import 'package:ropacalapp/core/notifications/notification_channels.dart';
import 'package:ropacalapp/core/notifications/notification_registry.dart';

/// Send a log line to Railway via /api/logs/diagnostic (fire-and-forget).
/// Works in both main isolate and background isolate.
void _remoteLog(String message, {String level = 'INFO', String context = 'FCM'}) {
  // Also print locally for Xcode/logcat
  print(message);

  const url = 'https://ropacal-backend-production.up.railway.app/api/logs/diagnostic';
  try {
    http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'context': context,
        'level': level,
        'message': message,
        'platform': Platform.isIOS ? 'iOS' : 'Android',
      }),
    ).catchError((_) => http.Response('', 500));
  } catch (_) {
    // Silently fail — never crash the app for logging
  }
}

/// Top-level background FCM handler — runs in a separate isolate.
/// Must be top-level (not inside a class) per Firebase requirement.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  _remoteLog('[FCM-BG] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  _remoteLog('[FCM-BG] Background handler fired');
  _remoteLog('[FCM-BG] Platform: ${Platform.isIOS ? "iOS" : "Android"}');
  _remoteLog('[FCM-BG] Data: ${message.data}');
  _remoteLog('[FCM-BG] Notification field: ${message.notification?.title}');
  _remoteLog('[FCM-BG] MessageId: ${message.messageId}');

  // Initialize awesome_notifications in this isolate
  await AwesomeNotifications().initialize(
    null,
    NotificationChannels.allChannels,
    channelGroups: NotificationChannels.channelGroups,
    debug: false,
  );

  final data = message.data;
  final eventType = data['type'] as String? ?? 'unknown';
  _remoteLog('[FCM-BG] Event type: $eventType');

  final config = NotificationRegistry.getConfig(eventType);

  if (config == null) {
    _remoteLog('[FCM-BG] No registry config for "$eventType" — skipping', level: 'WARNING');
    _remoteLog('[FCM-BG] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return;
  }

  // Build notification content from registry config
  final payload = Map<String, dynamic>.from(data);
  final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
  final title = config.titleBuilder(payload);
  final body = config.bodyBuilder(payload);

  _remoteLog('[FCM-BG] Creating notification: "$title" / "$body"');
  _remoteLog('[FCM-BG] Channel: ${config.channelKey}');

  // Persist dedupKey to SharedPreferences so the main isolate's router
  // knows about this event and won't re-show it when Centrifugo reconnects.
  final dedupId = data['id'] ?? data['shift_id'] ?? data['bin_id'] ??
      data['move_request_id'] ?? data['location_id'] ?? data['zone_id'] ?? '';
  final dedupKey = '$eventType:$dedupId';
  try {
    final prefs = await SharedPreferences.getInstance();
    final storedKeys = prefs.getStringList('fcm_bg_dedup_keys') ?? [];
    storedKeys.add('$dedupKey|${DateTime.now().millisecondsSinceEpoch}');
    // Keep only last 50 entries
    if (storedKeys.length > 50) {
      storedKeys.removeRange(0, storedKeys.length - 50);
    }
    await prefs.setStringList('fcm_bg_dedup_keys', storedKeys);
    _remoteLog('[FCM-BG] Persisted dedupKey: $dedupKey');
  } catch (e) {
    _remoteLog('[FCM-BG] Failed to persist dedupKey: $e', level: 'WARNING');
  }

  final content = NotificationContent(
    id: id,
    channelKey: config.channelKey,
    title: title,
    body: body,
    notificationLayout: config.layout,
    bigPicture: config.bigPictureBuilder?.call(payload),
    progress: (config.progressBuilder?.call(payload) ?? 0).toDouble(),
    groupKey: config.groupKey,
    payload: {
      'eventType': eventType,
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

  // On iOS the backend sends an APNS Alert, so the OS already displays the
  // notification. Creating a local one would cause a duplicate.
  // On Android we stay data-only, so the background handler must create it.
  if (Platform.isIOS) {
    _remoteLog('[FCM-BG] iOS — OS shows APNS alert, skipping local notification');
    _remoteLog('[FCM-BG] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return;
  }

  await AwesomeNotifications().createNotification(
    content: content,
    actionButtons: actionButtons,
  );
  _remoteLog('[FCM-BG] Notification created successfully (Android)');
  _remoteLog('[FCM-BG] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}

/// Firebase Cloud Messaging Service
/// Handles push notification permissions, token management, and message routing.
/// Token registration with the backend is handled by auth_provider on login.
class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  /// Set by notification_provider when router is created, so FCM messages
  /// flow through the full pipeline (dedup, role check, prefs, side effects).
  static NotificationRouter? router;

  /// Callback invoked when Firebase refreshes the FCM token.
  /// Set by auth_provider to re-register the new token with the backend.
  static Future<void> Function(String newToken)? _onTokenRefresh;

  /// Register a callback that fires when the FCM token is refreshed by Firebase.
  static void setTokenRefreshCallback(Future<void> Function(String newToken) callback) {
    _onTokenRefresh = callback;
  }

  /// Get the current FCM token
  static String? get token => _fcmToken;

  /// Initialize FCM and request permissions
  static Future<void> initialize() async {
    try {
      _remoteLog('[FCM-INIT] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _remoteLog('[FCM-INIT] Starting FCM initialization');
      _remoteLog('[FCM-INIT] Platform: ${Platform.isIOS ? "iOS" : "Android"}');

      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _remoteLog('[FCM-INIT] Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _remoteLog('[FCM-INIT] User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        _remoteLog('[FCM-INIT] User granted provisional permission');
      } else {
        _remoteLog('[FCM-INIT] User DECLINED permission — aborting', level: 'ERROR');
        _remoteLog('[FCM-INIT] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return;
      }

      // Suppress native iOS notification banner in foreground —
      // our custom in-app banner handles foreground display.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );
      _remoteLog('[FCM-INIT] Foreground presentation: alert=OFF (custom banner only)');

      // Register background handler (runs in separate isolate)
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
      _remoteLog('[FCM-INIT] Background handler registered');

      // Verify APNs token on iOS — null means push won't work
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) {
          _remoteLog('[FCM-INIT] APNs token PRESENT (${apnsToken.length} chars)');
        } else {
          _remoteLog(
            '[FCM-INIT] APNs token is NULL — push will NOT work! '
            'Check: aps-environment entitlement, Push Notifications capability, '
            'APNs key in Firebase Console',
            level: 'ERROR',
          );
        }
      }

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      _remoteLog('[FCM-INIT] FCM Token: $_fcmToken');

      // Listen for token refresh — re-register with backend automatically
      _messaging.onTokenRefresh.listen((newToken) async {
        final oldToken = _fcmToken;
        _fcmToken = newToken;
        _remoteLog('[FCM] Token refreshed (old: ${oldToken?.substring(0, 10) ?? "null"}..., new: ${newToken.substring(0, 10)}...)');

        if (_onTokenRefresh != null) {
          try {
            await _onTokenRefresh!(newToken);
            _remoteLog('[FCM] Token re-registered with backend after refresh');
          } catch (e) {
            _remoteLog('[FCM] Failed to re-register refreshed token: $e', level: 'WARNING');
          }
        } else {
          _remoteLog('[FCM] No token refresh callback set — backend not notified', level: 'WARNING');
        }
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _remoteLog('[FCM-FG] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        _remoteLog('[FCM-FG] Foreground message received');
        _remoteLog('[FCM-FG] MessageId: ${message.messageId}');
        _remoteLog('[FCM-FG] Data: ${message.data}');
        _remoteLog('[FCM-FG] Notification: ${message.notification?.title}');
        _handleMessage(message);
      });

      // Handle notification tap (app was in background)
      // User already SAW the notification — just navigate to the relevant page.
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _remoteLog('[FCM-OPEN] App opened from notification tap');
        _remoteLog('[FCM-OPEN] Data: ${message.data}');
        _navigateToDeepLink(message.data);
      });

      // Handle notification tap (app was terminated)
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _remoteLog('[FCM-INIT] App opened from terminated state via notification');
        _remoteLog('[FCM-INIT] Data: ${initialMessage.data}');
        _navigateToDeepLink(initialMessage.data);
      }

      _remoteLog('[FCM-INIT] FCM initialized successfully');
      _remoteLog('[FCM-INIT] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e, stack) {
      _remoteLog('[FCM-INIT] FCM initialization error: $e\nStack: $stack', level: 'ERROR');
      _remoteLog('[FCM-INIT] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  /// Navigate to deep link from a notification tap (background/terminated).
  /// Does NOT re-show the notification — user already saw it.
  static void _navigateToDeepLink(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'unknown';
    final config = NotificationRegistry.getConfig(type);
    final payload = Map<String, dynamic>.from(data);
    final deepLink = config?.deepLinkBuilder?.call(payload) ?? '';

    _remoteLog('[FCM-OPEN] Event type: $type, deepLink: $deepLink');

    if (deepLink.isNotEmpty) {
      NotificationService.router?.go(deepLink);
      _remoteLog('[FCM-OPEN] Navigated to $deepLink');
    } else {
      _remoteLog('[FCM-OPEN] No deep link for $type — ignoring');
    }
  }

  /// Handle incoming push notification.
  static void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    _remoteLog('[FCM-FG] Event type: $type');
    _remoteLog('[FCM-FG] Router available: ${router != null}');

    final event = NotificationAdapters.fromFCM(data);

    if (router != null) {
      router!.receive(event);
      _remoteLog('[FCM-FG] Routed through NotificationRouter');
    } else {
      NotificationService().showNotification(event);
      _remoteLog('[FCM-FG] Direct to NotificationService (no router)');
    }
    _remoteLog('[FCM-FG] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Persist a dedupKey from the foreground handler to SharedPreferences.
  /// Called by NotificationRouter after recording the event in its dedup cache.
  static Future<void> persistDedupKey(String dedupKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedKeys = prefs.getStringList('fcm_bg_dedup_keys') ?? [];
      storedKeys.add('$dedupKey|${DateTime.now().millisecondsSinceEpoch}');
      if (storedKeys.length > 50) {
        storedKeys.removeRange(0, storedKeys.length - 50);
      }
      await prefs.setStringList('fcm_bg_dedup_keys', storedKeys);
    } catch (_) {}
  }
}
