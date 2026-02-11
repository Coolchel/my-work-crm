import 'package:json_annotation/json_annotation.dart';
import 'estimate_item_model.dart';

part 'stage_model.g.dart';

@JsonSerializable()
class StageModel {
  final int id;

  /// Название этапа (например, 'stage_1')
  final String title;

  /// Статус (plan, in_progress, completed)
  final String status;

  /// Оплачен ли этап
  @JsonKey(name: 'is_paid')
  final bool isPaid;

  /// Дата начала (может быть null)
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;

  /// Дата окончания (может быть null)
  @JsonKey(name: 'ended_at')
  final DateTime? endedAt;

  @JsonKey(name: 'work_notes', defaultValue: '')
  final String workNotes;

  @JsonKey(name: 'material_notes', defaultValue: '')
  final String materialNotes;

  @JsonKey(name: 'work_remarks', defaultValue: '')
  final String workRemarks;

  @JsonKey(name: 'material_remarks', defaultValue: '')
  final String materialRemarks;

  @JsonKey(name: 'markup_percent', defaultValue: 0.0)
  final double markupPercent;

  @JsonKey(name: 'show_prices', defaultValue: false)
  final bool showPrices;

  /// Пункты сметы
  @JsonKey(name: 'estimate_items', defaultValue: [])
  final List<EstimateItemModel> estimateItems;

  StageModel({
    required this.id,
    required this.title,
    required this.status,
    required this.isPaid,
    this.startedAt,
    this.endedAt,
    this.estimateItems = const [],
    this.workNotes = '',
    this.materialNotes = '',
    this.workRemarks = '',
    this.materialRemarks = '',
    this.markupPercent = 0.0,
    this.showPrices = false,
  });

  /// Создает экземпляр из JSON
  factory StageModel.fromJson(Map<String, dynamic> json) =>
      _$StageModelFromJson(json);

  /// Конвертирует в JSON
  Map<String, dynamic> toJson() => _$StageModelToJson(this);

  /// Копирование объекта с изменением полей
  StageModel copyWith({
    int? id,
    String? title,
    String? status,
    bool? isPaid,
    DateTime? startedAt,
    DateTime? endedAt,
    List<EstimateItemModel>? estimateItems,
    String? workNotes,
    String? materialNotes,
    String? workRemarks,
    String? materialRemarks,
    double? markupPercent,
    bool? showPrices,
  }) {
    return StageModel(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      isPaid: isPaid ?? this.isPaid,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      estimateItems: estimateItems ?? this.estimateItems,
      workNotes: workNotes ?? this.workNotes,
      materialNotes: materialNotes ?? this.materialNotes,
      workRemarks: workRemarks ?? this.workRemarks,
      materialRemarks: materialRemarks ?? this.materialRemarks,
      markupPercent: markupPercent ?? this.markupPercent,
      showPrices: showPrices ?? this.showPrices,
    );
  }

  // Helpers for UI
  double get totalAmountUsd {
    return estimateItems
        .where((i) => i.itemType == 'work')
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get totalAmountMaterialsUsd {
    return estimateItems
        .where((i) => i.itemType != 'work')
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }
}
