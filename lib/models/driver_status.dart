import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ropacalapp/models/driver_location.dart';
import 'package:ropacalapp/models/shift_state.dart';

part 'driver_status.freezed.dart';
part 'driver_status.g.dart';

/// Driver's current state for manager dashboard
@freezed
class DriverStatus with _$DriverStatus {
  const factory DriverStatus({
    @JsonKey(name: 'driver_id') required String driverId,
    required String name,
    required ShiftStatus status, // active, paused, ready, etc.
    @JsonKey(name: 'shift_id') String? shiftId,
    @JsonKey(name: 'current_bin') @Default(0) int? currentBin,
    @JsonKey(name: 'total_bins') @Default(0) int? totalBins,
    @JsonKey(name: 'last_location') DriverLocation? lastLocation,
  }) = _DriverStatus;

  factory DriverStatus.fromJson(Map<String, dynamic> json) =>
      _$DriverStatusFromJson(json);
}
