// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'estimate_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EstimateItemModel _$EstimateItemModelFromJson(Map<String, dynamic> json) =>
    EstimateItemModel(
      id: (json['id'] as num).toInt(),
      stage: (json['stage'] as num).toInt(),
      itemType: json['item_type'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      totalQuantity: (json['total_quantity'] as num).toDouble(),
      employerQuantity: (json['employer_quantity'] as num?)?.toDouble() ?? 0.0,
      contractorQuantity:
          (json['contractor_quantity'] as num?)?.toDouble() ?? 0.0,
      pricePerUnit: (json['price_per_unit'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      markupPercent: (json['markup_percent'] as num?)?.toDouble() ?? 0.0,
      isPreliminary: json['is_preliminary'] as bool? ?? false,
      clientAmount: (json['client_amount'] as num?)?.toDouble(),
      employerAmount: (json['employer_amount'] as num?)?.toDouble(),
      myAmount: (json['my_amount'] as num?)?.toDouble(),
      categoryName: json['category_name'] as String?,
    );

Map<String, dynamic> _$EstimateItemModelToJson(EstimateItemModel instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'stage': instance.stage,
    'item_type': instance.itemType,
    'name': instance.name,
    'unit': instance.unit,
    'total_quantity': instance.totalQuantity,
    'employer_quantity': instance.employerQuantity,
    'contractor_quantity': instance.contractorQuantity,
    'price_per_unit': instance.pricePerUnit,
    'currency': instance.currency,
    'markup_percent': instance.markupPercent,
    'is_preliminary': instance.isPreliminary,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('client_amount', instance.clientAmount);
  writeNotNull('employer_amount', instance.employerAmount);
  writeNotNull('my_amount', instance.myAmount);
  writeNotNull('category_name', instance.categoryName);
  return val;
}
