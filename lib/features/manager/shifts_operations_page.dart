import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/enums/stop_type.dart';
import 'package:ropacalapp/models/route_task.dart';
import 'package:ropacalapp/core/utils/warehouse_stop_calculator.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/models/shift_state.dart';
import 'package:ropacalapp/providers/warehouse_provider.dart';

/// Manager Shifts Operations Page - Tabbed interface for shift management
/// Tabs: Active Shifts, Calendar, Create New
class ShiftsOperationsPage extends HookConsumerWidget {
  const ShiftsOperationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 3);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Shift Operations'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: tabController,
          indicatorColor: AppColors.primaryGreen,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Active Shifts'),
            Tab(text: 'Calendar'),
            Tab(text: 'Create New'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _ActiveShiftsTab(),
          _CalendarTab(),
          _CreateNewShiftTab(),
        ],
      ),
    );
  }
}

/// Active Shifts Tab - Shows list of active shifts
class _ActiveShiftsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDriversAsync = ref.watch(activeDriversProvider);

    return activeDriversAsync.when(
      data: (drivers) {
        if (drivers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Active Shifts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Active shifts will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(driversNotifierProvider.notifier).refresh();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return _ActiveShiftCard(driver: driver);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Failed to load shifts',
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
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Active Shift Card
class _ActiveShiftCard extends StatelessWidget {
  final driver;

  const _ActiveShiftCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.driverName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        driver.routeDisplayName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _getStatusBadge(driver.status),
              ],
            ),
            const SizedBox(height: 16),

            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${driver.completedBins}/${driver.totalBins} bins',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${(driver.completionPercentage * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: driver.completionPercentage,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  driver.completionPercentage >= 0.8
                      ? AppColors.successGreen
                      : driver.completionPercentage >= 0.5
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getStatusBadge(ShiftStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case ShiftStatus.active:
        color = AppColors.primaryGreen;
        label = 'Active';
        icon = Icons.play_circle_filled;
        break;
      case ShiftStatus.paused:
        color = Colors.amber.shade700;
        label = 'Paused';
        icon = Icons.pause_circle_filled;
        break;
      case ShiftStatus.ready:
        color = Colors.blue.shade700;
        label = 'Ready';
        icon = Icons.schedule;
        break;
      default:
        color = Colors.grey.shade600;
        label = 'Inactive';
        icon = Icons.event_available;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Calendar Tab - Placeholder for calendar view
class _CalendarTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Calendar View',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Create New Shift Tab - Embeds the shift builder functionality
class _CreateNewShiftTab extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = useState<List<RouteTask>>([]);
    final truckCapacity = useState<int>(6);
    final selectedDriver = useState<String?>(null);

    // Watch warehouse location from backend
    final warehouseAsync = ref.watch(warehouseLocationNotifierProvider);

    // Calculate warehouse stop analysis
    final analysis = useMemoized(
      () => WarehouseStopCalculator.analyzeWarehouseStops(
        tasks: tasks.value,
        truckBinCapacity: truckCapacity.value,
      ),
      [tasks.value, truckCapacity.value],
    );

    return Column(
      children: [
        // Shift Configuration
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Truck Capacity Input
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Truck Bin Capacity',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Required - How many bins can the truck carry?',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '6',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        final capacity = int.tryParse(value);
                        if (capacity != null && capacity > 0) {
                          truckCapacity.value = capacity;
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // System Analysis
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shift Analysis',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            analysis.summary,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Quick Add Buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickAddButton(
                  icon: Icons.route,
                  label: 'Add Route',
                  color: Colors.blue,
                  onTap: () => _showAddRouteDialog(context, tasks),
                ),
                const SizedBox(width: 12),
                _QuickAddButton(
                  icon: Icons.delete_outline,
                  label: 'Add Collection',
                  color: Colors.green,
                  onTap: () => _showAddCollectionDialog(context, tasks),
                ),
                const SizedBox(width: 12),
                _QuickAddButton(
                  icon: Icons.add_location,
                  label: 'Add Placement',
                  color: Colors.orange,
                  onTap: () => _showAddPlacementDialog(context, tasks),
                ),
                const SizedBox(width: 12),
                _QuickAddButton(
                  icon: Icons.move_up,
                  label: 'Add Move Request',
                  color: Colors.purple,
                  onTap: () => _showAddMoveRequestDialog(context, tasks),
                ),
                const SizedBox(width: 12),
                _QuickAddButton(
                  icon: Icons.warehouse,
                  label: 'Warehouse Stop',
                  color: Colors.grey.shade700,
                  onTap: warehouseAsync.when(
                    data: (warehouse) =>
                        () => _addWarehouseStop(context, tasks, warehouse),
                    loading: () => null,
                    error: (_, __) => null,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Task List
        Expanded(
          child: tasks.value.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.playlist_add,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks added yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use the buttons above to add tasks',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.value.length,
                  onReorder: (oldIndex, newIndex) {
                    final items = List<RouteTask>.from(tasks.value);
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = items.removeAt(oldIndex);
                    items.insert(newIndex, item);
                    tasks.value = items;
                  },
                  itemBuilder: (context, index) {
                    final task = tasks.value[index];
                    return _TaskCard(
                      key: ValueKey(task.id),
                      task: task,
                      index: index,
                      onDelete: () {
                        final items = List<RouteTask>.from(tasks.value);
                        items.removeAt(index);
                        tasks.value = items;
                      },
                    );
                  },
                ),
        ),

        // Auto-Calculate Warehouse Stops Button
        if (tasks.value.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton.icon(
                onPressed: warehouseAsync.when(
                  data: (warehouse) => () {
                    // Auto-insert warehouse stops using backend warehouse location
                    final withWarehouse =
                        WarehouseStopCalculator.insertWarehouseStops(
                      tasks: tasks.value,
                      truckBinCapacity: truckCapacity.value,
                      warehouseLocation: warehouse,
                      shiftId: 'temp_shift_id',
                    );
                    tasks.value = withWarehouse;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Added ${analysis.totalWarehouseStops} warehouse stops',
                        ),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  },
                  loading: () => null,
                  error: (_, __) => null,
                ),
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Auto-Insert Warehouse Stops'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showAddRouteDialog(
    BuildContext context,
    ValueNotifier<List<RouteTask>> tasks,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Route'),
        content: const Text(
          'Select an existing route to import all its bins as collection tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Show route picker
              Navigator.pop(context);
            },
            child: const Text('Select Route'),
          ),
        ],
      ),
    );
  }

  void _showAddCollectionDialog(
    BuildContext context,
    ValueNotifier<List<RouteTask>> tasks,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Collection'),
        content: const Text('Select bins to collect from the map or list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Show bin picker
              Navigator.pop(context);
            },
            child: const Text('Select Bins'),
          ),
        ],
      ),
    );
  }

  void _showAddPlacementDialog(
    BuildContext context,
    ValueNotifier<List<RouteTask>> tasks,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Placement'),
        content: const Text(
          'Select potential locations where new bins will be placed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Show location picker
              Navigator.pop(context);
            },
            child: const Text('Select Locations'),
          ),
        ],
      ),
    );
  }

  void _showAddMoveRequestDialog(
    BuildContext context,
    ValueNotifier<List<RouteTask>> tasks,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Move Request'),
        content: const Text(
          'Create a new move request or select an existing one to add to this shift.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Show move request creator/picker
              Navigator.pop(context);
            },
            child: const Text('Create/Select'),
          ),
        ],
      ),
    );
  }

  void _addWarehouseStop(
    BuildContext context,
    ValueNotifier<List<RouteTask>> tasks,
    WarehouseLocation warehouse,
  ) {
    // Add manual warehouse stop using backend warehouse location
    final newTask = RouteTask(
      id: "-${DateTime.now().millisecondsSinceEpoch}", // Negative ID for temporary tasks
      shiftId: 'temp',
      sequenceOrder: tasks.value.length + 1,
      taskType: StopType.warehouseStop,
      latitude: warehouse.latitude,
      longitude: warehouse.longitude,
      address: warehouse.address,
      warehouseAction: 'both',
      binsToLoad: 6,
      taskData: {'manual': true},
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    tasks.value = [...tasks.value, newTask];
  }
}

