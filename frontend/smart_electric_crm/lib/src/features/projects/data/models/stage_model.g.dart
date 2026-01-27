// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stage_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StageModel _$StageModelFromJson(Map<String, dynamic> json) => StageModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      status: json['status'] as String,
      isPaid: json['is_paid'] as bool,
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] == null
          ? null
          : DateTime.parse(json['ended_at'] as String),
      estimateItems: (json['estimate_items'] as List<dynamic>?)
              ?.map(
                  (e) => EstimateItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      workNotes: json['work_notes'] as String? ?? '',
      materialNotes: json['material_notes'] as String? ?? '',
    );

Map<String, dynamic> _$StageModelToJson(StageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'status': instance.status,
      'is_paid': instance.isPaid,
      'started_at': instance.startedAt?.toIso8601String(),
      'ended_at': instance.endedAt?.toIso8601String(),
      'work_notes': instance.workNotes,
      'material_notes': instance.materialNotes,
      'estimate_items': instance.estimateItems,
    };
