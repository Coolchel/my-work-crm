// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unpaid_project_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnpaidStageModel _$UnpaidStageModelFromJson(Map<String, dynamic> json) =>
    UnpaidStageModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      titleDisplay: json['title_display'] as String,
      ourAmountUsd: (json['our_amount_usd'] as num).toDouble(),
      ourAmountByn: (json['our_amount_byn'] as num).toDouble(),
      externalAmountUsd:
          (json['external_amount_usd'] as num?)?.toDouble() ?? 0.0,
      externalAmountByn:
          (json['external_amount_byn'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$UnpaidStageModelToJson(UnpaidStageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'title_display': instance.titleDisplay,
      'our_amount_usd': instance.ourAmountUsd,
      'our_amount_byn': instance.ourAmountByn,
      'external_amount_usd': instance.externalAmountUsd,
      'external_amount_byn': instance.externalAmountByn,
      'updated_at': instance.updatedAt,
    };

UnpaidProjectModel _$UnpaidProjectModelFromJson(Map<String, dynamic> json) =>
    UnpaidProjectModel(
      id: (json['id'] as num).toInt(),
      address: json['address'] as String,
      status: json['status'] as String,
      source: json['source'] as String?,
      totalUsd: (json['total_usd'] as num).toDouble(),
      totalByn: (json['total_byn'] as num).toDouble(),
      stages: (json['stages'] as List<dynamic>)
          .map((e) => UnpaidStageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UnpaidProjectModelToJson(UnpaidProjectModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'address': instance.address,
      'status': instance.status,
      'source': instance.source,
      'total_usd': instance.totalUsd,
      'total_byn': instance.totalByn,
      'stages': instance.stages,
    };

UnpaidProjectsResponse _$UnpaidProjectsResponseFromJson(
        Map<String, dynamic> json) =>
    UnpaidProjectsResponse(
      totalUsd: (json['total_usd'] as num).toDouble(),
      totalByn: (json['total_byn'] as num).toDouble(),
      projects: (json['projects'] as List<dynamic>)
          .map((e) => UnpaidProjectModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UnpaidProjectsResponseToJson(
        UnpaidProjectsResponse instance) =>
    <String, dynamic>{
      'total_usd': instance.totalUsd,
      'total_byn': instance.totalByn,
      'projects': instance.projects,
    };
