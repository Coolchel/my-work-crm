import 'package:json_annotation/json_annotation.dart';
import 'stage_model.dart';

part 'project_model.g.dart';

@JsonSerializable()
class ProjectModel {
  final int id;

  /// Адрес объекта
  final String address;

  /// Тип объекта (new_building и т.д.)
  @JsonKey(name: 'object_type')
  final String objectType;

  /// Статус проекта
  final String status;

  /// Дата создания
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Список этапов проекта
  final List<StageModel> stages;

  ProjectModel({
    required this.id,
    required this.address,
    required this.objectType,
    required this.status,
    required this.createdAt,
    required this.stages,
  });

  /// Создает экземпляр из JSON
  factory ProjectModel.fromJson(Map<String, dynamic> json) =>
      _$ProjectModelFromJson(json);

  /// Конвертирует в JSON
  Map<String, dynamic> toJson() => _$ProjectModelToJson(this);

  /// Копирование объекта с изменением полей
  ProjectModel copyWith({
    int? id,
    String? address,
    String? objectType,
    String? status,
    DateTime? createdAt,
    List<StageModel>? stages,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      address: address ?? this.address,
      objectType: objectType ?? this.objectType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      stages: stages ?? this.stages,
    );
  }
}
