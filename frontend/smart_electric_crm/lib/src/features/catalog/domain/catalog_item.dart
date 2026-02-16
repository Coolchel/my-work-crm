import 'package:json_annotation/json_annotation.dart';

part 'catalog_item.g.dart';

@JsonSerializable()
class CatalogItem {
  final int id;
  final String name;
  final String unit;

  @JsonKey(name: 'default_price', fromJson: _priceFromJson)
  final double defaultPrice;

  @JsonKey(name: 'default_currency', defaultValue: 'USD')
  final String defaultCurrency;

  @JsonKey(name: 'item_type')
  final String itemType;

  final int? category;
  @JsonKey(name: 'mapping_key')
  final String? mappingKey;
  @JsonKey(name: 'aggregation_key')
  final String? aggregationKey;
  @JsonKey(name: 'related_work_item')
  final int? relatedWorkItem;
  @JsonKey(name: 'search_name', defaultValue: '')
  final String searchName;

  CatalogItem({
    required this.id,
    this.name = '',
    this.unit = '',
    this.defaultPrice = 0.0,
    this.defaultCurrency = 'USD',
    this.itemType = 'material',
    this.category,
    this.mappingKey,
    this.aggregationKey,
    this.relatedWorkItem,
    this.searchName = '',
  });

  static double _priceFromJson(dynamic json) {
    if (json == null) return 0.0;
    if (json is num) return json.toDouble();
    return double.tryParse(json.toString()) ?? 0.0;
  }

  factory CatalogItem.fromJson(Map<String, dynamic> json) =>
      _$CatalogItemFromJson(json);
  Map<String, dynamic> toJson() => _$CatalogItemToJson(this);
}
