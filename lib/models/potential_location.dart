import 'package:freezed_annotation/freezed_annotation.dart';

part 'potential_location.freezed.dart';
part 'potential_location.g.dart';

@freezed
class PotentialLocation with _$PotentialLocation {
  const factory PotentialLocation({
    required String id,
    required String address,
    required String street,
    required String city,
    required String zip,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'requested_by_user_id') required String requestedByUserId,
    @JsonKey(name: 'requested_by_name') required String requestedByName,
    String? notes,
    @JsonKey(name: 'created_at_iso') required String createdAtIso,
    @JsonKey(name: 'converted_to_bin_id') String? convertedToBinId,
    @JsonKey(name: 'converted_at_iso') String? convertedAtIso,
    @JsonKey(name: 'converted_by_user_id') String? convertedByUserId,
    @JsonKey(name: 'converted_via_shift_id') String? convertedViaShiftId,
    @JsonKey(name: 'converted_by_driver_name') String? convertedByDriverName,
    @JsonKey(name: 'converted_by_manager_name') String? convertedByManagerName,
    @JsonKey(name: 'bin_number') int? binNumber,
  }) = _PotentialLocation;

  factory PotentialLocation.fromJson(Map<String, dynamic> json) =>
      _$PotentialLocationFromJson(json);
}
