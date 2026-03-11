import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/notifications/notification_channels.dart';
import 'package:ropacalapp/providers/notification_provider.dart';
import 'package:ropacalapp/providers/notification_preferences_provider.dart';

/// Notification Settings Page - Manage notification preferences
/// Backend-synced toggles for shift_events and move_requests.
/// Local-only toggles for sound and vibration.
class NotificationSettingsPage extends HookConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localPrefs = ref.read(notificationPreferencesProvider);
    final backendPrefsAsync =
        ref.watch(backendNotificationPreferencesProvider);

    // Local device settings (SharedPreferences only)
    final soundEnabled = useState(true);
    final vibrationEnabled = useState(true);
    final localLoaded = useState(false);

    // Load local device settings
    useEffect(() {
      Future<void> load() async {
        soundEnabled.value = await localPrefs.isSoundEnabled();
        vibrationEnabled.value = await localPrefs.isVibrationEnabled();
        localLoaded.value = true;
      }

      load();
      return null;
    }, []);

    if (!localLoaded.value) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage your notification preferences',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // Route & Shift Updates Section (backend-synced)
            _buildSectionHeader('ROUTE & SHIFT UPDATES'),
            const SizedBox(height: 8),
            backendPrefsAsync.when(
              data: (prefs) => _buildCard([
                _ToggleItem(
                  icon: Icons.work_history,
                  iconColor: Colors.green.shade600,
                  title: 'Shift & Route Updates',
                  subtitle:
                      'Shift assignments, cancellations, route assignments',
                  value: prefs.shiftEvents,
                  onChanged: (v) {
                    ref
                        .read(backendNotificationPreferencesProvider.notifier)
                        .updatePreference(shiftEvents: v);
                    // Also update local channels so FCM filtering matches
                    localPrefs.setChannelEnabled(
                        NotificationChannels.shiftUpdates, v);
                    localPrefs.setChannelEnabled(
                        NotificationChannels.routeUpdates, v);
                  },
                ),
                _ToggleItem(
                  icon: Icons.move_down,
                  iconColor: Colors.orange.shade600,
                  title: 'Move Requests',
                  subtitle: 'Bin move assignments and status updates',
                  value: prefs.moveRequests,
                  onChanged: (v) {
                    ref
                        .read(backendNotificationPreferencesProvider.notifier)
                        .updatePreference(moveRequests: v);
                    localPrefs.setChannelEnabled(
                        NotificationChannels.moveRequests, v);
                  },
                ),
              ]),
              loading: () => _buildCard([
                _ToggleItem(
                  icon: Icons.work_history,
                  iconColor: Colors.green.shade600,
                  title: 'Shift & Route Updates',
                  subtitle:
                      'Shift assignments, cancellations, route assignments',
                  value: true,
                  onChanged: null,
                ),
                _ToggleItem(
                  icon: Icons.move_down,
                  iconColor: Colors.orange.shade600,
                  title: 'Move Requests',
                  subtitle: 'Bin move assignments and status updates',
                  value: true,
                  onChanged: null,
                ),
              ]),
              error: (_, __) => _buildCard([
                _ToggleItem(
                  icon: Icons.work_history,
                  iconColor: Colors.green.shade600,
                  title: 'Shift & Route Updates',
                  subtitle: 'Could not load preferences',
                  value: true,
                  onChanged: null,
                ),
                _ToggleItem(
                  icon: Icons.move_down,
                  iconColor: Colors.orange.shade600,
                  title: 'Move Requests',
                  subtitle: 'Could not load preferences',
                  value: true,
                  onChanged: null,
                ),
              ]),
            ),

            const SizedBox(height: 24),

            // Coming Soon Section (grayed out)
            _buildSectionHeader('COMING SOON'),
            const SizedBox(height: 8),
            Opacity(
              opacity: 0.5,
              child: _buildCard([
                _ToggleItem(
                  icon: Icons.warning_amber_rounded,
                  iconColor: Colors.red.shade400,
                  title: 'High Fill Alerts',
                  subtitle: 'Alerts when bins reach high fill levels',
                  value: false,
                  onChanged: null,
                ),
                _ToggleItem(
                  icon: Icons.priority_high,
                  iconColor: Colors.amber.shade600,
                  title: 'Priority Bins',
                  subtitle: 'Notifications for priority bin changes',
                  value: false,
                  onChanged: null,
                ),
                _ToggleItem(
                  icon: Icons.message_outlined,
                  iconColor: Colors.blue.shade400,
                  title: 'Manager Messages',
                  subtitle: 'Direct messages from management',
                  value: false,
                  onChanged: null,
                ),
              ]),
            ),

            const SizedBox(height: 24),

            // Device Settings Section (local only)
            _buildSectionHeader('DEVICE'),
            const SizedBox(height: 8),
            _buildCard([
              _ToggleItem(
                icon: Icons.notifications_active,
                iconColor: Colors.indigo.shade600,
                title: 'Sound',
                subtitle: 'Play sound for notifications',
                value: soundEnabled.value,
                onChanged: (v) {
                  soundEnabled.value = v;
                  localPrefs.setSoundEnabled(v);
                },
              ),
              _ToggleItem(
                icon: Icons.vibration,
                iconColor: Colors.pink.shade600,
                title: 'Vibration',
                subtitle: 'Vibrate for notifications',
                value: vibrationEnabled.value,
                onChanged: (v) {
                  vibrationEnabled.value = v;
                  localPrefs.setVibrationEnabled(v);
                },
              ),
            ]),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard(List<_ToggleItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: AppColors.backgroundLight,
                indent: 60,
              ),
            _buildToggle(items[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildToggle(_ToggleItem item) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(
            value: item.value,
            onChanged: item.onChanged,
            activeThumbColor: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }
}

class _ToggleItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ToggleItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
}
