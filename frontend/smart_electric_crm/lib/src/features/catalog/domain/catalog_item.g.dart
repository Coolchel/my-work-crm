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
      itemType: json['item_type'] as String? ?? 'material',
      category: (json['category'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CatalogItemToJson(CatalogItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'unit': instance.unit,
      'default_price': instance.defaultPrice,
      'item_type': instance.itemType,
      'category': instance.category,
    };
