import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum UserRole {
  driver('driver'),
  admin('admin');

  const UserRole(this.value);

  final String value;
}
