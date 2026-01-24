import 'package:json_annotation/json_annotation.dart';

part 'led_template_model.g.dart';

@JsonSerializable()
class LedTemplateItemModel {
  final int id;
  final String transformer;
  final String zone;

  @JsonKey(name: 'catalog_item')
  final int? catalogItemId;

  LedTemplateItemModel({
    required this.id,
    required this.transformer,
    required this.zone,
    this.catalogItemId,
  });

  factory LedTemplateItemModel.fromJson(Map<String, dynamic> json) =>
      _$LedTemplateItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$LedTemplateItemModelToJson(this);
}

@JsonSerializable()
class LedTemplateModel {
  final int id;
  final String name;
  final String description;
  final List<LedTemplateItemModel> items;

  LedTemplateModel({
    required this.id,
    required this.name,
    this.description = '',
    this.items = const [],
  });

  factory LedTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$LedTemplateModelFromJson(json);

  Map<String, dynamic> toJson() => _$LedTemplateModelToJson(this);
}
