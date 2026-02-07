// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finance_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FinanceSettingsModel _$FinanceSettingsModelFromJson(
        Map<String, dynamic> json) =>
    FinanceSettingsModel(
      id: (json['id'] as num).toInt(),
      partnerExternalEstimate:
          json['partner_external_estimate'] as String? ?? '',
      financialNotes: json['financial_notes'] as String? ?? '',
    );

Map<String, dynamic> _$FinanceSettingsModelToJson(
        FinanceSettingsModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'partner_external_estimate': instance.partnerExternalEstimate,
      'financial_notes': instance.financialNotes,
    };
