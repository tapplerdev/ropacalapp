// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_bin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RouteBin _$RouteBinFromJson(Map<String, dynamic> json) {
  return _RouteBin.fromJson(json);
}

/// @nodoc
mixin _$RouteBin {
  /// Route bin ID
  int get id => throw _privateConstructorUsedError;

  /// Associated shift ID
  @JsonKey(name: 'shift_id')
  String get shiftId => throw _privateConstructorUsedError;

  /// Bin ID
  @JsonKey(name: 'bin_id')
  String get binId => throw _privateConstructorUsedError;

  /// Order in the route sequence
  @JsonKey(name: 'sequence_order')
  int get sequenceOrder => throw _privateConstructorUsedError;

  /// Whether this bin has been completed
  @JsonKey(name: 'is_completed')
  int get isCompleted => throw _privateConstructorUsedError;

  /// Timestamp when completed (Unix timestamp)
  @JsonKey(name: 'completed_at')
  int? get completedAt => throw _privateConstructorUsedError;

  /// Created timestamp (Unix timestamp)
  @JsonKey(name: 'created_at')
  int get createdAt => throw _privateConstructorUsedError;

  /// Bin number
  @JsonKey(name: 'bin_number')
  int get binNumber => throw _privateConstructorUsedError;

  /// Street address
  @JsonKey(name: 'current_street')
  String get currentStreet => throw _privateConstructorUsedError;

  /// City
  String get city => throw _privateConstructorUsedError;

  /// Zip code
  String get zip => throw _privateConstructorUsedError;

  /// Fill percentage (0-100)
  @JsonKey(name: 'fill_percentage')
  int get fillPercentage => throw _privateConstructorUsedError;

  /// Latitude coordinate
  double get latitude => throw _privateConstructorUsedError;

  /// Longitude coordinate
  double get longitude => throw _privateConstructorUsedError;

  /// Serializes this RouteBin to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RouteBin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RouteBinCopyWith<RouteBin> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RouteBinCopyWith<$Res> {
  factory $RouteBinCopyWith(RouteBin value, $Res Function(RouteBin) then) =
      _$RouteBinCopyWithImpl<$Res, RouteBin>;
  @useResult
  $Res call({
    int id,
    @JsonKey(name: 'shift_id') String shiftId,
    @JsonKey(name: 'bin_id') String binId,
    @JsonKey(name: 'sequence_order') int sequenceOrder,
    @JsonKey(name: 'is_completed') int isCompleted,
    @JsonKey(name: 'completed_at') int? completedAt,
    @JsonKey(name: 'created_at') int createdAt,
    @JsonKey(name: 'bin_number') int binNumber,
    @JsonKey(name: 'current_street') String currentStreet,
    String city,
    String zip,
    @JsonKey(name: 'fill_percentage') int fillPercentage,
    double latitude,
    double longitude,
  });
}

/// @nodoc
class _$RouteBinCopyWithImpl<$Res, $Val extends RouteBin>
    implements $RouteBinCopyWith<$Res> {
  _$RouteBinCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RouteBin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? shiftId = null,
    Object? binId = null,
    Object? sequenceOrder = null,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? createdAt = null,
    Object? binNumber = null,
    Object? currentStreet = null,
    Object? city = null,
    Object? zip = null,
    Object? fillPercentage = null,
    Object? latitude = null,
    Object? longitude = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            shiftId: null == shiftId
                ? _value.shiftId
                : shiftId // ignore: cast_nullable_to_non_nullable
                      as String,
            binId: null == binId
                ? _value.binId
                : binId // ignore: cast_nullable_to_non_nullable
                      as String,
            sequenceOrder: null == sequenceOrder
                ? _value.sequenceOrder
                : sequenceOrder // ignore: cast_nullable_to_non_nullable
                      as int,
            isCompleted: null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                      as int,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as int?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as int,
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
            fillPercentage: null == fillPercentage
                ? _value.fillPercentage
                : fillPercentage // ignore: cast_nullable_to_non_nullable
                      as int,
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RouteBinImplCopyWith<$Res>
    implements $RouteBinCopyWith<$Res> {
  factory _$$RouteBinImplCopyWith(
    _$RouteBinImpl value,
    $Res Function(_$RouteBinImpl) then,
  ) = __$$RouteBinImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    @JsonKey(name: 'shift_id') String shiftId,
    @JsonKey(name: 'bin_id') String binId,
    @JsonKey(name: 'sequence_order') int sequenceOrder,
    @JsonKey(name: 'is_completed') int isCompleted,
    @JsonKey(name: 'completed_at') int? completedAt,
    @JsonKey(name: 'created_at') int createdAt,
    @JsonKey(name: 'bin_number') int binNumber,
    @JsonKey(name: 'current_street') String currentStreet,
    String city,
    String zip,
    @JsonKey(name: 'fill_percentage') int fillPercentage,
    double latitude,
    double longitude,
  });
}

