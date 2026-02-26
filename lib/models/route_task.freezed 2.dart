// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RouteTask _$RouteTaskFromJson(Map<String, dynamic> json) {
  return _RouteTask.fromJson(json);
}

/// @nodoc
mixin _$RouteTask {
  /// Unique task ID (UUID from route_tasks table)
  String get id => throw _privateConstructorUsedError;

  /// Associated shift ID
  @JsonKey(name: 'shift_id')
  String get shiftId => throw _privateConstructorUsedError;

  /// Order in the route sequence (determines navigation order)
  @JsonKey(name: 'sequence_order')
  int get sequenceOrder => throw _privateConstructorUsedError;

  /// Type of task (collection, placement, pickup, dropoff, warehouse_stop)
  @JsonKey(name: 'task_type')
  StopType get taskType => throw _privateConstructorUsedError;

  /// Task location latitude
  double get latitude => throw _privateConstructorUsedError;

  /// Task location longitude
  double get longitude => throw _privateConstructorUsedError;

  /// Task location address
  String? get address =>
      throw _privateConstructorUsedError; // ========== COLLECTION TASK FIELDS ==========
  /// Bin ID (for collection and move request tasks)
  @JsonKey(name: 'bin_id')
  String? get binId => throw _privateConstructorUsedError;

  /// Bin number (for display)
  @JsonKey(name: 'bin_number')
  int? get binNumber => throw _privateConstructorUsedError;

  /// Current fill percentage before collection (0-100)
  @JsonKey(name: 'fill_percentage')
  int? get fillPercentage => throw _privateConstructorUsedError; // ========== PLACEMENT TASK FIELDS ==========
  /// Potential location ID (for placement tasks)
  @JsonKey(name: 'potential_location_id')
  String? get potentialLocationId => throw _privateConstructorUsedError;

  /// New bin number to place (for placement tasks)
  @JsonKey(name: 'new_bin_number')
  int? get newBinNumber => throw _privateConstructorUsedError; // ========== MOVE REQUEST TASK FIELDS ==========
  /// Move request ID (for pickup/dropoff tasks)
  @JsonKey(name: 'move_request_id')
  String? get moveRequestId => throw _privateConstructorUsedError;

  /// Destination latitude (for pickup tasks - where to drop off)
  @JsonKey(name: 'destination_latitude')
  double? get destinationLatitude => throw _privateConstructorUsedError;

  /// Destination longitude (for pickup tasks - where to drop off)
  @JsonKey(name: 'destination_longitude')
  double? get destinationLongitude => throw _privateConstructorUsedError;

  /// Destination address (for pickup tasks)
  @JsonKey(name: 'destination_address')
  String? get destinationAddress => throw _privateConstructorUsedError;

  /// Move request type (relocation, store, etc.)
  @JsonKey(name: 'move_type')
  String? get moveType => throw _privateConstructorUsedError; // ========== WAREHOUSE STOP FIELDS ==========
  /// Warehouse stop action type (load, unload, both)
  @JsonKey(name: 'warehouse_action')
  String? get warehouseAction => throw _privateConstructorUsedError;

  /// Number of bins to load at warehouse
  @JsonKey(name: 'bins_to_load')
  int? get binsToLoad => throw _privateConstructorUsedError; // ========== ROUTE TRACKING FIELDS ==========
  /// Route ID this task was imported from (if applicable)
  @JsonKey(name: 'route_id')
  String? get routeId => throw _privateConstructorUsedError; // ========== COMPLETION TRACKING ==========
  /// Whether this task has been completed
  @JsonKey(name: 'is_completed')
  int get isCompleted => throw _privateConstructorUsedError;

  /// When the task was completed (Unix timestamp)
  @JsonKey(name: 'completed_at')
  int? get completedAt => throw _privateConstructorUsedError;

  /// Whether this task was skipped
  bool get skipped => throw _privateConstructorUsedError;

  /// Updated fill percentage after collection (0-100)
  @JsonKey(name: 'updated_fill_percentage')
  int? get updatedFillPercentage => throw _privateConstructorUsedError; // ========== METADATA ==========
  /// Flexible JSON data for task-specific information
  @JsonKey(name: 'task_data')
  Map<String, dynamic>? get taskData => throw _privateConstructorUsedError;

  /// Created timestamp (Unix timestamp)
  @JsonKey(name: 'created_at')
  int get createdAt => throw _privateConstructorUsedError;

  /// Serializes this RouteTask to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RouteTask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RouteTaskCopyWith<RouteTask> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RouteTaskCopyWith<$Res> {
  factory $RouteTaskCopyWith(RouteTask value, $Res Function(RouteTask) then) =
      _$RouteTaskCopyWithImpl<$Res, RouteTask>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'shift_id') String shiftId,
    @JsonKey(name: 'sequence_order') int sequenceOrder,
    @JsonKey(name: 'task_type') StopType taskType,
    double latitude,
    double longitude,
    String? address,
    @JsonKey(name: 'bin_id') String? binId,
    @JsonKey(name: 'bin_number') int? binNumber,
    @JsonKey(name: 'fill_percentage') int? fillPercentage,
    @JsonKey(name: 'potential_location_id') String? potentialLocationId,
    @JsonKey(name: 'new_bin_number') int? newBinNumber,
    @JsonKey(name: 'move_request_id') String? moveRequestId,
    @JsonKey(name: 'destination_latitude') double? destinationLatitude,
    @JsonKey(name: 'destination_longitude') double? destinationLongitude,
    @JsonKey(name: 'destination_address') String? destinationAddress,
    @JsonKey(name: 'move_type') String? moveType,
    @JsonKey(name: 'warehouse_action') String? warehouseAction,
    @JsonKey(name: 'bins_to_load') int? binsToLoad,
    @JsonKey(name: 'route_id') String? routeId,
    @JsonKey(name: 'is_completed') int isCompleted,
    @JsonKey(name: 'completed_at') int? completedAt,
    bool skipped,
    @JsonKey(name: 'updated_fill_percentage') int? updatedFillPercentage,
    @JsonKey(name: 'task_data') Map<String, dynamic>? taskData,
    @JsonKey(name: 'created_at') int createdAt,
  });
}

