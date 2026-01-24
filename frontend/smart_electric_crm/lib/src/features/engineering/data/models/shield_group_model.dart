import 'package:json_annotation/json_annotation.dart';

part 'shield_group_model.g.dart';

@JsonSerializable()
class ShieldGroupModel {
  final int id;

  /// Устройство/Номинал (например, "Автомат 16А")
  final String device;

  /// Зона/Потребитель (например, "Кухня - Розетки")
  final String zone;

  /// ID товара из каталога (опционально)
  @JsonKey(name: 'catalog_item')
  final int? catalogItemId;

  ShieldGroupModel({
    required this.id,
    required this.device,
    required this.zone,
    this.catalogItemId,
  });

  factory ShieldGroupModel.fromJson(Map<String, dynamic> json) =>
      _$ShieldGroupModelFromJson(json);

  Map<String, dynamic> toJson() => _$ShieldGroupModelToJson(this);
}
