import 'package:json_annotation/json_annotation.dart';

part 'shield_template_model.g.dart';

@JsonSerializable()
class ShieldTemplateItemModel {
  final int id;
  final String device;
  final String zone;

  @JsonKey(name: 'catalog_item')
  final int? catalogItemId;

  ShieldTemplateItemModel({
    required this.id,
    required this.device,
    required this.zone,
    this.catalogItemId,
  });

  factory ShieldTemplateItemModel.fromJson(Map<String, dynamic> json) =>
      _$ShieldTemplateItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$ShieldTemplateItemModelToJson(this);
}

@JsonSerializable()
class ShieldTemplateModel {
  final int id;
  final String name;
  final String description;
  final List<ShieldTemplateItemModel> items;

  ShieldTemplateModel({
    required this.id,
    required this.name,
    this.description = '',
    this.items = const [],
  });

  factory ShieldTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$ShieldTemplateModelFromJson(json);

  Map<String, dynamic> toJson() => _$ShieldTemplateModelToJson(this);
}