/// Quick add button widget
class _QuickAddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAddButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Task card widget
class _TaskCard extends StatelessWidget {
  final RouteTask task;
  final int index;
  final VoidCallback onDelete;

  const _TaskCard({
    super.key,
    required this.task,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drag_handle, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTaskColor(task.taskType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTaskIcon(task.taskType),
                color: _getTaskColor(task.taskType),
                size: 20,
              ),
            ),
          ],
        ),
        title: Text(
          task.displayTitle,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          task.displaySubtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.close, color: Colors.grey.shade600, size: 20),
          onPressed: onDelete,
        ),
      ),
    );
  }

  Color _getTaskColor(StopType type) {
    switch (type) {
      case StopType.collection:
        return Colors.green;
      case StopType.placement:
        return Colors.orange;
      case StopType.pickup:
      case StopType.dropoff:
        return Colors.purple;
      case StopType.warehouseStop:
        return Colors.grey.shade700;
    }
  }

  IconData _getTaskIcon(StopType type) {
    switch (type) {
      case StopType.collection:
        return Icons.delete_outline;
      case StopType.placement:
        return Icons.add_location;
      case StopType.pickup:
        return Icons.upload;
      case StopType.dropoff:
        return Icons.download;
      case StopType.warehouseStop:
        return Icons.warehouse;
    }
  }
}
