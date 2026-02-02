import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/features/driver/widgets/shift_slide_button.dart';
import 'package:ropacalapp/features/driver/widgets/shift_controls.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/providers/api_provider.dart';

/// Demo page to test shift management features
class ShiftDemoPage extends ConsumerWidget {
  const ShiftDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftState = ref.watch(shiftNotifierProvider);
    final shiftNotifier = ref.read(shiftNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Management Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            _StatusCard(shiftState: shiftState),

            const SizedBox(height: 24),

            // Test buttons (simulate manager actions)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Simulate Manager Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Show loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📤 Assigning route...'),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        try {
                          // Call backend API to assign route with 3 specific bins
                          final apiService = ref.read(apiServiceProvider);
                          await apiService.post(
                            '/api/manager/assign-route',
                            {
                              'driver_id': '10d31b0e-1f4e-4b85-b312-47b458e6d823',
                              'route_id': 'test_route_3bins',
                              'bin_ids': [
                                'c96c3c41-fdbd-4777-86eb-326edba84309', // Bin 1
                                '14a67be5-9b31-4acf-bf48-4aacb39d3130', // Bin 2
                                '8f4f7f05-c61f-4e20-9bc4-6db3f4defd59', // Bin 3
                              ],
                            },
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🎉 Route assigned! 3 bins'),
                                backgroundColor: AppColors.successGreen,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Error: $e'),
                                backgroundColor: AppColors.alertRed,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.assignment),
                      label: const Text('Assign Route (Manager)'),
                      style: ElevatedButton.styleFrom(
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        // Use dummy IDs for demo purposes
                        try {
                          await shiftNotifier.completeTask('demo-task-id', 'demo-bin-id', 50);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Error: $e'),
                                backgroundColor: AppColors.alertRed,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Complete a Bin (Test)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.successGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Slide to start button
            if (shiftState.status == ShiftStatus.inactive ||
                shiftState.status == ShiftStatus.ready)
              ShiftSlideButton(
                status: shiftState.status,
                onSlideComplete: () async {
                  try {
                    await shiftNotifier.startShift();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Shift started!'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Error: $e'),
                          backgroundColor: AppColors.alertRed,
                        ),
                      );
                    }
                  }
                },
              ),

            // Shift controls (when active/paused)
            if (shiftState.status == ShiftStatus.active ||
                shiftState.status == ShiftStatus.paused)
              const ShiftControls(),

            const SizedBox(height: 24),

            // Instructions
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 How to Test',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. Click "Assign Route" to simulate manager assignment',
                    ),
                    SizedBox(height: 6),
                    Text('2. Slide the green button to start your shift'),
                    SizedBox(height: 6),
                    Text('3. Use Pause/Resume to take breaks'),
                    SizedBox(height: 6),
                    Text('4. Click "Complete a Bin" to test progress'),
                    SizedBox(height: 6),
                    Text('5. Click "End Shift" when done'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final ShiftState shiftState;

  const _StatusCard({required this.shiftState});

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (shiftState.status) {
      case ShiftStatus.inactive:
        statusText = 'Waiting for route assignment';
        statusColor = Colors.grey;
        statusIcon = Icons.pending;
        break;
      case ShiftStatus.ready:
        statusText = 'Ready to start shift';
        statusColor = AppColors.successGreen;
        statusIcon = Icons.check_circle;
        break;
      case ShiftStatus.active:
        statusText = 'On shift - Working';
        statusColor = AppColors.successGreen;
        statusIcon = Icons.work;
        break;
      case ShiftStatus.paused:
        statusText = 'On break';
        statusColor = AppColors.warningOrange;
        statusIcon = Icons.pause_circle;
        break;
      case ShiftStatus.ended:
        statusText = 'Shift completed';
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        break;
      case ShiftStatus.cancelled:
        statusText = 'Shift cancelled';
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      color: statusColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Status',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (shiftState.assignedRouteId != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Route ID: ${shiftState.assignedRouteId}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Bins: ${shiftState.completedBins}/${shiftState.totalBins}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
