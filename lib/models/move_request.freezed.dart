// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'move_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MoveRequest _$MoveRequestFromJson(Map<String, dynamic> json) {
  return _MoveRequest.fromJson(json);
}

/// @nodoc
mixin _$MoveRequest {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'bin_id')
  String get binId => throw _privateConstructorUsedError;
  @JsonKey(name: 'bin_number')
  int? get binNumber => throw _privateConstructorUsedError;
  MoveRequestStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'requested_at')
  DateTime get requestedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'assigned_shift_id')
  String? get assignedShiftId => throw _privateConstructorUsedError;
  @JsonKey(name: 'insert_after_bin_id')
  String? get insertAfterBinId => throw _privateConstructorUsedError;
  @JsonKey(name: 'insert_position')
  String? get insertPosition => throw _privateConstructorUsedError; // PICKUP LOCATION (current bin location OR warehouse)
  @JsonKey(name: 'pickup_latitude')
  double get pickupLatitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'pickup_longitude')
  double get pickupLongitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'pickup_address')
  String get pickupAddress => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_warehouse_pickup')
  bool get isWarehousePickup => throw _privateConstructorUsedError; // DROP-OFF LOCATION (new placement)
  @JsonKey(name: 'dropoff_latitude')
  double get dropoffLatitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'dropoff_longitude')
  double get dropoffLongitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'dropoff_address')
  String get dropoffAddress => throw _privateConstructorUsedError; // TRACKING
  @JsonKey(name: 'picked_up_at')
  DateTime? get pickedUpAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'pickup_photo_url')
  String? get pickupPhotoUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'placement_photo_url')
  String? get placementPhotoUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'notes')
  String? get notes => throw _privateConstructorUsedError; // DEPRECATED - kept for backward compatibility
  @JsonKey(name: 'new_location')
  String? get newLocation => throw _privateConstructorUsedError;
  @JsonKey(name: 'warehouse_location')
  String? get warehouseLocation => throw _privateConstructorUsedError;
  @JsonKey(name: 'resolved_at')
  DateTime? get resolvedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'resolved_by')
  String? get resolvedBy => throw _privateConstructorUsedError;

  /// Serializes this MoveRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MoveRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MoveRequestCopyWith<MoveRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MoveRequestCopyWith<$Res> {
  factory $MoveRequestCopyWith(
    MoveRequest value,
    $Res Function(MoveRequest) then,
  ) = _$MoveRequestCopyWithImpl<$Res, MoveRequest>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'bin_id') String binId,
    @JsonKey(name: 'bin_number') int? binNumber,
    MoveRequestStatus status,
    @JsonKey(name: 'requested_at') DateTime requestedAt,
    @JsonKey(name: 'assigned_shift_id') String? assignedShiftId,
    @JsonKey(name: 'insert_after_bin_id') String? insertAfterBinId,
    @JsonKey(name: 'insert_position') String? insertPosition,
    @JsonKey(name: 'pickup_latitude') double pickupLatitude,
    @JsonKey(name: 'pickup_longitude') double pickupLongitude,
    @JsonKey(name: 'pickup_address') String pickupAddress,
    @JsonKey(name: 'is_warehouse_pickup') bool isWarehousePickup,
    @JsonKey(name: 'dropoff_latitude') double dropoffLatitude,
    @JsonKey(name: 'dropoff_longitude') double dropoffLongitude,
    @JsonKey(name: 'dropoff_address') String dropoffAddress,
    @JsonKey(name: 'picked_up_at') DateTime? pickedUpAt,
    @JsonKey(name: 'pickup_photo_url') String? pickupPhotoUrl,
    @JsonKey(name: 'placement_photo_url') String? placementPhotoUrl,
    @JsonKey(name: 'notes') String? notes,
    @JsonKey(name: 'new_location') String? newLocation,
    @JsonKey(name: 'warehouse_location') String? warehouseLocation,
    @JsonKey(name: 'resolved_at') DateTime? resolvedAt,
    @JsonKey(name: 'resolved_by') String? resolvedBy,
  });
}

