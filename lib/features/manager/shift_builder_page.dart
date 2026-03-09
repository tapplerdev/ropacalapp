import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ropacalapp/core/theme/app_colors.dart';
import 'package:ropacalapp/core/enums/stop_type.dart';
import 'package:ropacalapp/models/route.dart';
import 'package:ropacalapp/models/route_task.dart';
import 'package:ropacalapp/core/utils/warehouse_stop_calculator.dart';
import 'package:ropacalapp/providers/drivers_provider.dart';
import 'package:ropacalapp/providers/warehouse_provider.dart';
import 'package:ropacalapp/models/potential_location.dart';
import 'package:ropacalapp/features/manager/widgets/driver_picker_sheet.dart';
import 'package:ropacalapp/features/manager/widgets/route_picker_sheet.dart';
import 'package:ropacalapp/features/manager/widgets/potential_location_picker_sheet.dart';
import 'package:ropacalapp/features/manager/widgets/move_request_picker_sheet.dart';
import 'package:ropacalapp/features/manager/widgets/bin_collection_picker_sheet.dart';
import 'package:ropacalapp/models/bin.dart';

/// Manager interface for building agnostic shifts with tasks
class ShiftBuilderPage extends HookConsumerWidget {
  const ShiftBuilderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = useState<List<RouteTask>>([]);
    final truckCapacity = useState<int>(0);
    final truckCapacityController = useTextEditingController(text: '0');
    final selectedDriverId = useState<String?>(null);
    final selectedDriverName = useState<String?>(null);
    final lockRouteOrder = useState<bool>(false);
    final isSaving = useState<bool>(false);

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

