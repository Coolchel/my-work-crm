// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectModel _$ProjectModelFromJson(Map<String, dynamic> json) => ProjectModel(
      id: (json['id'] as num).toInt(),
      address: json['address'] as String,
      objectType: json['object_type'] as String,
      status: json['status'] as String,
      intercomCode: json['intercom_code'] as String? ?? '',
      clientInfo: json['client_info'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      stages: (json['stages'] as List<dynamic>)
          .map((e) => StageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      internetLinesCount: (json['internet_lines_count'] as num?)?.toInt() ?? 0,
      multimediaNotes: json['multimedia_notes'] as String? ?? '',
      suggestedInternetShield:
          json['suggested_internet_shield'] as String? ?? '',
      ledShieldSize: json['led_shield_size'] as String?,
    );

Map<String, dynamic> _$ProjectModelToJson(ProjectModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'address': instance.address,
      'object_type': instance.objectType,
      'status': instance.status,
      'intercom_code': instance.intercomCode,
      'client_info': instance.clientInfo,
      'created_at': instance.createdAt.toIso8601String(),
      'internet_lines_count': instance.internetLinesCount,
      'multimedia_notes': instance.multimediaNotes,
      'suggested_internet_shield': instance.suggestedInternetShield,
      'led_shield_size': instance.ledShieldSize,
      'stages': instance.stages,
    };
