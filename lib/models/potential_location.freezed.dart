// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'potential_location.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PotentialLocation _$PotentialLocationFromJson(Map<String, dynamic> json) {
  return _PotentialLocation.fromJson(json);
}

/// @nodoc
mixin _$PotentialLocation {
  String get id => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  String get street => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get zip => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'requested_by_user_id')
  String get requestedByUserId => throw _privateConstructorUsedError;
  @JsonKey(name: 'requested_by_name')
  String get requestedByName => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at_iso')
  String get createdAtIso => throw _privateConstructorUsedError;
  @JsonKey(name: 'converted_to_bin_id')
  String? get convertedToBinId => throw _privateConstructorUsedError;
  @JsonKey(name: 'converted_at_iso')
  String? get convertedAtIso => throw _privateConstructorUsedError;
  @JsonKey(name: 'converted_by_user_id')
  String? get convertedByUserId => throw _privateConstructorUsedError;
  @JsonKey(name: 'bin_number')
  int? get binNumber => throw _privateConstructorUsedError;

  /// Serializes this PotentialLocation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PotentialLocation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PotentialLocationCopyWith<PotentialLocation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PotentialLocationCopyWith<$Res> {
  factory $PotentialLocationCopyWith(
    PotentialLocation value,
    $Res Function(PotentialLocation) then,
  ) = _$PotentialLocationCopyWithImpl<$Res, PotentialLocation>;
  @useResult
  $Res call({
    String id,
    String address,
    String street,
    String city,
    String zip,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'requested_by_user_id') String requestedByUserId,
    @JsonKey(name: 'requested_by_name') String requestedByName,
    String? notes,
    @JsonKey(name: 'created_at_iso') String createdAtIso,
    @JsonKey(name: 'converted_to_bin_id') String? convertedToBinId,
    @JsonKey(name: 'converted_at_iso') String? convertedAtIso,
    @JsonKey(name: 'converted_by_user_id') String? convertedByUserId,
    @JsonKey(name: 'bin_number') int? binNumber,
  });
}

/// @nodoc
class _$PotentialLocationCopyWithImpl<$Res, $Val extends PotentialLocation>
    implements $PotentialLocationCopyWith<$Res> {
  _$PotentialLocationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PotentialLocation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? address = null,
    Object? street = null,
    Object? city = null,
    Object? zip = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? requestedByUserId = null,
    Object? requestedByName = null,
    Object? notes = freezed,
    Object? createdAtIso = null,
    Object? convertedToBinId = freezed,
    Object? convertedAtIso = freezed,
    Object? convertedByUserId = freezed,
    Object? binNumber = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            street: null == street
                ? _value.street
                : street // ignore: cast_nullable_to_non_nullable
                      as String,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
            zip: null == zip
                ? _value.zip
                : zip // ignore: cast_nullable_to_non_nullable
                      as String,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            requestedByUserId: null == requestedByUserId
                ? _value.requestedByUserId
                : requestedByUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            requestedByName: null == requestedByName
                ? _value.requestedByName
                : requestedByName // ignore: cast_nullable_to_non_nullable
                      as String,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAtIso: null == createdAtIso
                ? _value.createdAtIso
                : createdAtIso // ignore: cast_nullable_to_non_nullable
                      as String,
            convertedToBinId: freezed == convertedToBinId
                ? _value.convertedToBinId
                : convertedToBinId // ignore: cast_nullable_to_non_nullable
                      as String?,
            convertedAtIso: freezed == convertedAtIso
                ? _value.convertedAtIso
                : convertedAtIso // ignore: cast_nullable_to_non_nullable
                      as String?,
            convertedByUserId: freezed == convertedByUserId
                ? _value.convertedByUserId
                : convertedByUserId // ignore: cast_nullable_to_non_nullable
                      as String?,
            binNumber: freezed == binNumber
                ? _value.binNumber
                : binNumber // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PotentialLocationImplCopyWith<$Res>
    implements $PotentialLocationCopyWith<$Res> {
  factory _$$PotentialLocationImplCopyWith(
    _$PotentialLocationImpl value,
    $Res Function(_$PotentialLocationImpl) then,
  ) = __$$PotentialLocationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String address,
    String street,
    String city,
    String zip,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'requested_by_user_id') String requestedByUserId,
    @JsonKey(name: 'requested_by_name') String requestedByName,
    String? notes,
    @JsonKey(name: 'created_at_iso') String createdAtIso,
    @JsonKey(name: 'converted_to_bin_id') String? convertedToBinId,
    @JsonKey(name: 'converted_at_iso') String? convertedAtIso,
    @JsonKey(name: 'converted_by_user_id') String? convertedByUserId,
    @JsonKey(name: 'bin_number') int? binNumber,
  });
}

