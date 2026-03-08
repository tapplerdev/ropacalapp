// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RouteTemplate _$RouteTemplateFromJson(Map<String, dynamic> json) {
  return _RouteTemplate.fromJson(json);
}

/// @nodoc
mixin _$RouteTemplate {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'geographic_area')
  String get geographicArea => throw _privateConstructorUsedError;
  @JsonKey(name: 'bin_count')
  int get binCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'estimated_duration_hours')
  double? get estimatedDurationHours => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  int get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  int get updatedAt => throw _privateConstructorUsedError;
  List<RouteBin> get bins => throw _privateConstructorUsedError;

  /// Serializes this RouteTemplate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RouteTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RouteTemplateCopyWith<RouteTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RouteTemplateCopyWith<$Res> {
  factory $RouteTemplateCopyWith(
    RouteTemplate value,
    $Res Function(RouteTemplate) then,
  ) = _$RouteTemplateCopyWithImpl<$Res, RouteTemplate>;
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    @JsonKey(name: 'geographic_area') String geographicArea,
    @JsonKey(name: 'bin_count') int binCount,
    @JsonKey(name: 'estimated_duration_hours') double? estimatedDurationHours,
    @JsonKey(name: 'created_at') int createdAt,
    @JsonKey(name: 'updated_at') int updatedAt,
    List<RouteBin> bins,
  });
}

/// @nodoc
class _$RouteTemplateCopyWithImpl<$Res, $Val extends RouteTemplate>
    implements $RouteTemplateCopyWith<$Res> {
  _$RouteTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RouteTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? geographicArea = null,
    Object? binCount = null,
    Object? estimatedDurationHours = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? bins = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            geographicArea: null == geographicArea
                ? _value.geographicArea
                : geographicArea // ignore: cast_nullable_to_non_nullable
                      as String,
            binCount: null == binCount
                ? _value.binCount
                : binCount // ignore: cast_nullable_to_non_nullable
                      as int,
            estimatedDurationHours: freezed == estimatedDurationHours
                ? _value.estimatedDurationHours
                : estimatedDurationHours // ignore: cast_nullable_to_non_nullable
                      as double?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as int,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as int,
            bins: null == bins
                ? _value.bins
                : bins // ignore: cast_nullable_to_non_nullable
                      as List<RouteBin>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RouteTemplateImplCopyWith<$Res>
    implements $RouteTemplateCopyWith<$Res> {
  factory _$$RouteTemplateImplCopyWith(
    _$RouteTemplateImpl value,
    $Res Function(_$RouteTemplateImpl) then,
  ) = __$$RouteTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    @JsonKey(name: 'geographic_area') String geographicArea,
    @JsonKey(name: 'bin_count') int binCount,
    @JsonKey(name: 'estimated_duration_hours') double? estimatedDurationHours,
    @JsonKey(name: 'created_at') int createdAt,
    @JsonKey(name: 'updated_at') int updatedAt,
    List<RouteBin> bins,
  });
}

