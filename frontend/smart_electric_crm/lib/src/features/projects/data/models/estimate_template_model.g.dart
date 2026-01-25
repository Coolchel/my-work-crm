// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'estimate_template_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EstimateTemplateModel _$EstimateTemplateModelFromJson(
        Map<String, dynamic> json) =>
    EstimateTemplateModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map(
                  (e) => TemplateItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$EstimateTemplateModelToJson(
        EstimateTemplateModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'items': instance.items,
    };

TemplateItemModel _$TemplateItemModelFromJson(Map<String, dynamic> json) =>
    TemplateItemModel(
      id: (json['id'] as num).toInt(),
      catalogItem: json['catalog_item'] == null
          ? null
          : CatalogItem.fromJson(json['catalog_item'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$TemplateItemModelToJson(TemplateItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'catalog_item': instance.catalogItem,
      'quantity': instance.quantity,
    };
