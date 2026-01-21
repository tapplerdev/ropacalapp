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
  MoveRequestStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'requested_at')
  DateTime get requestedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'assigned_shift_id')
  String? get assignedShiftId => throw _privateConstructorUsedError;
  @JsonKey(name: 'insert_after_bin_id')
  String? get insertAfterBinId => throw _privateConstructorUsedError;
  @JsonKey(name: 'insert_position')
  String? get insertPosition => throw _privateConstructorUsedError;
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
    MoveRequestStatus status,
    @JsonKey(name: 'requested_at') DateTime requestedAt,
    @JsonKey(name: 'assigned_shift_id') String? assignedShiftId,
    @JsonKey(name: 'insert_after_bin_id') String? insertAfterBinId,
    @JsonKey(name: 'insert_position') String? insertPosition,
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
    Object? status = null,
    Object? requestedAt = null,
    Object? assignedShiftId = freezed,
    Object? insertAfterBinId = freezed,
    Object? insertPosition = freezed,
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
    MoveRequestStatus status,
    @JsonKey(name: 'requested_at') DateTime requestedAt,
    @JsonKey(name: 'assigned_shift_id') String? assignedShiftId,
    @JsonKey(name: 'insert_after_bin_id') String? insertAfterBinId,
    @JsonKey(name: 'insert_position') String? insertPosition,
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
    Object? status = null,
    Object? requestedAt = null,
    Object? assignedShiftId = freezed,
    Object? insertAfterBinId = freezed,
    Object? insertPosition = freezed,
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
    required this.status,
    @JsonKey(name: 'requested_at') required this.requestedAt,
    @JsonKey(name: 'assigned_shift_id') this.assignedShiftId,
    @JsonKey(name: 'insert_after_bin_id') this.insertAfterBinId,
    @JsonKey(name: 'insert_position') this.insertPosition,
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
    return 'MoveRequest(id: $id, binId: $binId, status: $status, requestedAt: $requestedAt, assignedShiftId: $assignedShiftId, insertAfterBinId: $insertAfterBinId, insertPosition: $insertPosition, newLocation: $newLocation, warehouseLocation: $warehouseLocation, resolvedAt: $resolvedAt, resolvedBy: $resolvedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MoveRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.binId, binId) || other.binId == binId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.requestedAt, requestedAt) ||
                other.requestedAt == requestedAt) &&
            (identical(other.assignedShiftId, assignedShiftId) ||
                other.assignedShiftId == assignedShiftId) &&
            (identical(other.insertAfterBinId, insertAfterBinId) ||
                other.insertAfterBinId == insertAfterBinId) &&
            (identical(other.insertPosition, insertPosition) ||
                other.insertPosition == insertPosition) &&
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
  int get hashCode => Object.hash(
    runtimeType,
    id,
    binId,
    status,
    requestedAt,
    assignedShiftId,
    insertAfterBinId,
    insertPosition,
    newLocation,
    warehouseLocation,
    resolvedAt,
    resolvedBy,
  );

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
    required final MoveRequestStatus status,
    @JsonKey(name: 'requested_at') required final DateTime requestedAt,
    @JsonKey(name: 'assigned_shift_id') final String? assignedShiftId,
    @JsonKey(name: 'insert_after_bin_id') final String? insertAfterBinId,
    @JsonKey(name: 'insert_position') final String? insertPosition,
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
  String? get insertPosition;
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
