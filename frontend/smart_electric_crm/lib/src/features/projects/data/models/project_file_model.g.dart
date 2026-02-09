// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_file_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectFileModel _$ProjectFileModelFromJson(Map<String, dynamic> json) =>
    ProjectFileModel(
      id: (json['id'] as num).toInt(),
      project: (json['project'] as num).toInt(),
      file: json['file'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      originalName: json['original_name'] as String? ?? '',
    );

Map<String, dynamic> _$ProjectFileModelToJson(ProjectFileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'project': instance.project,
      'file': instance.file,
      'description': instance.description,
      'category': instance.category,
      'original_name': instance.originalName,
    };
