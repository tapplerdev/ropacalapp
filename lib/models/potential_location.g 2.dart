// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'potential_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PotentialLocationImpl _$$PotentialLocationImplFromJson(
  Map<String, dynamic> json,
) => _$PotentialLocationImpl(
  id: json['id'] as String,
  address: json['address'] as String,
  street: json['street'] as String,
  city: json['city'] as String,
  zip: json['zip'] as String,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  requestedByUserId: json['requested_by_user_id'] as String,
  requestedByName: json['requested_by_name'] as String,
  notes: json['notes'] as String?,
  createdAtIso: json['created_at_iso'] as String,
  convertedToBinId: json['converted_to_bin_id'] as String?,
  convertedAtIso: json['converted_at_iso'] as String?,
  convertedByUserId: json['converted_by_user_id'] as String?,
  convertedViaShiftId: json['converted_via_shift_id'] as String?,
  convertedByDriverName: json['converted_by_driver_name'] as String?,
  convertedByManagerName: json['converted_by_manager_name'] as String?,
  binNumber: (json['bin_number'] as num?)?.toInt(),
);

Map<String, dynamic> _$$PotentialLocationImplToJson(
  _$PotentialLocationImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'address': instance.address,
  'street': instance.street,
  'city': instance.city,
  'zip': instance.zip,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'requested_by_user_id': instance.requestedByUserId,
  'requested_by_name': instance.requestedByName,
  'notes': instance.notes,
  'created_at_iso': instance.createdAtIso,
  'converted_to_bin_id': instance.convertedToBinId,
  'converted_at_iso': instance.convertedAtIso,
  'converted_by_user_id': instance.convertedByUserId,
  'converted_via_shift_id': instance.convertedViaShiftId,
  'converted_by_driver_name': instance.convertedByDriverName,
  'converted_by_manager_name': instance.convertedByManagerName,
  'bin_number': instance.binNumber,
};
