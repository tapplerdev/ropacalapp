import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ropacalapp/core/constants/bin_constants.dart';
import 'package:ropacalapp/core/enums/bin_status.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/bin_helpers.dart';
import 'package:ropacalapp/features/driver/widgets/move_dialog.dart';
import 'package:ropacalapp/models/bin.dart';
import 'package:ropacalapp/providers/bins_provider.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';

class BinDetailPage extends HookConsumerWidget {
  final String binId;

  const BinDetailPage({super.key, required this.binId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final binsState = ref.watch(binsListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: binsState.when(
        data: (bins) {
          final bin = bins.firstWhere((b) => b.id == binId);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(bin),
                  const SizedBox(height: 24),
                  _buildFillLevelCard(context, bin),
                  const SizedBox(height: 16),
                  _buildInfoCard(context, bin),
                  const SizedBox(height: 20),
                  _buildActionButtons(context, bin, ref),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Bin bin) {
    return Row(
      children: [
        Text(
          'Bin #${bin.binNumber}',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: bin.status == BinStatus.active
                ? AppColors.successGreen
                : AppColors.alertRed,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            bin.status == BinStatus.active ? 'ACTIVE' : 'MISSING',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFillLevelCard(BuildContext context, Bin bin) {
    final fillPercentage = bin.fillPercentage ?? 0;
    final fillColor = BinHelpers.getFillColor(fillPercentage);
    final fillDescription = BinHelpers.getFillDescription(fillPercentage);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: fillColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: fillColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Fill Level',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Text(
                '$fillPercentage%',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: fillColor,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fillPercentage / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.7),
              valueColor: AlwaysStoppedAnimation(fillColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            fillDescription,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (bin.lastChecked != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  'Last checked ${_formatDateTime(bin.lastChecked!.toIso8601String())}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Bin bin) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.home_outlined,
            'Address',
            bin.currentStreet,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.location_city_outlined,
            'City',
            '${bin.city}, ${bin.zip}',
          ),
          if (bin.latitude != null && bin.longitude != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.my_location_outlined,
              'Coordinates',
              '${bin.latitude!.toStringAsFixed(4)}, ${bin.longitude!.toStringAsFixed(4)}',
            ),
          ],
          if (bin.lastMoved != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.local_shipping_outlined,
              'Last Moved',
              _formatDateTime(bin.lastMoved!.toIso8601String()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Bin bin, WidgetRef ref) {
    return Column(
      children: [
        _buildActionButton(
          context: context,
          icon: Icons.local_shipping_outlined,
          label: 'Move Bin',
          color: AppColors.primaryGreen,
          onTap: () => _showMoveDialog(context, bin, ref),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.history_rounded,
                label: 'Check History',
                color: Colors.blue.shade600,
                onTap: () => _showCheckHistoryModal(context, bin),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context: context,
                icon: Icons.drive_eta_outlined,
                label: 'Move History',
                color: Colors.orange.shade700,
                onTap: () => _showMoveHistoryModal(context, bin),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMoveDialog(BuildContext context, Bin bin, WidgetRef ref) async {
    try {
      // Check for active move requests
      final managerService = ref.read(managerServiceProvider);
      final activeRequests = await managerService.getBinMoveRequests(
        bin.id,
        status: null, // Get all statuses
      );

      // Filter to only active requests (not completed or cancelled)
      final active = activeRequests.where((r) {
        final status = r['status'] as String?;
        return status != 'completed' && status != 'cancelled';
      }).toList();

      if (active.isEmpty) {
        // No active requests - proceed normally
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => MoveDialog(bin: bin),
          );
        }
        return;
      }

      // Has active requests - show appropriate warning
      final inProgress = active.where((r) => r['status'] == 'in_progress').toList();
      final assigned = active.where((r) => r['status'] == 'assigned').toList();
      final pending = active.where((r) => r['status'] == 'pending').toList();

      if (context.mounted) {
        if (inProgress.isNotEmpty) {
          _showInProgressDialog(context, bin, inProgress[0], ref);
        } else if (assigned.isNotEmpty && pending.isEmpty) {
          if (assigned.length == 1) {
            _showSingleAssignedDialog(context, bin, assigned[0], ref);
          } else {
            _showMultipleAssignedDialog(context, bin, assigned, ref);
          }
        } else if (pending.isNotEmpty && assigned.isEmpty) {
          if (pending.length == 1) {
            _showSinglePendingDialog(context, bin, pending[0], ref);
          } else {
            _showMultiplePendingDialog(context, bin, pending, ref);
          }
        } else {
          // Mixed statuses
          _showMixedStatusDialog(context, bin, active, ref);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking move requests: $e')),
        );
      }
    }
  }

  // Dialog Scenarios

  void _showInProgressDialog(
    BuildContext context,
    Bin bin,
    Map<String, dynamic> moveRequest,
    WidgetRef ref,
  ) {
    final driverName = moveRequest['driver_name'] as String? ?? 'A driver';
    final newStreet = moveRequest['new_street'] as String?;
    final newCity = moveRequest['new_city'] as String?;
    final newZip = moveRequest['new_zip'] as String?;
    final moveRequestId = moveRequest['id'] as String;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text('🚚', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Move In Progress'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$driverName is currently moving this bin to:'),
            if (newStreet != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(newStreet,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (newCity != null && newZip != null)
                            Text('$newCity $newZip',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text('Cancel this move to create a new one?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Driver will be notified',
                        style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              await _cancelAndContinue(context, bin, moveRequestId, ref);
            },
            child: const Text('Cancel Move & Continue'),
          ),
        ],
      ),
    );
  }

  void _showSingleAssignedDialog(
    BuildContext context,
    Bin bin,
    Map<String, dynamic> moveRequest,
    WidgetRef ref,
  ) {
    final driverName = moveRequest['driver_name'] as String? ?? 'Unknown';
    final scheduledDateIso = moveRequest['scheduled_date_iso'] as String?;
    final moveType = moveRequest['move_type'] as String? ?? 'relocation';
    final moveRequestId = moveRequest['id'] as String;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text('📍', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Driver Assigned'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This bin is assigned to:'),
            const SizedBox(height: 12),
            _buildInfoChip(Icons.person, 'Driver', driverName),
            if (scheduledDateIso != null) ...[
              const SizedBox(height: 8),
              _buildInfoChip(Icons.calendar_today, 'Scheduled',
                  _formatDateTime(scheduledDateIso)),
            ],
            const SizedBox(height: 8),
            _buildInfoChip(
                Icons.local_shipping,
                'Type',
                moveType == 'pickup_only' ? 'Pickup Only' : 'Relocation'),
            const SizedBox(height: 12),
            const Text('What would you like to do?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showMoveHistoryModal(context, bin);
            },
            child: const Text('View All'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(context: context, builder: (context) => MoveDialog(bin: bin));
            },
            child: const Text('Keep Both'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _cancelAndContinue(context, bin, moveRequestId, ref);
            },
            child: const Text('Cancel & Replace'),
          ),
        ],
      ),
    );
  }

  void _showMultipleAssignedDialog(
    BuildContext context,
    Bin bin,
    List<Map<String, dynamic>> moveRequests,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('📍', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text('${moveRequests.length} Requests Assigned to Drivers'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...moveRequests.take(3).map((r) {
              final driverName = r['driver_name'] as String? ?? 'Unknown';
              final moveType = r['move_type'] as String? ?? 'relocation';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '• $driverName - ${moveType == 'pickup_only' ? 'Pickup Only' : 'Relocation'}',
                ),
              );
            }),
            const SizedBox(height: 12),
            const Text('Creating another request may cause conflicts.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(context: context, builder: (context) => MoveDialog(bin: bin));
            },
            child: const Text('Continue Anyway'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showMoveHistoryModal(context, bin);
            },
            child: const Text('View/Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              await _cancelAllAndContinue(context, bin, moveRequests, ref);
            },
            child: const Text('Cancel All'),
          ),
        ],
      ),
    );
  }

  void _showSinglePendingDialog(
    BuildContext context,
    Bin bin,
    Map<String, dynamic> moveRequest,
    WidgetRef ref,
  ) {
    final moveType = moveRequest['move_type'] as String? ?? 'relocation';
    final scheduledDateIso = moveRequest['scheduled_date_iso'] as String?;
    final requestedByName = moveRequest['requested_by_name'] as String?;
    final moveRequestId = moveRequest['id'] as String;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text('📋', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Pending Move Request'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This bin has 1 pending move request:'),
            const SizedBox(height: 12),
            _buildInfoChip(
                Icons.local_shipping,
                'Type',
                moveType == 'pickup_only' ? 'Pickup Only' : 'Relocation'),
            if (scheduledDateIso != null) ...[
              const SizedBox(height: 8),
              _buildInfoChip(Icons.calendar_today, 'Scheduled',
                  _formatDateTime(scheduledDateIso)),
            ],
            if (requestedByName != null) ...[
              const SizedBox(height: 8),
              _buildInfoChip(Icons.person, 'Requested by', requestedByName),
            ],
            const SizedBox(height: 12),
            const Text('Continue creating another request?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(context: context, builder: (context) => MoveDialog(bin: bin));
            },
            child: const Text('Continue Anyway'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showMoveHistoryModal(context, bin);
            },
            child: const Text('View All'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _cancelAndContinue(context, bin, moveRequestId, ref);
            },
            child: const Text('Cancel Existing'),
          ),
        ],
      ),
    );
  }

  void _showMultiplePendingDialog(
    BuildContext context,
    Bin bin,
    List<Map<String, dynamic>> moveRequests,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('📋', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text('${moveRequests.length} Pending Move Requests'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This bin has multiple pending move requests:'),
            const SizedBox(height: 12),
            ...moveRequests.take(3).map((r) {
              final moveType = r['move_type'] as String? ?? 'relocation';
              final scheduledDateIso = r['scheduled_date_iso'] as String?;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${moveType == 'pickup_only' ? 'Pickup Only' : 'Relocation'} - ${scheduledDateIso != null ? _formatDateTime(scheduledDateIso) : 'Unknown'}',
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }),
            const SizedBox(height: 12),
            const Text('Review existing requests before creating another?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(context: context, builder: (context) => MoveDialog(bin: bin));
            },
            child: const Text('Continue Anyway'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showMoveHistoryModal(context, bin);
            },
            child: const Text('View/Cancel'),
          ),
        ],
      ),
    );
  }

  void _showMixedStatusDialog(
    BuildContext context,
    Bin bin,
    List<Map<String, dynamic>> moveRequests,
    WidgetRef ref,
  ) {
    final assigned = moveRequests.where((r) => r['status'] == 'assigned').length;
    final pending = moveRequests.where((r) => r['status'] == 'pending').length;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.warningOrange.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warningOrange,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warningOrange.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Move Requests',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${moveRequests.length} ${moveRequests.length == 1 ? 'request' : 'requests'} found',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'This bin has active move requests that haven\'t been completed yet:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (assigned > 0)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.blue.shade100,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.person_pin_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Assigned to Driver',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$assigned ${assigned == 1 ? 'request' : 'requests'}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (assigned > 0 && pending > 0) const SizedBox(height: 10),
                      if (pending > 0)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.orange.shade100,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade600,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.schedule_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pending Assignment',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$pending ${pending == 1 ? 'request' : 'requests'}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Review existing requests before creating another.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.grey.shade100,
                            ),
                            child: const Text(
                              'Go Back',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showMoveHistoryModal(context, bin);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showDialog(context: context, builder: (context) => MoveDialog(bin: bin));
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Continue Anyway',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 13)),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAndContinue(
    BuildContext context,
    Bin bin,
    String moveRequestId,
    WidgetRef ref,
  ) async {
    try {
      final managerService = ref.read(managerServiceProvider);
      await managerService.cancelMoveRequest(moveRequestId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Move request cancelled')),
        );
        showDialog(
          context: context,
          builder: (context) => MoveDialog(bin: bin),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling request: $e')),
        );
      }
    }
  }

  Future<void> _cancelAllAndContinue(
    BuildContext context,
    Bin bin,
    List<Map<String, dynamic>> moveRequests,
    WidgetRef ref,
  ) async {
    try {
      final managerService = ref.read(managerServiceProvider);
      for (final request in moveRequests) {
        await managerService.cancelMoveRequest(request['id'] as String);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${moveRequests.length} requests cancelled')),
        );
        showDialog(
          context: context,
          builder: (context) => MoveDialog(bin: bin),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling requests: $e')),
        );
      }
    }
  }

  void _showCheckHistoryModal(BuildContext context, Bin bin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CheckHistoryModalContent(bin: bin),
    );
  }

  void _showMoveHistoryModal(BuildContext context, Bin bin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MoveHistoryModalContent(bin: bin),
    );
  }

  String _formatDateTime(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today at ${DateFormat('h:mm a').format(date)}';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${DateFormat('h:mm a').format(date)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d, yyyy').format(date);
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}

