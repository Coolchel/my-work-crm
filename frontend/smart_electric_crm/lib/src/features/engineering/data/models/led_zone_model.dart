import 'package:json_annotation/json_annotation.dart';

part 'led_zone_model.g.dart';

@JsonSerializable()
class LedZoneModel {
  final int id;

  /// Трансформатор/Блок питания
  final String transformer;

  /// Зона установки/Лента
  final String zone;

  /// ID товара из каталога (опционально)
  @JsonKey(name: 'catalog_item')
  final int? catalogItemId;

  LedZoneModel({
    required this.id,
    required this.transformer,
    required this.zone,
    this.catalogItemId,
  });

  factory LedZoneModel.fromJson(Map<String, dynamic> json) =>
      _$LedZoneModelFromJson(json);

  Map<String, dynamic> toJson() => _$LedZoneModelToJson(this);
}
