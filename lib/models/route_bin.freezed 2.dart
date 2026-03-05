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
  /// Route bin ID (route_task UUID)
  String get id => throw _privateConstructorUsedError;

  /// Associated shift ID
  @JsonKey(name: 'shift_id')
  String get shiftId => throw _privateConstructorUsedError;

  /// Bin ID
  @JsonKey(name: 'bin_id')
  String get binId => throw _privateConstructorUsedError;

  /// Order in the route sequence
  @JsonKey(name: 'sequence_order')
  int get sequenceOrder => throw _privateConstructorUsedError;

  /// Type of stop (collection, pickup, dropoff)
  @JsonKey(name: 'stop_type')
  StopType get stopType => throw _privateConstructorUsedError;

  /// Move request ID (for pickup/dropoff stops)
  @JsonKey(name: 'move_request_id')
  String? get moveRequestId => throw _privateConstructorUsedError;

  /// Original address for move request (pickup location)
  @JsonKey(name: 'original_address')
  String? get originalAddress => throw _privateConstructorUsedError;

  /// New address for move request (dropoff location)
  @JsonKey(name: 'new_address')
  String? get newAddress => throw _privateConstructorUsedError;

  /// Move request type (relocation, store, etc.)
  @JsonKey(name: 'move_type')
  String? get moveType => throw _privateConstructorUsedError;

  /// Potential location ID (for placement tasks)
  @JsonKey(name: 'potential_location_id')
  String? get potentialLocationId => throw _privateConstructorUsedError;

  /// New bin number being placed (for placement tasks)
  @JsonKey(name: 'new_bin_number')
  int? get newBinNumber => throw _privateConstructorUsedError;

  /// Warehouse action type (load, unload, both)
  @JsonKey(name: 'warehouse_action')
  String? get warehouseAction => throw _privateConstructorUsedError;

  /// Number of bins to load at warehouse
  @JsonKey(name: 'bins_to_load')
  int? get binsToLoad => throw _privateConstructorUsedError;

  /// Whether this bin has been completed
  @JsonKey(name: 'is_completed')
  int get isCompleted => throw _privateConstructorUsedError;

  /// Timestamp when completed (Unix timestamp)
  @JsonKey(name: 'completed_at')
  int? get completedAt => throw _privateConstructorUsedError;

  /// Updated fill percentage after driver check-in (0-100)
  @JsonKey(name: 'updated_fill_percentage')
  int? get updatedFillPercentage => throw _privateConstructorUsedError;

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
    String id,
    @JsonKey(name: 'shift_id') String shiftId,
    @JsonKey(name: 'bin_id') String binId,
    @JsonKey(name: 'sequence_order') int sequenceOrder,
    @JsonKey(name: 'stop_type') StopType stopType,
    @JsonKey(name: 'move_request_id') String? moveRequestId,
    @JsonKey(name: 'original_address') String? originalAddress,
    @JsonKey(name: 'new_address') String? newAddress,
    @JsonKey(name: 'move_type') String? moveType,
    @JsonKey(name: 'potential_location_id') String? potentialLocationId,
    @JsonKey(name: 'new_bin_number') int? newBinNumber,
    @JsonKey(name: 'warehouse_action') String? warehouseAction,
    @JsonKey(name: 'bins_to_load') int? binsToLoad,
    @JsonKey(name: 'is_completed') int isCompleted,
    @JsonKey(name: 'completed_at') int? completedAt,
    @JsonKey(name: 'updated_fill_percentage') int? updatedFillPercentage,
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
    Object? stopType = null,
    Object? moveRequestId = freezed,
    Object? originalAddress = freezed,
    Object? newAddress = freezed,
    Object? moveType = freezed,
    Object? potentialLocationId = freezed,
    Object? newBinNumber = freezed,
    Object? warehouseAction = freezed,
    Object? binsToLoad = freezed,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? updatedFillPercentage = freezed,
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
                      as String,
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
            stopType: null == stopType
                ? _value.stopType
                : stopType // ignore: cast_nullable_to_non_nullable
                      as StopType,
            moveRequestId: freezed == moveRequestId
                ? _value.moveRequestId
                : moveRequestId // ignore: cast_nullable_to_non_nullable
                      as String?,
            originalAddress: freezed == originalAddress
                ? _value.originalAddress
                : originalAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            newAddress: freezed == newAddress
                ? _value.newAddress
                : newAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            moveType: freezed == moveType
                ? _value.moveType
                : moveType // ignore: cast_nullable_to_non_nullable
                      as String?,
            potentialLocationId: freezed == potentialLocationId
                ? _value.potentialLocationId
                : potentialLocationId // ignore: cast_nullable_to_non_nullable
                      as String?,
            newBinNumber: freezed == newBinNumber
                ? _value.newBinNumber
                : newBinNumber // ignore: cast_nullable_to_non_nullable
                      as int?,
            warehouseAction: freezed == warehouseAction
                ? _value.warehouseAction
                : warehouseAction // ignore: cast_nullable_to_non_nullable
                      as String?,
            binsToLoad: freezed == binsToLoad
                ? _value.binsToLoad
                : binsToLoad // ignore: cast_nullable_to_non_nullable
                      as int?,
            isCompleted: null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                      as int,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as int?,
            updatedFillPercentage: freezed == updatedFillPercentage
                ? _value.updatedFillPercentage
                : updatedFillPercentage // ignore: cast_nullable_to_non_nullable
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
    String id,
    @JsonKey(name: 'shift_id') String shiftId,
    @JsonKey(name: 'bin_id') String binId,
    @JsonKey(name: 'sequence_order') int sequenceOrder,
    @JsonKey(name: 'stop_type') StopType stopType,
    @JsonKey(name: 'move_request_id') String? moveRequestId,
    @JsonKey(name: 'original_address') String? originalAddress,
    @JsonKey(name: 'new_address') String? newAddress,
    @JsonKey(name: 'move_type') String? moveType,
    @JsonKey(name: 'potential_location_id') String? potentialLocationId,
    @JsonKey(name: 'new_bin_number') int? newBinNumber,
    @JsonKey(name: 'warehouse_action') String? warehouseAction,
    @JsonKey(name: 'bins_to_load') int? binsToLoad,
    @JsonKey(name: 'is_completed') int isCompleted,
    @JsonKey(name: 'completed_at') int? completedAt,
    @JsonKey(name: 'updated_fill_percentage') int? updatedFillPercentage,
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
    Object? stopType = null,
    Object? moveRequestId = freezed,
    Object? originalAddress = freezed,
    Object? newAddress = freezed,
    Object? moveType = freezed,
    Object? potentialLocationId = freezed,
    Object? newBinNumber = freezed,
    Object? warehouseAction = freezed,
    Object? binsToLoad = freezed,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? updatedFillPercentage = freezed,
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
                  as String,
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
        stopType: null == stopType
            ? _value.stopType
            : stopType // ignore: cast_nullable_to_non_nullable
                  as StopType,
        moveRequestId: freezed == moveRequestId
            ? _value.moveRequestId
            : moveRequestId // ignore: cast_nullable_to_non_nullable
                  as String?,
        originalAddress: freezed == originalAddress
            ? _value.originalAddress
            : originalAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        newAddress: freezed == newAddress
            ? _value.newAddress
            : newAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        moveType: freezed == moveType
            ? _value.moveType
            : moveType // ignore: cast_nullable_to_non_nullable
                  as String?,
        potentialLocationId: freezed == potentialLocationId
            ? _value.potentialLocationId
            : potentialLocationId // ignore: cast_nullable_to_non_nullable
                  as String?,
        newBinNumber: freezed == newBinNumber
            ? _value.newBinNumber
            : newBinNumber // ignore: cast_nullable_to_non_nullable
                  as int?,
        warehouseAction: freezed == warehouseAction
            ? _value.warehouseAction
            : warehouseAction // ignore: cast_nullable_to_non_nullable
                  as String?,
        binsToLoad: freezed == binsToLoad
            ? _value.binsToLoad
            : binsToLoad // ignore: cast_nullable_to_non_nullable
                  as int?,
        isCompleted: null == isCompleted
            ? _value.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as int,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as int?,
        updatedFillPercentage: freezed == updatedFillPercentage
            ? _value.updatedFillPercentage
            : updatedFillPercentage // ignore: cast_nullable_to_non_nullable
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
class _$RouteBinImpl extends _RouteBin {
  const _$RouteBinImpl({
    required this.id,
    @JsonKey(name: 'shift_id') required this.shiftId,
    @JsonKey(name: 'bin_id') required this.binId,
    @JsonKey(name: 'sequence_order') required this.sequenceOrder,
    @JsonKey(name: 'stop_type') this.stopType = StopType.collection,
    @JsonKey(name: 'move_request_id') this.moveRequestId,
    @JsonKey(name: 'original_address') this.originalAddress,
    @JsonKey(name: 'new_address') this.newAddress,
    @JsonKey(name: 'move_type') this.moveType,
    @JsonKey(name: 'potential_location_id') this.potentialLocationId,
    @JsonKey(name: 'new_bin_number') this.newBinNumber,
    @JsonKey(name: 'warehouse_action') this.warehouseAction,
    @JsonKey(name: 'bins_to_load') this.binsToLoad,
    @JsonKey(name: 'is_completed') this.isCompleted = 0,
    @JsonKey(name: 'completed_at') this.completedAt,
    @JsonKey(name: 'updated_fill_percentage') this.updatedFillPercentage,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'bin_number') required this.binNumber,
    @JsonKey(name: 'current_street') required this.currentStreet,
    required this.city,
    required this.zip,
    @JsonKey(name: 'fill_percentage') required this.fillPercentage,
    required this.latitude,
    required this.longitude,
  }) : super._();

  factory _$RouteBinImpl.fromJson(Map<String, dynamic> json) =>
      _$$RouteBinImplFromJson(json);

  /// Route bin ID (route_task UUID)
  @override
  final String id;

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

  /// Type of stop (collection, pickup, dropoff)
  @override
  @JsonKey(name: 'stop_type')
  final StopType stopType;

  /// Move request ID (for pickup/dropoff stops)
  @override
  @JsonKey(name: 'move_request_id')
  final String? moveRequestId;

  /// Original address for move request (pickup location)
  @override
  @JsonKey(name: 'original_address')
  final String? originalAddress;

  /// New address for move request (dropoff location)
  @override
  @JsonKey(name: 'new_address')
  final String? newAddress;

  /// Move request type (relocation, store, etc.)
  @override
  @JsonKey(name: 'move_type')
  final String? moveType;

  /// Potential location ID (for placement tasks)
  @override
  @JsonKey(name: 'potential_location_id')
  final String? potentialLocationId;

  /// New bin number being placed (for placement tasks)
  @override
  @JsonKey(name: 'new_bin_number')
  final int? newBinNumber;

  /// Warehouse action type (load, unload, both)
  @override
  @JsonKey(name: 'warehouse_action')
  final String? warehouseAction;

  /// Number of bins to load at warehouse
  @override
  @JsonKey(name: 'bins_to_load')
  final int? binsToLoad;

  /// Whether this bin has been completed
  @override
  @JsonKey(name: 'is_completed')
  final int isCompleted;

  /// Timestamp when completed (Unix timestamp)
  @override
  @JsonKey(name: 'completed_at')
  final int? completedAt;

  /// Updated fill percentage after driver check-in (0-100)
  @override
  @JsonKey(name: 'updated_fill_percentage')
  final int? updatedFillPercentage;

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
    return 'RouteBin(id: $id, shiftId: $shiftId, binId: $binId, sequenceOrder: $sequenceOrder, stopType: $stopType, moveRequestId: $moveRequestId, originalAddress: $originalAddress, newAddress: $newAddress, moveType: $moveType, potentialLocationId: $potentialLocationId, newBinNumber: $newBinNumber, warehouseAction: $warehouseAction, binsToLoad: $binsToLoad, isCompleted: $isCompleted, completedAt: $completedAt, updatedFillPercentage: $updatedFillPercentage, createdAt: $createdAt, binNumber: $binNumber, currentStreet: $currentStreet, city: $city, zip: $zip, fillPercentage: $fillPercentage, latitude: $latitude, longitude: $longitude)';
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
            (identical(other.stopType, stopType) ||
                other.stopType == stopType) &&
            (identical(other.moveRequestId, moveRequestId) ||
                other.moveRequestId == moveRequestId) &&
            (identical(other.originalAddress, originalAddress) ||
                other.originalAddress == originalAddress) &&
            (identical(other.newAddress, newAddress) ||
                other.newAddress == newAddress) &&
            (identical(other.moveType, moveType) ||
                other.moveType == moveType) &&
            (identical(other.potentialLocationId, potentialLocationId) ||
                other.potentialLocationId == potentialLocationId) &&
            (identical(other.newBinNumber, newBinNumber) ||
                other.newBinNumber == newBinNumber) &&
            (identical(other.warehouseAction, warehouseAction) ||
                other.warehouseAction == warehouseAction) &&
            (identical(other.binsToLoad, binsToLoad) ||
                other.binsToLoad == binsToLoad) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.updatedFillPercentage, updatedFillPercentage) ||
                other.updatedFillPercentage == updatedFillPercentage) &&
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
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    shiftId,
    binId,
    sequenceOrder,
    stopType,
    moveRequestId,
    originalAddress,
    newAddress,
    moveType,
    potentialLocationId,
    newBinNumber,
    warehouseAction,
    binsToLoad,
    isCompleted,
    completedAt,
    updatedFillPercentage,
    createdAt,
    binNumber,
    currentStreet,
    city,
    zip,
    fillPercentage,
    latitude,
    longitude,
  ]);

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

