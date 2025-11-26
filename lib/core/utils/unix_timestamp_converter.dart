import 'package:freezed_annotation/freezed_annotation.dart';

/// Converts Unix timestamp (seconds since epoch) to DateTime
class UnixTimestampConverter implements JsonConverter<DateTime?, int?> {
  const UnixTimestampConverter();

  @override
  DateTime? fromJson(int? timestamp) {
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  @override
  int? toJson(DateTime? dateTime) {
    if (dateTime == null) return null;
    return dateTime.millisecondsSinceEpoch ~/ 1000;
  }
}