/// @nodoc
class __$$RouteBinImplCopyWithImpl<$Res>
    extends _$RouteBinCopyWithImpl<$Res, _$RouteBinImpl>
    implements _$$RouteBinImplCopyWith<$Res> {
  __$$RouteBinImplCopyWithImpl(
    _$RouteBinImpl _value,
    $Res Function(_$RouteBinImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RouteBin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? shiftId = null,
    Object? binId = null,
    Object? sequenceOrder = null,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? createdAt = null,
    Object? binNumber = null,
    Object? currentStreet = null,
    Object? city = null,
    Object? zip = null,
    Object? fillPercentage = null,
    Object? latitude = null,
    Object? longitude = null,
  }) {
    return _then(
      _$RouteBinImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        shiftId: null == shiftId
            ? _value.shiftId
            : shiftId // ignore: cast_nullable_to_non_nullable
                  as String,
        binId: null == binId
            ? _value.binId
            : binId // ignore: cast_nullable_to_non_nullable
                  as String,
        sequenceOrder: null == sequenceOrder
            ? _value.sequenceOrder
            : sequenceOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        isCompleted: null == isCompleted
            ? _value.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as int,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as int,
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
        fillPercentage: null == fillPercentage
            ? _value.fillPercentage
            : fillPercentage // ignore: cast_nullable_to_non_nullable
                  as int,
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RouteBinImpl implements _RouteBin {
  const _$RouteBinImpl({
    required this.id,
    @JsonKey(name: 'shift_id') required this.shiftId,
    @JsonKey(name: 'bin_id') required this.binId,
    @JsonKey(name: 'sequence_order') required this.sequenceOrder,
    @JsonKey(name: 'is_completed') this.isCompleted = 0,
    @JsonKey(name: 'completed_at') this.completedAt,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'bin_number') required this.binNumber,
    @JsonKey(name: 'current_street') required this.currentStreet,
    required this.city,
    required this.zip,
    @JsonKey(name: 'fill_percentage') required this.fillPercentage,
    required this.latitude,
    required this.longitude,
  });

  factory _$RouteBinImpl.fromJson(Map<String, dynamic> json) =>
      _$$RouteBinImplFromJson(json);

  /// Route bin ID
  @override
  final int id;

  /// Associated shift ID
  @override
  @JsonKey(name: 'shift_id')
  final String shiftId;

  /// Bin ID
  @override
  @JsonKey(name: 'bin_id')
  final String binId;

  /// Order in the route sequence
  @override
  @JsonKey(name: 'sequence_order')
  final int sequenceOrder;

  /// Whether this bin has been completed
  @override
  @JsonKey(name: 'is_completed')
  final int isCompleted;

  /// Timestamp when completed (Unix timestamp)
  @override
  @JsonKey(name: 'completed_at')
  final int? completedAt;

  /// Created timestamp (Unix timestamp)
  @override
  @JsonKey(name: 'created_at')
  final int createdAt;

  /// Bin number
  @override
  @JsonKey(name: 'bin_number')
  final int binNumber;

  /// Street address
  @override
  @JsonKey(name: 'current_street')
  final String currentStreet;

  /// City
  @override
  final String city;

  /// Zip code
  @override
  final String zip;

  /// Fill percentage (0-100)
  @override
  @JsonKey(name: 'fill_percentage')
  final int fillPercentage;

  /// Latitude coordinate
  @override
  final double latitude;

  /// Longitude coordinate
  @override
  final double longitude;

  @override
  String toString() {
    return 'RouteBin(id: $id, shiftId: $shiftId, binId: $binId, sequenceOrder: $sequenceOrder, isCompleted: $isCompleted, completedAt: $completedAt, createdAt: $createdAt, binNumber: $binNumber, currentStreet: $currentStreet, city: $city, zip: $zip, fillPercentage: $fillPercentage, latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RouteBinImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.shiftId, shiftId) || other.shiftId == shiftId) &&
            (identical(other.binId, binId) || other.binId == binId) &&
            (identical(other.sequenceOrder, sequenceOrder) ||
                other.sequenceOrder == sequenceOrder) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.binNumber, binNumber) ||
                other.binNumber == binNumber) &&
            (identical(other.currentStreet, currentStreet) ||
                other.currentStreet == currentStreet) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.zip, zip) || other.zip == zip) &&
            (identical(other.fillPercentage, fillPercentage) ||
                other.fillPercentage == fillPercentage) &&
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
    shiftId,
    binId,
    sequenceOrder,
    isCompleted,
    completedAt,
    createdAt,
    binNumber,
    currentStreet,
    city,
    zip,
    fillPercentage,
    latitude,
    longitude,
  );

  /// Create a copy of RouteBin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RouteBinImplCopyWith<_$RouteBinImpl> get copyWith =>
      __$$RouteBinImplCopyWithImpl<_$RouteBinImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RouteBinImplToJson(this);
  }
}

