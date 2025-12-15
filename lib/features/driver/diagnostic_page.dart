import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/services/remote_logger.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/location_provider.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/core/services/session_manager.dart';

/// Diagnostic page showing all critical app state
/// Use this to debug issues like:
/// - Shift not loading after app reopen
/// - Location not available
/// - Navigation not showing
class DiagnosticPage extends ConsumerWidget {
  const DiagnosticPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftState = ref.watch(shiftNotifierProvider);
    final locationState = ref.watch(currentLocationProvider);
    final authState = ref.watch(authNotifierProvider);
    final remoteLogger = ref.read(remoteLoggerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Diagnostics'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: () async {
              // Send all current state to Railway
              await _sendDiagnosticsToBackend(
                ref,
                shiftState,
                locationState,
                authState,
                remoteLogger,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📤 Diagnostics sent to Railway'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              }
            },
            tooltip: 'Send to Railway',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh providers
          ref.invalidate(shiftNotifierProvider);
          ref.invalidate(currentLocationProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSessionSection(),
            const SizedBox(height: 16),
            _buildShiftSection(shiftState),
            const SizedBox(height: 16),
            _buildLocationSection(locationState),
            const SizedBox(height: 16),
            _buildAuthSection(authState),
            const SizedBox(height: 16),
            _buildNavigationLogicSection(shiftState, locationState),
            const SizedBox(height: 16),
            _buildActionsSection(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionSection() {
    final sessionAge = SessionManager.sessionAge;
    final hasActiveSession = SessionManager.hasActiveSession;
    final canQuickRestore = SessionManager.canQuickRestore;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📅 Session Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildRow('Session Age', sessionAge.toString()),
            _buildRow('Has Active Session', hasActiveSession.toString()),
            _buildRow('Can Quick Restore', canQuickRestore.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftSection(shiftState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚚 Shift State',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildRow('Status', shiftState.status.toString()),
            _buildRow('Route ID', shiftState.assignedRouteId ?? 'null'),
            _buildRow('Route Bins', '${shiftState.routeBins.length}'),
            _buildRow('Completed Bins', '${shiftState.completedBins}'),
            _buildRow('Total Bins', '${shiftState.totalBins}'),
            _buildRow('Remaining Bins', '${shiftState.remainingBins.length}'),
            _buildRow('Shift ID', shiftState.shiftId ?? 'null'),
            _buildRow('Start Time', shiftState.startTime?.toString() ?? 'null'),
            const SizedBox(height: 8),
            if (shiftState.routeBins.isNotEmpty) ...[
              const Divider(),
              const Text('Bins Array:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...shiftState.routeBins.take(3).map((bin) =>
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text('• Bin #${bin.binNumber}: ${bin.currentStreet}', style: const TextStyle(fontSize: 12)),
                ),
              ),
              if (shiftState.routeBins.length > 3)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text('... and ${shiftState.routeBins.length - 3} more', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(locationState) {
    final location = locationState.valueOrNull;
    final hasValue = locationState.hasValue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📍 Location State',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildRow('Has Value', hasValue.toString()),
            _buildRow('Is Loading', locationState.isLoading.toString()),
            _buildRow('Has Error', locationState.hasError.toString()),
            if (location != null) ...[
              _buildRow('Latitude', location.latitude.toStringAsFixed(6)),
              _buildRow('Longitude', location.longitude.toStringAsFixed(6)),
              _buildRow('Accuracy', '${location.accuracy.toStringAsFixed(1)}m'),
              _buildRow('Speed', '${location.speed.toStringAsFixed(1)} m/s'),
              _buildRow('Heading', '${location.heading.toStringAsFixed(1)}°'),
              _buildRow('Timestamp', location.timestamp.toString()),
              _buildRow('Age', '${DateTime.now().difference(location.timestamp).inSeconds}s ago'),
            ] else if (locationState.hasError) ...[
              _buildRow('Error', locationState.error.toString(), isError: true),
            ] else ...[
              _buildRow('Status', 'Acquiring GPS...', isWarning: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuthSection(authState) {
    final user = authState.valueOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👤 Auth State',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildRow('Has User', (user != null).toString()),
            if (user != null) ...[
              _buildRow('Email', user.email),
              _buildRow('Role', user.role.toString()),
              _buildRow('User ID', user.id),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationLogicSection(shiftState, locationState) {
    final condition1 = shiftState.status.toString() == 'ShiftStatus.active';
    final condition2 = shiftState.routeBins.isNotEmpty;
    final condition3 = locationState.hasValue;
    final allConditionsMet = condition1 && condition2 && condition3;

    return Card(
      color: allConditionsMet ? AppColors.successGreen.withOpacity(0.1) : AppColors.alertRed.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧭 Navigation Logic Check',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('To show GoogleNavigationPage, ALL must be true:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            _buildConditionRow('1. status == ShiftStatus.active', condition1),
            _buildConditionRow('2. routeBins.isNotEmpty', condition2),
            _buildConditionRow('3. locationState.hasValue', condition3),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  allConditionsMet ? Icons.check_circle : Icons.cancel,
                  color: allConditionsMet ? AppColors.successGreen : AppColors.alertRed,
                ),
                const SizedBox(width: 8),
                Text(
                  allConditionsMet
                    ? 'Should show GoogleNavigationPage ✅'
                    : 'Will show DriverMapPage (no active shift) ❌',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: allConditionsMet ? AppColors.successGreen : AppColors.alertRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '⚙️ Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await ref.read(shiftNotifierProvider.notifier).fetchCurrentShift();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🔄 Shift refreshed from backend')),
                  );
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Shift from Backend'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                await ref.read(currentLocationProvider.notifier).refresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('📍 Location refreshed')),
                  );
                }
              },
              icon: const Icon(Icons.my_location),
              label: const Text('Refresh GPS Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                final data = _buildDiagnosticText(ref);
                Clipboard.setData(ClipboardData(text: data));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('📋 Copied to clipboard')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy All Diagnostics'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isError = false, bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isError ? AppColors.alertRed : (isWarning ? AppColors.warningOrange : null),
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionRow(String label, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_box : Icons.check_box_outline_blank,
            size: 20,
            color: isMet ? AppColors.successGreen : AppColors.alertRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isMet ? AppColors.successGreen : AppColors.alertRed,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildDiagnosticText(WidgetRef ref) {
    final shiftState = ref.read(shiftNotifierProvider);
    final locationState = ref.read(currentLocationProvider);
    final authState = ref.read(authNotifierProvider);
    final location = locationState.valueOrNull;

    return '''
=== DIAGNOSTICS SNAPSHOT ===
Timestamp: ${DateTime.now().toIso8601String()}

SESSION:
- Session Age: ${SessionManager.sessionAge}
- Has Active Session: ${SessionManager.hasActiveSession}
- Can Quick Restore: ${SessionManager.canQuickRestore}

SHIFT STATE:
- Status: ${shiftState.status}
- Route ID: ${shiftState.assignedRouteId}
- Route Bins Count: ${shiftState.routeBins.length}
- Completed: ${shiftState.completedBins}/${shiftState.totalBins}
- Shift ID: ${shiftState.shiftId}

LOCATION STATE:
- Has Value: ${locationState.hasValue}
- Is Loading: ${locationState.isLoading}
- Lat/Lng: ${location?.latitude.toStringAsFixed(6)}, ${location?.longitude.toStringAsFixed(6)}
- Accuracy: ${location?.accuracy.toStringAsFixed(1)}m
- Age: ${location != null ? DateTime.now().difference(location.timestamp).inSeconds : 'N/A'}s

AUTH STATE:
- Has User: ${authState.valueOrNull != null}
- Email: ${authState.valueOrNull?.email}
- Role: ${authState.valueOrNull?.role}

NAVIGATION LOGIC:
- status == active: ${shiftState.status.toString() == 'ShiftStatus.active'}
- routeBins.isNotEmpty: ${shiftState.routeBins.isNotEmpty}
- locationState.hasValue: ${locationState.hasValue}
- SHOULD SHOW NAVIGATION: ${shiftState.status.toString() == 'ShiftStatus.active' && shiftState.routeBins.isNotEmpty && locationState.hasValue}
''';
  }

  Future<void> _sendDiagnosticsToBackend(
    WidgetRef ref,
    shiftState,
    locationState,
    authState,
    RemoteLogger remoteLogger,
  ) async {
    final location = locationState.valueOrNull;

    await remoteLogger.log(
      context: 'FULL_DIAGNOSTIC_SNAPSHOT',
      message: 'Complete app state snapshot',
      data: {
        'session': {
          'age': SessionManager.sessionAge.toString(),
          'has_active_session': SessionManager.hasActiveSession,
          'can_quick_restore': SessionManager.canQuickRestore,
        },
        'shift': {
          'status': shiftState.status.toString(),
          'route_id': shiftState.assignedRouteId,
          'route_bins_count': shiftState.routeBins.length,
          'completed_bins': shiftState.completedBins,
          'total_bins': shiftState.totalBins,
          'shift_id': shiftState.shiftId,
          'start_time': shiftState.startTime?.toIso8601String(),
        },
        'location': {
          'has_value': locationState.hasValue,
          'is_loading': locationState.isLoading,
          'has_error': locationState.hasError,
          'latitude': location?.latitude,
          'longitude': location?.longitude,
          'accuracy': location?.accuracy,
          'age_seconds': location != null ? DateTime.now().difference(location.timestamp).inSeconds : null,
        },
        'auth': {
          'has_user': authState.valueOrNull != null,
          'email': authState.valueOrNull?.email,
          'role': authState.valueOrNull?.role.toString(),
          'user_id': authState.valueOrNull?.id,
        },
        'navigation_logic': {
          'condition_status_active': shiftState.status.toString() == 'ShiftStatus.active',
          'condition_bins_not_empty': shiftState.routeBins.isNotEmpty,
          'condition_location_has_value': locationState.hasValue,
          'should_show_navigation': shiftState.status.toString() == 'ShiftStatus.active' &&
                                     shiftState.routeBins.isNotEmpty &&
                                     locationState.hasValue,
        },
      },
      level: 'INFO',
    );
  }
}
