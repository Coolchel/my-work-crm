// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogCategory _$CatalogCategoryFromJson(Map<String, dynamic> json) =>
    CatalogCategory(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      slug: json['slug'] as String,
      laborCoefficient: (json['labor_coefficient'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$CatalogCategoryToJson(CatalogCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'labor_coefficient': instance.laborCoefficient,
    };
