// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shield_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShieldModel _$ShieldModelFromJson(Map<String, dynamic> json) => ShieldModel(
      id: (json['id'] as num).toInt(),
      projectId: (json['project'] as num).toInt(),
      name: json['name'] as String,
      shieldType: json['shield_type'] as String,
      mounting: json['mounting'] as String,
      groups: (json['groups'] as List<dynamic>?)
              ?.map((e) => ShieldGroupModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ledZones: (json['led_zones'] as List<dynamic>?)
              ?.map((e) => LedZoneModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      internetLinesCount: (json['internet_lines_count'] as num?)?.toInt() ?? 0,
      multimediaNotes: json['multimedia_notes'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      suggestedSize: json['suggested_size'] as String?,
    );

Map<String, dynamic> _$ShieldModelToJson(ShieldModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'project': instance.projectId,
      'name': instance.name,
      'shield_type': instance.shieldType,
      'mounting': instance.mounting,
      'groups': instance.groups,
      'led_zones': instance.ledZones,
      'internet_lines_count': instance.internetLinesCount,
      'multimedia_notes': instance.multimediaNotes,
      'notes': instance.notes,
      'suggested_size': instance.suggestedSize,
    };
