import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/notifications/notification_channels.dart';
import 'package:ropacalapp/providers/notification_provider.dart';

/// Notification Settings Page - Manage notification preferences
class NotificationSettingsPage extends HookConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.read(notificationPreferencesProvider);
    final isLoaded = useState(false);

    // Channel toggles
    final shiftUpdates = useState(true);
    final routeUpdates = useState(true);
    final moveRequests = useState(true);
    final binAlerts = useState(true);
    final driverAlerts = useState(true);
    final systemUpdates = useState(true);

    // Global toggles
    final soundEnabled = useState(true);
    final vibrationEnabled = useState(true);

    // Load initial values from SharedPreferences
    useEffect(() {
      Future<void> load() async {
        shiftUpdates.value =
            await prefs.isChannelEnabled(NotificationChannels.shiftUpdates);
        routeUpdates.value =
            await prefs.isChannelEnabled(NotificationChannels.routeUpdates);
        moveRequests.value =
            await prefs.isChannelEnabled(NotificationChannels.moveRequests);
        binAlerts.value =
            await prefs.isChannelEnabled(NotificationChannels.binAlerts);
        driverAlerts.value =
            await prefs.isChannelEnabled(NotificationChannels.driverAlerts);
        systemUpdates.value =
            await prefs.isChannelEnabled(NotificationChannels.systemUpdates);
        soundEnabled.value = await prefs.isSoundEnabled();
        vibrationEnabled.value = await prefs.isVibrationEnabled();
        isLoaded.value = true;
      }

      load();
      return null;
    }, []);

    if (!isLoaded.value) {
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

            // Route Updates Section
            _buildSectionHeader('ROUTE UPDATES'),
            const SizedBox(height: 8),
            _buildCard([
              _ToggleItem(
                icon: Icons.route,
                iconColor: Colors.blue.shade600,
                title: 'Route Assignments',
                subtitle: 'New route assignments & updates',
                value: routeUpdates.value,
                onChanged: (v) {
                  routeUpdates.value = v;
                  prefs.setChannelEnabled(
                      NotificationChannels.routeUpdates, v);
                },
              ),
              _ToggleItem(
                icon: Icons.work_history,
                iconColor: Colors.green.shade600,
                title: 'Shift Updates',
                subtitle: 'Shift assignments, edits & cancellations',
                value: shiftUpdates.value,
                onChanged: (v) {
                  shiftUpdates.value = v;
                  prefs.setChannelEnabled(
                      NotificationChannels.shiftUpdates, v);
                },
              ),
              _ToggleItem(
                icon: Icons.move_down,
                iconColor: Colors.orange.shade600,
                title: 'Move Requests',
                subtitle: 'Bin move requests and status updates',
                value: moveRequests.value,
                onChanged: (v) {
                  moveRequests.value = v;
                  prefs.setChannelEnabled(
                      NotificationChannels.moveRequests, v);
                },
              ),
            ]),

            const SizedBox(height: 24),

            // Alerts Section
            _buildSectionHeader('ALERTS'),
            const SizedBox(height: 8),
            _buildCard([
              _ToggleItem(
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.red.shade600,
                title: 'Bin Alerts',
                subtitle: 'High fill levels & bin status changes',
                value: binAlerts.value,
                onChanged: (v) {
                  binAlerts.value = v;
                  prefs.setChannelEnabled(
                      NotificationChannels.binAlerts, v);
                },
              ),
              _ToggleItem(
                icon: Icons.person_pin,
                iconColor: Colors.purple.shade600,
                title: 'Driver Alerts',
                subtitle: 'Driver status changes & location issues',
                value: driverAlerts.value,
                onChanged: (v) {
                  driverAlerts.value = v;
                  prefs.setChannelEnabled(
                      NotificationChannels.driverAlerts, v);
                },
              ),
            ]),

            const SizedBox(height: 24),

            // General Section
            _buildSectionHeader('GENERAL'),
            const SizedBox(height: 8),
            _buildCard([
              _ToggleItem(
                icon: Icons.info_outline,
                iconColor: Colors.teal.shade600,
                title: 'System Updates',
                subtitle: 'App updates & general information',
                value: systemUpdates.value,
                onChanged: (v) {
                  systemUpdates.value = v;
                  prefs.setChannelEnabled(
                      NotificationChannels.systemUpdates, v);
                },
              ),
              _ToggleItem(
                icon: Icons.notifications_active,
                iconColor: Colors.indigo.shade600,
                title: 'Sound',
                subtitle: 'Play sound for notifications',
                value: soundEnabled.value,
                onChanged: (v) {
                  soundEnabled.value = v;
                  prefs.setSoundEnabled(v);
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
                  prefs.setVibrationEnabled(v);
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
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
}
