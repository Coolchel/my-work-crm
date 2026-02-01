// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shield_group_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShieldGroupModel _$ShieldGroupModelFromJson(Map<String, dynamic> json) =>
    ShieldGroupModel(
      id: (json['id'] as num).toInt(),
      device: json['device'] as String? ?? '',
      zone: json['zone'] as String,
      deviceType: json['device_type'] as String? ?? 'circuit_breaker',
      rating: json['rating'] as String? ?? '16A',
      poles: json['poles'] as String? ?? '1P',
      modulesCount: (json['modules_count'] as num?)?.toInt() ?? 1,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      catalogItemId: (json['catalog_item'] as num?)?.toInt(),
      shieldId: (json['shield'] as num).toInt(),
    );

Map<String, dynamic> _$ShieldGroupModelToJson(ShieldGroupModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'device': instance.device,
      'zone': instance.zone,
      'device_type': instance.deviceType,
      'rating': instance.rating,
      'poles': instance.poles,
      'modules_count': instance.modulesCount,
      'quantity': instance.quantity,
      'catalog_item': instance.catalogItemId,
      'shield': instance.shieldId,
    };
