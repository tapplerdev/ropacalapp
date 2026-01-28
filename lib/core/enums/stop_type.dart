import 'package:json_annotation/json_annotation.dart';

/// Type of stop in a driver's route
@JsonEnum(valueField: 'value')
enum StopType {
  /// Normal bin collection stop - empty existing bin
  collection('collection'),

  /// Pick up bin for relocation (first step of move request)
  pickup('pickup'),

  /// Place bin at new location (second step of move request)
  dropoff('dropoff'),

  /// Place new bin at potential location
  placement('placement'),

  /// Warehouse stop - load new bins or unload waste
  warehouseStop('warehouse_stop');

  const StopType(this.value);

  final String value;
}
