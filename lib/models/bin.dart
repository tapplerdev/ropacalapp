import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ropacalapp/core/enums/bin_status.dart';

part 'bin.freezed.dart';
part 'bin.g.dart';

@freezed
class Bin with _$Bin {
  const factory Bin({
    required String id,
    @JsonKey(name: 'bin_number') required int binNumber,
    @JsonKey(name: 'current_street') required String currentStreet,
    required String city,
    required String zip,
    @JsonKey(name: 'last_moved') DateTime? lastMoved,
    @JsonKey(name: 'last_checked') DateTime? lastChecked,
    required BinStatus status,
    @JsonKey(name: 'fill_percentage') int? fillPercentage,
    @Default(false) bool checked,
    @JsonKey(name: 'move_requested') @Default(false) bool moveRequested,
    double? latitude,
    double? longitude,
  }) = _Bin;

  factory Bin.fromJson(Map<String, dynamic> json) => _$BinFromJson(json);
}
