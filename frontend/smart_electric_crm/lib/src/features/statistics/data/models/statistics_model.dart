import 'package:freezed_annotation/freezed_annotation.dart';

part 'statistics_model.freezed.dart';
part 'statistics_model.g.dart';

@freezed
class StatisticsModel with _$StatisticsModel {
  const factory StatisticsModel({
    required PipelineData pipeline,
    required List<SourceData> sources,
    @JsonKey(name: 'object_types') required List<ObjectTypeData> objectTypes,
  }) = _StatisticsModel;

  factory StatisticsModel.fromJson(Map<String, dynamic> json) =>
      _$StatisticsModelFromJson(json);
}

@freezed
class PipelineData with _$PipelineData {
  const factory PipelineData({
    required CurrencyAmount paid,
    required CurrencyAmount pending,
    @JsonKey(name: 'in_work') required CurrencyAmount inWork,
  }) = _PipelineData;

  factory PipelineData.fromJson(Map<String, dynamic> json) =>
      _$PipelineDataFromJson(json);
}

@freezed
class CurrencyAmount with _$CurrencyAmount {
  const factory CurrencyAmount({
    required double usd,
    required double byn,
  }) = _CurrencyAmount;

  factory CurrencyAmount.fromJson(Map<String, dynamic> json) =>
      _$CurrencyAmountFromJson(json);
}

@freezed
class SourceData with _$SourceData {
  const factory SourceData({
    required String name,
    required int count,
    required double usd,
    required double byn,
  }) = _SourceData;

  factory SourceData.fromJson(Map<String, dynamic> json) =>
      _$SourceDataFromJson(json);
}

@freezed
class ObjectTypeData with _$ObjectTypeData {
  const factory ObjectTypeData({
    required String name,
    required int count,
    required double usd,
    required double byn,
  }) = _ObjectTypeData;

  factory ObjectTypeData.fromJson(Map<String, dynamic> json) =>
      _$ObjectTypeDataFromJson(json);
}
