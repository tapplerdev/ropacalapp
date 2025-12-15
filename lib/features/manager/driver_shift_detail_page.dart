import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ropacalapp/core/exceptions/shift_ended_exception.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';
import 'package:ropacalapp/models/active_driver.dart';
import 'package:ropacalapp/models/driver_status.dart';
import 'package:ropacalapp/models/route_bin.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/providers/active_drivers_provider.dart';
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

  @override
  void initState() {
    super.initState();
    // Auto-refresh every 30 seconds
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
    // Watch driversNotifierProvider for real-time status updates (WebSocket)
    final driversAsync = ref.watch(driversNotifierProvider);
    final shiftDetailAsync = ref.watch(driverShiftDetailProvider(widget.driverId));

    // PRIMARY: Check if driver's shift has ended via WebSocket (instant detection)
    DriverStatus? driver;
    try {
      driver = driversAsync.valueOrNull?.firstWhere(
        (d) => d.driverId == widget.driverId,
      );
    } catch (e) {
      // Driver not found in list
      driver = null;
    }

    // If WebSocket shows shift ended or inactive, show "Shift Ended" immediately
    if (driver != null &&
        (driver.status == ShiftStatus.ended ||
            driver.status == ShiftStatus.inactive)) {
      AppLogger.general(
        '🏁 Driver shift detected as ended via WebSocket - Status: ${driver.status}',
      );
      _refreshTimer?.cancel(); // Stop auto-refresh
      return Scaffold(
        appBar: AppBar(
          title: const Text('Driver Shift Details'),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: _ShiftEndedView(driverName: driver.name),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Shift Details'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: shiftDetailAsync.when(
        data: (shiftDetail) {
          // SECONDARY: Check if shift has ended from API response
          if (shiftDetail.driver.status == ShiftStatus.ended) {
            AppLogger.general('🏁 Driver shift detected as ended via API response');
            _refreshTimer?.cancel();
            return _ShiftEndedView(driverName: shiftDetail.driver.driverName);
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver summary card
                _DriverSummaryCard(driver: shiftDetail.driver),

                // Bins list
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Bins (${shiftDetail.bins.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                // Bin cards
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: shiftDetail.bins.length,
                  itemBuilder: (context, index) {
                    final bin = shiftDetail.bins[index];
                    return _BinCard(
                      bin: bin,
                      index: index,
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) {
          // FALLBACK: If error is ShiftEndedException (from 404), show "Shift Ended" view
          if (error is ShiftEndedException) {
            AppLogger.general('🏁 Driver shift detected as ended via 404 error');
            _refreshTimer?.cancel();
            return _ShiftEndedView(
              driverName: error.driverName ?? 'Driver',
            );
          }

          // Other errors - show error state
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
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
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(driverShiftDetailProvider(widget.driverId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shift ended view
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
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
            child: const Text('Back to Active Drivers'),
          ),
        ],
      ),
    );
  }
}

/// Driver summary card at the top
class _DriverSummaryCard extends StatelessWidget {
  final ActiveDriver driver;

  const _DriverSummaryCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver name
          Text(
            driver.driverName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          // Route name
          Text(
            driver.routeDisplayName,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 16),

          // Date & Time
          if (driver.startTime != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Colors.white70,
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(driver.startTime!),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 18,
                  color: Colors.white70,
                ),
                const SizedBox(width: 8),
                Text(
                  'Started at ${timeFormat.format(driver.startTime!)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryStatColumn(
                icon: Icons.delete_outline,
                label: 'Bins',
                value: '${driver.completedBins}/${driver.totalBins}',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white30,
              ),
              if (driver.startTime != null)
                _SummaryStatColumn(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: _formatDuration(driver.activeDuration),
                ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white30,
              ),
              _SummaryStatColumn(
                icon: Icons.check_circle_outline,
                label: 'Complete',
                value: '${(driver.completionPercentage * 100).toInt()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

/// Stat column in summary card
class _SummaryStatColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryStatColumn({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 28,
          color: Colors.white,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

/// Individual bin card showing status
class _BinCard extends StatelessWidget {
  final RouteBin bin;
  final int index;

  const _BinCard({
    required this.bin,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final isCompleted = bin.isCompleted == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Sequence number + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Sequence badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.successGreen
                            : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Bin #${bin.binNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                // Status icon
                Icon(
                  isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isCompleted
                      ? AppColors.successGreen
                      : Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Address
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${bin.currentStreet}, ${bin.city} ${bin.zip}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),

            // Completion time
            if (isCompleted && bin.completedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(
                      DateTime.fromMillisecondsSinceEpoch(
                        bin.completedAt! * 1000,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Fill percentage bars
            Row(
              children: [
                // Before
                Expanded(
                  child: _FillBar(
                    label: 'Before',
                    percentage: bin.fillPercentage,
                  ),
                ),
                const SizedBox(width: 16),

                // After
                Expanded(
                  child: _FillBar(
                    label: 'After',
                    percentage: bin.updatedFillPercentage ?? bin.fillPercentage,
                    isAfter: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Fill percentage bar with label
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
            minHeight: 12,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Color _getColor(int percentage) {
    if (percentage >= 80) {
      return Colors.red.shade600;
    } else if (percentage >= 50) {
      return Colors.orange.shade600;
    } else if (percentage >= 30) {
      return Colors.amber.shade700;
    } else {
      return AppColors.successGreen;
    }
  }
}
