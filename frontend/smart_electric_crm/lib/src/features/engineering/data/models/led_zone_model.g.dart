// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'led_zone_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LedZoneModel _$LedZoneModelFromJson(Map<String, dynamic> json) => LedZoneModel(
      id: (json['id'] as num).toInt(),
      transformer: json['transformer'] as String,
      zone: json['zone'] as String,
      catalogItemId: (json['catalog_item'] as num?)?.toInt(),
      shieldId: (json['shield'] as num).toInt(),
    );

Map<String, dynamic> _$LedZoneModelToJson(LedZoneModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'transformer': instance.transformer,
      'zone': instance.zone,
      'catalog_item': instance.catalogItemId,
      'shield': instance.shieldId,
    };
