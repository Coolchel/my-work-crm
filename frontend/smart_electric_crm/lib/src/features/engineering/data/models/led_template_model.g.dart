// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'led_template_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LedTemplateItemModel _$LedTemplateItemModelFromJson(
        Map<String, dynamic> json) =>
    LedTemplateItemModel(
      id: (json['id'] as num).toInt(),
      transformer: json['transformer'] as String,
      zone: json['zone'] as String,
      catalogItemId: (json['catalog_item'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LedTemplateItemModelToJson(
        LedTemplateItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'transformer': instance.transformer,
      'zone': instance.zone,
      'catalog_item': instance.catalogItemId,
    };

LedTemplateModel _$LedTemplateModelFromJson(Map<String, dynamic> json) =>
    LedTemplateModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  LedTemplateItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$LedTemplateModelToJson(LedTemplateModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'items': instance.items,
    };
