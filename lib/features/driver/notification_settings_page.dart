import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/enums/user_role.dart';
import 'package:ropacalapp/core/notifications/notification_channels.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/providers/notification_provider.dart';
import 'package:ropacalapp/providers/notification_preferences_provider.dart';

/// Notification Settings Page - Manage notification preferences
/// Shows all 6 backend-synced toggles for admins, 2 for drivers.
/// Local-only toggles for sound and vibration.
class NotificationSettingsPage extends HookConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localPrefs = ref.read(notificationPreferencesProvider);
    final backendPrefsAsync =
        ref.watch(backendNotificationPreferencesProvider);
    final authState = ref.watch(authNotifierProvider);
    final isAdmin = authState.valueOrNull?.role == UserRole.admin;

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
            // Shifts & Routes Section
            _buildSectionHeader('SHIFTS & ROUTES'),
            const SizedBox(height: 8),
            backendPrefsAsync.when(
              data: (prefs) => _buildCard([
                _ToggleItem(
                  icon: Icons.work_history,
                  iconColor: Colors.green.shade600,
                  title: 'Shift Updates',
                  subtitle:
                      'Shift assignments, cancellations, and route changes',
                  value: prefs.shiftEvents,
                  onChanged: (v) {
                    ref
                        .read(backendNotificationPreferencesProvider.notifier)
                        .updatePreference(shiftEvents: v);
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
              loading: () => _buildLoadingCard(2),
              error: (_, __) => _buildErrorCard(2),
            ),

            // Admin-only sections
            if (isAdmin) ...[
              const SizedBox(height: 24),
              _buildSectionHeader('DAILY REPORTS'),
              const SizedBox(height: 8),
              backendPrefsAsync.when(
                data: (prefs) => _buildCard([
                  _ToggleItem(
                    icon: Icons.assignment_rounded,
                    iconColor: Colors.blue.shade600,
                    title: 'Move Reports',
                    subtitle:
                        'Daily summary of overdue and upcoming moves',
                    value: prefs.digests,
                    onChanged: (v) {
                      ref
                          .read(
                              backendNotificationPreferencesProvider.notifier)
                          .updatePreference(digests: v);
                    },
                  ),
                  _ToggleItem(
                    icon: Icons.fact_check_rounded,
                    iconColor: Colors.teal.shade600,
                    title: 'Bin Check Reports',
                    subtitle:
                        'Daily summary of bins that need checking',
                    value: prefs.binCheckReports,
                    onChanged: (v) {
                      ref
                          .read(
                              backendNotificationPreferencesProvider.notifier)
                          .updatePreference(binCheckReports: v);
                    },
                  ),
                ]),
                loading: () => _buildLoadingCard(2),
                error: (_, __) => _buildErrorCard(2),
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('REAL-TIME ALERTS'),
              const SizedBox(height: 8),
              backendPrefsAsync.when(
                data: (prefs) => _buildCard([
                  _ToggleItem(
                    icon: Icons.gps_off_rounded,
                    iconColor: Colors.red.shade600,
                    title: 'Drift Alerts',
                    subtitle:
                        'Get alerted when bins move from their location',
                    value: prefs.driftAlerts,
                    onChanged: (v) {
                      ref
                          .read(
                              backendNotificationPreferencesProvider.notifier)
                          .updatePreference(driftAlerts: v);
                      localPrefs.setChannelEnabled(
                          NotificationChannels.binAlerts, v);
                    },
                  ),
                  _ToggleItem(
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.red.shade400,
                    title: 'Overdue Move Alerts',
                    subtitle:
                        'Real-time alerts when moves pass their due date',
                    value: prefs.overdueMoveAlerts,
                    onChanged: (v) {
                      ref
                          .read(
                              backendNotificationPreferencesProvider.notifier)
                          .updatePreference(overdueMoveAlerts: v);
                    },
                  ),
                  _ToggleItem(
                    icon: Icons.schedule_rounded,
                    iconColor: Colors.amber.shade600,
                    title: 'Due Soon Alerts',
                    subtitle:
                        'Alerts when moves are approaching their due date',
                    value: prefs.dueSoonAlerts,
                    onChanged: (v) {
                      ref
                          .read(
                              backendNotificationPreferencesProvider.notifier)
                          .updatePreference(dueSoonAlerts: v);
                    },
                  ),
                ]),
                loading: () => _buildLoadingCard(3),
                error: (_, __) => _buildErrorCard(3),
              ),
            ],

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

  Widget _buildLoadingCard(int count) {
    return _buildCard(List.generate(
      count,
      (_) => _ToggleItem(
        icon: Icons.hourglass_empty,
        iconColor: Colors.grey.shade400,
        title: 'Loading...',
        subtitle: '',
        value: true,
        onChanged: null,
      ),
    ));
  }

  Widget _buildErrorCard(int count) {
    return _buildCard(List.generate(
      count,
      (_) => _ToggleItem(
        icon: Icons.error_outline,
        iconColor: Colors.grey.shade400,
        title: 'Could not load',
        subtitle: 'Pull down to retry',
        value: true,
        onChanged: null,
      ),
    ));
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
                if (item.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: item.value,
            onChanged: item.onChanged,
            activeColor: AppColors.primaryGreen,
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
