// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StatisticsModelImpl _$$StatisticsModelImplFromJson(
        Map<String, dynamic> json) =>
    _$StatisticsModelImpl(
      finances:
          CurrencyAmount.fromJson(json['finances'] as Map<String, dynamic>),
      sources: (json['sources'] as List<dynamic>)
          .map((e) => SourceData.fromJson(e as Map<String, dynamic>))
          .toList(),
      objectTypes: (json['object_types'] as List<dynamic>)
          .map((e) => ObjectTypeData.fromJson(e as Map<String, dynamic>))
          .toList(),
      workDynamics: (json['work_dynamics'] as List<dynamic>)
          .map((e) => WorkDynamicsData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$StatisticsModelImplToJson(
        _$StatisticsModelImpl instance) =>
    <String, dynamic>{
      'finances': instance.finances,
      'sources': instance.sources,
      'object_types': instance.objectTypes,
      'work_dynamics': instance.workDynamics,
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

_$WorkDynamicsDataImpl _$$WorkDynamicsDataImplFromJson(
        Map<String, dynamic> json) =>
    _$WorkDynamicsDataImpl(
      date: json['date'] as String,
      usd: (json['usd'] as num).toDouble(),
      byn: (json['byn'] as num).toDouble(),
    );

Map<String, dynamic> _$$WorkDynamicsDataImplToJson(
        _$WorkDynamicsDataImpl instance) =>
    <String, dynamic>{
      'date': instance.date,
      'usd': instance.usd,
      'byn': instance.byn,
    };
