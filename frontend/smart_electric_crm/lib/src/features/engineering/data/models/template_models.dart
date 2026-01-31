import 'package:freezed_annotation/freezed_annotation.dart';

part 'template_models.freezed.dart';
part 'template_models.g.dart';

@freezed
class WorkTemplate with _$WorkTemplate {
  const factory WorkTemplate({
    required int id,
    required String name,
    required String description,
    @Default([]) List<WorkTemplateItem> items,
  }) = _WorkTemplate;

  factory WorkTemplate.fromJson(Map<String, dynamic> json) =>
      _$WorkTemplateFromJson(json);
}

@freezed
class WorkTemplateItem with _$WorkTemplateItem {
  const factory WorkTemplateItem({
    required int id,
    @JsonKey(name: 'catalog_item') required int catalogItemId,
    @JsonKey(name: 'catalog_item_name') required String catalogItemName,
    @Default(1.0) double quantity,
  }) = _WorkTemplateItem;

  factory WorkTemplateItem.fromJson(Map<String, dynamic> json) =>
      _$WorkTemplateItemFromJson(json);
}

@freezed
class MaterialTemplate with _$MaterialTemplate {
  const factory MaterialTemplate({
    required int id,
    required String name,
    required String description,
    @Default([]) List<MaterialTemplateItem> items,
  }) = _MaterialTemplate;

  factory MaterialTemplate.fromJson(Map<String, dynamic> json) =>
      _$MaterialTemplateFromJson(json);
}

@freezed
class MaterialTemplateItem with _$MaterialTemplateItem {
  const factory MaterialTemplateItem({
    required int id,
    @JsonKey(name: 'catalog_item') required int catalogItemId,
    @JsonKey(name: 'catalog_item_name') required String catalogItemName,
    @Default(1.0) double quantity,
  }) = _MaterialTemplateItem;

  factory MaterialTemplateItem.fromJson(Map<String, dynamic> json) =>
      _$MaterialTemplateItemFromJson(json);
}

@freezed
class PowerShieldTemplate with _$PowerShieldTemplate {
  const factory PowerShieldTemplate({
    required int id,
    required String name,
    required String description,
    @Default([]) List<PowerShieldTemplateItem> items,
  }) = _PowerShieldTemplate;

  factory PowerShieldTemplate.fromJson(Map<String, dynamic> json) =>
      _$PowerShieldTemplateFromJson(json);
}

@freezed
class PowerShieldTemplateItem with _$PowerShieldTemplateItem {
  const factory PowerShieldTemplateItem({
    required int id,
    @JsonKey(name: 'device_type') required String deviceType,
    @Default('16A') String rating,
    @Default('1P') String poles,
    @Default(1) int quantity,
    @JsonKey(name: 'catalog_item') int? catalogItemId,
    @JsonKey(name: 'catalog_item_name') String? catalogItemName,
  }) = _PowerShieldTemplateItem;

  factory PowerShieldTemplateItem.fromJson(Map<String, dynamic> json) =>
      _$PowerShieldTemplateItemFromJson(json);
}

@freezed
class MultimediaTemplate with _$MultimediaTemplate {
  const factory MultimediaTemplate({
    required int id,
    required String name,
    required String description,
    @Default([]) List<MultimediaTemplateItem> items,
  }) = _MultimediaTemplate;

  factory MultimediaTemplate.fromJson(Map<String, dynamic> json) =>
      _$MultimediaTemplateFromJson(json);
}

@freezed
class MultimediaTemplateItem with _$MultimediaTemplateItem {
  const factory MultimediaTemplateItem({
    required int id,
    required String name,
    @Default(1) int quantity,
    @JsonKey(name: 'catalog_item') int? catalogItemId,
    @JsonKey(name: 'catalog_item_name') String? catalogItemName,
  }) = _MultimediaTemplateItem;

  factory MultimediaTemplateItem.fromJson(Map<String, dynamic> json) =>
      _$MultimediaTemplateItemFromJson(json);
}