    // Determine if Create Shift button should be enabled
    final canCreate = selectedDriverId.value != null &&
        tasks.value.length >= 2 &&
        truckCapacity.value > 0 &&
        !isSaving.value;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      appBar: AppBar(
        title: const Text('Build New Shift'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Shift Configuration
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Driver Selection Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildDriverSelector(
                      context,
                      selectedDriverName: selectedDriverName.value,
                      onTap: () => _showDriverPicker(
                        context,
                        selectedDriverId: selectedDriverId,
                        selectedDriverName: selectedDriverName,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Truck Capacity & Lock Route Order Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Truck Capacity
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.local_shipping_outlined,
                                    size: 20,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Truck Bin Capacity',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'How many bins can the truck carry?',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 64,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: TextField(
                                    controller: truckCapacityController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    textAlignVertical: TextAlignVertical.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      if (value.isEmpty) {
                                        truckCapacity.value = 0;
                                        return;
                                      }
                                      final capacity = int.tryParse(value);
                                      truckCapacity.value =
                                          (capacity != null && capacity > 0)
                                              ? capacity
                                              : 0;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Divider(
                            height: 1,
                            color: Colors.grey.shade100,
                            indent: 16,
                            endIndent: 16,
                          ),

                          // Lock Route Order
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.lock_outline,
                                    size: 20,
                                    color: Colors.orange.shade600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Lock Route Order',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Prevent reordering during optimization',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: lockRouteOrder.value,
                                  onChanged: (v) => lockRouteOrder.value = v,
                                  activeColor: AppColors.primaryGreen,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Shift Analysis Card
                  if (tasks.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.analytics_outlined,
                                size: 20,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Shift Analysis',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    analysis.summary,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Quick Add Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _QuickAddButton(
                            icon: Icons.route,
                            label: 'Add Route',
                            color: Colors.blue,
                            onTap: () => _showAddRouteSheet(context, tasks),
                          ),
                          const SizedBox(width: 10),
                          _QuickAddButton(
                            icon: Icons.delete_outline,
                            label: 'Add Collection',
                            color: Colors.green,
                            onTap: () =>
                                _showAddCollectionSheet(context, tasks),
                          ),
                          const SizedBox(width: 10),
                          _QuickAddButton(
                            icon: Icons.add_location,
                            label: 'Add Placement',
                            color: Colors.orange,
                            onTap: () =>
                                _showAddPlacementDialog(context, tasks),
                          ),
                          const SizedBox(width: 10),
                          _QuickAddButton(
                            icon: Icons.move_up,
                            label: 'Move Request',
                            color: Colors.purple,
                            onTap: () =>
                                _showAddMoveRequestDialog(context, tasks),
                          ),
                          const SizedBox(width: 10),
                          _QuickAddButton(
                            icon: Icons.warehouse,
                            label: 'Warehouse',
                            color: Colors.grey.shade700,
                            onTap: warehouseAsync.when(
                              data: (warehouse) => () =>
                                  _addWarehouseStop(context, tasks, warehouse),
                              loading: () => null,
                              error: (_, __) => null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Task List
                  if (tasks.value.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.playlist_add,
                            size: 56,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No tasks added yet',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "Add Route" to import a route template',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tasks.value.length,
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

                  // Bottom spacing for button
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom: Create Shift Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton.icon(
                onPressed: canCreate
                    ? () => _saveShift(
                          context,
                          ref,
                          tasks: tasks,
                          driverId: selectedDriverId.value,
                          driverName: selectedDriverName.value,
                          truckCapacity: truckCapacity.value,
                          lockRouteOrder: lockRouteOrder.value,
                          isSaving: isSaving,
                        )
                    : null,
                icon: isSaving.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  isSaving.value ? 'Creating Shift...' : 'Create Shift',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Driver Selection
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDriverSelector(
    BuildContext context, {
    required String? selectedDriverName,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedDriverName != null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryGreen.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
            color: Colors.white,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isSelected
                    ? AppColors.primaryGreen.withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                child: Icon(
                  isSelected ? Icons.person : Icons.person_add_alt_1,
                  size: 22,
                  color: isSelected
                      ? AppColors.primaryGreen
                      : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSelected ? 'Driver' : 'Select Driver',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSelected
                          ? selectedDriverName
                          : 'Required - Tap to choose',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? Colors.black87
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDriverPicker(
    BuildContext context, {
    required ValueNotifier<String?> selectedDriverId,
    required ValueNotifier<String?> selectedDriverName,
  }) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DriverPickerSheet(),
    );

    if (result != null) {
      selectedDriverId.value = result['id'];
      selectedDriverName.value = result['name'];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Route Import
  // ═══════════════════════════════════════════════════════════════

  void _showAddRouteSheet(
    BuildContext context,
    ValueNotifier<List<RouteTask>> tasks,
  ) async {
    final route = await showModalBottomSheet<RouteTemplate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RoutePickerSheet(),
    );

    if (route == null) return;

    // Convert route bins to collection tasks
    final newTasks = route.bins.map((bin) {
      return RouteTask(
        id: 'temp_${bin.id}',
        shiftId: 'temp',
        sequenceOrder: bin.sequenceOrder,
        taskType: StopType.collection,
        latitude: bin.latitude ?? 0,
        longitude: bin.longitude ?? 0,
        address: bin.address,
        binId: bin.id,
        binNumber: bin.binNumber,
        fillPercentage: bin.fillPercentage,
        routeId: route.id,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }).toList();

    // Sort by sequence order
    newTasks.sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));

    // Append to existing tasks
    tasks.value = [...tasks.value, ...newTasks];

  }

  // ═══════════════════════════════════════════════════════════════
  // Save Shift
  // ═══════════════════════════════════════════════════════════════

  Future<void> _saveShift(
    BuildContext context,
    WidgetRef ref, {
    required ValueNotifier<List<RouteTask>> tasks,
    required String? driverId,
    required String? driverName,
    required int truckCapacity,
    required bool lockRouteOrder,
    required ValueNotifier<bool> isSaving,
  }) async {
    // Get warehouse location
    final warehouseAsync = ref.read(warehouseLocationNotifierProvider);
    final warehouse = warehouseAsync.valueOrNull;
    if (warehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Warehouse location not loaded yet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    isSaving.value = true;

    try {
      final managerService = ref.read(managerServiceProvider);

      // Build tasks payload — filter out warehouse_stop tasks (backend auto-inserts them)
      final taskPayload = tasks.value
          .where((t) => t.taskType != StopType.warehouseStop)
          .map((t) {
        final taskMap = <String, dynamic>{
          'task_type': t.taskType.name,
          'latitude': t.latitude,
          'longitude': t.longitude,
          'address': t.address ?? '',
        };

        // Collection fields
        if (t.binId != null) taskMap['bin_id'] = t.binId;
        if (t.binNumber != null) taskMap['bin_number'] = t.binNumber;
        if (t.fillPercentage != null) {
          taskMap['fill_percentage'] = t.fillPercentage;
        }

        // Placement fields
        if (t.potentialLocationId != null) {
          taskMap['potential_location_id'] = t.potentialLocationId;
        }
        if (t.newBinNumber != null) {
          taskMap['new_bin_number'] = t.newBinNumber;
        }

        // Move request fields
        if (t.moveRequestId != null) {
          taskMap['move_request_id'] = t.moveRequestId;
        }
        if (t.destinationLatitude != null) {
          taskMap['destination_latitude'] = t.destinationLatitude;
        }
        if (t.destinationLongitude != null) {
          taskMap['destination_longitude'] = t.destinationLongitude;
        }
        if (t.destinationAddress != null) {
          taskMap['destination_address'] = t.destinationAddress;
        }
        if (t.moveType != null) taskMap['move_type'] = t.moveType;

        // Route ID
        if (t.routeId != null) taskMap['route_id'] = t.routeId;

        return taskMap;
      }).toList();

      await managerService.createShiftWithTasks(
        driverId: driverId!,
        truckBinCapacity: truckCapacity,
        warehouseLatitude: warehouse.latitude,
        warehouseLongitude: warehouse.longitude,
        warehouseAddress: warehouse.address,
        lockRouteOrder: lockRouteOrder,
        tasks: taskPayload,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Shift created for $driverName with ${taskPayload.length} tasks',
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create shift: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isSaving.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Placeholder Dialogs (Phase 2)
  // ═══════════════════════════════════════════════════════════════

  void _showAddCollectionSheet(
    BuildContext context,
    ValueNotifier<List<RouteTask>> tasks,
  ) async {
    // Collect bin IDs already in the task list
    final existingBinIds = tasks.value
        .where((t) => t.binId != null && t.taskType == StopType.collection)
        .map((t) => t.binId!)
        .toSet();

    final selected = await showModalBottomSheet<List<Bin>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BinCollectionPickerSheet(existingBinIds: existingBinIds),
    );

    if (selected == null || selected.isEmpty) return;

    // Deduplicate: skip bins already in the task list
    final newBins = selected.where((b) => !existingBinIds.contains(b.id));

    final newTasks = newBins.map((bin) {
      return RouteTask(
        id: 'temp_col_${bin.id}',
        shiftId: 'temp',
        sequenceOrder: tasks.value.length + 1,
        taskType: StopType.collection,
        latitude: bin.latitude ?? 0,
        longitude: bin.longitude ?? 0,
        address: bin.address,
        binId: bin.id,
        binNumber: bin.binNumber,
        fillPercentage: bin.fillPercentage,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }).toList();

    tasks.value = [...tasks.value, ...newTasks];
  }

  void _showAddPlacementDialog(
    BuildContext context,
    ValueNotifier<List<RouteTask>> tasks,
  ) async {
    final selected = await showModalBottomSheet<List<PotentialLocation>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PotentialLocationPickerSheet(),
    );

    if (selected == null || selected.isEmpty) return;

    final newTasks = selected.map((location) {
      final addressParts = <String>[];
      if (location.street.isNotEmpty) addressParts.add(location.street);
      if (location.city.isNotEmpty) addressParts.add(location.city);
      if (location.zip.isNotEmpty) addressParts.add(location.zip);
      final address =
          addressParts.isEmpty ? 'No address' : addressParts.join(', ');

      return RouteTask(
        id: 'temp_pl_${location.id}',
        shiftId: 'temp',
        sequenceOrder: tasks.value.length + 1,
        taskType: StopType.placement,
        latitude: location.latitude ?? 0,
        longitude: location.longitude ?? 0,
        address: address,
        potentialLocationId: location.id,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }).toList();

    tasks.value = [...tasks.value, ...newTasks];
  }

  void _showAddMoveRequestDialog(
    BuildContext context,
    ValueNotifier<List<RouteTask>> tasks,
  ) async {
    final selected = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MoveRequestPickerSheet(),
    );

    if (selected == null || selected.isEmpty) return;

    final newTasks = <RouteTask>[];
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    for (final request in selected) {
      final requestId = request['id'] as String;
      final binId = request['bin_id'] as String?;
      final binNumber = request['bin_number'] as int?;
      final moveType = (request['move_type'] as String?) ?? 'relocation';

      // Current (pickup) location
      final origLat = (request['original_latitude'] as num?)?.toDouble() ?? 0;
      final origLng = (request['original_longitude'] as num?)?.toDouble() ?? 0;
      final currentStreet = request['current_street'] as String? ?? '';
      final city = request['city'] as String? ?? '';
      final zip = request['zip'] as String? ?? '';
      final pickupAddress = currentStreet.isNotEmpty
          ? '$currentStreet, $city $zip'.trim()
          : 'No address';

      // Destination (dropoff) location
      final newLat = (request['new_latitude'] as num?)?.toDouble() ?? 0;
      final newLng = (request['new_longitude'] as num?)?.toDouble() ?? 0;
      final newStreet = request['new_street'] as String? ?? '';
      final newCity = request['new_city'] as String? ?? '';
      final newZip = request['new_zip'] as String? ?? '';
      final dropoffAddress = moveType == 'store'
          ? 'Warehouse Storage'
          : newStreet.isNotEmpty
              ? '$newStreet, $newCity $newZip'.trim()
              : 'No address';

      // 1. Pickup task at current location
      newTasks.add(RouteTask(
        id: 'temp_mr_${requestId}_pickup',
        shiftId: 'temp',
        sequenceOrder: tasks.value.length + newTasks.length + 1,
        taskType: StopType.pickup,
        latitude: origLat,
        longitude: origLng,
        address: pickupAddress,
        moveRequestId: requestId,
        binId: binId,
        binNumber: binNumber,
        destinationLatitude: newLat,
        destinationLongitude: newLng,
        destinationAddress: dropoffAddress,
        moveType: moveType,
        createdAt: now,
      ));

      // 2. Dropoff task at destination
      newTasks.add(RouteTask(
        id: 'temp_mr_${requestId}_dropoff',
        shiftId: 'temp',
        sequenceOrder: tasks.value.length + newTasks.length + 1,
        taskType: StopType.dropoff,
        latitude: newLat,
        longitude: newLng,
        address: dropoffAddress,
        moveRequestId: requestId,
        binId: binId,
        binNumber: binNumber,
        destinationLatitude: newLat,
        destinationLongitude: newLng,
        destinationAddress: dropoffAddress,
        moveType: moveType,
        createdAt: now,
      ));
    }

    tasks.value = [...tasks.value, ...newTasks];
  }

  void _addWarehouseStop(
    BuildContext context,
    ValueNotifier<List<RouteTask>> tasks,
    WarehouseLocation warehouse,
  ) {
    final newTask = RouteTask(
      id: "-${DateTime.now().millisecondsSinceEpoch}",
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
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
    return Dismissible(
      key: ValueKey('dismiss_${task.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.drag_handle, color: Colors.grey.shade300, size: 20),
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
                  size: 18,
                ),
              ),
            ],
          ),
          title: Text(
            task.displayTitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            task.displaySubtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
