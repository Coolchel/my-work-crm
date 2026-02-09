import 'package:json_annotation/json_annotation.dart';

part 'project_file_model.g.dart';

@JsonSerializable()
class ProjectFileModel {
  final int id;
  final int project;
  final String file;
  final String description;
  final String category;
  @JsonKey(name: 'original_name')
  final String originalName;

  ProjectFileModel({
    required this.id,
    required this.project,
    required this.file,
    required this.description,
    required this.category,
    this.originalName = '',
  });

  factory ProjectFileModel.fromJson(Map<String, dynamic> json) =>
      _$ProjectFileModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectFileModelToJson(this);
}
