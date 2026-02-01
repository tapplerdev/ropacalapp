// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shift_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ShiftState _$ShiftStateFromJson(Map<String, dynamic> json) {
  return _ShiftState.fromJson(json);
}

/// @nodoc
mixin _$ShiftState {
  /// Current shift status
  ShiftStatus get status => throw _privateConstructorUsedError;

  /// Shift ID (unique identifier for this shift instance)
  @JsonKey(name: 'id')
  String? get shiftId => throw _privateConstructorUsedError;

  /// When the shift started (clock in time)
  @JsonKey(name: 'start_time')
  @UnixTimestampConverter()
  DateTime? get startTime => throw _privateConstructorUsedError;

  /// Total pause time in seconds
  @JsonKey(name: 'total_pause_seconds')
  int get totalPauseSeconds => throw _privateConstructorUsedError;

  /// Current pause start time (null if not paused)
  @JsonKey(name: 'pause_start_time')
  @UnixTimestampConverter()
  DateTime? get pauseStartTime => throw _privateConstructorUsedError;

  /// Assigned route ID
  @JsonKey(name: 'route_id')
  String? get assignedRouteId => throw _privateConstructorUsedError;

  /// Total bins in assigned route
  @JsonKey(name: 'total_bins')
  int get totalBins => throw _privateConstructorUsedError;

  /// Completed bins count
  @JsonKey(name: 'completed_bins')
  int get completedBins => throw _privateConstructorUsedError;

  /// List of bins in the route with their details (legacy)
  @JsonKey(name: 'bins')
  List<RouteBin> get routeBins => throw _privateConstructorUsedError;

  /// List of tasks in the route (new task-based system)
  @JsonKey(name: 'tasks')
  List<RouteTask> get tasks => throw _privateConstructorUsedError;

  /// Serializes this ShiftState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShiftState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShiftStateCopyWith<ShiftState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShiftStateCopyWith<$Res> {
  factory $ShiftStateCopyWith(
    ShiftState value,
    $Res Function(ShiftState) then,
  ) = _$ShiftStateCopyWithImpl<$Res, ShiftState>;
  @useResult
  $Res call({
    ShiftStatus status,
    @JsonKey(name: 'id') String? shiftId,
    @JsonKey(name: 'start_time') @UnixTimestampConverter() DateTime? startTime,
    @JsonKey(name: 'total_pause_seconds') int totalPauseSeconds,
    @JsonKey(name: 'pause_start_time')
    @UnixTimestampConverter()
    DateTime? pauseStartTime,
    @JsonKey(name: 'route_id') String? assignedRouteId,
    @JsonKey(name: 'total_bins') int totalBins,
    @JsonKey(name: 'completed_bins') int completedBins,
    @JsonKey(name: 'bins') List<RouteBin> routeBins,
    @JsonKey(name: 'tasks') List<RouteTask> tasks,
  });
}