/// @nodoc
class __$$RouteTemplateImplCopyWithImpl<$Res>
    extends _$RouteTemplateCopyWithImpl<$Res, _$RouteTemplateImpl>
    implements _$$RouteTemplateImplCopyWith<$Res> {
  __$$RouteTemplateImplCopyWithImpl(
    _$RouteTemplateImpl _value,
    $Res Function(_$RouteTemplateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RouteTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? geographicArea = null,
    Object? binCount = null,
    Object? estimatedDurationHours = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? bins = null,
  }) {
    return _then(
      _$RouteTemplateImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        geographicArea: null == geographicArea
            ? _value.geographicArea
            : geographicArea // ignore: cast_nullable_to_non_nullable
                  as String,
        binCount: null == binCount
            ? _value.binCount
            : binCount // ignore: cast_nullable_to_non_nullable
                  as int,
        estimatedDurationHours: freezed == estimatedDurationHours
            ? _value.estimatedDurationHours
            : estimatedDurationHours // ignore: cast_nullable_to_non_nullable
                  as double?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as int,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as int,
        bins: null == bins
            ? _value._bins
            : bins // ignore: cast_nullable_to_non_nullable
                  as List<RouteBin>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RouteTemplateImpl implements _RouteTemplate {
  const _$RouteTemplateImpl({
    required this.id,
    required this.name,
    this.description,
    @JsonKey(name: 'geographic_area') this.geographicArea = '',
    @JsonKey(name: 'bin_count') this.binCount = 0,
    @JsonKey(name: 'estimated_duration_hours') this.estimatedDurationHours,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'updated_at') required this.updatedAt,
    final List<RouteBin> bins = const [],
  }) : _bins = bins;

  factory _$RouteTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$RouteTemplateImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  @JsonKey(name: 'geographic_area')
  final String geographicArea;
  @override
  @JsonKey(name: 'bin_count')
  final int binCount;
  @override
  @JsonKey(name: 'estimated_duration_hours')
  final double? estimatedDurationHours;
  @override
  @JsonKey(name: 'created_at')
  final int createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final int updatedAt;
  final List<RouteBin> _bins;
  @override
  @JsonKey()
  List<RouteBin> get bins {
    if (_bins is EqualUnmodifiableListView) return _bins;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bins);
  }

  @override
  String toString() {
    return 'RouteTemplate(id: $id, name: $name, description: $description, geographicArea: $geographicArea, binCount: $binCount, estimatedDurationHours: $estimatedDurationHours, createdAt: $createdAt, updatedAt: $updatedAt, bins: $bins)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RouteTemplateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.geographicArea, geographicArea) ||
                other.geographicArea == geographicArea) &&
            (identical(other.binCount, binCount) ||
                other.binCount == binCount) &&
            (identical(other.estimatedDurationHours, estimatedDurationHours) ||
                other.estimatedDurationHours == estimatedDurationHours) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other._bins, _bins));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    geographicArea,
    binCount,
    estimatedDurationHours,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_bins),
  );

  /// Create a copy of RouteTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RouteTemplateImplCopyWith<_$RouteTemplateImpl> get copyWith =>
      __$$RouteTemplateImplCopyWithImpl<_$RouteTemplateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RouteTemplateImplToJson(this);
  }
}

abstract class _RouteTemplate implements RouteTemplate {
  const factory _RouteTemplate({
    required final String id,
    required final String name,
    final String? description,
    @JsonKey(name: 'geographic_area') final String geographicArea,
    @JsonKey(name: 'bin_count') final int binCount,
    @JsonKey(name: 'estimated_duration_hours')
    final double? estimatedDurationHours,
    @JsonKey(name: 'created_at') required final int createdAt,
    @JsonKey(name: 'updated_at') required final int updatedAt,
    final List<RouteBin> bins,
  }) = _$RouteTemplateImpl;

  factory _RouteTemplate.fromJson(Map<String, dynamic> json) =
      _$RouteTemplateImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  @JsonKey(name: 'geographic_area')
  String get geographicArea;
  @override
  @JsonKey(name: 'bin_count')
  int get binCount;
  @override
  @JsonKey(name: 'estimated_duration_hours')
  double? get estimatedDurationHours;
  @override
  @JsonKey(name: 'created_at')
  int get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  int get updatedAt;
  @override
  List<RouteBin> get bins;

  /// Create a copy of RouteTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RouteTemplateImplCopyWith<_$RouteTemplateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RouteBin _$RouteBinFromJson(Map<String, dynamic> json) {
  return _RouteBin.fromJson(json);
}

