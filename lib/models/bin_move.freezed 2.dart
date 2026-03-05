// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bin_move.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BinMove _$BinMoveFromJson(Map<String, dynamic> json) {
  return _BinMove.fromJson(json);
}

/// @nodoc
mixin _$BinMove {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'bin_id')
  String get binId => throw _privateConstructorUsedError;
  @JsonKey(name: 'moved_from')
  String get movedFrom => throw _privateConstructorUsedError;
  @JsonKey(name: 'moved_to')
  String get movedTo => throw _privateConstructorUsedError;
  @JsonKey(name: 'moved_on')
  DateTime get movedOn => throw _privateConstructorUsedError;

  /// Serializes this BinMove to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BinMove
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BinMoveCopyWith<BinMove> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BinMoveCopyWith<$Res> {
  factory $BinMoveCopyWith(BinMove value, $Res Function(BinMove) then) =
      _$BinMoveCopyWithImpl<$Res, BinMove>;
  @useResult
  $Res call({
    int id,
    @JsonKey(name: 'bin_id') String binId,
    @JsonKey(name: 'moved_from') String movedFrom,
    @JsonKey(name: 'moved_to') String movedTo,
    @JsonKey(name: 'moved_on') DateTime movedOn,
  });
}

/// @nodoc
class _$BinMoveCopyWithImpl<$Res, $Val extends BinMove>
    implements $BinMoveCopyWith<$Res> {
  _$BinMoveCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BinMove
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? binId = null,
    Object? movedFrom = null,
    Object? movedTo = null,
    Object? movedOn = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            binId: null == binId
                ? _value.binId
                : binId // ignore: cast_nullable_to_non_nullable
                      as String,
            movedFrom: null == movedFrom
                ? _value.movedFrom
                : movedFrom // ignore: cast_nullable_to_non_nullable
                      as String,
            movedTo: null == movedTo
                ? _value.movedTo
                : movedTo // ignore: cast_nullable_to_non_nullable
                      as String,
            movedOn: null == movedOn
                ? _value.movedOn
                : movedOn // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BinMoveImplCopyWith<$Res> implements $BinMoveCopyWith<$Res> {
  factory _$$BinMoveImplCopyWith(
    _$BinMoveImpl value,
    $Res Function(_$BinMoveImpl) then,
  ) = __$$BinMoveImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    @JsonKey(name: 'bin_id') String binId,
    @JsonKey(name: 'moved_from') String movedFrom,
    @JsonKey(name: 'moved_to') String movedTo,
    @JsonKey(name: 'moved_on') DateTime movedOn,
  });
}

/// @nodoc
class __$$BinMoveImplCopyWithImpl<$Res>
    extends _$BinMoveCopyWithImpl<$Res, _$BinMoveImpl>
    implements _$$BinMoveImplCopyWith<$Res> {
  __$$BinMoveImplCopyWithImpl(
    _$BinMoveImpl _value,
    $Res Function(_$BinMoveImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BinMove
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? binId = null,
    Object? movedFrom = null,
    Object? movedTo = null,
    Object? movedOn = null,
  }) {
    return _then(
      _$BinMoveImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        binId: null == binId
            ? _value.binId
            : binId // ignore: cast_nullable_to_non_nullable
                  as String,
        movedFrom: null == movedFrom
            ? _value.movedFrom
            : movedFrom // ignore: cast_nullable_to_non_nullable
                  as String,
        movedTo: null == movedTo
            ? _value.movedTo
            : movedTo // ignore: cast_nullable_to_non_nullable
                  as String,
        movedOn: null == movedOn
            ? _value.movedOn
            : movedOn // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BinMoveImpl implements _BinMove {
  const _$BinMoveImpl({
    required this.id,
    @JsonKey(name: 'bin_id') required this.binId,
    @JsonKey(name: 'moved_from') required this.movedFrom,
    @JsonKey(name: 'moved_to') required this.movedTo,
    @JsonKey(name: 'moved_on') required this.movedOn,
  });

  factory _$BinMoveImpl.fromJson(Map<String, dynamic> json) =>
      _$$BinMoveImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'bin_id')
  final String binId;
  @override
  @JsonKey(name: 'moved_from')
  final String movedFrom;
  @override
  @JsonKey(name: 'moved_to')
  final String movedTo;
  @override
  @JsonKey(name: 'moved_on')
  final DateTime movedOn;

  @override
  String toString() {
    return 'BinMove(id: $id, binId: $binId, movedFrom: $movedFrom, movedTo: $movedTo, movedOn: $movedOn)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BinMoveImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.binId, binId) || other.binId == binId) &&
            (identical(other.movedFrom, movedFrom) ||
                other.movedFrom == movedFrom) &&
            (identical(other.movedTo, movedTo) || other.movedTo == movedTo) &&
            (identical(other.movedOn, movedOn) || other.movedOn == movedOn));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, binId, movedFrom, movedTo, movedOn);

  /// Create a copy of BinMove
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BinMoveImplCopyWith<_$BinMoveImpl> get copyWith =>
      __$$BinMoveImplCopyWithImpl<_$BinMoveImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BinMoveImplToJson(this);
  }
}

abstract class _BinMove implements BinMove {
  const factory _BinMove({
    required final int id,
    @JsonKey(name: 'bin_id') required final String binId,
    @JsonKey(name: 'moved_from') required final String movedFrom,
    @JsonKey(name: 'moved_to') required final String movedTo,
    @JsonKey(name: 'moved_on') required final DateTime movedOn,
  }) = _$BinMoveImpl;

  factory _BinMove.fromJson(Map<String, dynamic> json) = _$BinMoveImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'bin_id')
  String get binId;
  @override
  @JsonKey(name: 'moved_from')
  String get movedFrom;
  @override
  @JsonKey(name: 'moved_to')
  String get movedTo;
  @override
  @JsonKey(name: 'moved_on')
  DateTime get movedOn;

  /// Create a copy of BinMove
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BinMoveImplCopyWith<_$BinMoveImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
