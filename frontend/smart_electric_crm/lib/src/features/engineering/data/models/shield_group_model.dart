import 'package:json_annotation/json_annotation.dart';

part 'shield_group_model.g.dart';

@JsonSerializable()
class ShieldGroupModel {
  final int id;

  /// Устройство/Номинал (например, "Автомат 16А")
  /// Вычисляемое поле с бэкенда, можно использовать для отображения
  @JsonKey(defaultValue: '')
  final String device;

  /// Зона/Потребитель (например, "Кухня - Розетки")
  final String zone;

  /// Тип устройства (circuit_breaker, diff_breaker, etc)
  @JsonKey(name: 'device_type', defaultValue: 'circuit_breaker')
  final String deviceType;

  /// Номинал (16A, etc)
  @JsonKey(defaultValue: '16A')
  final String rating;

  /// Полюса (1P, 2P, etc)
  @JsonKey(defaultValue: '1P')
  final String poles;

  /// Кол-во модулей (считается на бэке)
  @JsonKey(name: 'modules_count', defaultValue: 1)
  final int modulesCount;

  /// Количество (для объединения позиций)
  @JsonKey(defaultValue: 1)
  final int quantity;

  /// ID товара из каталога (опционально)
  @JsonKey(name: 'catalog_item')
  final int? catalogItemId;

  @JsonKey(name: 'shield')
  final int shieldId;

  ShieldGroupModel({
    required this.id,
    required this.device,
    required this.zone,
    required this.deviceType,
    required this.rating,
    required this.poles,
    required this.modulesCount,
    this.quantity = 1,
    this.catalogItemId,
    required this.shieldId,
  });

  factory ShieldGroupModel.fromJson(Map<String, dynamic> json) =>
      _$ShieldGroupModelFromJson(json);

  Map<String, dynamic> toJson() => _$ShieldGroupModelToJson(this);
}
