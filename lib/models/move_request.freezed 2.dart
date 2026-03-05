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
  @JsonKey(name: 'urgency')
  String? get urgency => throw _privateConstructorUsedError;
  @JsonKey(name: 'requested_by')
  String? get requestedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'scheduled_date')
  int? get scheduledDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'assigned_shift_id')
  String? get assignedShiftId => throw _privateConstructorUsedError;
  @JsonKey(name: 'assignment_type')
  String? get assignmentType => throw _privateConstructorUsedError;
  @JsonKey(name: 'move_type')
  String? get moveType => throw _privateConstructorUsedError; // ORIGINAL LOCATION (where bin currently is)
  @JsonKey(name: 'original_latitude')
  double get originalLatitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'original_longitude')
  double get originalLongitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'original_address')
  String get originalAddress => throw _privateConstructorUsedError; // NEW LOCATION (where to move it - nullable for pickup-only)
  @JsonKey(name: 'new_latitude')
  double? get newLatitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'new_longitude')
  double? get newLongitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'new_address')
  String? get newAddress => throw _privateConstructorUsedError; // TRACKING & METADATA
  @JsonKey(name: 'reason')
  String? get reason => throw _privateConstructorUsedError;
  @JsonKey(name: 'notes')
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_at')
  int? get completedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  int get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  int get updatedAt => throw _privateConstructorUsedError;

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
    @JsonKey(name: 'urgency') String? urgency,
    @JsonKey(name: 'requested_by') String? requestedBy,
    @JsonKey(name: 'scheduled_date') int? scheduledDate,
    @JsonKey(name: 'assigned_shift_id') String? assignedShiftId,
    @JsonKey(name: 'assignment_type') String? assignmentType,
    @JsonKey(name: 'move_type') String? moveType,
    @JsonKey(name: 'original_latitude') double originalLatitude,
    @JsonKey(name: 'original_longitude') double originalLongitude,
    @JsonKey(name: 'original_address') String originalAddress,
    @JsonKey(name: 'new_latitude') double? newLatitude,
    @JsonKey(name: 'new_longitude') double? newLongitude,
    @JsonKey(name: 'new_address') String? newAddress,
    @JsonKey(name: 'reason') String? reason,
    @JsonKey(name: 'notes') String? notes,
    @JsonKey(name: 'completed_at') int? completedAt,
    @JsonKey(name: 'created_at') int createdAt,
    @JsonKey(name: 'updated_at') int updatedAt,
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
    Object? urgency = freezed,
    Object? requestedBy = freezed,
    Object? scheduledDate = freezed,
    Object? assignedShiftId = freezed,
    Object? assignmentType = freezed,
    Object? moveType = freezed,
    Object? originalLatitude = null,
    Object? originalLongitude = null,
    Object? originalAddress = null,
    Object? newLatitude = freezed,
    Object? newLongitude = freezed,
    Object? newAddress = freezed,
    Object? reason = freezed,
    Object? notes = freezed,
    Object? completedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
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
            urgency: freezed == urgency
                ? _value.urgency
                : urgency // ignore: cast_nullable_to_non_nullable
                      as String?,
            requestedBy: freezed == requestedBy
                ? _value.requestedBy
                : requestedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            scheduledDate: freezed == scheduledDate
                ? _value.scheduledDate
                : scheduledDate // ignore: cast_nullable_to_non_nullable
                      as int?,
            assignedShiftId: freezed == assignedShiftId
                ? _value.assignedShiftId
                : assignedShiftId // ignore: cast_nullable_to_non_nullable
                      as String?,
            assignmentType: freezed == assignmentType
                ? _value.assignmentType
                : assignmentType // ignore: cast_nullable_to_non_nullable
                      as String?,
            moveType: freezed == moveType
                ? _value.moveType
                : moveType // ignore: cast_nullable_to_non_nullable
                      as String?,
            originalLatitude: null == originalLatitude
                ? _value.originalLatitude
                : originalLatitude // ignore: cast_nullable_to_non_nullable
                      as double,
            originalLongitude: null == originalLongitude
                ? _value.originalLongitude
                : originalLongitude // ignore: cast_nullable_to_non_nullable
                      as double,
            originalAddress: null == originalAddress
                ? _value.originalAddress
                : originalAddress // ignore: cast_nullable_to_non_nullable
                      as String,
            newLatitude: freezed == newLatitude
                ? _value.newLatitude
                : newLatitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            newLongitude: freezed == newLongitude
                ? _value.newLongitude
                : newLongitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            newAddress: freezed == newAddress
                ? _value.newAddress
                : newAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            reason: freezed == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as int?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as int,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as int,
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
    @JsonKey(name: 'urgency') String? urgency,
    @JsonKey(name: 'requested_by') String? requestedBy,
    @JsonKey(name: 'scheduled_date') int? scheduledDate,
    @JsonKey(name: 'assigned_shift_id') String? assignedShiftId,
    @JsonKey(name: 'assignment_type') String? assignmentType,
    @JsonKey(name: 'move_type') String? moveType,
    @JsonKey(name: 'original_latitude') double originalLatitude,
    @JsonKey(name: 'original_longitude') double originalLongitude,
    @JsonKey(name: 'original_address') String originalAddress,
    @JsonKey(name: 'new_latitude') double? newLatitude,
    @JsonKey(name: 'new_longitude') double? newLongitude,
    @JsonKey(name: 'new_address') String? newAddress,
    @JsonKey(name: 'reason') String? reason,
    @JsonKey(name: 'notes') String? notes,
    @JsonKey(name: 'completed_at') int? completedAt,
    @JsonKey(name: 'created_at') int createdAt,
    @JsonKey(name: 'updated_at') int updatedAt,
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
    Object? urgency = freezed,
    Object? requestedBy = freezed,
    Object? scheduledDate = freezed,
    Object? assignedShiftId = freezed,
    Object? assignmentType = freezed,
    Object? moveType = freezed,
    Object? originalLatitude = null,
    Object? originalLongitude = null,
    Object? originalAddress = null,
    Object? newLatitude = freezed,
    Object? newLongitude = freezed,
    Object? newAddress = freezed,
    Object? reason = freezed,
    Object? notes = freezed,
    Object? completedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
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
        urgency: freezed == urgency
            ? _value.urgency
            : urgency // ignore: cast_nullable_to_non_nullable
                  as String?,
        requestedBy: freezed == requestedBy
            ? _value.requestedBy
            : requestedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        scheduledDate: freezed == scheduledDate
            ? _value.scheduledDate
            : scheduledDate // ignore: cast_nullable_to_non_nullable
                  as int?,
        assignedShiftId: freezed == assignedShiftId
            ? _value.assignedShiftId
            : assignedShiftId // ignore: cast_nullable_to_non_nullable
                  as String?,
        assignmentType: freezed == assignmentType
            ? _value.assignmentType
            : assignmentType // ignore: cast_nullable_to_non_nullable
                  as String?,
        moveType: freezed == moveType
            ? _value.moveType
            : moveType // ignore: cast_nullable_to_non_nullable
                  as String?,
        originalLatitude: null == originalLatitude
            ? _value.originalLatitude
            : originalLatitude // ignore: cast_nullable_to_non_nullable
                  as double,
        originalLongitude: null == originalLongitude
            ? _value.originalLongitude
            : originalLongitude // ignore: cast_nullable_to_non_nullable
                  as double,
        originalAddress: null == originalAddress
            ? _value.originalAddress
            : originalAddress // ignore: cast_nullable_to_non_nullable
                  as String,
        newLatitude: freezed == newLatitude
            ? _value.newLatitude
            : newLatitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        newLongitude: freezed == newLongitude
            ? _value.newLongitude
            : newLongitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        newAddress: freezed == newAddress
            ? _value.newAddress
            : newAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        reason: freezed == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as int,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MoveRequestImpl extends _MoveRequest {
  const _$MoveRequestImpl({
    required this.id,
    @JsonKey(name: 'bin_id') required this.binId,
    @JsonKey(name: 'bin_number') this.binNumber,
    required this.status,
    @JsonKey(name: 'urgency') this.urgency,
    @JsonKey(name: 'requested_by') this.requestedBy,
    @JsonKey(name: 'scheduled_date') this.scheduledDate,
    @JsonKey(name: 'assigned_shift_id') this.assignedShiftId,
    @JsonKey(name: 'assignment_type') this.assignmentType,
    @JsonKey(name: 'move_type') this.moveType,
    @JsonKey(name: 'original_latitude') required this.originalLatitude,
    @JsonKey(name: 'original_longitude') required this.originalLongitude,
    @JsonKey(name: 'original_address') required this.originalAddress,
    @JsonKey(name: 'new_latitude') this.newLatitude,
    @JsonKey(name: 'new_longitude') this.newLongitude,
    @JsonKey(name: 'new_address') this.newAddress,
    @JsonKey(name: 'reason') this.reason,
    @JsonKey(name: 'notes') this.notes,
    @JsonKey(name: 'completed_at') this.completedAt,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'updated_at') required this.updatedAt,
  }) : super._();

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
  @JsonKey(name: 'urgency')
  final String? urgency;
  @override
  @JsonKey(name: 'requested_by')
  final String? requestedBy;
  @override
  @JsonKey(name: 'scheduled_date')
  final int? scheduledDate;
  @override
  @JsonKey(name: 'assigned_shift_id')
  final String? assignedShiftId;
  @override
  @JsonKey(name: 'assignment_type')
  final String? assignmentType;
  @override
  @JsonKey(name: 'move_type')
  final String? moveType;
  // ORIGINAL LOCATION (where bin currently is)
  @override
  @JsonKey(name: 'original_latitude')
  final double originalLatitude;
  @override
  @JsonKey(name: 'original_longitude')
  final double originalLongitude;
  @override
  @JsonKey(name: 'original_address')
  final String originalAddress;
  // NEW LOCATION (where to move it - nullable for pickup-only)
  @override
  @JsonKey(name: 'new_latitude')
  final double? newLatitude;
  @override
  @JsonKey(name: 'new_longitude')
  final double? newLongitude;
  @override
  @JsonKey(name: 'new_address')
  final String? newAddress;
  // TRACKING & METADATA
  @override
  @JsonKey(name: 'reason')
  final String? reason;
  @override
  @JsonKey(name: 'notes')
  final String? notes;
  @override
  @JsonKey(name: 'completed_at')
  final int? completedAt;
  @override
  @JsonKey(name: 'created_at')
  final int createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final int updatedAt;

  @override
  String toString() {
    return 'MoveRequest(id: $id, binId: $binId, binNumber: $binNumber, status: $status, urgency: $urgency, requestedBy: $requestedBy, scheduledDate: $scheduledDate, assignedShiftId: $assignedShiftId, assignmentType: $assignmentType, moveType: $moveType, originalLatitude: $originalLatitude, originalLongitude: $originalLongitude, originalAddress: $originalAddress, newLatitude: $newLatitude, newLongitude: $newLongitude, newAddress: $newAddress, reason: $reason, notes: $notes, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
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
            (identical(other.urgency, urgency) || other.urgency == urgency) &&
            (identical(other.requestedBy, requestedBy) ||
                other.requestedBy == requestedBy) &&
            (identical(other.scheduledDate, scheduledDate) ||
                other.scheduledDate == scheduledDate) &&
            (identical(other.assignedShiftId, assignedShiftId) ||
                other.assignedShiftId == assignedShiftId) &&
            (identical(other.assignmentType, assignmentType) ||
                other.assignmentType == assignmentType) &&
            (identical(other.moveType, moveType) ||
                other.moveType == moveType) &&
            (identical(other.originalLatitude, originalLatitude) ||
                other.originalLatitude == originalLatitude) &&
            (identical(other.originalLongitude, originalLongitude) ||
                other.originalLongitude == originalLongitude) &&
            (identical(other.originalAddress, originalAddress) ||
                other.originalAddress == originalAddress) &&
            (identical(other.newLatitude, newLatitude) ||
                other.newLatitude == newLatitude) &&
            (identical(other.newLongitude, newLongitude) ||
                other.newLongitude == newLongitude) &&
            (identical(other.newAddress, newAddress) ||
                other.newAddress == newAddress) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    binId,
    binNumber,
    status,
    urgency,
    requestedBy,
    scheduledDate,
    assignedShiftId,
    assignmentType,
    moveType,
    originalLatitude,
    originalLongitude,
    originalAddress,
    newLatitude,
    newLongitude,
    newAddress,
    reason,
    notes,
    completedAt,
    createdAt,
    updatedAt,
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

abstract class _MoveRequest extends MoveRequest {
  const factory _MoveRequest({
    required final String id,
    @JsonKey(name: 'bin_id') required final String binId,
    @JsonKey(name: 'bin_number') final int? binNumber,
    required final MoveRequestStatus status,
    @JsonKey(name: 'urgency') final String? urgency,
    @JsonKey(name: 'requested_by') final String? requestedBy,
    @JsonKey(name: 'scheduled_date') final int? scheduledDate,
    @JsonKey(name: 'assigned_shift_id') final String? assignedShiftId,
    @JsonKey(name: 'assignment_type') final String? assignmentType,
    @JsonKey(name: 'move_type') final String? moveType,
    @JsonKey(name: 'original_latitude') required final double originalLatitude,
    @JsonKey(name: 'original_longitude')
    required final double originalLongitude,
    @JsonKey(name: 'original_address') required final String originalAddress,
    @JsonKey(name: 'new_latitude') final double? newLatitude,
    @JsonKey(name: 'new_longitude') final double? newLongitude,
    @JsonKey(name: 'new_address') final String? newAddress,
    @JsonKey(name: 'reason') final String? reason,
    @JsonKey(name: 'notes') final String? notes,
    @JsonKey(name: 'completed_at') final int? completedAt,
    @JsonKey(name: 'created_at') required final int createdAt,
    @JsonKey(name: 'updated_at') required final int updatedAt,
  }) = _$MoveRequestImpl;
  const _MoveRequest._() : super._();

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
  @JsonKey(name: 'urgency')
  String? get urgency;
  @override
  @JsonKey(name: 'requested_by')
  String? get requestedBy;
  @override
  @JsonKey(name: 'scheduled_date')
  int? get scheduledDate;
  @override
  @JsonKey(name: 'assigned_shift_id')
  String? get assignedShiftId;
  @override
  @JsonKey(name: 'assignment_type')
  String? get assignmentType;
  @override
  @JsonKey(name: 'move_type')
  String? get moveType; // ORIGINAL LOCATION (where bin currently is)
  @override
  @JsonKey(name: 'original_latitude')
  double get originalLatitude;
  @override
  @JsonKey(name: 'original_longitude')
  double get originalLongitude;
  @override
  @JsonKey(name: 'original_address')
  String get originalAddress; // NEW LOCATION (where to move it - nullable for pickup-only)
  @override
  @JsonKey(name: 'new_latitude')
  double? get newLatitude;
  @override
  @JsonKey(name: 'new_longitude')
  double? get newLongitude;
  @override
  @JsonKey(name: 'new_address')
  String? get newAddress; // TRACKING & METADATA
  @override
  @JsonKey(name: 'reason')
  String? get reason;
  @override
  @JsonKey(name: 'notes')
  String? get notes;
  @override
  @JsonKey(name: 'completed_at')
  int? get completedAt;
  @override
  @JsonKey(name: 'created_at')
  int get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  int get updatedAt;

  /// Create a copy of MoveRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MoveRequestImplCopyWith<_$MoveRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