class _MoveHistoryModalContent extends HookConsumerWidget {
  final Bin bin;

  const _MoveHistoryModalContent({required this.bin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = useState<String?>('all');
    final moveRequestsFuture = useMemoized(
      () => ref.read(managerServiceProvider).getBinMoveRequests(bin.id),
      [bin.id],
    );
    final moveRequestsSnapshot = useFuture(moveRequestsFuture);

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_shipping_outlined,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Move History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            // Filter chips
            Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('All', 'all', selectedFilter),
                  const SizedBox(width: 10),
                  _buildFilterChip('Pending', 'pending', selectedFilter),
                  const SizedBox(width: 10),
                  _buildFilterChip('Assigned', 'assigned', selectedFilter),
                  const SizedBox(width: 10),
                  _buildFilterChip('In Progress', 'in_progress', selectedFilter),
                  const SizedBox(width: 10),
                  _buildFilterChip('Completed', 'completed', selectedFilter),
                  const SizedBox(width: 10),
                  _buildFilterChip('Cancelled', 'cancelled', selectedFilter),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: _buildContent(
                context,
                ref,
                scrollController,
                moveRequestsSnapshot,
                selectedFilter.value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    ValueNotifier<String?> selectedFilter,
  ) {
    final isSelected = selectedFilter.value == value;

    return GestureDetector(
      onTap: () => selectedFilter.value = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGreen
                : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ScrollController scrollController,
    AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
    String? selectedFilter,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGreen,
        ),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade700,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load move history',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              SelectableText.rich(
                TextSpan(
                  text: snapshot.error.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[600],
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final allMoveRequests = snapshot.data ?? [];

    // Apply filter
    final filteredMoveRequests = selectedFilter == null || selectedFilter == 'all'
        ? allMoveRequests
        : allMoveRequests.where((r) {
            final status = r['status'] as String?;
            return status == selectedFilter;
          }).toList();

    if (filteredMoveRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                size: 48,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              selectedFilter == 'all' || selectedFilter == null
                  ? 'No Move Requests'
                  : 'No ${selectedFilter.replaceAll('_', ' ').toUpperCase()} Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              selectedFilter == 'all' || selectedFilter == null
                  ? 'Move requests will appear here'
                  : 'Try selecting a different filter',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: filteredMoveRequests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final moveRequest = filteredMoveRequests[index];
        return _buildMoveRequestItem(context, ref, moveRequest);
      },
    );
  }

  Widget _buildMoveRequestItem(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> moveRequest,
  ) {
    final status = moveRequest['status'] as String? ?? 'pending';
    final moveRequestId = moveRequest['id'] as String;
    final urgency = moveRequest['urgency'] as String? ?? 'scheduled';
    final moveType = moveRequest['move_type'] as String? ?? 'relocation';
    final scheduledDateIso = moveRequest['scheduled_date_iso'] as String?;
    final requestedByName = moveRequest['requested_by_name'] as String?;
    final driverName = moveRequest['driver_name'] as String?;
    final reason = moveRequest['reason'] as String?;
    final notes = moveRequest['notes'] as String?;
    final disposalAction = moveRequest['disposal_action'] as String?;
    final originalStreet = moveRequest['original_street'] as String?;
    final originalCity = moveRequest['original_city'] as String?;
    final originalZip = moveRequest['original_zip'] as String?;
    final newStreet = moveRequest['new_street'] as String?;
    final newCity = moveRequest['new_city'] as String?;
    final newZip = moveRequest['new_zip'] as String?;

    // Get status color
    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange.shade700;
        break;
      case 'assigned':
        statusColor = Colors.blue.shade700;
        break;
      case 'in_progress':
        statusColor = Colors.purple.shade700;
        break;
      case 'completed':
        statusColor = AppColors.successGreen;
        break;
      case 'cancelled':
        statusColor = Colors.red.shade700;
        break;
      default:
        statusColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status and urgency
          Row(
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Urgency badge
              if (urgency == 'urgent')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.red.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'URGENT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              // Move type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: moveType == 'pickup_only'
                      ? Colors.purple.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: moveType == 'pickup_only'
                        ? Colors.purple.shade300
                        : Colors.blue.shade300,
                    width: 1,
                  ),
                ),
                child: Text(
                  moveType == 'pickup_only' ? 'PICKUP' : 'RELOCATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: moveType == 'pickup_only'
                        ? Colors.purple.shade700
                        : Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Scheduled date
          if (scheduledDateIso != null) ...[
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatMoveDate(scheduledDateIso),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          // Requester
          if (requestedByName != null) ...[
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 8),
                Text(
                  'Requested by $requestedByName',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          // Assigned to
          Row(
            children: [
              Icon(
                Icons.person_pin_outlined,
                size: 16,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 8),
              Text(
                driverName != null
                    ? 'Assigned to $driverName'
                    : 'Not yet assigned',
                style: TextStyle(
                  fontSize: 13,
                  color: driverName != null
                      ? Colors.grey.shade700
                      : Colors.grey.shade500,
                  fontStyle:
                      driverName != null ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Relocation details (from → to)
          if (moveType == 'relocation' &&
              originalStreet != null &&
              newStreet != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // From location
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.my_location,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              originalStreet,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (originalCity != null && originalZip != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '$originalCity $originalZip',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Arrow
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.arrow_downward,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // To location
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              newStreet,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (newCity != null && newZip != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '$newCity $newZip',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Disposal action (for pickups)
          if (moveType == 'pickup_only' && disposalAction != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: disposalAction == 'retire'
                    ? Colors.red.shade50
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: disposalAction == 'retire'
                      ? Colors.red.shade300
                      : Colors.amber.shade300,
                  width: 1,
                ),
              ),
              child: Text(
                'Disposal: ${disposalAction.toUpperCase()}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: disposalAction == 'retire'
                      ? Colors.red.shade700
                      : Colors.amber.shade900,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Reason
          if (reason != null && reason.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Notes
          if (notes != null && notes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Cancel button (only for active requests)
          if (status == 'pending' || status == 'assigned' || status == 'in_progress') ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCancelConfirmation(
                  context,
                  ref,
                  moveRequestId,
                  status,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: Colors.red.shade200,
                      width: 1,
                    ),
                  ),
                ),
                icon: Icon(
                  Icons.cancel_outlined,
                  size: 18,
                  color: Colors.red.shade700,
                ),
                label: Text(
                  'Cancel Move Request',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showCancelConfirmation(
    BuildContext context,
    WidgetRef ref,
    String moveRequestId,
    String status,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.shade600.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cancel Request?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Confirm cancellation',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context, false),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status == 'in_progress'
                          ? 'This request is currently in progress. The driver will be notified if you cancel it.'
                          : status == 'assigned'
                              ? 'This request is assigned to a driver. Cancelling will remove it from their route.'
                              : 'Are you sure you want to cancel this move request?',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 20,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This action cannot be undone.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.grey.shade100,
                        ),
                        child: const Text(
                          'Go Back',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel Request',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Show loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Cancelling move request...'),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.grey.shade700,
          ),
        );

        // Cancel the request
        await ref.read(managerServiceProvider).cancelMoveRequest(moveRequestId);

        if (context.mounted) {
          // Close the modal and show success
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Move request cancelled successfully',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Failed to cancel: $e')),
                ],
              ),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  Widget _buildMoveItem(Map<String, dynamic> move, bool isLast) {
    final movedAt = move['movedOnIso'] as String?;
    final fromStreet = move['fromStreet'] as String? ?? 'Unknown';
    final fromCity = move['fromCity'] as String? ?? '';
    final toStreet = move['toStreet'] as String? ?? 'Unknown';
    final toCity = move['toCity'] as String? ?? '';
    final moveType = move['moveType'] as String? ?? 'shift'; // 'shift' or 'manual'

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                movedAt != null ? _formatMoveDate(movedAt) : 'Unknown date',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: moveType == 'manual'
                      ? Colors.amber.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: moveType == 'manual'
                        ? Colors.amber.shade300
                        : Colors.blue.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      moveType == 'manual' ? '👤' : '🚛',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      moveType == 'manual' ? 'MANUAL' : 'SHIFT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: moveType == 'manual'
                            ? Colors.amber.shade900
                            : Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // From location
          _buildLocationRow(
            icon: Icons.my_location,
            iconColor: Colors.orange.shade700,
            label: 'From',
            street: fromStreet,
            city: fromCity,
          ),
          const SizedBox(height: 12),
          // Arrow
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(
              Icons.arrow_downward,
              size: 20,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 12),
          // To location
          _buildLocationRow(
            icon: Icons.location_on,
            iconColor: AppColors.primaryGreen,
            label: 'To',
            street: toStreet,
            city: toCity,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String street,
    required String city,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                street,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (city.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  city,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatMoveDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today at ${DateFormat('h:mm a').format(date)}';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${DateFormat('h:mm a').format(date)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d, yyyy \'at\' h:mm a').format(date);
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}

class _CheckHistoryModalContent extends HookConsumerWidget {
  final Bin bin;

  const _CheckHistoryModalContent({required this.bin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkHistoryFuture = useMemoized(
      () => ref.read(managerServiceProvider).getBinCheckHistory(bin.id),
      [bin.id],
    );
    final checkHistorySnapshot = useFuture(checkHistoryFuture);

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: Colors.blue.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Check History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: _buildContent(context, scrollController, checkHistorySnapshot),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
    AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGreen,
        ),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade700,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load check history',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              SelectableText.rich(
                TextSpan(
                  text: snapshot.error.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[600],
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final checks = snapshot.data ?? [];

    if (checks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 48,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Check History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check-ins will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: checks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final check = checks[index];
        return _buildCheckItem(check);
      },
    );
  }

  Widget _buildCheckItem(Map<String, dynamic> check) {
    final checkedOnIso = check['checkedOnIso'] as String?;
    final fillPercentage = check['fillPercentage'] as int?;
    final checkedByName = check['checkedByName'] as String?;
    final checkedFrom = check['checkedFrom'] as String? ?? 'Unknown location';
    final photoUrl = check['photoUrl'] as String?;

    final fillColor = fillPercentage != null
        ? BinHelpers.getFillColor(fillPercentage)
        : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and driver info header
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checkedOnIso != null
                          ? _formatCheckDate(checkedOnIso)
                          : 'Unknown date',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (checkedByName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'by $checkedByName',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Fill percentage badge
              if (fillPercentage != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: fillColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: fillColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$fillPercentage%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: fillColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Location info
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  checkedFrom,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          // Photo thumbnail if available
          if (photoUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photoUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey.shade400,
                      size: 48,
                    ),
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 150,
                    color: Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCheckDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today at ${DateFormat('h:mm a').format(date)}';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${DateFormat('h:mm a').format(date)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d, yyyy \'at\' h:mm a').format(date);
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