/// @nodoc
class _$MoveRequestCopyWithImpl<$Res, $Val extends MoveRequest>
    implements $MoveRequestCopyWith<$Res> {
  _$MoveRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MoveRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? binId = null,
    Object? binNumber = freezed,
    Object? status = null,
    Object? requestedAt = null,
    Object? assignedShiftId = freezed,
    Object? insertAfterBinId = freezed,
    Object? insertPosition = freezed,
    Object? pickupLatitude = null,
    Object? pickupLongitude = null,
    Object? pickupAddress = null,
    Object? isWarehousePickup = null,
    Object? dropoffLatitude = null,
    Object? dropoffLongitude = null,
    Object? dropoffAddress = null,
    Object? pickedUpAt = freezed,
    Object? pickupPhotoUrl = freezed,
    Object? placementPhotoUrl = freezed,
    Object? notes = freezed,
    Object? newLocation = freezed,
    Object? warehouseLocation = freezed,
    Object? resolvedAt = freezed,
    Object? resolvedBy = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            binId: null == binId
                ? _value.binId
                : binId // ignore: cast_nullable_to_non_nullable
                      as String,
            binNumber: freezed == binNumber
                ? _value.binNumber
                : binNumber // ignore: cast_nullable_to_non_nullable
                      as int?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as MoveRequestStatus,
            requestedAt: null == requestedAt
                ? _value.requestedAt
                : requestedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            assignedShiftId: freezed == assignedShiftId
                ? _value.assignedShiftId
                : assignedShiftId // ignore: cast_nullable_to_non_nullable
                      as String?,
            insertAfterBinId: freezed == insertAfterBinId
                ? _value.insertAfterBinId
                : insertAfterBinId // ignore: cast_nullable_to_non_nullable
                      as String?,
            insertPosition: freezed == insertPosition
                ? _value.insertPosition
                : insertPosition // ignore: cast_nullable_to_non_nullable
                      as String?,
            pickupLatitude: null == pickupLatitude
                ? _value.pickupLatitude
                : pickupLatitude // ignore: cast_nullable_to_non_nullable
                      as double,
            pickupLongitude: null == pickupLongitude
                ? _value.pickupLongitude
                : pickupLongitude // ignore: cast_nullable_to_non_nullable
                      as double,
            pickupAddress: null == pickupAddress
                ? _value.pickupAddress
                : pickupAddress // ignore: cast_nullable_to_non_nullable
                      as String,
            isWarehousePickup: null == isWarehousePickup
                ? _value.isWarehousePickup
                : isWarehousePickup // ignore: cast_nullable_to_non_nullable
                      as bool,
            dropoffLatitude: null == dropoffLatitude
                ? _value.dropoffLatitude
                : dropoffLatitude // ignore: cast_nullable_to_non_nullable
                      as double,
            dropoffLongitude: null == dropoffLongitude
                ? _value.dropoffLongitude
                : dropoffLongitude // ignore: cast_nullable_to_non_nullable
                      as double,
            dropoffAddress: null == dropoffAddress
                ? _value.dropoffAddress
                : dropoffAddress // ignore: cast_nullable_to_non_nullable
                      as String,
            pickedUpAt: freezed == pickedUpAt
                ? _value.pickedUpAt
                : pickedUpAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            pickupPhotoUrl: freezed == pickupPhotoUrl
                ? _value.pickupPhotoUrl
                : pickupPhotoUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            placementPhotoUrl: freezed == placementPhotoUrl
                ? _value.placementPhotoUrl
                : placementPhotoUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            newLocation: freezed == newLocation
                ? _value.newLocation
                : newLocation // ignore: cast_nullable_to_non_nullable
                      as String?,
            warehouseLocation: freezed == warehouseLocation
                ? _value.warehouseLocation
                : warehouseLocation // ignore: cast_nullable_to_non_nullable
                      as String?,
            resolvedAt: freezed == resolvedAt
                ? _value.resolvedAt
                : resolvedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            resolvedBy: freezed == resolvedBy
                ? _value.resolvedBy
                : resolvedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MoveRequestImplCopyWith<$Res>
    implements $MoveRequestCopyWith<$Res> {
  factory _$$MoveRequestImplCopyWith(
    _$MoveRequestImpl value,
    $Res Function(_$MoveRequestImpl) then,
  ) = __$$MoveRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'bin_id') String binId,
    @JsonKey(name: 'bin_number') int? binNumber,
    MoveRequestStatus status,
    @JsonKey(name: 'requested_at') DateTime requestedAt,
    @JsonKey(name: 'assigned_shift_id') String? assignedShiftId,
    @JsonKey(name: 'insert_after_bin_id') String? insertAfterBinId,
    @JsonKey(name: 'insert_position') String? insertPosition,
    @JsonKey(name: 'pickup_latitude') double pickupLatitude,
    @JsonKey(name: 'pickup_longitude') double pickupLongitude,
    @JsonKey(name: 'pickup_address') String pickupAddress,
    @JsonKey(name: 'is_warehouse_pickup') bool isWarehousePickup,
    @JsonKey(name: 'dropoff_latitude') double dropoffLatitude,
    @JsonKey(name: 'dropoff_longitude') double dropoffLongitude,
    @JsonKey(name: 'dropoff_address') String dropoffAddress,
    @JsonKey(name: 'picked_up_at') DateTime? pickedUpAt,
    @JsonKey(name: 'pickup_photo_url') String? pickupPhotoUrl,
    @JsonKey(name: 'placement_photo_url') String? placementPhotoUrl,
    @JsonKey(name: 'notes') String? notes,
    @JsonKey(name: 'new_location') String? newLocation,
    @JsonKey(name: 'warehouse_location') String? warehouseLocation,
    @JsonKey(name: 'resolved_at') DateTime? resolvedAt,
    @JsonKey(name: 'resolved_by') String? resolvedBy,
  });
}

