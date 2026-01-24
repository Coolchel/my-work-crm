import 'package:json_annotation/json_annotation.dart';
import 'shield_group_model.dart';
import 'led_zone_model.dart';

part 'shield_model.g.dart';

@JsonSerializable()
class ShieldModel {
  final int id;

  @JsonKey(name: 'project')
  final int projectId;

  final String name;

  @JsonKey(name: 'shield_type')
  final String shieldType; // 'power', 'led', 'multimedia'

  final String mounting; // 'internal', 'external'

  // Nested content
  @JsonKey(defaultValue: [])
  final List<ShieldGroupModel> groups;

  @JsonKey(name: 'led_zones', defaultValue: [])
  final List<LedZoneModel> ledZones;

  // Multimedia specific
  @JsonKey(name: 'internet_lines_count', defaultValue: 0)
  final int internetLinesCount;

  @JsonKey(name: 'multimedia_notes', defaultValue: '')
  final String multimediaNotes;

  // Calculated
  @JsonKey(name: 'suggested_size')
  final String? suggestedSize;

  ShieldModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.shieldType,
    required this.mounting,
    this.groups = const [],
    this.ledZones = const [],
    this.internetLinesCount = 0,
    this.multimediaNotes = '',
    this.suggestedSize,
  });

  factory ShieldModel.fromJson(Map<String, dynamic> json) =>
      _$ShieldModelFromJson(json);

  Map<String, dynamic> toJson() => _$ShieldModelToJson(this);
}