/// @nodoc
class _$RouteTaskCopyWithImpl<$Res, $Val extends RouteTask>
    implements $RouteTaskCopyWith<$Res> {
  _$RouteTaskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RouteTask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? shiftId = null,
    Object? sequenceOrder = null,
    Object? taskType = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? address = freezed,
    Object? binId = freezed,
    Object? binNumber = freezed,
    Object? fillPercentage = freezed,
    Object? potentialLocationId = freezed,
    Object? newBinNumber = freezed,
    Object? moveRequestId = freezed,
    Object? destinationLatitude = freezed,
    Object? destinationLongitude = freezed,
    Object? destinationAddress = freezed,
    Object? moveType = freezed,
    Object? warehouseAction = freezed,
    Object? binsToLoad = freezed,
    Object? routeId = freezed,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? skipped = null,
    Object? updatedFillPercentage = freezed,
    Object? taskData = freezed,
    Object? createdAt = null,
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
            sequenceOrder: null == sequenceOrder
                ? _value.sequenceOrder
                : sequenceOrder // ignore: cast_nullable_to_non_nullable
                      as int,
            taskType: null == taskType
                ? _value.taskType
                : taskType // ignore: cast_nullable_to_non_nullable
                      as StopType,
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
            address: freezed == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String?,
            binId: freezed == binId
                ? _value.binId
                : binId // ignore: cast_nullable_to_non_nullable
                      as String?,
            binNumber: freezed == binNumber
                ? _value.binNumber
                : binNumber // ignore: cast_nullable_to_non_nullable
                      as int?,
            fillPercentage: freezed == fillPercentage
                ? _value.fillPercentage
                : fillPercentage // ignore: cast_nullable_to_non_nullable
                      as int?,
            potentialLocationId: freezed == potentialLocationId
                ? _value.potentialLocationId
                : potentialLocationId // ignore: cast_nullable_to_non_nullable
                      as String?,
            newBinNumber: freezed == newBinNumber
                ? _value.newBinNumber
                : newBinNumber // ignore: cast_nullable_to_non_nullable
                      as int?,
            moveRequestId: freezed == moveRequestId
                ? _value.moveRequestId
                : moveRequestId // ignore: cast_nullable_to_non_nullable
                      as String?,
            destinationLatitude: freezed == destinationLatitude
                ? _value.destinationLatitude
                : destinationLatitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            destinationLongitude: freezed == destinationLongitude
                ? _value.destinationLongitude
                : destinationLongitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            destinationAddress: freezed == destinationAddress
                ? _value.destinationAddress
                : destinationAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            moveType: freezed == moveType
                ? _value.moveType
                : moveType // ignore: cast_nullable_to_non_nullable
                      as String?,
            warehouseAction: freezed == warehouseAction
                ? _value.warehouseAction
                : warehouseAction // ignore: cast_nullable_to_non_nullable
                      as String?,
            binsToLoad: freezed == binsToLoad
                ? _value.binsToLoad
                : binsToLoad // ignore: cast_nullable_to_non_nullable
                      as int?,
            routeId: freezed == routeId
                ? _value.routeId
                : routeId // ignore: cast_nullable_to_non_nullable
                      as String?,
            isCompleted: null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                      as int,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as int?,
            skipped: null == skipped
                ? _value.skipped
                : skipped // ignore: cast_nullable_to_non_nullable
                      as bool,
            updatedFillPercentage: freezed == updatedFillPercentage
                ? _value.updatedFillPercentage
                : updatedFillPercentage // ignore: cast_nullable_to_non_nullable
                      as int?,
            taskData: freezed == taskData
                ? _value.taskData
                : taskData // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RouteTaskImplCopyWith<$Res>
    implements $RouteTaskCopyWith<$Res> {
  factory _$$RouteTaskImplCopyWith(
    _$RouteTaskImpl value,
    $Res Function(_$RouteTaskImpl) then,
  ) = __$$RouteTaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'shift_id') String shiftId,
    @JsonKey(name: 'sequence_order') int sequenceOrder,
    @JsonKey(name: 'task_type') StopType taskType,
    double latitude,
    double longitude,
    String? address,
    @JsonKey(name: 'bin_id') String? binId,
    @JsonKey(name: 'bin_number') int? binNumber,
    @JsonKey(name: 'fill_percentage') int? fillPercentage,
    @JsonKey(name: 'potential_location_id') String? potentialLocationId,
    @JsonKey(name: 'new_bin_number') int? newBinNumber,
    @JsonKey(name: 'move_request_id') String? moveRequestId,
    @JsonKey(name: 'destination_latitude') double? destinationLatitude,
    @JsonKey(name: 'destination_longitude') double? destinationLongitude,
    @JsonKey(name: 'destination_address') String? destinationAddress,
    @JsonKey(name: 'move_type') String? moveType,
    @JsonKey(name: 'warehouse_action') String? warehouseAction,
    @JsonKey(name: 'bins_to_load') int? binsToLoad,
    @JsonKey(name: 'route_id') String? routeId,
    @JsonKey(name: 'is_completed') int isCompleted,
    @JsonKey(name: 'completed_at') int? completedAt,
    bool skipped,
    @JsonKey(name: 'updated_fill_percentage') int? updatedFillPercentage,
    @JsonKey(name: 'task_data') Map<String, dynamic>? taskData,
    @JsonKey(name: 'created_at') int createdAt,
  });
}