abstract class _RouteBin extends RouteBin {
  const factory _RouteBin({
    required final String id,
    @JsonKey(name: 'shift_id') required final String shiftId,
    @JsonKey(name: 'bin_id') required final String binId,
    @JsonKey(name: 'sequence_order') required final int sequenceOrder,
    @JsonKey(name: 'stop_type') final StopType stopType,
    @JsonKey(name: 'move_request_id') final String? moveRequestId,
    @JsonKey(name: 'original_address') final String? originalAddress,
    @JsonKey(name: 'new_address') final String? newAddress,
    @JsonKey(name: 'move_type') final String? moveType,
    @JsonKey(name: 'potential_location_id') final String? potentialLocationId,
    @JsonKey(name: 'new_bin_number') final int? newBinNumber,
    @JsonKey(name: 'warehouse_action') final String? warehouseAction,
    @JsonKey(name: 'bins_to_load') final int? binsToLoad,
    @JsonKey(name: 'is_completed') final int isCompleted,
    @JsonKey(name: 'completed_at') final int? completedAt,
    @JsonKey(name: 'updated_fill_percentage') final int? updatedFillPercentage,
    @JsonKey(name: 'created_at') required final int createdAt,
    @JsonKey(name: 'bin_number') required final int binNumber,
    @JsonKey(name: 'current_street') required final String currentStreet,
    required final String city,
    required final String zip,
    @JsonKey(name: 'fill_percentage') required final int fillPercentage,
    required final double latitude,
    required final double longitude,
  }) = _$RouteBinImpl;
  const _RouteBin._() : super._();