/// @nodoc
class __$$PotentialLocationImplCopyWithImpl<$Res>
    extends _$PotentialLocationCopyWithImpl<$Res, _$PotentialLocationImpl>
    implements _$$PotentialLocationImplCopyWith<$Res> {
  __$$PotentialLocationImplCopyWithImpl(
    _$PotentialLocationImpl _value,
    $Res Function(_$PotentialLocationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PotentialLocation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? address = null,
    Object? street = null,
    Object? city = null,
    Object? zip = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? requestedByUserId = null,
    Object? requestedByName = null,
    Object? notes = freezed,
    Object? createdAtIso = null,
    Object? convertedToBinId = freezed,
    Object? convertedAtIso = freezed,
    Object? convertedByUserId = freezed,
    Object? binNumber = freezed,
  }) {
    return _then(
      _$PotentialLocationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        street: null == street
            ? _value.street
            : street // ignore: cast_nullable_to_non_nullable
                  as String,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
        zip: null == zip
            ? _value.zip
            : zip // ignore: cast_nullable_to_non_nullable
                  as String,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        requestedByUserId: null == requestedByUserId
            ? _value.requestedByUserId
            : requestedByUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        requestedByName: null == requestedByName
            ? _value.requestedByName
            : requestedByName // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAtIso: null == createdAtIso
            ? _value.createdAtIso
            : createdAtIso // ignore: cast_nullable_to_non_nullable
                  as String,
        convertedToBinId: freezed == convertedToBinId
            ? _value.convertedToBinId
            : convertedToBinId // ignore: cast_nullable_to_non_nullable
                  as String?,
        convertedAtIso: freezed == convertedAtIso
            ? _value.convertedAtIso
            : convertedAtIso // ignore: cast_nullable_to_non_nullable
                  as String?,
        convertedByUserId: freezed == convertedByUserId
            ? _value.convertedByUserId
            : convertedByUserId // ignore: cast_nullable_to_non_nullable
                  as String?,
        binNumber: freezed == binNumber
            ? _value.binNumber
            : binNumber // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PotentialLocationImpl implements _PotentialLocation {
  const _$PotentialLocationImpl({
    required this.id,
    required this.address,
    required this.street,
    required this.city,
    required this.zip,
    this.latitude,
    this.longitude,
    @JsonKey(name: 'requested_by_user_id') required this.requestedByUserId,
    @JsonKey(name: 'requested_by_name') required this.requestedByName,
    this.notes,
    @JsonKey(name: 'created_at_iso') required this.createdAtIso,
    @JsonKey(name: 'converted_to_bin_id') this.convertedToBinId,
    @JsonKey(name: 'converted_at_iso') this.convertedAtIso,
    @JsonKey(name: 'converted_by_user_id') this.convertedByUserId,
    @JsonKey(name: 'bin_number') this.binNumber,
  });

  factory _$PotentialLocationImpl.fromJson(Map<String, dynamic> json) =>
      _$$PotentialLocationImplFromJson(json);

  @override
  final String id;
  @override
  final String address;
  @override
  final String street;
  @override
  final String city;
  @override
  final String zip;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  @JsonKey(name: 'requested_by_user_id')
  final String requestedByUserId;
  @override
  @JsonKey(name: 'requested_by_name')
  final String requestedByName;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'created_at_iso')
  final String createdAtIso;
  @override
  @JsonKey(name: 'converted_to_bin_id')
  final String? convertedToBinId;
  @override
  @JsonKey(name: 'converted_at_iso')
  final String? convertedAtIso;
  @override
  @JsonKey(name: 'converted_by_user_id')
  final String? convertedByUserId;
  @override
  @JsonKey(name: 'bin_number')
  final int? binNumber;

  @override
  String toString() {
    return 'PotentialLocation(id: $id, address: $address, street: $street, city: $city, zip: $zip, latitude: $latitude, longitude: $longitude, requestedByUserId: $requestedByUserId, requestedByName: $requestedByName, notes: $notes, createdAtIso: $createdAtIso, convertedToBinId: $convertedToBinId, convertedAtIso: $convertedAtIso, convertedByUserId: $convertedByUserId, binNumber: $binNumber)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PotentialLocationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.street, street) || other.street == street) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.zip, zip) || other.zip == zip) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.requestedByUserId, requestedByUserId) ||
                other.requestedByUserId == requestedByUserId) &&
            (identical(other.requestedByName, requestedByName) ||
                other.requestedByName == requestedByName) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAtIso, createdAtIso) ||
                other.createdAtIso == createdAtIso) &&
            (identical(other.convertedToBinId, convertedToBinId) ||
                other.convertedToBinId == convertedToBinId) &&
            (identical(other.convertedAtIso, convertedAtIso) ||
                other.convertedAtIso == convertedAtIso) &&
            (identical(other.convertedByUserId, convertedByUserId) ||
                other.convertedByUserId == convertedByUserId) &&
            (identical(other.binNumber, binNumber) ||
                other.binNumber == binNumber));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    address,
    street,
    city,
    zip,
    latitude,
    longitude,
    requestedByUserId,
    requestedByName,
    notes,
    createdAtIso,
    convertedToBinId,
    convertedAtIso,
    convertedByUserId,
    binNumber,
  );

  /// Create a copy of PotentialLocation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PotentialLocationImplCopyWith<_$PotentialLocationImpl> get copyWith =>
      __$$PotentialLocationImplCopyWithImpl<_$PotentialLocationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PotentialLocationImplToJson(this);
  }
}

