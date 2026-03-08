import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ropacalapp/core/enums/stop_type.dart';
import 'package:ropacalapp/core/exceptions/shift_ended_exception.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/active_driver.dart';
import 'package:ropacalapp/models/route_task.dart';
import 'package:ropacalapp/core/extensions/route_task_extensions.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';

/// Driver Shift Detail Page - Shows detailed information about a driver's active shift
class DriverShiftDetailPage extends ConsumerStatefulWidget {
  final String driverId;

  const DriverShiftDetailPage({
    required this.driverId,
    super.key,
  });

  @override
  ConsumerState<DriverShiftDetailPage> createState() =>
      _DriverShiftDetailPageState();
}

class _DriverShiftDetailPageState
    extends ConsumerState<DriverShiftDetailPage> {
  Timer? _refreshTimer;
  String _taskFilter = 'all'; // all, collection, placement, move

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(driverShiftDetailProvider(widget.driverId));
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(driversNotifierProvider);
    final shiftDetailAsync =
        ref.watch(driverShiftDetailProvider(widget.driverId));

    // Check if driver's shift has ended via WebSocket
    ActiveDriver? driver;
    try {
      driver = driversAsync.valueOrNull?.firstWhere(
        (d) => d.driverId == widget.driverId,
      );
    } catch (e) {
      driver = null;
    }

    if (driver != null &&
        (driver.status == ShiftStatus.ended ||
            driver.status == ShiftStatus.inactive)) {
      AppLogger.general(
        '🏁 Driver shift detected as ended via WebSocket - Status: ${driver.status}',
      );
      _refreshTimer?.cancel();
      return Scaffold(
        appBar: AppBar(title: const Text('Shift Details')),
        body: _ShiftEndedView(driverName: driver.driverName),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Shift Details'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: shiftDetailAsync.when(
        data: (shiftDetail) {
          if (shiftDetail.driver.status == ShiftStatus.ended) {
            AppLogger.general(
                '🏁 Driver shift detected as ended via API response');
            _refreshTimer?.cancel();
            return _ShiftEndedView(
                driverName: shiftDetail.driver.driverName);
          }

          final tasks = shiftDetail.bins;
          final filteredTasks = _filterTasks(tasks);

          // Compute stats
          final completed =
              tasks.where((t) => t.isCompleted == 1).length;
          final skipped = tasks.where((t) => t.skipped).length;
          final remaining = tasks.length - completed - skipped;

          return RefreshIndicator(
            color: AppColors.primaryGreen,
            onRefresh: () async {
              ref.invalidate(
                  driverShiftDetailProvider(widget.driverId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Driver summary card
                  _DriverSummaryCard(driver: shiftDetail.driver),

                  // Summary stats pills
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _StatPill(
                          label: 'Completed',
                          count: completed,
                          color: AppColors.successGreen,
                        ),
                        const SizedBox(width: 8),
                        _StatPill(
                          label: 'Skipped',
                          count: skipped,
                          color: AppColors.warningOrange,
                        ),
                        const SizedBox(width: 8),
                        _StatPill(
                          label: 'Remaining',
                          count: remaining,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),

                  // Current task indicator
                  Builder(
                    builder: (context) {
                      final currentTask = tasks.cast<RouteTask?>().firstWhere(
                        (t) => t!.isCompleted != 1 && !t.skipped,
                        orElse: () => null,
                      );
                      if (currentTask == null) return const SizedBox.shrink();
                      final doneCount = tasks.where((t) => t.isCompleted == 1 || t.skipped).length;
                      return _CurrentTaskBanner(
                        task: currentTask,
                        progress: '$doneCount/${tasks.length}',
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Task type filter tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _TaskFilterChip(
                          label: 'All (${tasks.length})',
                          isSelected: _taskFilter == 'all',
                          onTap: () =>
                              setState(() => _taskFilter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _TaskFilterChip(
                          label:
                              'Collections (${tasks.where((t) => t.isCollection).length})',
                          isSelected: _taskFilter == 'collection',
                          onTap: () => setState(
                              () => _taskFilter = 'collection'),
                        ),
                        if (tasks.any((t) => t.isPlacement)) ...[
                          const SizedBox(width: 8),
                          _TaskFilterChip(
                            label:
                                'Placements (${tasks.where((t) => t.isPlacement).length})',
                            isSelected: _taskFilter == 'placement',
                            onTap: () => setState(
                                () => _taskFilter = 'placement'),
                          ),
                        ],
                        if (tasks.any((t) => t.isMoveRequest)) ...[
                          const SizedBox(width: 8),
                          _TaskFilterChip(
                            label:
                                'Moves (${tasks.where((t) => t.isMoveRequest).length})',
                            isSelected: _taskFilter == 'move',
                            onTap: () => setState(
                                () => _taskFilter = 'move'),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tasks header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Tasks (${filteredTasks.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Task cards
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      return _TaskCard(task: filteredTasks[index]);
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.primaryGreen),
        ),
        error: (error, stack) {
          if (error is ShiftEndedException) {
            AppLogger.general(
                '🏁 Driver shift detected as ended via 404 error');
            _refreshTimer?.cancel();
            return _ShiftEndedView(
              driverName: error.driverName ?? 'Driver',
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Failed to load shift details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(
                      driverShiftDetailProvider(widget.driverId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<RouteTask> _filterTasks(List<RouteTask> tasks) {
    switch (_taskFilter) {
      case 'collection':
        return tasks.where((t) => t.isCollection).toList();
      case 'placement':
        return tasks.where((t) => t.isPlacement).toList();
      case 'move':
        return tasks.where((t) => t.isMoveRequest).toList();
      default:
        return tasks;
    }
  }
}

// =============================================================================
// Summary stat pill
// =============================================================================

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatPill({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Current task banner
// =============================================================================

class _CurrentTaskBanner extends StatelessWidget {
  final RouteTask task;
  final String progress;

  const _CurrentTaskBanner({
    required this.task,
    required this.progress,
  });

  Color get _moveTypeColor {
    switch (task.moveType?.toLowerCase()) {
      case 'store':
        return Colors.blue.shade600;
      case 'redeployment':
        return Colors.teal.shade600;
      default:
        return Colors.purple.shade600;
    }
  }

  ({IconData icon, Color color, String label}) get _taskConfig {
    switch (task.taskType) {
      case StopType.collection:
        return (icon: Icons.delete_outline, color: AppColors.primaryGreen, label: 'Collection');
      case StopType.placement:
        return (icon: Icons.add_location, color: AppColors.warningOrange, label: 'Placement');
      case StopType.pickup:
        return (icon: Icons.arrow_upward, color: _moveTypeColor, label: 'Pickup');
      case StopType.dropoff:
        return (icon: Icons.arrow_downward, color: _moveTypeColor, label: 'Dropoff');
      case StopType.warehouseStop:
        return (icon: Icons.warehouse, color: Colors.teal.shade600, label: 'Warehouse');
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF3B82F6); // Blue accent — distinct from green Done badges
    final config = _taskConfig;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Current:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(width: 6),
          Icon(config.icon, size: 16, color: config.color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              task.displayTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$progress tasks',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Task filter chip
// =============================================================================

class _TaskFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TaskFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Shift ended view
// =============================================================================

class _ShiftEndedView extends StatelessWidget {
  final String driverName;

  const _ShiftEndedView({required this.driverName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.flag_circle,
            size: 80,
            color: AppColors.successGreen,
          ),
          const SizedBox(height: 24),
          const Text(
            'Shift Ended',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$driverName has completed their shift',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
            child: const Text('Back to Drivers'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Compact driver summary card
// =============================================================================

class _DriverSummaryCard extends StatelessWidget {
  final ActiveDriver driver;

  const _DriverSummaryCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Name + route
          Row(
            children: [
              // Green avatar circle
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    driver.driverName.isNotEmpty
                        ? driver.driverName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.driverName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          driver.routeDisplayName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (driver.startTime != null) ...[
                          Text(
                            '  ·  ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          Text(
                            timeFormat.format(driver.startTime!),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
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
          const SizedBox(height: 10),
          // Row 2: Inline stat chips with labels
          Row(
            children: [
              _InlineStat(
                icon: Icons.task_alt,
                label: 'Tasks',
                value: '${driver.completedBins}/${driver.totalBins}',
                color: AppColors.primaryGreen,
              ),
              if (driver.startTime != null) ...[
                const SizedBox(width: 10),
                _InlineStat(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: _formatDuration(driver.activeDuration),
                  color: Colors.blueGrey,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _completionColor(double pct) {
    if (pct >= 0.75) return AppColors.successGreen;
    if (pct >= 0.40) return Colors.amber.shade700;
    return Colors.grey.shade600;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

class _InlineStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InlineStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Enhanced task card with type icons, skip status, and skip reasons
// =============================================================================

class _TaskCard extends StatelessWidget {
  final RouteTask task;

  const _TaskCard({required this.task});

  /// Move type color — distinct color per move request type
  Color get _moveTypeColor {
    switch (task.moveType?.toLowerCase()) {
      case 'store':
        return Colors.blue.shade600;
      case 'redeployment':
        return Colors.teal.shade600;
      default:
        return Colors.purple.shade600; // relocation + fallback
    }
  }

  /// Get task type config: icon, color, label
  ({IconData icon, Color color, String label}) get _taskConfig {
    switch (task.taskType) {
      case StopType.collection:
        return (
          icon: Icons.delete_outline,
          color: AppColors.primaryGreen,
          label: 'Collection'
        );
      case StopType.placement:
        return (
          icon: Icons.add_location,
          color: AppColors.warningOrange,
          label: 'Placement'
        );
      case StopType.pickup:
        return (
          icon: Icons.arrow_upward,
          color: _moveTypeColor,
          label: 'Pickup'
        );
      case StopType.dropoff:
        return (
          icon: Icons.arrow_downward,
          color: _moveTypeColor,
          label: 'Dropoff'
        );
      case StopType.warehouseStop:
        return (
          icon: Icons.warehouse,
          color: Colors.teal.shade600,
          label: 'Warehouse'
        );
    }
  }

  /// Get the photo URL — check direct field first, then taskData as fallback
  String? get _effectivePhotoUrl {
    if (task.photoUrl != null) return task.photoUrl;
    // Fallback: check taskData for photo_url
    final data = task.taskData;
    if (data == null) return null;
    if (data.containsKey('photo_url') && data['photo_url'] is String) {
      return data['photo_url'] as String;
    }
    if (data.containsKey('photoUrl') && data['photoUrl'] is String) {
      return data['photoUrl'] as String;
    }
    return null;
  }

  /// Parse skip reason from taskData
  String? get _skipReason {
    if (!task.skipped || task.taskData == null) return null;
    final data = task.taskData!;

    // Try direct map keys first
    if (data.containsKey('skip_reason')) {
      return data['skip_reason'] as String?;
    }
    if (data.containsKey('reason')) {
      return data['reason'] as String?;
    }

    // Try base64-encoded JSON (some backend responses use this)
    for (final key in data.keys) {
      final value = data[key];
      if (value is String && value.length > 10) {
        try {
          final decoded = utf8.decode(base64.decode(value));
          final parsed = json.decode(decoded) as Map<String, dynamic>;
          return parsed['skip_reason'] as String? ??
              parsed['reason'] as String?;
        } catch (_) {
          // Not base64 JSON, skip
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final isCompleted = task.isCompleted == 1;
    final isSkipped = task.skipped;
    final config = _taskConfig;
    final skipReason = _skipReason;
    final photoUrl = _effectivePhotoUrl;

    // Determine status color for the left border
    final Color borderColor;
    if (isCompleted) {
      borderColor = AppColors.successGreen;
    } else if (isSkipped) {
      borderColor = AppColors.warningOrange;
    } else {
      borderColor = Colors.grey.shade300;
    }

    // Completed cards get a subtle green wash
    final Color cardBg;
    if (isCompleted) {
      cardBg = AppColors.successGreen.withValues(alpha: 0.04);
    } else if (isSkipped) {
      cardBg = AppColors.warningOrange.withValues(alpha: 0.03);
    } else {
      cardBg = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Task type icon + title + photo thumbnail + status
            Row(
              children: [
                // Task type icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    config.icon,
                    size: 20,
                    color: config.color,
                  ),
                ),
                const SizedBox(width: 12),
                // Title and type label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.displayTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        config.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: config.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Photo thumbnail (if completed task with photo)
                if (isCompleted && photoUrl != null) ...[
                  GestureDetector(
                    onTap: () => _showFullPhoto(context, photoUrl),
                    child: Hero(
                      tag: 'photo_${task.binId ?? task.hashCode}',
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primaryGreen.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade100,
                                child: Icon(Icons.image, size: 18, color: Colors.grey.shade400),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Status badge
                _buildStatusBadge(isCompleted, isSkipped),
              ],
            ),

            const SizedBox(height: 10),

            // Address
            Row(
              children: [
                Icon(Icons.location_on,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    task.safeAddress,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),

            // Completion time
            if (isCompleted && task.completedAt != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    'Completed at ${timeFormat.format(DateTime.fromMillisecondsSinceEpoch(task.completedAt! * 1000))}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // Skipped time
            if (isSkipped && task.completedAt != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    'Skipped at ${timeFormat.format(DateTime.fromMillisecondsSinceEpoch(task.completedAt! * 1000))}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.warningOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // Skip reason
            if (isSkipped && skipReason != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        skipReason,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Fill percentage bars (for collection tasks)
            if (task.isCollection) ...[
              const SizedBox(height: 12),
              if (isCompleted)
                // Completed: show before/after comparison
                Row(
                  children: [
                    Expanded(
                      child: _FillBar(
                        label: 'Before',
                        percentage: task.safeFillPercentage,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _FillBar(
                        label: 'After',
                        percentage: task.updatedFillPercentage ?? 0,
                      ),
                    ),
                  ],
                )
              else
                // Pending/Skipped: show current fill level only
                _FillBar(
                  label: 'Fill Level',
                  percentage: task.safeFillPercentage,
                ),
            ],

            // Move request details
            if (task.isMoveRequest && task.destinationAddress != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _moveTypeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward,
                        size: 16, color: _moveTypeColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.isPickup
                            ? 'Deliver to: ${task.destinationAddress}'
                            : 'From: ${task.originalAddress ?? task.safeAddress}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _moveTypeColor,
                        ),
                      ),
                    ),
                    if (task.moveType != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _moveTypeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task.moveType!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _moveTypeColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Placement details
            if (task.isPlacement && task.newBinNumber != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_location,
                        size: 16, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Place Bin #${task.newBinNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Warehouse details
            if (task.isWarehouseStop) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warehouse,
                        size: 16, color: Colors.teal.shade600),
                    const SizedBox(width: 8),
                    Text(
                      '${task.warehouseAction?.toUpperCase() ?? 'STOP'}${task.binsToLoad != null ? ' — ${task.binsToLoad} bins' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Photo is now shown as inline thumbnail in the header row above
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isCompleted, bool isSkipped) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.successGreen,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            const Text(
              'Done',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (isSkipped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.warningOrange,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.skip_next, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            const Text(
              'Skipped',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.radio_button_unchecked,
              size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(
            'Pending',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullPhoto(BuildContext context, String url) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  // Tap background to close
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(color: Colors.transparent),
                  ),
                  Center(
                    child: Hero(
                      tag: 'photo_${task.binId ?? task.hashCode}',
                      child: InteractiveViewer(
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Fill percentage bar
// =============================================================================

class _FillBar extends StatelessWidget {
  final String label;
  final int percentage;
  final bool isAfter;

  const _FillBar({
    required this.label,
    required this.percentage,
    this.isAfter = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor(percentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Color _getColor(int percentage) {
    if (percentage >= 80) return Colors.red.shade600;
    if (percentage >= 50) return Colors.orange.shade600;
    if (percentage >= 30) return Colors.amber.shade700;
    return AppColors.successGreen;
  }
}
