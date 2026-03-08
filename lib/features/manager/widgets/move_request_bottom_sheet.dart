import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/widgets/route_map_preview.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';


class MoveRequestBottomSheet extends HookConsumerWidget {
  final Map<String, dynamic> data;
  final String computedUrgency;

  const MoveRequestBottomSheet({
    super.key,
    required this.data,
    required this.computedUrgency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);

    final id = data['id'] as String? ?? '';
    final status = data['status'] as String? ?? 'pending';
    final moveType = data['move_type'] as String? ?? 'relocation';
    final binNumber = data['bin_number'] as int? ?? 0;
    final currentStreet = data['current_street'] as String? ?? '';
    final city = data['city'] as String? ?? '';
    final zip = data['zip'] as String? ?? '';
    final requestedByName = data['requested_by_name'] as String?;
    final scheduledDateIso = data['scheduled_date_iso'] as String?;
    final createdAtIso = data['created_at_iso'] as String?;
    final completedAtIso = data['completed_at_iso'] as String?;
    final assignmentType = data['assignment_type'] as String? ?? '';
    final reason = data['reason'] as String?;
    final reasonCategory = data['reason_category'] as String?;
    final notes = data['notes'] as String?;
    final driverName = data['driver_name'] as String?
        ?? data['assigned_driver_name'] as String?
        ?? data['assigned_user_name'] as String?;

    // Destination (for relocation)
    final newAddress = data['new_address'] as String?;
    final newStreet = data['new_street'] as String?;
    final newCity = data['new_city'] as String?;

    // Coordinates for map preview
    final origLat = (data['original_latitude'] as num?)?.toDouble();
    final origLng = (data['original_longitude'] as num?)?.toDouble();
    final newLat = (data['new_latitude'] as num?)?.toDouble();
    final newLng = (data['new_longitude'] as num?)?.toDouble();
    final sourcePotentialLocationId = data['source_potential_location_id'] as String?;

    final statusColor = _statusColor(status);
    final urgencyInfo = _urgencyInfo(computedUrgency);

    final canAssign = status == 'pending';
    final canCancel = status == 'pending' || status == 'assigned';
    final canComplete = status == 'assigned' || status == 'in_progress';
    final hasActions = canAssign || canCancel || canComplete;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: icon + title + status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      color: AppColors.primaryGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bin #$binNumber',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (computedUrgency != 'resolved' &&
                                computedUrgency != 'scheduled') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: urgencyInfo.color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(urgencyInfo.icon,
                                        size: 12, color: Colors.white),
                                    const SizedBox(width: 3),
                                    Text(
                                      urgencyInfo.label,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Map preview (if coordinates are available)
              if (origLat != null && origLng != null) ...[
                RouteMapPreview(
                  originLat: origLat,
                  originLng: origLng,
                  destLat: newLat,
                  destLng: newLng,
                  binNumber: binNumber,
                  moveType: moveType,
                  sourcePotentialLocationId: sourcePotentialLocationId,
                  managerService: ref.read(managerServiceProvider),
                  height: 180,
                  showLegend: true,
                  onViewFullScreen: () {
                    _showFullScreenMap(
                      context,
                      ref,
                      origLat: origLat,
                      origLng: origLng,
                      newLat: newLat,
                      newLng: newLng,
                      binNumber: binNumber,
                      moveType: moveType,
                      sourcePotentialLocationId: sourcePotentialLocationId,
                      currentStreet: currentStreet,
                      city: city,
                      newStreet: newStreet ?? '',
                      newCity: newCity ?? '',
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Location flow card
              _buildLocationFlow(
                moveType: moveType,
                currentStreet: currentStreet,
                city: city,
                zip: zip,
                newStreet: newStreet,
                newCity: newCity,
                newAddress: newAddress,
              ),

              const SizedBox(height: 12),

              // Detail rows
              _buildDetailRow(
                icon: Icons.category_outlined,
                label: 'Move Type',
                value: _moveTypeLabel(moveType),
                valueColor: moveType == 'store'
                    ? Colors.purple.shade700
                    : Colors.blue.shade700,
              ),
              if (assignmentType.isNotEmpty)
                _buildDetailRow(
                  icon: Icons.settings_outlined,
                  label: 'Assignment',
                  value: assignmentType == 'manual'
                      ? 'Manual'
                      : 'Shift',
                ),
              if (requestedByName != null)
                _buildDetailRow(
                  icon: Icons.person_outline,
                  label: 'Requested By',
                  value: requestedByName,
                ),
              if (driverName != null)
                _buildDetailRow(
                  icon: Icons.assignment_ind_outlined,
                  label: 'Assigned To',
                  value: driverName,
                  valueColor: Colors.blue.shade700,
                ),
              if (driverName == null &&
                  (status == 'pending'))
                _buildDetailRow(
                  icon: Icons.assignment_ind_outlined,
                  label: 'Assigned To',
                  value: 'Unassigned',
                  valueColor: Colors.orange.shade700,
                ),
              if (scheduledDateIso != null)
                _buildDetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Scheduled',
                  value: _formatDate(scheduledDateIso),
                ),
              if (createdAtIso != null)
                _buildDetailRow(
                  icon: Icons.access_time,
                  label: 'Created',
                  value: _formatDate(createdAtIso),
                ),
              if (completedAtIso != null)
                _buildDetailRow(
                  icon: Icons.check_circle_outline,
                  label: 'Completed',
                  value: _formatDate(completedAtIso),
                  valueColor: AppColors.successGreen,
                ),
              if (reasonCategory != null && reasonCategory.isNotEmpty)
                _buildDetailRow(
                  icon: Icons.label_outline,
                  label: 'Category',
                  value: reasonCategory,
                ),

              // Reason
              if (reason != null && reason.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reason,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Notes
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notes,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action buttons
              if (hasActions) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                if (canAssign)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading.value
                            ? null
                            : () => _showAssignUserSheet(
                                  context,
                                  ref,
                                  id,
                                  isLoading,
                                ),
                        icon: const Icon(Icons.person_add_outlined, size: 20),
                        label: const Text(
                          'Assign to User',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (canComplete)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading.value
                            ? null
                            : () => _confirmComplete(
                                  context,
                                  ref,
                                  id,
                                  binNumber,
                                  isLoading,
                                ),
                        icon: isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text(
                          'Complete Manually',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (canCancel)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading.value
                          ? null
                          : () => _confirmCancel(
                                context,
                                ref,
                                id,
                                binNumber,
                                isLoading,
                              ),
                      icon: const Icon(Icons.cancel_outlined, size: 20),
                      label: const Text(
                        'Cancel Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildLocationFlow({
    required String moveType,
    required String currentStreet,
    required String city,
    required String zip,
    String? newStreet,
    String? newCity,
    String? newAddress,
  }) {
    // Determine labels and addresses based on move type
    final String fromLabel;
    final String fromAddress;
    final String fromSub;
    final IconData fromIcon;
    final Color fromColor;

    final String toLabel;
    final String toAddress;
    final String toSub;
    final IconData toIcon;
    final Color toColor;

    switch (moveType) {
      case 'store':
        fromLabel = 'Pickup';
        fromAddress = currentStreet;
        fromSub = [city, zip].where((s) => s.isNotEmpty).join(', ');
        fromIcon = Icons.location_on;
        fromColor = AppColors.primaryGreen;
        toLabel = 'To Warehouse';
        toAddress = newStreet ?? newAddress ?? 'Warehouse';
        toSub = newCity ?? '';
        toIcon = Icons.warehouse;
        toColor = const Color(0xFF9C27B0);
        break;
      case 'redeployment':
        fromLabel = 'From Storage';
        fromAddress = currentStreet;
        fromSub = [city, zip].where((s) => s.isNotEmpty).join(', ');
        fromIcon = Icons.warehouse;
        fromColor = const Color(0xFF9C27B0);
        toLabel = 'Deploy To';
        toAddress = newStreet ?? newAddress ?? '';
        toSub = newCity ?? '';
        toIcon = Icons.location_on;
        toColor = Colors.blue.shade600;
        break;
      default: // relocation
        fromLabel = 'Current';
        fromAddress = currentStreet;
        fromSub = [city, zip].where((s) => s.isNotEmpty).join(', ');
        fromIcon = Icons.location_on;
        fromColor = AppColors.primaryGreen;
        toLabel = 'New Location';
        toAddress = newStreet ?? newAddress ?? '';
        toSub = newCity ?? '';
        toIcon = Icons.flag_rounded;
        toColor = Colors.blue.shade600;
    }

    final bool hasDestination = toAddress.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: icon timeline
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: fromColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(fromIcon, size: 16, color: fromColor),
              ),
              if (hasDestination) ...[
                Container(
                  width: 2,
                  height: 24,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: toColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(toIcon, size: 16, color: toColor),
                ),
              ],
            ],
          ),
          const SizedBox(width: 12),
          // Right: labels + addresses
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // From section
                Text(
                  fromLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: fromColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fromAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (fromSub.isNotEmpty)
                  Text(
                    fromSub,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                if (hasDestination) ...[
                  const SizedBox(height: 14),
                  // To section
                  Text(
                    toLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: toColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    toAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (toSub.isNotEmpty)
                    Text(
                      toSub,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions ────────────────────────────────────────────────────────

  Future<void> _showAssignUserSheet(
    BuildContext context,
    WidgetRef ref,
    String moveRequestId,
    ValueNotifier<bool> isLoading,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AssignUserSheet(moveRequestId: moveRequestId),
    );

    if (result == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _confirmComplete(
    BuildContext context,
    WidgetRef ref,
    String moveRequestId,
    int binNumber,
    ValueNotifier<bool> isLoading,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.blue.shade50,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade100,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 40,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Complete Move Request',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Mark move request for Bin #$binNumber as manually completed?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Complete',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    isLoading.value = true;
    try {
      final managerService = ref.read(managerServiceProvider);
      await managerService.manuallyCompleteMoveRequest(moveRequestId);

      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bin #$binNumber move request completed'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      isLoading.value = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    String moveRequestId,
    int binNumber,
    ValueNotifier<bool> isLoading,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.red.shade50,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade100,
                ),
                child: Icon(
                  Icons.cancel_outlined,
                  size: 40,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Cancel Move Request',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to cancel the move request for Bin #$binNumber? This cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Keep',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel Request',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    isLoading.value = true;
    try {
      final managerService = ref.read(managerServiceProvider);
      await managerService.cancelMoveRequest(moveRequestId);

      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bin #$binNumber move request cancelled'),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      isLoading.value = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Full Screen Map ─────────────────────────────────────────────────

  void _showFullScreenMap(
    BuildContext context,
    WidgetRef ref, {
    required double origLat,
    required double origLng,
    required double? newLat,
    required double? newLng,
    required int binNumber,
    required String moveType,
    required String? sourcePotentialLocationId,
    required String currentStreet,
    required String city,
    required String newStreet,
    required String newCity,
  }) {
    final destinationLabel = moveType == 'store'
        ? 'Warehouse Storage'
        : newStreet.isNotEmpty
            ? '$newStreet, $newCity'
            : 'Destination';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bin #$binNumber Move',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            currentStreet.isNotEmpty
                                ? '$currentStreet, $city → $destinationLabel'
                                : 'View on map',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Full-screen map
              Expanded(
                child: RouteMapPreview(
                  originLat: origLat,
                  originLng: origLng,
                  destLat: newLat,
                  destLng: newLng,
                  binNumber: binNumber,
                  moveType: moveType,
                  sourcePotentialLocationId: sourcePotentialLocationId,
                  managerService: ref.read(managerServiceProvider),
                  isExpanded: true,
                  showLegend: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade700;
      case 'assigned':
        return Colors.blue.shade700;
      case 'in_progress':
        return Colors.purple.shade700;
      case 'completed':
        return AppColors.successGreen;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'IN PROGRESS';
      default:
        return status.toUpperCase();
    }
  }

  ({Color color, String label, IconData icon}) _urgencyInfo(String urgency) {
    return switch (urgency) {
      'overdue' => (
        color: Colors.red.shade700,
        label: 'OVERDUE',
        icon: Icons.error_outline,
      ),
      'urgent' => (
        color: Colors.red.shade600,
        label: 'URGENT',
        icon: Icons.warning_amber_rounded,
      ),
      'soon' => (
        color: Colors.orange.shade700,
        label: 'SOON',
        icon: Icons.schedule,
      ),
      _ => (
        color: Colors.blue.shade600,
        label: 'SCHEDULED',
        icon: Icons.event_outlined,
      ),
    };
  }

  String _moveTypeLabel(String moveType) {
    switch (moveType) {
      case 'store':
        return 'Store in Warehouse';
      case 'relocation':
        return 'Relocation';
      case 'redeployment':
        return 'Redeployment (Warehouse to Field)';
      default:
        return moveType;
    }
  }

  static String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    } catch (e) {
      return isoDate;
    }
  }
}

// =============================================================================
// ASSIGN USER SHEET
// =============================================================================

class _AssignUserSheet extends HookConsumerWidget {
  final String moveRequestId;

  const _AssignUserSheet({required this.moveRequestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersFuture = useMemoized(
      () => ref.read(managerServiceProvider).getAllUsers(),
    );
    final usersSnapshot = useFuture(usersFuture);
    final isAssigning = useState(false);
    final searchQuery = useState('');
    final searchController = useTextEditingController();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              const Text(
                'Assign to User',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Search
              TextField(
                controller: searchController,
                onChanged: (v) => searchQuery.value = v.toLowerCase(),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade500,
                    size: 22,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryGreen,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // User list
              Flexible(
                child: _buildUserList(
                  context,
                  ref,
                  usersSnapshot,
                  isAssigning,
                  searchQuery.value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(
    BuildContext context,
    WidgetRef ref,
    AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
    ValueNotifier<bool> isAssigning,
    String searchQuery,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Failed to load users: ${snapshot.error}',
            style: TextStyle(color: Colors.red.shade600),
          ),
        ),
      );
    }

    final users = snapshot.data ?? [];
    final filtered = searchQuery.isEmpty
        ? users
        : users.where((u) {
            final name = (u['name'] as String? ?? '').toLowerCase();
            final email = (u['email'] as String? ?? '').toLowerCase();
            return name.contains(searchQuery) || email.contains(searchQuery);
          }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            searchQuery.isNotEmpty
                ? 'No users matching "$searchQuery"'
                : 'No users available',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: filtered.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final user = filtered[index];
        final userId = user['id'] as String? ?? '';
        final name = user['name'] as String? ?? 'Unknown';
        final role = user['role'] as String? ?? '';
        final email = user['email'] as String? ?? '';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          leading: CircleAvatar(
            backgroundColor: _roleColor(role).withValues(alpha: 0.15),
            child: Icon(
              _roleIcon(role),
              color: _roleColor(role),
              size: 22,
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            [role, email].where((s) => s.isNotEmpty).join(' • '),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          trailing: isAssigning.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryGreen,
                  ),
                )
              : Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
          onTap: isAssigning.value
              ? null
              : () => _assignUser(context, ref, userId, name, isAssigning),
        );
      },
    );
  }

  Future<void> _assignUser(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String userName,
    ValueNotifier<bool> isAssigning,
  ) async {
    isAssigning.value = true;
    try {
      final managerService = ref.read(managerServiceProvider);
      await managerService.assignMoveToUser(moveRequestId, userId);

      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assigned to $userName'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      isAssigning.value = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'driver':
        return Colors.blue.shade700;
      case 'manager':
        return Colors.purple.shade700;
      case 'admin':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'driver':
        return Icons.local_shipping_outlined;
      case 'manager':
        return Icons.manage_accounts_outlined;
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.person_outline;
    }
  }
}
