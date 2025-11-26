import 'package:freezed_annotation/freezed_annotation.dart';

part 'bin_check.freezed.dart';
part 'bin_check.g.dart';

@freezed
class BinCheck with _$BinCheck {
  const factory BinCheck({
    required int id,
    @JsonKey(name: 'bin_id') required String binId,
    @JsonKey(name: 'checked_from') required String checkedFrom,
    @JsonKey(name: 'fill_percentage') required int fillPercentage,
    @JsonKey(name: 'checked_on') required DateTime checkedOn,
  }) = _BinCheck;

  factory BinCheck.fromJson(Map<String, dynamic> json) =>
      _$BinCheckFromJson(json);
}
