import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum BinStatus {
  active('active'),
  missing('missing'),
  pendingMove('pending_move'),
  retired('retired'),
  inStorage('in_storage');

  const BinStatus(this.value);

  final String value;
}
