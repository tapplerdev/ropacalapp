import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ropacalapp/core/utils/unix_timestamp_converter.dart';
import 'package:ropacalapp/models/driver_location.dart';
import 'package:ropacalapp/models/shift_state.dart';

part 'active_driver.freezed.dart';
part 'active_driver.g.dart';

/// Represents an active driver with their current shift status
@freezed
class ActiveDriver with _$ActiveDriver {
  const factory ActiveDriver({
    /// Driver ID
    @JsonKey(name: 'driver_id') required String driverId,

    /// Driver name
    @JsonKey(name: 'driver_name') @Default('Unknown Driver') String driverName,

    /// Shift ID (null for idle drivers)
    @JsonKey(name: 'shift_id') @Default('') String shiftId,

    /// Assigned route ID
    @JsonKey(name: 'route_id') String? routeId,

    /// Shift status
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
    required ShiftStatus status,

    /// When the shift started
    @JsonKey(name: 'start_time') @UnixTimestampConverter() DateTime? startTime,

    /// Total bins in route
    @JsonKey(name: 'total_bins') @Default(0) int totalBins,

    /// Completed bins count
    @JsonKey(name: 'completed_bins') @Default(0) int completedBins,

    /// Driver's current GPS location
    @JsonKey(name: 'current_location') DriverLocation? currentLocation,

    /// Last updated timestamp
    @JsonKey(name: 'updated_at') int? updatedAt,
  }) = _ActiveDriver;

  const ActiveDriver._();

  factory ActiveDriver.fromJson(Map<String, dynamic> json) =>
      _$ActiveDriverFromJson(json);

  /// Get route display name
  String get routeDisplayName {
    if (routeId != null && routeId!.isNotEmpty) {
      return routeId!.replaceAll('_', ' ').split(' ').map((word) {
        return word[0].toUpperCase() + word.substring(1);
      }).join(' ');
    }
    return 'No Route';
  }

  /// Get completion percentage
  double get completionPercentage {
    if (totalBins == 0) return 0.0;
    return (completedBins / totalBins).clamp(0.0, 1.0);
  }

  /// Get active duration since shift started
  Duration get activeDuration {
    if (startTime == null) return Duration.zero;
    return DateTime.now().difference(startTime!);
  }
}
