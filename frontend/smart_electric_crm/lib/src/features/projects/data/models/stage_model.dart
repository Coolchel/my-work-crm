import 'package:json_annotation/json_annotation.dart';

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

  StageModel({
    required this.id,
    required this.title,
    required this.status,
    required this.isPaid,
    this.startedAt,
    this.endedAt,
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
  }) {
    return StageModel(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      isPaid: isPaid ?? this.isPaid,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}
