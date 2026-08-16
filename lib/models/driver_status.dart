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
    @JsonKey(name: 'driver_name') @Default('Unknown Driver') String name,
    /// UNKNOWN STATUSES MUST NOT THROW. Without `unknownValue`, `$enumDecode`
    /// raises an `ArgumentError` on any status this build has never heard of,
    /// and it raises inside `fromJson` — so the whole object fails to parse.
    /// For a shift that means the provider's catch falls back to `inactive`,
    /// the driver is shown "no shift assigned", and Start is offered again to
    /// someone who has ALREADY started: the exact double-start the backend's
    /// `optimizing` status exists to prevent, arriving through another door.
    ///
    /// Not hypothetical — that is what `optimizing` did to this app before it
    /// was added to the enum. The backend can ship a new status without an app
    /// release, so degrading beats crashing.
    @JsonKey(unknownEnumValue: ShiftStatus.inactive)
    required ShiftStatus status, // active, paused, ready, etc.
    @JsonKey(name: 'shift_id') String? shiftId,
    @JsonKey(name: 'current_bin') @Default(0) int? currentBin,
    @JsonKey(name: 'total_bins') @Default(0) int? totalBins,
    @JsonKey(name: 'last_location') DriverLocation? lastLocation,
  }) = _DriverStatus;

  factory DriverStatus.fromJson(Map<String, dynamic> json) =>
      _$DriverStatusFromJson(json);
}
