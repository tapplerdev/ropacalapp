import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum MoveRequestStatus {
  // Request types (original)
  pendingMove('pending_move'),
  relocate('relocate'),
  retire('retire'),
  warehouseStorage('warehouse_storage'),

  // Execution status (new - for tracking pickup/completion)
  assigned('assigned'), // Assigned to a shift (not started yet)
  inProgress('in_progress'), // Assigned to active shift, driver working on it
  pending('pending'), // Assigned to driver, not picked up yet
  pickedUp('picked_up'), // Bin picked up, in transit to drop-off
  completed('completed'), // Placed at new location
  cancelled('cancelled'); // Move request cancelled

  const MoveRequestStatus(this.value);

  final String value;
}