/// @nodoc
mixin _$RouteBin {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'bin_number')
  int get binNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_street')
  String get currentStreet => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get zip => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'fill_percentage')
  int? get fillPercentage => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'sequence_order')
  int get sequenceOrder => throw _privateConstructorUsedError;

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
    @JsonKey(name: 'bin_number') int binNumber,
    @JsonKey(name: 'current_street') String currentStreet,
    String city,
    String zip,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'fill_percentage') int? fillPercentage,
    String status,
    @JsonKey(name: 'sequence_order') int sequenceOrder,
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
    Object? binNumber = null,
    Object? currentStreet = null,
    Object? city = null,
    Object? zip = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? fillPercentage = freezed,
    Object? status = null,
    Object? sequenceOrder = null,
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
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            fillPercentage: freezed == fillPercentage
                ? _value.fillPercentage
                : fillPercentage // ignore: cast_nullable_to_non_nullable
                      as int?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            sequenceOrder: null == sequenceOrder
                ? _value.sequenceOrder
                : sequenceOrder // ignore: cast_nullable_to_non_nullable
                      as int,
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
    @JsonKey(name: 'bin_number') int binNumber,
    @JsonKey(name: 'current_street') String currentStreet,
    String city,
    String zip,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'fill_percentage') int? fillPercentage,
    String status,
    @JsonKey(name: 'sequence_order') int sequenceOrder,
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
    Object? binNumber = null,
    Object? currentStreet = null,
    Object? city = null,
    Object? zip = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? fillPercentage = freezed,
    Object? status = null,
    Object? sequenceOrder = null,
  }) {
    return _then(
      _$RouteBinImpl(
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
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        fillPercentage: freezed == fillPercentage
            ? _value.fillPercentage
            : fillPercentage // ignore: cast_nullable_to_non_nullable
                  as int?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        sequenceOrder: null == sequenceOrder
            ? _value.sequenceOrder
            : sequenceOrder // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RouteBinImpl extends _RouteBin {
  const _$RouteBinImpl({
    required this.id,
    @JsonKey(name: 'bin_number') required this.binNumber,
    @JsonKey(name: 'current_street') this.currentStreet = '',
    this.city = '',
    this.zip = '',
    this.latitude,
    this.longitude,
    @JsonKey(name: 'fill_percentage') this.fillPercentage,
    this.status = 'active',
    @JsonKey(name: 'sequence_order') this.sequenceOrder = 0,
  }) : super._();

  factory _$RouteBinImpl.fromJson(Map<String, dynamic> json) =>
      _$$RouteBinImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'bin_number')
  final int binNumber;
  @override
  @JsonKey(name: 'current_street')
  final String currentStreet;
  @override
  @JsonKey()
  final String city;
  @override
  @JsonKey()
  final String zip;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  @JsonKey(name: 'fill_percentage')
  final int? fillPercentage;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'sequence_order')
  final int sequenceOrder;

  @override
  String toString() {
    return 'RouteBin(id: $id, binNumber: $binNumber, currentStreet: $currentStreet, city: $city, zip: $zip, latitude: $latitude, longitude: $longitude, fillPercentage: $fillPercentage, status: $status, sequenceOrder: $sequenceOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RouteBinImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.binNumber, binNumber) ||
                other.binNumber == binNumber) &&
            (identical(other.currentStreet, currentStreet) ||
                other.currentStreet == currentStreet) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.zip, zip) || other.zip == zip) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.fillPercentage, fillPercentage) ||
                other.fillPercentage == fillPercentage) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.sequenceOrder, sequenceOrder) ||
                other.sequenceOrder == sequenceOrder));
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
    latitude,
    longitude,
    fillPercentage,
    status,
    sequenceOrder,
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

abstract class _RouteBin extends RouteBin {
  const factory _RouteBin({
    required final String id,
    @JsonKey(name: 'bin_number') required final int binNumber,
    @JsonKey(name: 'current_street') final String currentStreet,
    final String city,
    final String zip,
    final double? latitude,
    final double? longitude,
    @JsonKey(name: 'fill_percentage') final int? fillPercentage,
    final String status,
    @JsonKey(name: 'sequence_order') final int sequenceOrder,
  }) = _$RouteBinImpl;
  const _RouteBin._() : super._();

  factory _RouteBin.fromJson(Map<String, dynamic> json) =
      _$RouteBinImpl.fromJson;

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
  double? get latitude;
  @override
  double? get longitude;
  @override
  @JsonKey(name: 'fill_percentage')
  int? get fillPercentage;
  @override
  String get status;
  @override
  @JsonKey(name: 'sequence_order')
  int get sequenceOrder;

  /// Create a copy of RouteBin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RouteBinImplCopyWith<_$RouteBinImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
