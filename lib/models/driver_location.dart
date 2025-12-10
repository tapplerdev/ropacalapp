import 'package:freezed_annotation/freezed_annotation.dart';

part 'driver_location.freezed.dart';
part 'driver_location.g.dart';

/// GPS location update from a driver (single row per driver)
@freezed
class DriverLocation with _$DriverLocation {
  const factory DriverLocation({
    @JsonKey(name: 'driver_id') required String driverId,
    required double latitude,
    required double longitude,
    double? heading, // Direction of travel (0-360 degrees)
    double? speed, // Speed in m/s
    double? accuracy, // GPS accuracy in meters
    @JsonKey(name: 'shift_id') String? shiftId,
    required int timestamp, // Client-side timestamp (milliseconds)
    @JsonKey(name: 'is_connected') @Default(true) bool? isConnected, // WebSocket connection status (null = connected for broadcasts)
    @JsonKey(name: 'updated_at') required int updatedAt, // Last update timestamp (seconds)
  }) = _DriverLocation;

  factory DriverLocation.fromJson(Map<String, dynamic> json) =>
      _$DriverLocationFromJson(json);
}
