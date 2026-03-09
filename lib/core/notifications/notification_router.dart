import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/core/notifications/notification_event.dart';
import 'package:ropacalapp/core/notifications/notification_registry.dart';
import 'package:ropacalapp/core/notifications/notification_service.dart';
import 'package:ropacalapp/core/notifications/notification_preferences.dart';
import 'package:ropacalapp/core/notifications/notification_side_effects.dart';

/// The central notification pipeline.
///
/// Flow: receive() → dedup → role check → pref check →
///       quiet hours → side effects → display
class NotificationRouter {
  final NotificationService _service;
  final NotificationPreferences _preferences;
  final NotificationSideEffects _sideEffects;
  final Ref _ref;

  /// Current user role string ('driver' or 'admin'). Set by the provider.
  String? currentUserRole;

  /// Dedup cache: maps dedupKey → timestamp. Drops duplicates within 10s.
  final LinkedHashMap<String, DateTime> _dedupCache = LinkedHashMap();
  static const int _dedupMaxEntries = 500;
  static const Duration _dedupWindow = Duration(seconds: 10);

  NotificationRouter({
    required NotificationService service,
    required NotificationPreferences preferences,
    required NotificationSideEffects sideEffects,
    required Ref ref,
  })  : _service = service,
        _preferences = preferences,
        _sideEffects = sideEffects,
        _ref = ref;

  /// Main entry point. Call this from any event source adapter.
  Future<void> receive(NotificationEvent event) async {
    AppLogger.general(
        '[NotificationRouter] Received: ${event.eventType} '
        'from ${event.source.name}');

    // Step 0: Deduplication — drop if same dedupKey seen within 10s
    if (_isDuplicate(event)) {
      AppLogger.general(
          '[NotificationRouter] Duplicate dropped: ${event.dedupKey}');
      return;
    }

    // Step 1: Derived events (e.g., bin_fill_high from bin_updated)
    _emitDerivedEvents(event);

    // Step 2: Look up registry config
    final config = NotificationRegistry.getConfig(event.eventType);

    // Step 3: Role check
    if (config != null && config.allowedRoles.isNotEmpty) {
      final role = currentUserRole;
      if (role != null && !config.allowedRoles.contains(role)) {
        AppLogger.general(
            '[NotificationRouter] Role mismatch: user=$role, '
            'allowed=${config.allowedRoles}. Dropping.');
        return;
      }
    }

    // Step 4: User preference check (channel enabled?)
    if (config != null) {
      final channelEnabled =
          await _preferences.isChannelEnabled(config.channelKey);
      if (!channelEnabled) {
        AppLogger.general(
            '[NotificationRouter] Channel ${config.channelKey} disabled.');
        // Still run side effects
        if (config.hasSideEffects) {
          _sideEffects.execute(event, _ref);
        }
        return;
      }
    }

    // Step 5: Quiet hours check
    if (await _preferences.isInQuietHours()) {
      AppLogger.general(
          '[NotificationRouter] In quiet hours. Suppressing display.');
      if (config != null && config.hasSideEffects) {
        _sideEffects.execute(event, _ref);
      }
      return;
    }

    // Step 6: Execute side effects
    if (config != null && config.hasSideEffects) {
      _sideEffects.execute(event, _ref);
    }

    // Step 7: Display notification
    await _service.showNotification(event);
    AppLogger.general(
        '[NotificationRouter] Notification displayed: ${event.eventType}');
  }

  /// Returns true if this event was seen within the dedup window.
  bool _isDuplicate(NotificationEvent event) {
    final key = event.dedupKey;
    final now = DateTime.now();

    // Prune stale entries (oldest first thanks to insertion order)
    while (_dedupCache.isNotEmpty) {
      final oldestKey = _dedupCache.keys.first;
      final oldestTime = _dedupCache[oldestKey]!;
      if (now.difference(oldestTime) > _dedupWindow) {
        _dedupCache.remove(oldestKey);
      } else {
        break;
      }
    }

    // Check if duplicate
    if (_dedupCache.containsKey(key)) {
      return true;
    }

    // Record and cap size
    _dedupCache[key] = now;
    if (_dedupCache.length > _dedupMaxEntries) {
      _dedupCache.remove(_dedupCache.keys.first);
    }
    return false;
  }

  /// Emit derived events (synthetic events computed from incoming events).
  void _emitDerivedEvents(NotificationEvent event) {
    // bin_updated with high fill → also emit bin_fill_high
    if (event.eventType == 'bin_updated') {
      final fill = event.payload['fill_percentage'];
      final fillValue = fill is int
          ? fill
          : fill is double
              ? fill.round()
              : 0;
      if (fillValue >= 80) {
        final derived = NotificationEvent(
          eventType: 'bin_fill_high',
          source: event.source,
          payload: event.payload,
          receivedAt: event.receivedAt,
        );
        // Don't await — fire and forget for derived events
        receive(derived);
      }
    }
  }
}
