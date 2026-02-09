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
      shields: (json['shields'] as List<dynamic>?)
              ?.map((e) => ShieldModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      files: (json['files'] as List<dynamic>?)
              ?.map((e) => ProjectFileModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
      'stages': instance.stages,
      'shields': instance.shields,
      'files': instance.files,
    };