/// @nodoc
class __$$MoveRequestImplCopyWithImpl<$Res>
    extends _$MoveRequestCopyWithImpl<$Res, _$MoveRequestImpl>
    implements _$$MoveRequestImplCopyWith<$Res> {
  __$$MoveRequestImplCopyWithImpl(
    _$MoveRequestImpl _value,
    $Res Function(_$MoveRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MoveRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? binId = null,
    Object? binNumber = freezed,
    Object? status = null,
    Object? requestedAt = null,
    Object? assignedShiftId = freezed,
    Object? insertAfterBinId = freezed,
    Object? insertPosition = freezed,
    Object? pickupLatitude = null,
    Object? pickupLongitude = null,
    Object? pickupAddress = null,
    Object? isWarehousePickup = null,
    Object? dropoffLatitude = null,
    Object? dropoffLongitude = null,
    Object? dropoffAddress = null,
    Object? pickedUpAt = freezed,
    Object? pickupPhotoUrl = freezed,
    Object? placementPhotoUrl = freezed,
    Object? notes = freezed,
    Object? newLocation = freezed,
    Object? warehouseLocation = freezed,
    Object? resolvedAt = freezed,
    Object? resolvedBy = freezed,
  }) {
    return _then(
      _$MoveRequestImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        binId: null == binId
            ? _value.binId
            : binId // ignore: cast_nullable_to_non_nullable
                  as String,
        binNumber: freezed == binNumber
            ? _value.binNumber
            : binNumber // ignore: cast_nullable_to_non_nullable
                  as int?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as MoveRequestStatus,
        requestedAt: null == requestedAt
            ? _value.requestedAt
            : requestedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        assignedShiftId: freezed == assignedShiftId
            ? _value.assignedShiftId
            : assignedShiftId // ignore: cast_nullable_to_non_nullable
                  as String?,
        insertAfterBinId: freezed == insertAfterBinId
            ? _value.insertAfterBinId
            : insertAfterBinId // ignore: cast_nullable_to_non_nullable
                  as String?,
        insertPosition: freezed == insertPosition
            ? _value.insertPosition
            : insertPosition // ignore: cast_nullable_to_non_nullable
                  as String?,
        pickupLatitude: null == pickupLatitude
            ? _value.pickupLatitude
            : pickupLatitude // ignore: cast_nullable_to_non_nullable
                  as double,
        pickupLongitude: null == pickupLongitude
            ? _value.pickupLongitude
            : pickupLongitude // ignore: cast_nullable_to_non_nullable
                  as double,
        pickupAddress: null == pickupAddress
            ? _value.pickupAddress
            : pickupAddress // ignore: cast_nullable_to_non_nullable
                  as String,
        isWarehousePickup: null == isWarehousePickup
            ? _value.isWarehousePickup
            : isWarehousePickup // ignore: cast_nullable_to_non_nullable
                  as bool,
        dropoffLatitude: null == dropoffLatitude
            ? _value.dropoffLatitude
            : dropoffLatitude // ignore: cast_nullable_to_non_nullable
                  as double,
        dropoffLongitude: null == dropoffLongitude
            ? _value.dropoffLongitude
            : dropoffLongitude // ignore: cast_nullable_to_non_nullable
                  as double,
        dropoffAddress: null == dropoffAddress
            ? _value.dropoffAddress
            : dropoffAddress // ignore: cast_nullable_to_non_nullable
                  as String,
        pickedUpAt: freezed == pickedUpAt
            ? _value.pickedUpAt
            : pickedUpAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        pickupPhotoUrl: freezed == pickupPhotoUrl
            ? _value.pickupPhotoUrl
            : pickupPhotoUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        placementPhotoUrl: freezed == placementPhotoUrl
            ? _value.placementPhotoUrl
            : placementPhotoUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        newLocation: freezed == newLocation
            ? _value.newLocation
            : newLocation // ignore: cast_nullable_to_non_nullable
                  as String?,
        warehouseLocation: freezed == warehouseLocation
            ? _value.warehouseLocation
            : warehouseLocation // ignore: cast_nullable_to_non_nullable
                  as String?,
        resolvedAt: freezed == resolvedAt
            ? _value.resolvedAt
            : resolvedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        resolvedBy: freezed == resolvedBy
            ? _value.resolvedBy
            : resolvedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MoveRequestImpl implements _MoveRequest {
  const _$MoveRequestImpl({
    required this.id,
    @JsonKey(name: 'bin_id') required this.binId,
    @JsonKey(name: 'bin_number') this.binNumber,
    required this.status,
    @JsonKey(name: 'requested_at') required this.requestedAt,
    @JsonKey(name: 'assigned_shift_id') this.assignedShiftId,
    @JsonKey(name: 'insert_after_bin_id') this.insertAfterBinId,
    @JsonKey(name: 'insert_position') this.insertPosition,
    @JsonKey(name: 'pickup_latitude') required this.pickupLatitude,
    @JsonKey(name: 'pickup_longitude') required this.pickupLongitude,
    @JsonKey(name: 'pickup_address') required this.pickupAddress,
    @JsonKey(name: 'is_warehouse_pickup') this.isWarehousePickup = false,
    @JsonKey(name: 'dropoff_latitude') required this.dropoffLatitude,
    @JsonKey(name: 'dropoff_longitude') required this.dropoffLongitude,
    @JsonKey(name: 'dropoff_address') required this.dropoffAddress,
    @JsonKey(name: 'picked_up_at') this.pickedUpAt,
    @JsonKey(name: 'pickup_photo_url') this.pickupPhotoUrl,
    @JsonKey(name: 'placement_photo_url') this.placementPhotoUrl,
    @JsonKey(name: 'notes') this.notes,
    @JsonKey(name: 'new_location') this.newLocation,
    @JsonKey(name: 'warehouse_location') this.warehouseLocation,
    @JsonKey(name: 'resolved_at') this.resolvedAt,
    @JsonKey(name: 'resolved_by') this.resolvedBy,
  });

  factory _$MoveRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$MoveRequestImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'bin_id')
  final String binId;
  @override
  @JsonKey(name: 'bin_number')
  final int? binNumber;
  @override
  final MoveRequestStatus status;
  @override
  @JsonKey(name: 'requested_at')
  final DateTime requestedAt;
  @override
  @JsonKey(name: 'assigned_shift_id')
  final String? assignedShiftId;
  @override
  @JsonKey(name: 'insert_after_bin_id')
  final String? insertAfterBinId;
  @override
  @JsonKey(name: 'insert_position')
  final String? insertPosition;
  // PICKUP LOCATION (current bin location OR warehouse)
  @override
  @JsonKey(name: 'pickup_latitude')
  final double pickupLatitude;
  @override
  @JsonKey(name: 'pickup_longitude')
  final double pickupLongitude;
  @override
  @JsonKey(name: 'pickup_address')
  final String pickupAddress;
  @override
  @JsonKey(name: 'is_warehouse_pickup')
  final bool isWarehousePickup;
  // DROP-OFF LOCATION (new placement)
  @override
  @JsonKey(name: 'dropoff_latitude')
  final double dropoffLatitude;
  @override
  @JsonKey(name: 'dropoff_longitude')
  final double dropoffLongitude;
  @override
  @JsonKey(name: 'dropoff_address')
  final String dropoffAddress;
  // TRACKING
  @override
  @JsonKey(name: 'picked_up_at')
  final DateTime? pickedUpAt;
  @override
  @JsonKey(name: 'pickup_photo_url')
  final String? pickupPhotoUrl;
  @override
  @JsonKey(name: 'placement_photo_url')
  final String? placementPhotoUrl;
  @override
  @JsonKey(name: 'notes')
  final String? notes;
  // DEPRECATED - kept for backward compatibility
  @override
  @JsonKey(name: 'new_location')
  final String? newLocation;
  @override
  @JsonKey(name: 'warehouse_location')
  final String? warehouseLocation;
  @override
  @JsonKey(name: 'resolved_at')
  final DateTime? resolvedAt;
  @override
  @JsonKey(name: 'resolved_by')
  final String? resolvedBy;

  @override
  String toString() {
    return 'MoveRequest(id: $id, binId: $binId, binNumber: $binNumber, status: $status, requestedAt: $requestedAt, assignedShiftId: $assignedShiftId, insertAfterBinId: $insertAfterBinId, insertPosition: $insertPosition, pickupLatitude: $pickupLatitude, pickupLongitude: $pickupLongitude, pickupAddress: $pickupAddress, isWarehousePickup: $isWarehousePickup, dropoffLatitude: $dropoffLatitude, dropoffLongitude: $dropoffLongitude, dropoffAddress: $dropoffAddress, pickedUpAt: $pickedUpAt, pickupPhotoUrl: $pickupPhotoUrl, placementPhotoUrl: $placementPhotoUrl, notes: $notes, newLocation: $newLocation, warehouseLocation: $warehouseLocation, resolvedAt: $resolvedAt, resolvedBy: $resolvedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MoveRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.binId, binId) || other.binId == binId) &&
            (identical(other.binNumber, binNumber) ||
                other.binNumber == binNumber) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.requestedAt, requestedAt) ||
                other.requestedAt == requestedAt) &&
            (identical(other.assignedShiftId, assignedShiftId) ||
                other.assignedShiftId == assignedShiftId) &&
            (identical(other.insertAfterBinId, insertAfterBinId) ||
                other.insertAfterBinId == insertAfterBinId) &&
            (identical(other.insertPosition, insertPosition) ||
                other.insertPosition == insertPosition) &&
            (identical(other.pickupLatitude, pickupLatitude) ||
                other.pickupLatitude == pickupLatitude) &&
            (identical(other.pickupLongitude, pickupLongitude) ||
                other.pickupLongitude == pickupLongitude) &&
            (identical(other.pickupAddress, pickupAddress) ||
                other.pickupAddress == pickupAddress) &&
            (identical(other.isWarehousePickup, isWarehousePickup) ||
                other.isWarehousePickup == isWarehousePickup) &&
            (identical(other.dropoffLatitude, dropoffLatitude) ||
                other.dropoffLatitude == dropoffLatitude) &&
            (identical(other.dropoffLongitude, dropoffLongitude) ||
                other.dropoffLongitude == dropoffLongitude) &&
            (identical(other.dropoffAddress, dropoffAddress) ||
                other.dropoffAddress == dropoffAddress) &&
            (identical(other.pickedUpAt, pickedUpAt) ||
                other.pickedUpAt == pickedUpAt) &&
            (identical(other.pickupPhotoUrl, pickupPhotoUrl) ||
                other.pickupPhotoUrl == pickupPhotoUrl) &&
            (identical(other.placementPhotoUrl, placementPhotoUrl) ||
                other.placementPhotoUrl == placementPhotoUrl) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.newLocation, newLocation) ||
                other.newLocation == newLocation) &&
            (identical(other.warehouseLocation, warehouseLocation) ||
                other.warehouseLocation == warehouseLocation) &&
            (identical(other.resolvedAt, resolvedAt) ||
                other.resolvedAt == resolvedAt) &&
            (identical(other.resolvedBy, resolvedBy) ||
                other.resolvedBy == resolvedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    binId,
    binNumber,
    status,
    requestedAt,
    assignedShiftId,
    insertAfterBinId,
    insertPosition,
    pickupLatitude,
    pickupLongitude,
    pickupAddress,
    isWarehousePickup,
    dropoffLatitude,
    dropoffLongitude,
    dropoffAddress,
    pickedUpAt,
    pickupPhotoUrl,
    placementPhotoUrl,
    notes,
    newLocation,
    warehouseLocation,
    resolvedAt,
    resolvedBy,
  ]);

  /// Create a copy of MoveRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MoveRequestImplCopyWith<_$MoveRequestImpl> get copyWith =>
      __$$MoveRequestImplCopyWithImpl<_$MoveRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MoveRequestImplToJson(this);
  }
}

