// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bin_check.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BinCheck _$BinCheckFromJson(Map<String, dynamic> json) {
  return _BinCheck.fromJson(json);
}

/// @nodoc
mixin _$BinCheck {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'bin_id')
  String get binId => throw _privateConstructorUsedError;
  @JsonKey(name: 'checked_from')
  String get checkedFrom => throw _privateConstructorUsedError;
  @JsonKey(name: 'fill_percentage')
  int get fillPercentage => throw _privateConstructorUsedError;
  @JsonKey(name: 'checked_on')
  DateTime get checkedOn => throw _privateConstructorUsedError;

  /// Serializes this BinCheck to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BinCheck
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BinCheckCopyWith<BinCheck> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BinCheckCopyWith<$Res> {
  factory $BinCheckCopyWith(BinCheck value, $Res Function(BinCheck) then) =
      _$BinCheckCopyWithImpl<$Res, BinCheck>;
  @useResult
  $Res call({
    int id,
    @JsonKey(name: 'bin_id') String binId,
    @JsonKey(name: 'checked_from') String checkedFrom,
    @JsonKey(name: 'fill_percentage') int fillPercentage,
    @JsonKey(name: 'checked_on') DateTime checkedOn,
  });
}

/// @nodoc
class _$BinCheckCopyWithImpl<$Res, $Val extends BinCheck>
    implements $BinCheckCopyWith<$Res> {
  _$BinCheckCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BinCheck
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? binId = null,
    Object? checkedFrom = null,
    Object? fillPercentage = null,
    Object? checkedOn = null,
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
            checkedFrom: null == checkedFrom
                ? _value.checkedFrom
                : checkedFrom // ignore: cast_nullable_to_non_nullable
                      as String,
            fillPercentage: null == fillPercentage
                ? _value.fillPercentage
                : fillPercentage // ignore: cast_nullable_to_non_nullable
                      as int,
            checkedOn: null == checkedOn
                ? _value.checkedOn
                : checkedOn // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BinCheckImplCopyWith<$Res>
    implements $BinCheckCopyWith<$Res> {
  factory _$$BinCheckImplCopyWith(
    _$BinCheckImpl value,
    $Res Function(_$BinCheckImpl) then,
  ) = __$$BinCheckImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    @JsonKey(name: 'bin_id') String binId,
    @JsonKey(name: 'checked_from') String checkedFrom,
    @JsonKey(name: 'fill_percentage') int fillPercentage,
    @JsonKey(name: 'checked_on') DateTime checkedOn,
  });
}

/// @nodoc
class __$$BinCheckImplCopyWithImpl<$Res>
    extends _$BinCheckCopyWithImpl<$Res, _$BinCheckImpl>
    implements _$$BinCheckImplCopyWith<$Res> {
  __$$BinCheckImplCopyWithImpl(
    _$BinCheckImpl _value,
    $Res Function(_$BinCheckImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BinCheck
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? binId = null,
    Object? checkedFrom = null,
    Object? fillPercentage = null,
    Object? checkedOn = null,
  }) {
    return _then(
      _$BinCheckImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        binId: null == binId
            ? _value.binId
            : binId // ignore: cast_nullable_to_non_nullable
                  as String,
        checkedFrom: null == checkedFrom
            ? _value.checkedFrom
            : checkedFrom // ignore: cast_nullable_to_non_nullable
                  as String,
        fillPercentage: null == fillPercentage
            ? _value.fillPercentage
            : fillPercentage // ignore: cast_nullable_to_non_nullable
                  as int,
        checkedOn: null == checkedOn
            ? _value.checkedOn
            : checkedOn // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BinCheckImpl implements _BinCheck {
  const _$BinCheckImpl({
    required this.id,
    @JsonKey(name: 'bin_id') required this.binId,
    @JsonKey(name: 'checked_from') required this.checkedFrom,
    @JsonKey(name: 'fill_percentage') required this.fillPercentage,
    @JsonKey(name: 'checked_on') required this.checkedOn,
  });

  factory _$BinCheckImpl.fromJson(Map<String, dynamic> json) =>
      _$$BinCheckImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'bin_id')
  final String binId;
  @override
  @JsonKey(name: 'checked_from')
  final String checkedFrom;
  @override
  @JsonKey(name: 'fill_percentage')
  final int fillPercentage;
  @override
  @JsonKey(name: 'checked_on')
  final DateTime checkedOn;

  @override
  String toString() {
    return 'BinCheck(id: $id, binId: $binId, checkedFrom: $checkedFrom, fillPercentage: $fillPercentage, checkedOn: $checkedOn)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BinCheckImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.binId, binId) || other.binId == binId) &&
            (identical(other.checkedFrom, checkedFrom) ||
                other.checkedFrom == checkedFrom) &&
            (identical(other.fillPercentage, fillPercentage) ||
                other.fillPercentage == fillPercentage) &&
            (identical(other.checkedOn, checkedOn) ||
                other.checkedOn == checkedOn));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    binId,
    checkedFrom,
    fillPercentage,
    checkedOn,
  );

  /// Create a copy of BinCheck
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BinCheckImplCopyWith<_$BinCheckImpl> get copyWith =>
      __$$BinCheckImplCopyWithImpl<_$BinCheckImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BinCheckImplToJson(this);
  }
}

abstract class _BinCheck implements BinCheck {
  const factory _BinCheck({
    required final int id,
    @JsonKey(name: 'bin_id') required final String binId,
    @JsonKey(name: 'checked_from') required final String checkedFrom,
    @JsonKey(name: 'fill_percentage') required final int fillPercentage,
    @JsonKey(name: 'checked_on') required final DateTime checkedOn,
  }) = _$BinCheckImpl;

  factory _BinCheck.fromJson(Map<String, dynamic> json) =
      _$BinCheckImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'bin_id')
  String get binId;
  @override
  @JsonKey(name: 'checked_from')
  String get checkedFrom;
  @override
  @JsonKey(name: 'fill_percentage')
  int get fillPercentage;
  @override
  @JsonKey(name: 'checked_on')
  DateTime get checkedOn;

  /// Create a copy of BinCheck
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BinCheckImplCopyWith<_$BinCheckImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
