// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shield_template_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShieldTemplateItemModel _$ShieldTemplateItemModelFromJson(
        Map<String, dynamic> json) =>
    ShieldTemplateItemModel(
      id: (json['id'] as num).toInt(),
      device: json['device'] as String,
      zone: json['zone'] as String,
      catalogItemId: (json['catalog_item'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ShieldTemplateItemModelToJson(
        ShieldTemplateItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'device': instance.device,
      'zone': instance.zone,
      'catalog_item': instance.catalogItemId,
    };

ShieldTemplateModel _$ShieldTemplateModelFromJson(Map<String, dynamic> json) =>
    ShieldTemplateModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  ShieldTemplateItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ShieldTemplateModelToJson(
        ShieldTemplateModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'items': instance.items,
    };