/// @nodoc
class __$$RouteTaskImplCopyWithImpl<$Res>
    extends _$RouteTaskCopyWithImpl<$Res, _$RouteTaskImpl>
    implements _$$RouteTaskImplCopyWith<$Res> {
  __$$RouteTaskImplCopyWithImpl(
    _$RouteTaskImpl _value,
    $Res Function(_$RouteTaskImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RouteTask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? shiftId = null,
    Object? sequenceOrder = null,
    Object? taskType = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? address = freezed,
    Object? binId = freezed,
    Object? binNumber = freezed,
    Object? fillPercentage = freezed,
    Object? potentialLocationId = freezed,
    Object? newBinNumber = freezed,
    Object? moveRequestId = freezed,
    Object? destinationLatitude = freezed,
    Object? destinationLongitude = freezed,
    Object? destinationAddress = freezed,
    Object? moveType = freezed,
    Object? warehouseAction = freezed,
    Object? binsToLoad = freezed,
    Object? routeId = freezed,
    Object? isCompleted = null,
    Object? completedAt = freezed,
    Object? skipped = null,
    Object? updatedFillPercentage = freezed,
    Object? taskData = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$RouteTaskImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        shiftId: null == shiftId
            ? _value.shiftId
            : shiftId // ignore: cast_nullable_to_non_nullable
                  as String,
        sequenceOrder: null == sequenceOrder
            ? _value.sequenceOrder
            : sequenceOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        taskType: null == taskType
            ? _value.taskType
            : taskType // ignore: cast_nullable_to_non_nullable
                  as StopType,
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
        address: freezed == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String?,
        binId: freezed == binId
            ? _value.binId
            : binId // ignore: cast_nullable_to_non_nullable
                  as String?,
        binNumber: freezed == binNumber
            ? _value.binNumber
            : binNumber // ignore: cast_nullable_to_non_nullable
                  as int?,
        fillPercentage: freezed == fillPercentage
            ? _value.fillPercentage
            : fillPercentage // ignore: cast_nullable_to_non_nullable
                  as int?,
        potentialLocationId: freezed == potentialLocationId
            ? _value.potentialLocationId
            : potentialLocationId // ignore: cast_nullable_to_non_nullable
                  as String?,
        newBinNumber: freezed == newBinNumber
            ? _value.newBinNumber
            : newBinNumber // ignore: cast_nullable_to_non_nullable
                  as int?,
        moveRequestId: freezed == moveRequestId
            ? _value.moveRequestId
            : moveRequestId // ignore: cast_nullable_to_non_nullable
                  as String?,
        destinationLatitude: freezed == destinationLatitude
            ? _value.destinationLatitude
            : destinationLatitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        destinationLongitude: freezed == destinationLongitude
            ? _value.destinationLongitude
            : destinationLongitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        destinationAddress: freezed == destinationAddress
            ? _value.destinationAddress
            : destinationAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        moveType: freezed == moveType
            ? _value.moveType
            : moveType // ignore: cast_nullable_to_non_nullable
                  as String?,
        warehouseAction: freezed == warehouseAction
            ? _value.warehouseAction
            : warehouseAction // ignore: cast_nullable_to_non_nullable
                  as String?,
        binsToLoad: freezed == binsToLoad
            ? _value.binsToLoad
            : binsToLoad // ignore: cast_nullable_to_non_nullable
                  as int?,
        routeId: freezed == routeId
            ? _value.routeId
            : routeId // ignore: cast_nullable_to_non_nullable
                  as String?,
        isCompleted: null == isCompleted
            ? _value.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as int,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as int?,
        skipped: null == skipped
            ? _value.skipped
            : skipped // ignore: cast_nullable_to_non_nullable
                  as bool,
        updatedFillPercentage: freezed == updatedFillPercentage
            ? _value.updatedFillPercentage
            : updatedFillPercentage // ignore: cast_nullable_to_non_nullable
                  as int?,
        taskData: freezed == taskData
            ? _value._taskData
            : taskData // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RouteTaskImpl extends _RouteTask {
  const _$RouteTaskImpl({
    required this.id,
    @JsonKey(name: 'shift_id') required this.shiftId,
    @JsonKey(name: 'sequence_order') required this.sequenceOrder,
    @JsonKey(name: 'task_type') required this.taskType,
    required this.latitude,
    required this.longitude,
    this.address,
    @JsonKey(name: 'bin_id') this.binId,
    @JsonKey(name: 'bin_number') this.binNumber,
    @JsonKey(name: 'fill_percentage') this.fillPercentage,
    @JsonKey(name: 'potential_location_id') this.potentialLocationId,
    @JsonKey(name: 'new_bin_number') this.newBinNumber,
    @JsonKey(name: 'move_request_id') this.moveRequestId,
    @JsonKey(name: 'destination_latitude') this.destinationLatitude,
    @JsonKey(name: 'destination_longitude') this.destinationLongitude,
    @JsonKey(name: 'destination_address') this.destinationAddress,
    @JsonKey(name: 'move_type') this.moveType,
    @JsonKey(name: 'warehouse_action') this.warehouseAction,
    @JsonKey(name: 'bins_to_load') this.binsToLoad,
    @JsonKey(name: 'route_id') this.routeId,
    @JsonKey(name: 'is_completed') this.isCompleted = 0,
    @JsonKey(name: 'completed_at') this.completedAt,
    this.skipped = false,
    @JsonKey(name: 'updated_fill_percentage') this.updatedFillPercentage,
    @JsonKey(name: 'task_data') final Map<String, dynamic>? taskData,
    @JsonKey(name: 'created_at') required this.createdAt,
  }) : _taskData = taskData,
       super._();

  factory _$RouteTaskImpl.fromJson(Map<String, dynamic> json) =>
      _$$RouteTaskImplFromJson(json);

  /// Unique task ID (UUID from route_tasks table)
  @override
  final String id;

  /// Associated shift ID
  @override
  @JsonKey(name: 'shift_id')
  final String shiftId;

  /// Order in the route sequence (determines navigation order)
  @override
  @JsonKey(name: 'sequence_order')
  final int sequenceOrder;

  /// Type of task (collection, placement, pickup, dropoff, warehouse_stop)
  @override
  @JsonKey(name: 'task_type')
  final StopType taskType;

  /// Task location latitude
  @override
  final double latitude;

  /// Task location longitude
  @override
  final double longitude;

  /// Task location address
  @override
  final String? address;
  // ========== COLLECTION TASK FIELDS ==========
  /// Bin ID (for collection and move request tasks)
  @override
  @JsonKey(name: 'bin_id')
  final String? binId;

  /// Bin number (for display)
  @override
  @JsonKey(name: 'bin_number')
  final int? binNumber;

  /// Current fill percentage before collection (0-100)
  @override
  @JsonKey(name: 'fill_percentage')
  final int? fillPercentage;
  // ========== PLACEMENT TASK FIELDS ==========
  /// Potential location ID (for placement tasks)
  @override
  @JsonKey(name: 'potential_location_id')
  final String? potentialLocationId;

  /// New bin number to place (for placement tasks)
  @override
  @JsonKey(name: 'new_bin_number')
  final int? newBinNumber;
  // ========== MOVE REQUEST TASK FIELDS ==========
  /// Move request ID (for pickup/dropoff tasks)
  @override
  @JsonKey(name: 'move_request_id')
  final String? moveRequestId;

  /// Destination latitude (for pickup tasks - where to drop off)
  @override
  @JsonKey(name: 'destination_latitude')
  final double? destinationLatitude;

  /// Destination longitude (for pickup tasks - where to drop off)
  @override
  @JsonKey(name: 'destination_longitude')
  final double? destinationLongitude;

  /// Destination address (for pickup tasks)
  @override
  @JsonKey(name: 'destination_address')
  final String? destinationAddress;

  /// Move request type (relocation, store, etc.)
  @override
  @JsonKey(name: 'move_type')
  final String? moveType;
  // ========== WAREHOUSE STOP FIELDS ==========
  /// Warehouse stop action type (load, unload, both)
  @override
  @JsonKey(name: 'warehouse_action')
  final String? warehouseAction;

  /// Number of bins to load at warehouse
  @override
  @JsonKey(name: 'bins_to_load')
  final int? binsToLoad;
  // ========== ROUTE TRACKING FIELDS ==========
  /// Route ID this task was imported from (if applicable)
  @override
  @JsonKey(name: 'route_id')
  final String? routeId;
  // ========== COMPLETION TRACKING ==========
  /// Whether this task has been completed
  @override
  @JsonKey(name: 'is_completed')
  final int isCompleted;

  /// When the task was completed (Unix timestamp)
  @override
  @JsonKey(name: 'completed_at')
  final int? completedAt;

  /// Whether this task was skipped
  @override
  @JsonKey()
  final bool skipped;

  /// Updated fill percentage after collection (0-100)
  @override
  @JsonKey(name: 'updated_fill_percentage')
  final int? updatedFillPercentage;
  // ========== METADATA ==========
  /// Flexible JSON data for task-specific information
  final Map<String, dynamic>? _taskData;
  // ========== METADATA ==========
  /// Flexible JSON data for task-specific information
  @override
  @JsonKey(name: 'task_data')
  Map<String, dynamic>? get taskData {
    final value = _taskData;
    if (value == null) return null;
    if (_taskData is EqualUnmodifiableMapView) return _taskData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// Created timestamp (Unix timestamp)
  @override
  @JsonKey(name: 'created_at')
  final int createdAt;

  @override
  String toString() {
    return 'RouteTask(id: $id, shiftId: $shiftId, sequenceOrder: $sequenceOrder, taskType: $taskType, latitude: $latitude, longitude: $longitude, address: $address, binId: $binId, binNumber: $binNumber, fillPercentage: $fillPercentage, potentialLocationId: $potentialLocationId, newBinNumber: $newBinNumber, moveRequestId: $moveRequestId, destinationLatitude: $destinationLatitude, destinationLongitude: $destinationLongitude, destinationAddress: $destinationAddress, moveType: $moveType, warehouseAction: $warehouseAction, binsToLoad: $binsToLoad, routeId: $routeId, isCompleted: $isCompleted, completedAt: $completedAt, skipped: $skipped, updatedFillPercentage: $updatedFillPercentage, taskData: $taskData, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RouteTaskImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.shiftId, shiftId) || other.shiftId == shiftId) &&
            (identical(other.sequenceOrder, sequenceOrder) ||
                other.sequenceOrder == sequenceOrder) &&
            (identical(other.taskType, taskType) ||
                other.taskType == taskType) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.binId, binId) || other.binId == binId) &&
            (identical(other.binNumber, binNumber) ||
                other.binNumber == binNumber) &&
            (identical(other.fillPercentage, fillPercentage) ||
                other.fillPercentage == fillPercentage) &&
            (identical(other.potentialLocationId, potentialLocationId) ||
                other.potentialLocationId == potentialLocationId) &&
            (identical(other.newBinNumber, newBinNumber) ||
                other.newBinNumber == newBinNumber) &&
            (identical(other.moveRequestId, moveRequestId) ||
                other.moveRequestId == moveRequestId) &&
            (identical(other.destinationLatitude, destinationLatitude) ||
                other.destinationLatitude == destinationLatitude) &&
            (identical(other.destinationLongitude, destinationLongitude) ||
                other.destinationLongitude == destinationLongitude) &&
            (identical(other.destinationAddress, destinationAddress) ||
                other.destinationAddress == destinationAddress) &&
            (identical(other.moveType, moveType) ||
                other.moveType == moveType) &&
            (identical(other.warehouseAction, warehouseAction) ||
                other.warehouseAction == warehouseAction) &&
            (identical(other.binsToLoad, binsToLoad) ||
                other.binsToLoad == binsToLoad) &&
            (identical(other.routeId, routeId) || other.routeId == routeId) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.skipped, skipped) || other.skipped == skipped) &&
            (identical(other.updatedFillPercentage, updatedFillPercentage) ||
                other.updatedFillPercentage == updatedFillPercentage) &&
            const DeepCollectionEquality().equals(other._taskData, _taskData) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    shiftId,
    sequenceOrder,
    taskType,
    latitude,
    longitude,
    address,
    binId,
    binNumber,
    fillPercentage,
    potentialLocationId,
    newBinNumber,
    moveRequestId,
    destinationLatitude,
    destinationLongitude,
    destinationAddress,
    moveType,
    warehouseAction,
    binsToLoad,
    routeId,
    isCompleted,
    completedAt,
    skipped,
    updatedFillPercentage,
    const DeepCollectionEquality().hash(_taskData),
    createdAt,
  ]);

  /// Create a copy of RouteTask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RouteTaskImplCopyWith<_$RouteTaskImpl> get copyWith =>
      __$$RouteTaskImplCopyWithImpl<_$RouteTaskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RouteTaskImplToJson(this);
  }
}