abstract class _MoveRequest implements MoveRequest {
  const factory _MoveRequest({
    required final String id,
    @JsonKey(name: 'bin_id') required final String binId,
    @JsonKey(name: 'bin_number') final int? binNumber,
    required final MoveRequestStatus status,
    @JsonKey(name: 'requested_at') required final DateTime requestedAt,
    @JsonKey(name: 'assigned_shift_id') final String? assignedShiftId,
    @JsonKey(name: 'insert_after_bin_id') final String? insertAfterBinId,
    @JsonKey(name: 'insert_position') final String? insertPosition,
    @JsonKey(name: 'pickup_latitude') required final double pickupLatitude,
    @JsonKey(name: 'pickup_longitude') required final double pickupLongitude,
    @JsonKey(name: 'pickup_address') required final String pickupAddress,
    @JsonKey(name: 'is_warehouse_pickup') final bool isWarehousePickup,
    @JsonKey(name: 'dropoff_latitude') required final double dropoffLatitude,
    @JsonKey(name: 'dropoff_longitude') required final double dropoffLongitude,
    @JsonKey(name: 'dropoff_address') required final String dropoffAddress,
    @JsonKey(name: 'picked_up_at') final DateTime? pickedUpAt,
    @JsonKey(name: 'pickup_photo_url') final String? pickupPhotoUrl,
    @JsonKey(name: 'placement_photo_url') final String? placementPhotoUrl,
    @JsonKey(name: 'notes') final String? notes,
    @JsonKey(name: 'new_location') final String? newLocation,
    @JsonKey(name: 'warehouse_location') final String? warehouseLocation,
    @JsonKey(name: 'resolved_at') final DateTime? resolvedAt,
    @JsonKey(name: 'resolved_by') final String? resolvedBy,
  }) = _$MoveRequestImpl;