abstract class _RouteBin implements RouteBin {
  const factory _RouteBin({
    required final int id,
    @JsonKey(name: 'shift_id') required final String shiftId,
    @JsonKey(name: 'bin_id') required final String binId,
    @JsonKey(name: 'sequence_order') required final int sequenceOrder,
    @JsonKey(name: 'is_completed') final int isCompleted,
    @JsonKey(name: 'completed_at') final int? completedAt,
    @JsonKey(name: 'created_at') required final int createdAt,
    @JsonKey(name: 'bin_number') required final int binNumber,
    @JsonKey(name: 'current_street') required final String currentStreet,
    required final String city,
    required final String zip,
    @JsonKey(name: 'fill_percentage') required final int fillPercentage,
    required final double latitude,
    required final double longitude,
  }) = _$RouteBinImpl;

  factory _RouteBin.fromJson(Map<String, dynamic> json) =
      _$RouteBinImpl.fromJson;

  /// Route bin ID
  @override
  int get id;

  /// Associated shift ID
  @override
  @JsonKey(name: 'shift_id')
  String get shiftId;

  /// Bin ID
  @override
  @JsonKey(name: 'bin_id')
  String get binId;

  /// Order in the route sequence
  @override
  @JsonKey(name: 'sequence_order')
  int get sequenceOrder;

  /// Whether this bin has been completed
  @override
  @JsonKey(name: 'is_completed')
  int get isCompleted;

  /// Timestamp when completed (Unix timestamp)
  @override
  @JsonKey(name: 'completed_at')
  int? get completedAt;

  /// Created timestamp (Unix timestamp)
  @override
  @JsonKey(name: 'created_at')
  int get createdAt;

  /// Bin number
  @override
  @JsonKey(name: 'bin_number')
  int get binNumber;

  /// Street address
  @override
  @JsonKey(name: 'current_street')
  String get currentStreet;

  /// City
  @override
  String get city;

  /// Zip code
  @override
  String get zip;

  /// Fill percentage (0-100)
  @override
  @JsonKey(name: 'fill_percentage')
  int get fillPercentage;

  /// Latitude coordinate
  @override
  double get latitude;

  /// Longitude coordinate
  @override
  double get longitude;

  /// Create a copy of RouteBin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RouteBinImplCopyWith<_$RouteBinImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