/// @nodoc
class _$ShiftStateCopyWithImpl<$Res, $Val extends ShiftState>
    implements $ShiftStateCopyWith<$Res> {
  _$ShiftStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShiftState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? shiftId = freezed,
    Object? startTime = freezed,
    Object? totalPauseSeconds = null,
    Object? pauseStartTime = freezed,
    Object? assignedRouteId = freezed,
    Object? totalBins = null,
    Object? completedBins = null,
    Object? routeBins = null,
    Object? tasks = null,
  }) {
    return _then(
      _value.copyWith(
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ShiftStatus,
            shiftId: freezed == shiftId
                ? _value.shiftId
                : shiftId // ignore: cast_nullable_to_non_nullable
                      as String?,
            startTime: freezed == startTime
                ? _value.startTime
                : startTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            totalPauseSeconds: null == totalPauseSeconds
                ? _value.totalPauseSeconds
                : totalPauseSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            pauseStartTime: freezed == pauseStartTime
                ? _value.pauseStartTime
                : pauseStartTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            assignedRouteId: freezed == assignedRouteId
                ? _value.assignedRouteId
                : assignedRouteId // ignore: cast_nullable_to_non_nullable
                      as String?,
            totalBins: null == totalBins
                ? _value.totalBins
                : totalBins // ignore: cast_nullable_to_non_nullable
                      as int,
            completedBins: null == completedBins
                ? _value.completedBins
                : completedBins // ignore: cast_nullable_to_non_nullable
                      as int,
            routeBins: null == routeBins
                ? _value.routeBins
                : routeBins // ignore: cast_nullable_to_non_nullable
                      as List<RouteBin>,
            tasks: null == tasks
                ? _value.tasks
                : tasks // ignore: cast_nullable_to_non_nullable
                      as List<RouteTask>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ShiftStateImplCopyWith<$Res>
    implements $ShiftStateCopyWith<$Res> {
  factory _$$ShiftStateImplCopyWith(
    _$ShiftStateImpl value,
    $Res Function(_$ShiftStateImpl) then,
  ) = __$$ShiftStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    ShiftStatus status,
    @JsonKey(name: 'id') String? shiftId,
    @JsonKey(name: 'start_time') @UnixTimestampConverter() DateTime? startTime,
    @JsonKey(name: 'total_pause_seconds') int totalPauseSeconds,
    @JsonKey(name: 'pause_start_time')
    @UnixTimestampConverter()
    DateTime? pauseStartTime,
    @JsonKey(name: 'route_id') String? assignedRouteId,
    @JsonKey(name: 'total_bins') int totalBins,
    @JsonKey(name: 'completed_bins') int completedBins,
    @JsonKey(name: 'bins') List<RouteBin> routeBins,
    @JsonKey(name: 'tasks') List<RouteTask> tasks,
  });
}

/// @nodoc
class __$$ShiftStateImplCopyWithImpl<$Res>
    extends _$ShiftStateCopyWithImpl<$Res, _$ShiftStateImpl>
    implements _$$ShiftStateImplCopyWith<$Res> {
  __$$ShiftStateImplCopyWithImpl(
    _$ShiftStateImpl _value,
    $Res Function(_$ShiftStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ShiftState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? shiftId = freezed,
    Object? startTime = freezed,
    Object? totalPauseSeconds = null,
    Object? pauseStartTime = freezed,
    Object? assignedRouteId = freezed,
    Object? totalBins = null,
    Object? completedBins = null,
    Object? routeBins = null,
    Object? tasks = null,
  }) {
    return _then(
      _$ShiftStateImpl(
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ShiftStatus,
        shiftId: freezed == shiftId
            ? _value.shiftId
            : shiftId // ignore: cast_nullable_to_non_nullable
                  as String?,
        startTime: freezed == startTime
            ? _value.startTime
            : startTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        totalPauseSeconds: null == totalPauseSeconds
            ? _value.totalPauseSeconds
            : totalPauseSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        pauseStartTime: freezed == pauseStartTime
            ? _value.pauseStartTime
            : pauseStartTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        assignedRouteId: freezed == assignedRouteId
            ? _value.assignedRouteId
            : assignedRouteId // ignore: cast_nullable_to_non_nullable
                  as String?,
        totalBins: null == totalBins
            ? _value.totalBins
            : totalBins // ignore: cast_nullable_to_non_nullable
                  as int,
        completedBins: null == completedBins
            ? _value.completedBins
            : completedBins // ignore: cast_nullable_to_non_nullable
                  as int,
        routeBins: null == routeBins
            ? _value._routeBins
            : routeBins // ignore: cast_nullable_to_non_nullable
                  as List<RouteBin>,
        tasks: null == tasks
            ? _value._tasks
            : tasks // ignore: cast_nullable_to_non_nullable
                  as List<RouteTask>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ShiftStateImpl extends _ShiftState {
  const _$ShiftStateImpl({
    required this.status,
    @JsonKey(name: 'id') this.shiftId,
    @JsonKey(name: 'start_time') @UnixTimestampConverter() this.startTime,
    @JsonKey(name: 'total_pause_seconds') this.totalPauseSeconds = 0,
    @JsonKey(name: 'pause_start_time')
    @UnixTimestampConverter()
    this.pauseStartTime,
    @JsonKey(name: 'route_id') this.assignedRouteId,
    @JsonKey(name: 'total_bins') this.totalBins = 0,
    @JsonKey(name: 'completed_bins') this.completedBins = 0,
    @JsonKey(name: 'bins') final List<RouteBin> routeBins = const [],
    @JsonKey(name: 'tasks') final List<RouteTask> tasks = const [],
  }) : _routeBins = routeBins,
       _tasks = tasks,
       super._();

  factory _$ShiftStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShiftStateImplFromJson(json);

  /// Current shift status
  @override
  final ShiftStatus status;

  /// Shift ID (unique identifier for this shift instance)
  @override
  @JsonKey(name: 'id')
  final String? shiftId;

  /// When the shift started (clock in time)
  @override
  @JsonKey(name: 'start_time')
  @UnixTimestampConverter()
  final DateTime? startTime;

  /// Total pause time in seconds
  @override
  @JsonKey(name: 'total_pause_seconds')
  final int totalPauseSeconds;

  /// Current pause start time (null if not paused)
  @override
  @JsonKey(name: 'pause_start_time')
  @UnixTimestampConverter()
  final DateTime? pauseStartTime;

  /// Assigned route ID
  @override
  @JsonKey(name: 'route_id')
  final String? assignedRouteId;

  /// Total bins in assigned route
  @override
  @JsonKey(name: 'total_bins')
  final int totalBins;

  /// Completed bins count
  @override
  @JsonKey(name: 'completed_bins')
  final int completedBins;

  /// List of bins in the route with their details (legacy)
  final List<RouteBin> _routeBins;

  /// List of bins in the route with their details (legacy)
  @override
  @JsonKey(name: 'bins')
  List<RouteBin> get routeBins {
    if (_routeBins is EqualUnmodifiableListView) return _routeBins;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_routeBins);
  }

  /// List of tasks in the route (new task-based system)
  final List<RouteTask> _tasks;

  /// List of tasks in the route (new task-based system)
  @override
  @JsonKey(name: 'tasks')
  List<RouteTask> get tasks {
    if (_tasks is EqualUnmodifiableListView) return _tasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tasks);
  }

  @override
  String toString() {
    return 'ShiftState(status: $status, shiftId: $shiftId, startTime: $startTime, totalPauseSeconds: $totalPauseSeconds, pauseStartTime: $pauseStartTime, assignedRouteId: $assignedRouteId, totalBins: $totalBins, completedBins: $completedBins, routeBins: $routeBins, tasks: $tasks)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShiftStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.shiftId, shiftId) || other.shiftId == shiftId) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.totalPauseSeconds, totalPauseSeconds) ||
                other.totalPauseSeconds == totalPauseSeconds) &&
            (identical(other.pauseStartTime, pauseStartTime) ||
                other.pauseStartTime == pauseStartTime) &&
            (identical(other.assignedRouteId, assignedRouteId) ||
                other.assignedRouteId == assignedRouteId) &&
            (identical(other.totalBins, totalBins) ||
                other.totalBins == totalBins) &&
            (identical(other.completedBins, completedBins) ||
                other.completedBins == completedBins) &&
            const DeepCollectionEquality().equals(
              other._routeBins,
              _routeBins,
            ) &&
            const DeepCollectionEquality().equals(other._tasks, _tasks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    status,
    shiftId,
    startTime,
    totalPauseSeconds,
    pauseStartTime,
    assignedRouteId,
    totalBins,
    completedBins,
    const DeepCollectionEquality().hash(_routeBins),
    const DeepCollectionEquality().hash(_tasks),
  );

  /// Create a copy of ShiftState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShiftStateImplCopyWith<_$ShiftStateImpl> get copyWith =>
      __$$ShiftStateImplCopyWithImpl<_$ShiftStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShiftStateImplToJson(this);
  }
}

abstract class _ShiftState extends ShiftState {
  const factory _ShiftState({
    required final ShiftStatus status,
    @JsonKey(name: 'id') final String? shiftId,
    @JsonKey(name: 'start_time')
    @UnixTimestampConverter()
    final DateTime? startTime,
    @JsonKey(name: 'total_pause_seconds') final int totalPauseSeconds,
    @JsonKey(name: 'pause_start_time')
    @UnixTimestampConverter()
    final DateTime? pauseStartTime,
    @JsonKey(name: 'route_id') final String? assignedRouteId,
    @JsonKey(name: 'total_bins') final int totalBins,
    @JsonKey(name: 'completed_bins') final int completedBins,
    @JsonKey(name: 'bins') final List<RouteBin> routeBins,
    @JsonKey(name: 'tasks') final List<RouteTask> tasks,
  }) = _$ShiftStateImpl;
  const _ShiftState._() : super._();

  factory _ShiftState.fromJson(Map<String, dynamic> json) =
      _$ShiftStateImpl.fromJson;

  /// Current shift status
  @override
  ShiftStatus get status;

  /// Shift ID (unique identifier for this shift instance)
  @override
  @JsonKey(name: 'id')
  String? get shiftId;

  /// When the shift started (clock in time)
  @override
  @JsonKey(name: 'start_time')
  @UnixTimestampConverter()
  DateTime? get startTime;

  /// Total pause time in seconds
  @override
  @JsonKey(name: 'total_pause_seconds')
  int get totalPauseSeconds;

  /// Current pause start time (null if not paused)
  @override
  @JsonKey(name: 'pause_start_time')
  @UnixTimestampConverter()
  DateTime? get pauseStartTime;

  /// Assigned route ID
  @override
  @JsonKey(name: 'route_id')
  String? get assignedRouteId;

  /// Total bins in assigned route
  @override
  @JsonKey(name: 'total_bins')
  int get totalBins;

  /// Completed bins count
  @override
  @JsonKey(name: 'completed_bins')
  int get completedBins;

  /// List of bins in the route with their details (legacy)
  @override
  @JsonKey(name: 'bins')
  List<RouteBin> get routeBins;

  /// List of tasks in the route (new task-based system)
  @override
  @JsonKey(name: 'tasks')
  List<RouteTask> get tasks;

  /// Create a copy of ShiftState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShiftStateImplCopyWith<_$ShiftStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
