// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shield_group_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShieldGroupModel _$ShieldGroupModelFromJson(Map<String, dynamic> json) =>
    ShieldGroupModel(
      id: (json['id'] as num).toInt(),
      device: json['device'] as String,
      zone: json['zone'] as String,
      catalogItemId: (json['catalog_item'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ShieldGroupModelToJson(ShieldGroupModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'device': instance.device,
      'zone': instance.zone,
      'catalog_item': instance.catalogItemId,
    };
