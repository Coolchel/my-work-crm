import 'package:json_annotation/json_annotation.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';

part 'estimate_template_model.g.dart';

@JsonSerializable()
class EstimateTemplateModel {
  final int id;
  final String name;
  final String? description;
  final List<TemplateItemModel> items;

  EstimateTemplateModel({
    required this.id,
    required this.name,
    this.description,
    this.items = const [],
  });

  factory EstimateTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$EstimateTemplateModelFromJson(json);
  Map<String, dynamic> toJson() => _$EstimateTemplateModelToJson(this);
}

@JsonSerializable()
class TemplateItemModel {
  final int id;
  @JsonKey(name: 'catalog_item')
  final CatalogItem? catalogItem;

  // При импорте мы берем данные из каталога, но шаблон может переопределять кол-во?
  // В модели Django: TemplateItem(template, catalog_item, quantity...)
  // Проверим бэкенд?
  // Бекенд core/models.py: TemplateItem(catalog_item, quantity, ...)

  @JsonKey(defaultValue: 1.0)
  final double quantity;

  TemplateItemModel({
    required this.id,
    this.catalogItem,
    this.quantity = 1.0,
  });

  factory TemplateItemModel.fromJson(Map<String, dynamic> json) =>
      _$TemplateItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$TemplateItemModelToJson(this);
}
