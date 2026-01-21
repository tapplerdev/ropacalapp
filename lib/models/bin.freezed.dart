// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Bin _$BinFromJson(Map<String, dynamic> json) {
  return _Bin.fromJson(json);
}

/// @nodoc
mixin _$Bin {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'bin_number')
  int get binNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_street')
  String get currentStreet => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get zip => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_moved')
  DateTime? get lastMoved => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_checked')
  DateTime? get lastChecked => throw _privateConstructorUsedError;
  BinStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'fill_percentage')
  int? get fillPercentage => throw _privateConstructorUsedError;
  bool get checked => throw _privateConstructorUsedError;
  @JsonKey(name: 'move_requested')
  bool get moveRequested => throw _privateConstructorUsedError;
  @JsonKey(name: 'move_request_id')
  String? get moveRequestId => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;

  /// Serializes this Bin to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Bin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BinCopyWith<Bin> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BinCopyWith<$Res> {
  factory $BinCopyWith(Bin value, $Res Function(Bin) then) =
      _$BinCopyWithImpl<$Res, Bin>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'bin_number') int binNumber,
    @JsonKey(name: 'current_street') String currentStreet,
    String city,
    String zip,
    @JsonKey(name: 'last_moved') DateTime? lastMoved,
    @JsonKey(name: 'last_checked') DateTime? lastChecked,
    BinStatus status,
    @JsonKey(name: 'fill_percentage') int? fillPercentage,
    bool checked,
    @JsonKey(name: 'move_requested') bool moveRequested,
    @JsonKey(name: 'move_request_id') String? moveRequestId,
    double? latitude,
    double? longitude,
  });
}

/// @nodoc
class _$BinCopyWithImpl<$Res, $Val extends Bin> implements $BinCopyWith<$Res> {
  _$BinCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Bin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? binNumber = null,
    Object? currentStreet = null,
    Object? city = null,
    Object? zip = null,
    Object? lastMoved = freezed,
    Object? lastChecked = freezed,
    Object? status = null,
    Object? fillPercentage = freezed,
    Object? checked = null,
    Object? moveRequested = null,
    Object? moveRequestId = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            binNumber: null == binNumber
                ? _value.binNumber
                : binNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            currentStreet: null == currentStreet
                ? _value.currentStreet
                : currentStreet // ignore: cast_nullable_to_non_nullable
                      as String,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
            zip: null == zip
                ? _value.zip
                : zip // ignore: cast_nullable_to_non_nullable
                      as String,
            lastMoved: freezed == lastMoved
                ? _value.lastMoved
                : lastMoved // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lastChecked: freezed == lastChecked
                ? _value.lastChecked
                : lastChecked // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as BinStatus,
            fillPercentage: freezed == fillPercentage
                ? _value.fillPercentage
                : fillPercentage // ignore: cast_nullable_to_non_nullable
                      as int?,
            checked: null == checked
                ? _value.checked
                : checked // ignore: cast_nullable_to_non_nullable
                      as bool,
            moveRequested: null == moveRequested
                ? _value.moveRequested
                : moveRequested // ignore: cast_nullable_to_non_nullable
                      as bool,
            moveRequestId: freezed == moveRequestId
                ? _value.moveRequestId
                : moveRequestId // ignore: cast_nullable_to_non_nullable
                      as String?,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BinImplCopyWith<$Res> implements $BinCopyWith<$Res> {
  factory _$$BinImplCopyWith(_$BinImpl value, $Res Function(_$BinImpl) then) =
      __$$BinImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'bin_number') int binNumber,
    @JsonKey(name: 'current_street') String currentStreet,
    String city,
    String zip,
    @JsonKey(name: 'last_moved') DateTime? lastMoved,
    @JsonKey(name: 'last_checked') DateTime? lastChecked,
    BinStatus status,
    @JsonKey(name: 'fill_percentage') int? fillPercentage,
    bool checked,
    @JsonKey(name: 'move_requested') bool moveRequested,
    @JsonKey(name: 'move_request_id') String? moveRequestId,
    double? latitude,
    double? longitude,
  });
}

