// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkTemplateImpl _$$WorkTemplateImplFromJson(Map<String, dynamic> json) =>
    _$WorkTemplateImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => WorkTemplateItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$WorkTemplateImplToJson(_$WorkTemplateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'items': instance.items,
    };

_$WorkTemplateItemImpl _$$WorkTemplateItemImplFromJson(
        Map<String, dynamic> json) =>
    _$WorkTemplateItemImpl(
      id: (json['id'] as num).toInt(),
      catalogItemId: (json['catalog_item'] as num).toInt(),
      catalogItemName: json['catalog_item_name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$$WorkTemplateItemImplToJson(
        _$WorkTemplateItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'catalog_item': instance.catalogItemId,
      'catalog_item_name': instance.catalogItemName,
      'quantity': instance.quantity,
    };

_$MaterialTemplateImpl _$$MaterialTemplateImplFromJson(
        Map<String, dynamic> json) =>
    _$MaterialTemplateImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  MaterialTemplateItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$MaterialTemplateImplToJson(
        _$MaterialTemplateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'items': instance.items,
    };

_$MaterialTemplateItemImpl _$$MaterialTemplateItemImplFromJson(
        Map<String, dynamic> json) =>
    _$MaterialTemplateItemImpl(
      id: (json['id'] as num).toInt(),
      catalogItemId: (json['catalog_item'] as num).toInt(),
      catalogItemName: json['catalog_item_name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$$MaterialTemplateItemImplToJson(
        _$MaterialTemplateItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'catalog_item': instance.catalogItemId,
      'catalog_item_name': instance.catalogItemName,
      'quantity': instance.quantity,
    };

_$PowerShieldTemplateImpl _$$PowerShieldTemplateImplFromJson(
        Map<String, dynamic> json) =>
    _$PowerShieldTemplateImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  PowerShieldTemplateItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$PowerShieldTemplateImplToJson(
        _$PowerShieldTemplateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'items': instance.items,
    };

_$PowerShieldTemplateItemImpl _$$PowerShieldTemplateItemImplFromJson(
        Map<String, dynamic> json) =>
    _$PowerShieldTemplateItemImpl(
      id: (json['id'] as num).toInt(),
      deviceType: json['device_type'] as String,
      rating: json['rating'] as String? ?? '16A',
      poles: json['poles'] as String? ?? '1P',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      catalogItemId: (json['catalog_item'] as num?)?.toInt(),
      catalogItemName: json['catalog_item_name'] as String?,
    );

Map<String, dynamic> _$$PowerShieldTemplateItemImplToJson(
        _$PowerShieldTemplateItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'device_type': instance.deviceType,
      'rating': instance.rating,
      'poles': instance.poles,
      'quantity': instance.quantity,
      'catalog_item': instance.catalogItemId,
      'catalog_item_name': instance.catalogItemName,
    };

_$MultimediaTemplateImpl _$$MultimediaTemplateImplFromJson(
        Map<String, dynamic> json) =>
    _$MultimediaTemplateImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  MultimediaTemplateItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$MultimediaTemplateImplToJson(
        _$MultimediaTemplateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'items': instance.items,
    };

_$MultimediaTemplateItemImpl _$$MultimediaTemplateItemImplFromJson(
        Map<String, dynamic> json) =>
    _$MultimediaTemplateItemImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      catalogItemId: (json['catalog_item'] as num?)?.toInt(),
      catalogItemName: json['catalog_item_name'] as String?,
    );

Map<String, dynamic> _$$MultimediaTemplateItemImplToJson(
        _$MultimediaTemplateItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'quantity': instance.quantity,
      'catalog_item': instance.catalogItemId,
      'catalog_item_name': instance.catalogItemName,
    };
