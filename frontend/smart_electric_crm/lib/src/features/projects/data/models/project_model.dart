import 'package:json_annotation/json_annotation.dart';
import 'stage_model.dart';
import 'project_file_model.dart';
import 'package:smart_electric_crm/src/features/engineering/data/models/shield_model.dart';

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

  /// Код домофона
  @JsonKey(name: 'intercom_code', defaultValue: '')
  final String intercomCode;

  /// Информация о клиенте
  @JsonKey(name: 'client_info', defaultValue: '')
  final String clientInfo;

  /// Дата создания
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Дата последнего обновления
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Список этапов проекта
  final List<StageModel> stages;

  /// Список щитов (New)
  @JsonKey(defaultValue: [])
  final List<ShieldModel> shields;

  /// Список файлов (New)
  @JsonKey(defaultValue: [])
  final List<ProjectFileModel> files;

  /// Источник объекта
  @JsonKey(defaultValue: '')
  final String source;

  ProjectModel({
    required this.id,
    required this.address,
    required this.objectType,
    required this.status,
    this.intercomCode = '',
    this.clientInfo = '',
    this.source = '',
    required this.createdAt,
    this.updatedAt,
    required this.stages,
    this.shields = const [],
    this.files = const [],
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
    String? intercomCode,
    String? clientInfo,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<StageModel>? stages,
    List<ShieldModel>? shields,
    List<ProjectFileModel>? files,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      address: address ?? this.address,
      objectType: objectType ?? this.objectType,
      status: status ?? this.status,
      intercomCode: intercomCode ?? this.intercomCode,
      clientInfo: clientInfo ?? this.clientInfo,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stages: stages ?? this.stages,
      shields: shields ?? this.shields,
      files: files ?? this.files,
    );
  }
}