  factory _MoveRequest.fromJson(Map<String, dynamic> json) =
      _$MoveRequestImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'bin_id')
  String get binId;
  @override
  @JsonKey(name: 'bin_number')
  int? get binNumber;
  @override
  MoveRequestStatus get status;
  @override
  @JsonKey(name: 'requested_at')
  DateTime get requestedAt;
  @override
  @JsonKey(name: 'assigned_shift_id')
  String? get assignedShiftId;
  @override
  @JsonKey(name: 'insert_after_bin_id')
  String? get insertAfterBinId;
  @override
  @JsonKey(name: 'insert_position')
  String? get insertPosition; // PICKUP LOCATION (current bin location OR warehouse)
  @override
  @JsonKey(name: 'pickup_latitude')
  double get pickupLatitude;
  @override
  @JsonKey(name: 'pickup_longitude')
  double get pickupLongitude;
  @override
  @JsonKey(name: 'pickup_address')
  String get pickupAddress;
  @override
  @JsonKey(name: 'is_warehouse_pickup')
  bool get isWarehousePickup; // DROP-OFF LOCATION (new placement)
  @override
  @JsonKey(name: 'dropoff_latitude')
  double get dropoffLatitude;
  @override
  @JsonKey(name: 'dropoff_longitude')
  double get dropoffLongitude;
  @override
  @JsonKey(name: 'dropoff_address')
  String get dropoffAddress; // TRACKING
  @override
  @JsonKey(name: 'picked_up_at')
  DateTime? get pickedUpAt;
  @override
  @JsonKey(name: 'pickup_photo_url')
  String? get pickupPhotoUrl;
  @override
  @JsonKey(name: 'placement_photo_url')
  String? get placementPhotoUrl;
  @override
  @JsonKey(name: 'notes')
  String? get notes; // DEPRECATED - kept for backward compatibility
  @override
  @JsonKey(name: 'new_location')
  String? get newLocation;
  @override
  @JsonKey(name: 'warehouse_location')
  String? get warehouseLocation;
  @override
  @JsonKey(name: 'resolved_at')
  DateTime? get resolvedAt;
  @override
  @JsonKey(name: 'resolved_by')
  String? get resolvedBy;

  /// Create a copy of MoveRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MoveRequestImplCopyWith<_$MoveRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
