import 'package:json_annotation/json_annotation.dart';

part 'estimate_item_model.g.dart';

@JsonSerializable()
class EstimateItemModel {
  final int id;

  /// ID Этапа
  final int stage;

  /// Тип (work/material)
  @JsonKey(name: 'item_type')
  final String itemType;

  /// Наименование
  final String name;

  /// Единица измерения
  final String unit;

  /// Общий объем (для клиента)
  @JsonKey(name: 'total_quantity')
  final double totalQuantity;

  /// Объем работодателя
  @JsonKey(name: 'employer_quantity', defaultValue: 0.0)
  final double employerQuantity;

  /// Кол-во подрядчика (для совместимости)
  @JsonKey(name: 'contractor_quantity', defaultValue: 0.0)
  final double contractorQuantity;

  /// Цена за единицу
  @JsonKey(name: 'price_per_unit')
  final double? pricePerUnit;

  /// Валюта (USD/BYN)
  @JsonKey(defaultValue: 'USD')
  final String currency;

  /// Наценка %
  @JsonKey(name: 'markup_percent', defaultValue: 0.0)
  final double markupPercent;

  /// Доп. работы?
  @JsonKey(name: 'is_extra', defaultValue: false)
  final bool isExtra;

  /// Предпросчет?
  @JsonKey(name: 'is_preliminary', defaultValue: false)
  final bool isPreliminary;

  /// Расчетные поля (Read-only from API)
  @JsonKey(name: 'client_amount', includeIfNull: false)
  final double? clientAmount;

  @JsonKey(name: 'employer_amount', includeIfNull: false)
  final double? employerAmount;

  @JsonKey(name: 'my_amount', includeIfNull: false)
  final double? myAmount;

  EstimateItemModel({
    required this.id,
    required this.stage,
    required this.itemType,
    required this.name,
    required this.unit,
    required this.totalQuantity,
    this.employerQuantity = 0.0,
    this.contractorQuantity = 0.0,
    this.pricePerUnit,
    this.currency = 'USD',
    this.markupPercent = 0.0,
    this.isExtra = false,
    this.isPreliminary = false,
    this.clientAmount,
    this.employerAmount,
    this.myAmount,
  });

  factory EstimateItemModel.fromJson(Map<String, dynamic> json) =>
      _$EstimateItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$EstimateItemModelToJson(this);

  EstimateItemModel copyWith({
    int? id,
    int? stage,
    String? itemType,
    String? name,
    String? unit,
    double? totalQuantity,
    double? employerQuantity,
    double? contractorQuantity,
    double? pricePerUnit,
    String? currency,
    double? markupPercent,
    bool? isExtra,
    bool? isPreliminary,
  }) {
    return EstimateItemModel(
      id: id ?? this.id,
      stage: stage ?? this.stage,
      itemType: itemType ?? this.itemType,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      employerQuantity: employerQuantity ?? this.employerQuantity,
      contractorQuantity: contractorQuantity ?? this.contractorQuantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      currency: currency ?? this.currency,
      markupPercent: markupPercent ?? this.markupPercent,
      isExtra: isExtra ?? this.isExtra,
      isPreliminary: isPreliminary ?? this.isPreliminary,
      clientAmount:
          this.clientAmount, // Не обновляем calculation fields при копировании
      employerAmount: this.employerAmount,
      myAmount: this.myAmount,
    );
  }
}
