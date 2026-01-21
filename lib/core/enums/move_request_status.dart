import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum MoveRequestStatus {
  pendingMove('pending_move'),
  relocate('relocate'),
  retire('retire'),
  warehouseStorage('warehouse_storage');

  const MoveRequestStatus(this.value);

  final String value;
}
