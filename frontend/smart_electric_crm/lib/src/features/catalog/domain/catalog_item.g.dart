// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogItem _$CatalogItemFromJson(Map<String, dynamic> json) => CatalogItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      defaultPrice: json['default_price'] == null
          ? 0.0
          : CatalogItem._priceFromJson(json['default_price']),
      defaultCurrency: json['default_currency'] as String? ?? 'USD',
      itemType: json['item_type'] as String? ?? 'material',
      category: (json['category'] as num?)?.toInt(),
      mappingKey: json['mapping_key'] as String?,
      aggregationKey: json['aggregation_key'] as String?,
      relatedWorkItem: (json['related_work_item'] as num?)?.toInt(),
      searchName: json['search_name'] as String? ?? '',
    );

Map<String, dynamic> _$CatalogItemToJson(CatalogItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'unit': instance.unit,
      'default_price': instance.defaultPrice,
      'default_currency': instance.defaultCurrency,
      'item_type': instance.itemType,
      'category': instance.category,
      'mapping_key': instance.mappingKey,
      'aggregation_key': instance.aggregationKey,
      'related_work_item': instance.relatedWorkItem,
      'search_name': instance.searchName,
    };
