import 'package:json_annotation/json_annotation.dart';

part 'finance_settings_model.g.dart';

/// Модель глобальных финансовых настроек (singleton)
@JsonSerializable()
class FinanceSettingsModel {
  final int id;

  @JsonKey(name: 'partner_external_estimate', defaultValue: '')
  final String partnerExternalEstimate;

  @JsonKey(name: 'financial_notes', defaultValue: '')
  final String financialNotes;

  FinanceSettingsModel({
    required this.id,
    this.partnerExternalEstimate = '',
    this.financialNotes = '',
  });

  factory FinanceSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$FinanceSettingsModelFromJson(json);

  Map<String, dynamic> toJson() => _$FinanceSettingsModelToJson(this);

  FinanceSettingsModel copyWith({
    int? id,
    String? partnerExternalEstimate,
    String? financialNotes,
  }) {
    return FinanceSettingsModel(
      id: id ?? this.id,
      partnerExternalEstimate:
          partnerExternalEstimate ?? this.partnerExternalEstimate,
      financialNotes: financialNotes ?? this.financialNotes,
    );
  }
}
