import 'package:json_annotation/json_annotation.dart';

part 'category_model.g.dart';

@JsonSerializable()
class CatalogCategory {
  final int id;
  final String name;
  final String slug;

  // В Python: labor_coefficient (snake_case)
  // В Dart: laborCoefficient (camelCase)
  // @JsonKey связывает их
  @JsonKey(name: 'labor_coefficient')
  final double laborCoefficient;

  CatalogCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.laborCoefficient = 1.0,
  });

  // Магия превращения JSON в объект
  factory CatalogCategory.fromJson(Map<String, dynamic> json) =>
      _$CatalogCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$CatalogCategoryToJson(this);
}