abstract class _RouteTask extends RouteTask {
  const factory _RouteTask({
    required final String id,
    @JsonKey(name: 'shift_id') required final String shiftId,
    @JsonKey(name: 'sequence_order') required final int sequenceOrder,
    @JsonKey(name: 'task_type') required final StopType taskType,
    required final double latitude,
    required final double longitude,
    final String? address,
    @JsonKey(name: 'bin_id') final String? binId,
    @JsonKey(name: 'bin_number') final int? binNumber,
    @JsonKey(name: 'fill_percentage') final int? fillPercentage,
    @JsonKey(name: 'potential_location_id') final String? potentialLocationId,
    @JsonKey(name: 'new_bin_number') final int? newBinNumber,
    @JsonKey(name: 'move_request_id') final String? moveRequestId,
    @JsonKey(name: 'destination_latitude') final double? destinationLatitude,
    @JsonKey(name: 'destination_longitude') final double? destinationLongitude,
    @JsonKey(name: 'destination_address') final String? destinationAddress,
    @JsonKey(name: 'move_type') final String? moveType,
    @JsonKey(name: 'warehouse_action') final String? warehouseAction,
    @JsonKey(name: 'bins_to_load') final int? binsToLoad,
    @JsonKey(name: 'route_id') final String? routeId,
    @JsonKey(name: 'is_completed') final int isCompleted,
    @JsonKey(name: 'completed_at') final int? completedAt,
    final bool skipped,
    @JsonKey(name: 'updated_fill_percentage') final int? updatedFillPercentage,
    @JsonKey(name: 'task_data') final Map<String, dynamic>? taskData,
    @JsonKey(name: 'created_at') required final int createdAt,
  }) = _$RouteTaskImpl;
  const _RouteTask._() : super._();

