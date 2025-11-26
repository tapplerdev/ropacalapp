import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum BinStatus {
  active('active'),
  missing('missing');

  const BinStatus(this.value);

  final String value;
}