  factory _RouteBin.fromJson(Map<String, dynamic> json) =
      _$RouteBinImpl.fromJson;

  /// Route bin ID (route_task UUID)
  @override
  String get id;

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

  /// Type of stop (collection, pickup, dropoff)
  @override
  @JsonKey(name: 'stop_type')
  StopType get stopType;

  /// Move request ID (for pickup/dropoff stops)
  @override
  @JsonKey(name: 'move_request_id')
  String? get moveRequestId;

  /// Original address for move request (pickup location)
  @override
  @JsonKey(name: 'original_address')
  String? get originalAddress;

  /// New address for move request (dropoff location)
  @override
  @JsonKey(name: 'new_address')
  String? get newAddress;

  /// Move request type (relocation, store, etc.)
  @override
  @JsonKey(name: 'move_type')
  String? get moveType;

  /// Potential location ID (for placement tasks)
  @override
  @JsonKey(name: 'potential_location_id')
  String? get potentialLocationId;

  /// New bin number being placed (for placement tasks)
  @override
  @JsonKey(name: 'new_bin_number')
  int? get newBinNumber;

  /// Warehouse action type (load, unload, both)
  @override
  @JsonKey(name: 'warehouse_action')
  String? get warehouseAction;

  /// Number of bins to load at warehouse
  @override
  @JsonKey(name: 'bins_to_load')
  int? get binsToLoad;

  /// Whether this bin has been completed
  @override
  @JsonKey(name: 'is_completed')
  int get isCompleted;

  /// Timestamp when completed (Unix timestamp)
  @override
  @JsonKey(name: 'completed_at')
  int? get completedAt;

  /// Updated fill percentage after driver check-in (0-100)
  @override
  @JsonKey(name: 'updated_fill_percentage')
  int? get updatedFillPercentage;

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