  factory _RouteTask.fromJson(Map<String, dynamic> json) =
      _$RouteTaskImpl.fromJson;

  /// Unique task ID (UUID from route_tasks table)
  @override
  String get id;

  /// Associated shift ID
  @override
  @JsonKey(name: 'shift_id')
  String get shiftId;

  /// Order in the route sequence (determines navigation order)
  @override
  @JsonKey(name: 'sequence_order')
  int get sequenceOrder;

  /// Type of task (collection, placement, pickup, dropoff, warehouse_stop)
  @override
  @JsonKey(name: 'task_type')
  StopType get taskType;

  /// Task location latitude
  @override
  double get latitude;

  /// Task location longitude
  @override
  double get longitude;

  /// Task location address
  @override
  String? get address; // ========== COLLECTION TASK FIELDS ==========
  /// Bin ID (for collection and move request tasks)
  @override
  @JsonKey(name: 'bin_id')
  String? get binId;

  /// Bin number (for display)
  @override
  @JsonKey(name: 'bin_number')
  int? get binNumber;

  /// Current fill percentage before collection (0-100)
  @override
  @JsonKey(name: 'fill_percentage')
  int? get fillPercentage; // ========== PLACEMENT TASK FIELDS ==========
  /// Potential location ID (for placement tasks)
  @override
  @JsonKey(name: 'potential_location_id')
  String? get potentialLocationId;