/// @nodoc
class __$$BinImplCopyWithImpl<$Res> extends _$BinCopyWithImpl<$Res, _$BinImpl>
    implements _$$BinImplCopyWith<$Res> {
  __$$BinImplCopyWithImpl(_$BinImpl _value, $Res Function(_$BinImpl) _then)
    : super(_value, _then);

  /// Create a copy of Bin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? binNumber = null,
    Object? currentStreet = null,
    Object? city = null,
    Object? zip = null,
    Object? lastMoved = freezed,
    Object? lastChecked = freezed,
    Object? status = null,
    Object? fillPercentage = freezed,
    Object? checked = null,
    Object? moveRequested = null,
    Object? moveRequestId = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
  }) {
    return _then(
      _$BinImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        binNumber: null == binNumber
            ? _value.binNumber
            : binNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        currentStreet: null == currentStreet
            ? _value.currentStreet
            : currentStreet // ignore: cast_nullable_to_non_nullable
                  as String,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
        zip: null == zip
            ? _value.zip
            : zip // ignore: cast_nullable_to_non_nullable
                  as String,
        lastMoved: freezed == lastMoved
            ? _value.lastMoved
            : lastMoved // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastChecked: freezed == lastChecked
            ? _value.lastChecked
            : lastChecked // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as BinStatus,
        fillPercentage: freezed == fillPercentage
            ? _value.fillPercentage
            : fillPercentage // ignore: cast_nullable_to_non_nullable
                  as int?,
        checked: null == checked
            ? _value.checked
            : checked // ignore: cast_nullable_to_non_nullable
                  as bool,
        moveRequested: null == moveRequested
            ? _value.moveRequested
            : moveRequested // ignore: cast_nullable_to_non_nullable
                  as bool,
        moveRequestId: freezed == moveRequestId
            ? _value.moveRequestId
            : moveRequestId // ignore: cast_nullable_to_non_nullable
                  as String?,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BinImpl implements _Bin {
  const _$BinImpl({
    required this.id,
    @JsonKey(name: 'bin_number') required this.binNumber,
    @JsonKey(name: 'current_street') required this.currentStreet,
    required this.city,
    required this.zip,
    @JsonKey(name: 'last_moved') this.lastMoved,
    @JsonKey(name: 'last_checked') this.lastChecked,
    required this.status,
    @JsonKey(name: 'fill_percentage') this.fillPercentage,
    this.checked = false,
    @JsonKey(name: 'move_requested') this.moveRequested = false,
    @JsonKey(name: 'move_request_id') this.moveRequestId,
    this.latitude,
    this.longitude,
  });

  factory _$BinImpl.fromJson(Map<String, dynamic> json) =>
      _$$BinImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'bin_number')
  final int binNumber;
  @override
  @JsonKey(name: 'current_street')
  final String currentStreet;
  @override
  final String city;
  @override
  final String zip;
  @override
  @JsonKey(name: 'last_moved')
  final DateTime? lastMoved;
  @override
  @JsonKey(name: 'last_checked')
  final DateTime? lastChecked;
  @override
  final BinStatus status;
  @override
  @JsonKey(name: 'fill_percentage')
  final int? fillPercentage;
  @override
  @JsonKey()
  final bool checked;
  @override
  @JsonKey(name: 'move_requested')
  final bool moveRequested;
  @override
  @JsonKey(name: 'move_request_id')
  final String? moveRequestId;
  @override
  final double? latitude;
  @override
  final double? longitude;

  @override
  String toString() {
    return 'Bin(id: $id, binNumber: $binNumber, currentStreet: $currentStreet, city: $city, zip: $zip, lastMoved: $lastMoved, lastChecked: $lastChecked, status: $status, fillPercentage: $fillPercentage, checked: $checked, moveRequested: $moveRequested, moveRequestId: $moveRequestId, latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BinImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.binNumber, binNumber) ||
                other.binNumber == binNumber) &&
            (identical(other.currentStreet, currentStreet) ||
                other.currentStreet == currentStreet) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.zip, zip) || other.zip == zip) &&
            (identical(other.lastMoved, lastMoved) ||
                other.lastMoved == lastMoved) &&
            (identical(other.lastChecked, lastChecked) ||
                other.lastChecked == lastChecked) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.fillPercentage, fillPercentage) ||
                other.fillPercentage == fillPercentage) &&
            (identical(other.checked, checked) || other.checked == checked) &&
            (identical(other.moveRequested, moveRequested) ||
                other.moveRequested == moveRequested) &&
            (identical(other.moveRequestId, moveRequestId) ||
                other.moveRequestId == moveRequestId) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    binNumber,
    currentStreet,
    city,
    zip,
    lastMoved,
    lastChecked,
    status,
    fillPercentage,
    checked,
    moveRequested,
    moveRequestId,
    latitude,
    longitude,
  );

  /// Create a copy of Bin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BinImplCopyWith<_$BinImpl> get copyWith =>
      __$$BinImplCopyWithImpl<_$BinImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BinImplToJson(this);
  }
}

abstract class _Bin implements Bin {
  const factory _Bin({
    required final String id,
    @JsonKey(name: 'bin_number') required final int binNumber,
    @JsonKey(name: 'current_street') required final String currentStreet,
    required final String city,
    required final String zip,
    @JsonKey(name: 'last_moved') final DateTime? lastMoved,
    @JsonKey(name: 'last_checked') final DateTime? lastChecked,
    required final BinStatus status,
    @JsonKey(name: 'fill_percentage') final int? fillPercentage,
    final bool checked,
    @JsonKey(name: 'move_requested') final bool moveRequested,
    @JsonKey(name: 'move_request_id') final String? moveRequestId,
    final double? latitude,
    final double? longitude,
  }) = _$BinImpl;

  factory _Bin.fromJson(Map<String, dynamic> json) = _$BinImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'bin_number')
  int get binNumber;
  @override
  @JsonKey(name: 'current_street')
  String get currentStreet;
  @override
  String get city;
  @override
  String get zip;
  @override
  @JsonKey(name: 'last_moved')
  DateTime? get lastMoved;
  @override
  @JsonKey(name: 'last_checked')
  DateTime? get lastChecked;
  @override
  BinStatus get status;
  @override
  @JsonKey(name: 'fill_percentage')
  int? get fillPercentage;
  @override
  bool get checked;
  @override
  @JsonKey(name: 'move_requested')
  bool get moveRequested;
  @override
  @JsonKey(name: 'move_request_id')
  String? get moveRequestId;
  @override
  double? get latitude;
  @override
  double? get longitude;

  /// Create a copy of Bin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BinImplCopyWith<_$BinImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
