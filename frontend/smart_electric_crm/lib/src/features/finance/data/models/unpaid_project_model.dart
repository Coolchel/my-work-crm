import 'package:json_annotation/json_annotation.dart';

part 'unpaid_project_model.g.dart';

/// Модель этапа для финансового монитора
@JsonSerializable()
class UnpaidStageModel {
  final int id;
  final String title;

  @JsonKey(name: 'title_display')
  final String titleDisplay;

  @JsonKey(name: 'our_amount_usd')
  final double ourAmountUsd;

  @JsonKey(name: 'our_amount_byn')
  final double ourAmountByn;

  UnpaidStageModel({
    required this.id,
    required this.title,
    required this.titleDisplay,
    required this.ourAmountUsd,
    required this.ourAmountByn,
  });

  factory UnpaidStageModel.fromJson(Map<String, dynamic> json) =>
      _$UnpaidStageModelFromJson(json);

  Map<String, dynamic> toJson() => _$UnpaidStageModelToJson(this);
}

/// Модель проекта для финансового монитора
@JsonSerializable()
class UnpaidProjectModel {
  final int id;
  final String address;
  final String status;

  @JsonKey(name: 'total_usd')
  final double totalUsd;

  @JsonKey(name: 'total_byn')
  final double totalByn;

  final List<UnpaidStageModel> stages;

  UnpaidProjectModel({
    required this.id,
    required this.address,
    required this.status,
    required this.totalUsd,
    required this.totalByn,
    required this.stages,
  });

  factory UnpaidProjectModel.fromJson(Map<String, dynamic> json) =>
      _$UnpaidProjectModelFromJson(json);

  Map<String, dynamic> toJson() => _$UnpaidProjectModelToJson(this);
}

/// Модель ответа API финансового монитора
@JsonSerializable()
class UnpaidProjectsResponse {
  @JsonKey(name: 'total_usd')
  final double totalUsd;

  @JsonKey(name: 'total_byn')
  final double totalByn;

  final List<UnpaidProjectModel> projects;

  UnpaidProjectsResponse({
    required this.totalUsd,
    required this.totalByn,
    required this.projects,
  });

  factory UnpaidProjectsResponse.fromJson(Map<String, dynamic> json) =>
      _$UnpaidProjectsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UnpaidProjectsResponseToJson(this);
}
