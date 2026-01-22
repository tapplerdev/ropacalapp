import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/providers/bins_provider.dart';

class MoveRequestsPage extends HookConsumerWidget {
  const MoveRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moveRequestsFuture = useMemoized(
      () => ref.read(managerServiceProvider).getAllMoveRequests(),
    );
    final moveRequestsSnapshot = useFuture(moveRequestsFuture);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Move Requests',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: _buildContent(context, moveRequestsSnapshot),
    );
  }

  Widget _buildContent(
    BuildContext context,
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
                'Failed to load move requests',
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

    final moveRequests = snapshot.data ?? [];

    if (moveRequests.isEmpty) {
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
              'No Move Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Move requests will appear here',
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
      padding: const EdgeInsets.all(20),
      itemCount: moveRequests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final moveRequest = moveRequests[index];
        return _buildMoveRequestCard(moveRequest);
      },
    );
  }

  Widget _buildMoveRequestCard(Map<String, dynamic> moveRequest) {
    final status = moveRequest['status'] as String? ?? 'pending';
    final urgency = moveRequest['urgency'] as String? ?? 'scheduled';
    final moveType = moveRequest['move_type'] as String? ?? 'relocation';
    final binNumber = moveRequest['bin_number'] as int? ?? 0;
    final currentStreet = moveRequest['current_street'] as String? ?? '';
    final city = moveRequest['city'] as String? ?? '';
    final requestedByName = moveRequest['requested_by_name'] as String?;
    final scheduledDateIso = moveRequest['scheduled_date_iso'] as String?;
    final assignmentType = moveRequest['assignment_type'] as String? ?? '';
    final reason = moveRequest['reason'] as String?;
    final notes = moveRequest['notes'] as String?;

    // Get status color
    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange.shade700;
        break;
      case 'assigned':
        statusColor = Colors.blue.shade700;
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
          // Header with bin number and status
          Row(
            children: [
              // Bin number badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Bin #$binNumber',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
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
            ],
          ),
          const SizedBox(height: 12),
          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStreet,
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
          ),
          const SizedBox(height: 12),
          // Requester and scheduled date
          Row(
            children: [
              // Requester
              if (requestedByName != null) ...[
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Requested by $requestedByName',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (scheduledDateIso != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatScheduledDate(scheduledDateIso),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
          // Move type badge
          const SizedBox(height: 12),
          Row(
            children: [
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      moveType == 'pickup_only' ? '📦' : '🚚',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      moveType == 'pickup_only' ? 'PICKUP' : 'RELOCATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: moveType == 'pickup_only'
                            ? Colors.purple.shade700
                            : Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Assignment type badge
              if (assignmentType.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: assignmentType == 'manual'
                        ? Colors.amber.shade50
                        : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: assignmentType == 'manual'
                          ? Colors.amber.shade300
                          : Colors.teal.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        assignmentType == 'manual' ? '👤' : '🚛',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        assignmentType == 'manual' ? 'MANUAL' : 'SHIFT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: assignmentType == 'manual'
                              ? Colors.amber.shade900
                              : Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Reason and notes
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 12),
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
          ],
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 8),
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
          ],
        ],
      ),
    );
  }

  String _formatScheduledDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = date.difference(now);

      if (difference.inDays == 0 && difference.inHours >= 0) {
        return 'Today at ${DateFormat('h:mm a').format(date)}';
      } else if (difference.inDays == 1) {
        return 'Tomorrow at ${DateFormat('h:mm a').format(date)}';
      } else if (difference.inDays > 1 && difference.inDays < 7) {
        return 'In ${difference.inDays} days';
      } else if (difference.inDays < 0) {
        final daysPast = difference.inDays.abs();
        if (daysPast == 0) {
          return 'Earlier today at ${DateFormat('h:mm a').format(date)}';
        } else if (daysPast == 1) {
          return 'Yesterday at ${DateFormat('h:mm a').format(date)}';
        } else {
          return '$daysPast days ago';
        }
      } else {
        return DateFormat('MMM d, yyyy \'at\' h:mm a').format(date);
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
