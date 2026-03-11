import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ropacalapp/core/constants/api_constants.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/providers/auth_provider.dart';

/// Backend notification preferences (synced with user_notification_preferences table).
/// Drivers only use shift_events and move_requests.
class BackendNotificationPreferences {
  final bool shiftEvents;
  final bool moveRequests;

  const BackendNotificationPreferences({
    this.shiftEvents = true,
    this.moveRequests = true,
  });

  factory BackendNotificationPreferences.fromJson(Map<String, dynamic> json) {
    return BackendNotificationPreferences(
      shiftEvents: json['shift_events'] as bool? ?? true,
      moveRequests: json['move_requests'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'shift_events': shiftEvents,
        'move_requests': moveRequests,
      };

  BackendNotificationPreferences copyWith({
    bool? shiftEvents,
    bool? moveRequests,
  }) {
    return BackendNotificationPreferences(
      shiftEvents: shiftEvents ?? this.shiftEvents,
      moveRequests: moveRequests ?? this.moveRequests,
    );
  }
}

/// Async notifier that fetches and updates notification preferences via the backend API.
class BackendNotificationPreferencesNotifier
    extends AsyncNotifier<BackendNotificationPreferences> {
  @override
  Future<BackendNotificationPreferences> build() async {
    return _fetch();
  }

  Future<BackendNotificationPreferences> _fetch() async {
    final api = ref.read(apiServiceProvider);
    try {
      final response = await api.get(
        ApiConstants.notificationPreferencesEndpoint,
      );
      final data = response.data as Map<String, dynamic>;
      AppLogger.general(
          '✅ [NOTIF-PREFS] Loaded preferences from backend: $data');
      return BackendNotificationPreferences.fromJson(data);
    } catch (e) {
      AppLogger.general(
          '⚠️ [NOTIF-PREFS] Failed to load preferences, using defaults: $e');
      return const BackendNotificationPreferences();
    }
  }

  /// Update a single preference field and persist to backend.
  Future<void> updatePreference({
    bool? shiftEvents,
    bool? moveRequests,
  }) async {
    final current = state.valueOrNull ?? const BackendNotificationPreferences();
    final updated = current.copyWith(
      shiftEvents: shiftEvents,
      moveRequests: moveRequests,
    );

    // Optimistic update
    state = AsyncData(updated);

    final api = ref.read(apiServiceProvider);
    try {
      await api.put(
        ApiConstants.notificationPreferencesEndpoint,
        updated.toJson(),
      );
      AppLogger.general(
          '✅ [NOTIF-PREFS] Saved preferences to backend: ${updated.toJson()}');
    } catch (e) {
      AppLogger.general('❌ [NOTIF-PREFS] Failed to save preferences: $e');
      // Revert on failure
      state = AsyncData(current);
    }
  }
}

/// Provider for backend notification preferences.
final backendNotificationPreferencesProvider = AsyncNotifierProvider<
    BackendNotificationPreferencesNotifier,
    BackendNotificationPreferences>(
  BackendNotificationPreferencesNotifier.new,
);