abstract class _PotentialLocation implements PotentialLocation {
  const factory _PotentialLocation({
    required final String id,
    required final String address,
    required final String street,
    required final String city,
    required final String zip,
    final double? latitude,
    final double? longitude,
    @JsonKey(name: 'requested_by_user_id')
    required final String requestedByUserId,
    @JsonKey(name: 'requested_by_name') required final String requestedByName,
    final String? notes,
    @JsonKey(name: 'created_at_iso') required final String createdAtIso,
    @JsonKey(name: 'converted_to_bin_id') final String? convertedToBinId,
    @JsonKey(name: 'converted_at_iso') final String? convertedAtIso,
    @JsonKey(name: 'converted_by_user_id') final String? convertedByUserId,
    @JsonKey(name: 'bin_number') final int? binNumber,
  }) = _$PotentialLocationImpl;

  factory _PotentialLocation.fromJson(Map<String, dynamic> json) =
      _$PotentialLocationImpl.fromJson;

  @override
  String get id;
  @override
  String get address;
  @override
  String get street;
  @override
  String get city;
  @override
  String get zip;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  @JsonKey(name: 'requested_by_user_id')
  String get requestedByUserId;
  @override
  @JsonKey(name: 'requested_by_name')
  String get requestedByName;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'created_at_iso')
  String get createdAtIso;
  @override
  @JsonKey(name: 'converted_to_bin_id')
  String? get convertedToBinId;
  @override
  @JsonKey(name: 'converted_at_iso')
  String? get convertedAtIso;
  @override
  @JsonKey(name: 'converted_by_user_id')
  String? get convertedByUserId;
  @override
  @JsonKey(name: 'bin_number')
  int? get binNumber;

  /// Create a copy of PotentialLocation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PotentialLocationImplCopyWith<_$PotentialLocationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
