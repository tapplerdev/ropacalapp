import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ropacalapp/core/constants/api_constants.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/providers/auth_provider.dart';

/// Backend notification preferences (synced with user_notification_preferences table).
/// Drivers only use shift_events and move_requests.
class BackendNotificationPreferences {
  final bool driftAlerts;
  final bool digests;
  final bool shiftEvents;
  final bool moveRequests;
  final bool overdueMoveAlerts;
  final bool dueSoonAlerts;

  const BackendNotificationPreferences({
    this.driftAlerts = true,
    this.digests = true,
    this.shiftEvents = true,
    this.moveRequests = true,
    this.overdueMoveAlerts = true,
    this.dueSoonAlerts = true,
  });

  factory BackendNotificationPreferences.fromJson(Map<String, dynamic> json) {
    return BackendNotificationPreferences(
      driftAlerts: json['drift_alerts'] as bool? ?? true,
      digests: json['digests'] as bool? ?? true,
      shiftEvents: json['shift_events'] as bool? ?? true,
      moveRequests: json['move_requests'] as bool? ?? true,
      overdueMoveAlerts: json['overdue_move_alerts'] as bool? ?? true,
      dueSoonAlerts: json['due_soon_alerts'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'drift_alerts': driftAlerts,
        'digests': digests,
        'shift_events': shiftEvents,
        'move_requests': moveRequests,
        'overdue_move_alerts': overdueMoveAlerts,
        'due_soon_alerts': dueSoonAlerts,
      };

  BackendNotificationPreferences copyWith({
    bool? driftAlerts,
    bool? digests,
    bool? shiftEvents,
    bool? moveRequests,
    bool? overdueMoveAlerts,
    bool? dueSoonAlerts,
  }) {
    return BackendNotificationPreferences(
      driftAlerts: driftAlerts ?? this.driftAlerts,
      digests: digests ?? this.digests,
      shiftEvents: shiftEvents ?? this.shiftEvents,
      moveRequests: moveRequests ?? this.moveRequests,
      overdueMoveAlerts: overdueMoveAlerts ?? this.overdueMoveAlerts,
      dueSoonAlerts: dueSoonAlerts ?? this.dueSoonAlerts,
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
    bool? driftAlerts,
    bool? digests,
    bool? shiftEvents,
    bool? moveRequests,
    bool? overdueMoveAlerts,
    bool? dueSoonAlerts,
  }) async {
    final current = state.valueOrNull ?? const BackendNotificationPreferences();
    final updated = current.copyWith(
      driftAlerts: driftAlerts,
      digests: digests,
      shiftEvents: shiftEvents,
      moveRequests: moveRequests,
      overdueMoveAlerts: overdueMoveAlerts,
      dueSoonAlerts: dueSoonAlerts,
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
