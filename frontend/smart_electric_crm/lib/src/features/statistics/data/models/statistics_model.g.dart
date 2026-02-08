// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StatisticsModelImpl _$$StatisticsModelImplFromJson(
        Map<String, dynamic> json) =>
    _$StatisticsModelImpl(
      pipeline: PipelineData.fromJson(json['pipeline'] as Map<String, dynamic>),
      sources: (json['sources'] as List<dynamic>)
          .map((e) => SourceData.fromJson(e as Map<String, dynamic>))
          .toList(),
      objectTypes: (json['object_types'] as List<dynamic>)
          .map((e) => ObjectTypeData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$StatisticsModelImplToJson(
        _$StatisticsModelImpl instance) =>
    <String, dynamic>{
      'pipeline': instance.pipeline,
      'sources': instance.sources,
      'object_types': instance.objectTypes,
    };

_$PipelineDataImpl _$$PipelineDataImplFromJson(Map<String, dynamic> json) =>
    _$PipelineDataImpl(
      paid: CurrencyAmount.fromJson(json['paid'] as Map<String, dynamic>),
      pending: CurrencyAmount.fromJson(json['pending'] as Map<String, dynamic>),
      inWork: CurrencyAmount.fromJson(json['in_work'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$PipelineDataImplToJson(_$PipelineDataImpl instance) =>
    <String, dynamic>{
      'paid': instance.paid,
      'pending': instance.pending,
      'in_work': instance.inWork,
    };

_$CurrencyAmountImpl _$$CurrencyAmountImplFromJson(Map<String, dynamic> json) =>
    _$CurrencyAmountImpl(
      usd: (json['usd'] as num).toDouble(),
      byn: (json['byn'] as num).toDouble(),
    );

Map<String, dynamic> _$$CurrencyAmountImplToJson(
        _$CurrencyAmountImpl instance) =>
    <String, dynamic>{
      'usd': instance.usd,
      'byn': instance.byn,
    };

_$SourceDataImpl _$$SourceDataImplFromJson(Map<String, dynamic> json) =>
    _$SourceDataImpl(
      name: json['name'] as String,
      count: (json['count'] as num).toInt(),
      usd: (json['usd'] as num).toDouble(),
      byn: (json['byn'] as num).toDouble(),
    );

Map<String, dynamic> _$$SourceDataImplToJson(_$SourceDataImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'count': instance.count,
      'usd': instance.usd,
      'byn': instance.byn,
    };

_$ObjectTypeDataImpl _$$ObjectTypeDataImplFromJson(Map<String, dynamic> json) =>
    _$ObjectTypeDataImpl(
      name: json['name'] as String,
      count: (json['count'] as num).toInt(),
      usd: (json['usd'] as num).toDouble(),
      byn: (json['byn'] as num).toDouble(),
    );

Map<String, dynamic> _$$ObjectTypeDataImplToJson(
        _$ObjectTypeDataImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'count': instance.count,
      'usd': instance.usd,
      'byn': instance.byn,
    };