  /// New bin number to place (for placement tasks)
  @override
  @JsonKey(name: 'new_bin_number')
  int? get newBinNumber; // ========== MOVE REQUEST TASK FIELDS ==========
  /// Move request ID (for pickup/dropoff tasks)
  @override
  @JsonKey(name: 'move_request_id')
  String? get moveRequestId;

  /// Destination latitude (for pickup tasks - where to drop off)
  @override
  @JsonKey(name: 'destination_latitude')
  double? get destinationLatitude;

  /// Destination longitude (for pickup tasks - where to drop off)
  @override
  @JsonKey(name: 'destination_longitude')
  double? get destinationLongitude;

  /// Destination address (for pickup tasks)
  @override
  @JsonKey(name: 'destination_address')
  String? get destinationAddress;

  /// Move request type (relocation, store, etc.)
  @override
  @JsonKey(name: 'move_type')
  String? get moveType; // ========== WAREHOUSE STOP FIELDS ==========
  /// Warehouse stop action type (load, unload, both)
  @override
  @JsonKey(name: 'warehouse_action')
  String? get warehouseAction;

  /// Number of bins to load at warehouse
  @override
  @JsonKey(name: 'bins_to_load')
  int? get binsToLoad; // ========== ROUTE TRACKING FIELDS ==========
  /// Route ID this task was imported from (if applicable)
  @override
  @JsonKey(name: 'route_id')
  String? get routeId; // ========== COMPLETION TRACKING ==========
  /// Whether this task has been completed
  @override
  @JsonKey(name: 'is_completed')
  int get isCompleted;

  /// When the task was completed (Unix timestamp)
  @override
  @JsonKey(name: 'completed_at')
  int? get completedAt;

  /// Whether this task was skipped
  @override
  bool get skipped;

  /// Updated fill percentage after collection (0-100)
  @override
  @JsonKey(name: 'updated_fill_percentage')
  int? get updatedFillPercentage; // ========== METADATA ==========
  /// Flexible JSON data for task-specific information
  @override
  @JsonKey(name: 'task_data')
  Map<String, dynamic>? get taskData;

  /// Created timestamp (Unix timestamp)
  @override
  @JsonKey(name: 'created_at')
  int get createdAt;

  /// Create a copy of RouteTask
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RouteTaskImplCopyWith<_$RouteTaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
