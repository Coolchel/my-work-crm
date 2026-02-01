// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'template_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WorkTemplate _$WorkTemplateFromJson(Map<String, dynamic> json) {
  return _WorkTemplate.fromJson(json);
}

/// @nodoc
mixin _$WorkTemplate {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<WorkTemplateItem> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkTemplateCopyWith<WorkTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkTemplateCopyWith<$Res> {
  factory $WorkTemplateCopyWith(
          WorkTemplate value, $Res Function(WorkTemplate) then) =
      _$WorkTemplateCopyWithImpl<$Res, WorkTemplate>;
  @useResult
  $Res call(
      {int id, String name, String description, List<WorkTemplateItem> items});
}

/// @nodoc
class _$WorkTemplateCopyWithImpl<$Res, $Val extends WorkTemplate>
    implements $WorkTemplateCopyWith<$Res> {
  _$WorkTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<WorkTemplateItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkTemplateImplCopyWith<$Res>
    implements $WorkTemplateCopyWith<$Res> {
  factory _$$WorkTemplateImplCopyWith(
          _$WorkTemplateImpl value, $Res Function(_$WorkTemplateImpl) then) =
      __$$WorkTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id, String name, String description, List<WorkTemplateItem> items});
}

/// @nodoc
class __$$WorkTemplateImplCopyWithImpl<$Res>
    extends _$WorkTemplateCopyWithImpl<$Res, _$WorkTemplateImpl>
    implements _$$WorkTemplateImplCopyWith<$Res> {
  __$$WorkTemplateImplCopyWithImpl(
      _$WorkTemplateImpl _value, $Res Function(_$WorkTemplateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? items = null,
  }) {
    return _then(_$WorkTemplateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<WorkTemplateItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkTemplateImpl implements _WorkTemplate {
  const _$WorkTemplateImpl(
      {required this.id,
      required this.name,
      required this.description,
      final List<WorkTemplateItem> items = const []})
      : _items = items;

  factory _$WorkTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkTemplateImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String description;
  final List<WorkTemplateItem> _items;
  @override
  @JsonKey()
  List<WorkTemplateItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'WorkTemplate(id: $id, name: $name, description: $description, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkTemplateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description,
      const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkTemplateImplCopyWith<_$WorkTemplateImpl> get copyWith =>
      __$$WorkTemplateImplCopyWithImpl<_$WorkTemplateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkTemplateImplToJson(
      this,
    );
  }
}

abstract class _WorkTemplate implements WorkTemplate {
  const factory _WorkTemplate(
      {required final int id,
      required final String name,
      required final String description,
      final List<WorkTemplateItem> items}) = _$WorkTemplateImpl;

  factory _WorkTemplate.fromJson(Map<String, dynamic> json) =
      _$WorkTemplateImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get description;
  @override
  List<WorkTemplateItem> get items;
  @override
  @JsonKey(ignore: true)
  _$$WorkTemplateImplCopyWith<_$WorkTemplateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WorkTemplateItem _$WorkTemplateItemFromJson(Map<String, dynamic> json) {
  return _WorkTemplateItem.fromJson(json);
}

/// @nodoc
mixin _$WorkTemplateItem {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'catalog_item')
  int get catalogItemId => throw _privateConstructorUsedError;
  @JsonKey(name: 'catalog_item_name')
  String get catalogItemName => throw _privateConstructorUsedError;
  double get quantity => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkTemplateItemCopyWith<WorkTemplateItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkTemplateItemCopyWith<$Res> {
  factory $WorkTemplateItemCopyWith(
          WorkTemplateItem value, $Res Function(WorkTemplateItem) then) =
      _$WorkTemplateItemCopyWithImpl<$Res, WorkTemplateItem>;
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'catalog_item') int catalogItemId,
      @JsonKey(name: 'catalog_item_name') String catalogItemName,
      double quantity});
}

/// @nodoc
class _$WorkTemplateItemCopyWithImpl<$Res, $Val extends WorkTemplateItem>
    implements $WorkTemplateItemCopyWith<$Res> {
  _$WorkTemplateItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? catalogItemId = null,
    Object? catalogItemName = null,
    Object? quantity = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      catalogItemId: null == catalogItemId
          ? _value.catalogItemId
          : catalogItemId // ignore: cast_nullable_to_non_nullable
              as int,
      catalogItemName: null == catalogItemName
          ? _value.catalogItemName
          : catalogItemName // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkTemplateItemImplCopyWith<$Res>
    implements $WorkTemplateItemCopyWith<$Res> {
  factory _$$WorkTemplateItemImplCopyWith(_$WorkTemplateItemImpl value,
          $Res Function(_$WorkTemplateItemImpl) then) =
      __$$WorkTemplateItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'catalog_item') int catalogItemId,
      @JsonKey(name: 'catalog_item_name') String catalogItemName,
      double quantity});
}

/// @nodoc
class __$$WorkTemplateItemImplCopyWithImpl<$Res>
    extends _$WorkTemplateItemCopyWithImpl<$Res, _$WorkTemplateItemImpl>
    implements _$$WorkTemplateItemImplCopyWith<$Res> {
  __$$WorkTemplateItemImplCopyWithImpl(_$WorkTemplateItemImpl _value,
      $Res Function(_$WorkTemplateItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? catalogItemId = null,
    Object? catalogItemName = null,
    Object? quantity = null,
  }) {
    return _then(_$WorkTemplateItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      catalogItemId: null == catalogItemId
          ? _value.catalogItemId
          : catalogItemId // ignore: cast_nullable_to_non_nullable
              as int,
      catalogItemName: null == catalogItemName
          ? _value.catalogItemName
          : catalogItemName // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkTemplateItemImpl implements _WorkTemplateItem {
  const _$WorkTemplateItemImpl(
      {required this.id,
      @JsonKey(name: 'catalog_item') required this.catalogItemId,
      @JsonKey(name: 'catalog_item_name') required this.catalogItemName,
      this.quantity = 1.0});

  factory _$WorkTemplateItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkTemplateItemImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'catalog_item')
  final int catalogItemId;
  @override
  @JsonKey(name: 'catalog_item_name')
  final String catalogItemName;
  @override
  @JsonKey()
  final double quantity;

  @override
  String toString() {
    return 'WorkTemplateItem(id: $id, catalogItemId: $catalogItemId, catalogItemName: $catalogItemName, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkTemplateItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.catalogItemId, catalogItemId) ||
                other.catalogItemId == catalogItemId) &&
            (identical(other.catalogItemName, catalogItemName) ||
                other.catalogItemName == catalogItemName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, catalogItemId, catalogItemName, quantity);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkTemplateItemImplCopyWith<_$WorkTemplateItemImpl> get copyWith =>
      __$$WorkTemplateItemImplCopyWithImpl<_$WorkTemplateItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkTemplateItemImplToJson(
      this,
    );
  }
}

abstract class _WorkTemplateItem implements WorkTemplateItem {
  const factory _WorkTemplateItem(
      {required final int id,
      @JsonKey(name: 'catalog_item') required final int catalogItemId,
      @JsonKey(name: 'catalog_item_name') required final String catalogItemName,
      final double quantity}) = _$WorkTemplateItemImpl;

  factory _WorkTemplateItem.fromJson(Map<String, dynamic> json) =
      _$WorkTemplateItemImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'catalog_item')
  int get catalogItemId;
  @override
  @JsonKey(name: 'catalog_item_name')
  String get catalogItemName;
  @override
  double get quantity;
  @override
  @JsonKey(ignore: true)
  _$$WorkTemplateItemImplCopyWith<_$WorkTemplateItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MaterialTemplate _$MaterialTemplateFromJson(Map<String, dynamic> json) {
  return _MaterialTemplate.fromJson(json);
}

/// @nodoc
mixin _$MaterialTemplate {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<MaterialTemplateItem> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MaterialTemplateCopyWith<MaterialTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaterialTemplateCopyWith<$Res> {
  factory $MaterialTemplateCopyWith(
          MaterialTemplate value, $Res Function(MaterialTemplate) then) =
      _$MaterialTemplateCopyWithImpl<$Res, MaterialTemplate>;
  @useResult
  $Res call(
      {int id,
      String name,
      String description,
      List<MaterialTemplateItem> items});
}

/// @nodoc
class _$MaterialTemplateCopyWithImpl<$Res, $Val extends MaterialTemplate>
    implements $MaterialTemplateCopyWith<$Res> {
  _$MaterialTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<MaterialTemplateItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MaterialTemplateImplCopyWith<$Res>
    implements $MaterialTemplateCopyWith<$Res> {
  factory _$$MaterialTemplateImplCopyWith(_$MaterialTemplateImpl value,
          $Res Function(_$MaterialTemplateImpl) then) =
      __$$MaterialTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      String description,
      List<MaterialTemplateItem> items});
}

/// @nodoc
class __$$MaterialTemplateImplCopyWithImpl<$Res>
    extends _$MaterialTemplateCopyWithImpl<$Res, _$MaterialTemplateImpl>
    implements _$$MaterialTemplateImplCopyWith<$Res> {
  __$$MaterialTemplateImplCopyWithImpl(_$MaterialTemplateImpl _value,
      $Res Function(_$MaterialTemplateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? items = null,
  }) {
    return _then(_$MaterialTemplateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<MaterialTemplateItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MaterialTemplateImpl implements _MaterialTemplate {
  const _$MaterialTemplateImpl(
      {required this.id,
      required this.name,
      required this.description,
      final List<MaterialTemplateItem> items = const []})
      : _items = items;

  factory _$MaterialTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaterialTemplateImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String description;
  final List<MaterialTemplateItem> _items;
  @override
  @JsonKey()
  List<MaterialTemplateItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'MaterialTemplate(id: $id, name: $name, description: $description, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaterialTemplateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description,
      const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MaterialTemplateImplCopyWith<_$MaterialTemplateImpl> get copyWith =>
      __$$MaterialTemplateImplCopyWithImpl<_$MaterialTemplateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MaterialTemplateImplToJson(
      this,
    );
  }
}

abstract class _MaterialTemplate implements MaterialTemplate {
  const factory _MaterialTemplate(
      {required final int id,
      required final String name,
      required final String description,
      final List<MaterialTemplateItem> items}) = _$MaterialTemplateImpl;

  factory _MaterialTemplate.fromJson(Map<String, dynamic> json) =
      _$MaterialTemplateImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get description;
  @override
  List<MaterialTemplateItem> get items;
  @override
  @JsonKey(ignore: true)
  _$$MaterialTemplateImplCopyWith<_$MaterialTemplateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MaterialTemplateItem _$MaterialTemplateItemFromJson(Map<String, dynamic> json) {
  return _MaterialTemplateItem.fromJson(json);
}

/// @nodoc
mixin _$MaterialTemplateItem {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'catalog_item')
  int get catalogItemId => throw _privateConstructorUsedError;
  @JsonKey(name: 'catalog_item_name')
  String get catalogItemName => throw _privateConstructorUsedError;
  double get quantity => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MaterialTemplateItemCopyWith<MaterialTemplateItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaterialTemplateItemCopyWith<$Res> {
  factory $MaterialTemplateItemCopyWith(MaterialTemplateItem value,
          $Res Function(MaterialTemplateItem) then) =
      _$MaterialTemplateItemCopyWithImpl<$Res, MaterialTemplateItem>;
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'catalog_item') int catalogItemId,
      @JsonKey(name: 'catalog_item_name') String catalogItemName,
      double quantity});
}

/// @nodoc
class _$MaterialTemplateItemCopyWithImpl<$Res,
        $Val extends MaterialTemplateItem>
    implements $MaterialTemplateItemCopyWith<$Res> {
  _$MaterialTemplateItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? catalogItemId = null,
    Object? catalogItemName = null,
    Object? quantity = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      catalogItemId: null == catalogItemId
          ? _value.catalogItemId
          : catalogItemId // ignore: cast_nullable_to_non_nullable
              as int,
      catalogItemName: null == catalogItemName
          ? _value.catalogItemName
          : catalogItemName // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MaterialTemplateItemImplCopyWith<$Res>
    implements $MaterialTemplateItemCopyWith<$Res> {
  factory _$$MaterialTemplateItemImplCopyWith(_$MaterialTemplateItemImpl value,
          $Res Function(_$MaterialTemplateItemImpl) then) =
      __$$MaterialTemplateItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'catalog_item') int catalogItemId,
      @JsonKey(name: 'catalog_item_name') String catalogItemName,
      double quantity});
}

/// @nodoc
class __$$MaterialTemplateItemImplCopyWithImpl<$Res>
    extends _$MaterialTemplateItemCopyWithImpl<$Res, _$MaterialTemplateItemImpl>
    implements _$$MaterialTemplateItemImplCopyWith<$Res> {
  __$$MaterialTemplateItemImplCopyWithImpl(_$MaterialTemplateItemImpl _value,
      $Res Function(_$MaterialTemplateItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? catalogItemId = null,
    Object? catalogItemName = null,
    Object? quantity = null,
  }) {
    return _then(_$MaterialTemplateItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      catalogItemId: null == catalogItemId
          ? _value.catalogItemId
          : catalogItemId // ignore: cast_nullable_to_non_nullable
              as int,
      catalogItemName: null == catalogItemName
          ? _value.catalogItemName
          : catalogItemName // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MaterialTemplateItemImpl implements _MaterialTemplateItem {
  const _$MaterialTemplateItemImpl(
      {required this.id,
      @JsonKey(name: 'catalog_item') required this.catalogItemId,
      @JsonKey(name: 'catalog_item_name') required this.catalogItemName,
      this.quantity = 1.0});

  factory _$MaterialTemplateItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaterialTemplateItemImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'catalog_item')
  final int catalogItemId;
  @override
  @JsonKey(name: 'catalog_item_name')
  final String catalogItemName;
  @override
  @JsonKey()
  final double quantity;

  @override
  String toString() {
    return 'MaterialTemplateItem(id: $id, catalogItemId: $catalogItemId, catalogItemName: $catalogItemName, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaterialTemplateItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.catalogItemId, catalogItemId) ||
                other.catalogItemId == catalogItemId) &&
            (identical(other.catalogItemName, catalogItemName) ||
                other.catalogItemName == catalogItemName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, catalogItemId, catalogItemName, quantity);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MaterialTemplateItemImplCopyWith<_$MaterialTemplateItemImpl>
      get copyWith =>
          __$$MaterialTemplateItemImplCopyWithImpl<_$MaterialTemplateItemImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MaterialTemplateItemImplToJson(
      this,
    );
  }
}

abstract class _MaterialTemplateItem implements MaterialTemplateItem {
  const factory _MaterialTemplateItem(
      {required final int id,
      @JsonKey(name: 'catalog_item') required final int catalogItemId,
      @JsonKey(name: 'catalog_item_name') required final String catalogItemName,
      final double quantity}) = _$MaterialTemplateItemImpl;

  factory _MaterialTemplateItem.fromJson(Map<String, dynamic> json) =
      _$MaterialTemplateItemImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'catalog_item')
  int get catalogItemId;
  @override
  @JsonKey(name: 'catalog_item_name')
  String get catalogItemName;
  @override
  double get quantity;
  @override
  @JsonKey(ignore: true)
  _$$MaterialTemplateItemImplCopyWith<_$MaterialTemplateItemImpl>
      get copyWith => throw _privateConstructorUsedError;
}

PowerShieldTemplate _$PowerShieldTemplateFromJson(Map<String, dynamic> json) {
  return _PowerShieldTemplate.fromJson(json);
}

/// @nodoc
mixin _$PowerShieldTemplate {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<PowerShieldTemplateItem> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PowerShieldTemplateCopyWith<PowerShieldTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PowerShieldTemplateCopyWith<$Res> {
  factory $PowerShieldTemplateCopyWith(
          PowerShieldTemplate value, $Res Function(PowerShieldTemplate) then) =
      _$PowerShieldTemplateCopyWithImpl<$Res, PowerShieldTemplate>;
  @useResult
  $Res call(
      {int id,
      String name,
      String description,
      List<PowerShieldTemplateItem> items});
}

/// @nodoc
class _$PowerShieldTemplateCopyWithImpl<$Res, $Val extends PowerShieldTemplate>
    implements $PowerShieldTemplateCopyWith<$Res> {
  _$PowerShieldTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<PowerShieldTemplateItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PowerShieldTemplateImplCopyWith<$Res>
    implements $PowerShieldTemplateCopyWith<$Res> {
  factory _$$PowerShieldTemplateImplCopyWith(_$PowerShieldTemplateImpl value,
          $Res Function(_$PowerShieldTemplateImpl) then) =
      __$$PowerShieldTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      String description,
      List<PowerShieldTemplateItem> items});
}

/// @nodoc
class __$$PowerShieldTemplateImplCopyWithImpl<$Res>
    extends _$PowerShieldTemplateCopyWithImpl<$Res, _$PowerShieldTemplateImpl>
    implements _$$PowerShieldTemplateImplCopyWith<$Res> {
  __$$PowerShieldTemplateImplCopyWithImpl(_$PowerShieldTemplateImpl _value,
      $Res Function(_$PowerShieldTemplateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? items = null,
  }) {
    return _then(_$PowerShieldTemplateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<PowerShieldTemplateItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PowerShieldTemplateImpl implements _PowerShieldTemplate {
  const _$PowerShieldTemplateImpl(
      {required this.id,
      required this.name,
      required this.description,
      final List<PowerShieldTemplateItem> items = const []})
      : _items = items;

  factory _$PowerShieldTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PowerShieldTemplateImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String description;
  final List<PowerShieldTemplateItem> _items;
  @override
  @JsonKey()
  List<PowerShieldTemplateItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'PowerShieldTemplate(id: $id, name: $name, description: $description, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PowerShieldTemplateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description,
      const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PowerShieldTemplateImplCopyWith<_$PowerShieldTemplateImpl> get copyWith =>
      __$$PowerShieldTemplateImplCopyWithImpl<_$PowerShieldTemplateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PowerShieldTemplateImplToJson(
      this,
    );
  }
}

abstract class _PowerShieldTemplate implements PowerShieldTemplate {
  const factory _PowerShieldTemplate(
      {required final int id,
      required final String name,
      required final String description,
      final List<PowerShieldTemplateItem> items}) = _$PowerShieldTemplateImpl;

  factory _PowerShieldTemplate.fromJson(Map<String, dynamic> json) =
      _$PowerShieldTemplateImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get description;
  @override
  List<PowerShieldTemplateItem> get items;
  @override
  @JsonKey(ignore: true)
  _$$PowerShieldTemplateImplCopyWith<_$PowerShieldTemplateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PowerShieldTemplateItem _$PowerShieldTemplateItemFromJson(
    Map<String, dynamic> json) {
  return _PowerShieldTemplateItem.fromJson(json);
}

/// @nodoc
mixin _$PowerShieldTemplateItem {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'device_type')
  String get deviceType => throw _privateConstructorUsedError;
  String get rating => throw _privateConstructorUsedError;
  String get poles => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  @JsonKey(name: 'catalog_item')
  int? get catalogItemId => throw _privateConstructorUsedError;
  @JsonKey(name: 'catalog_item_name')
  String? get catalogItemName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PowerShieldTemplateItemCopyWith<PowerShieldTemplateItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PowerShieldTemplateItemCopyWith<$Res> {
  factory $PowerShieldTemplateItemCopyWith(PowerShieldTemplateItem value,
          $Res Function(PowerShieldTemplateItem) then) =
      _$PowerShieldTemplateItemCopyWithImpl<$Res, PowerShieldTemplateItem>;
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'device_type') String deviceType,
      String rating,
      String poles,
      int quantity,
      @JsonKey(name: 'catalog_item') int? catalogItemId,
      @JsonKey(name: 'catalog_item_name') String? catalogItemName});
}

/// @nodoc
class _$PowerShieldTemplateItemCopyWithImpl<$Res,
        $Val extends PowerShieldTemplateItem>
    implements $PowerShieldTemplateItemCopyWith<$Res> {
  _$PowerShieldTemplateItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceType = null,
    Object? rating = null,
    Object? poles = null,
    Object? quantity = null,
    Object? catalogItemId = freezed,
    Object? catalogItemName = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      deviceType: null == deviceType
          ? _value.deviceType
          : deviceType // ignore: cast_nullable_to_non_nullable
              as String,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as String,
      poles: null == poles
          ? _value.poles
          : poles // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      catalogItemId: freezed == catalogItemId
          ? _value.catalogItemId
          : catalogItemId // ignore: cast_nullable_to_non_nullable
              as int?,
      catalogItemName: freezed == catalogItemName
          ? _value.catalogItemName
          : catalogItemName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PowerShieldTemplateItemImplCopyWith<$Res>
    implements $PowerShieldTemplateItemCopyWith<$Res> {
  factory _$$PowerShieldTemplateItemImplCopyWith(
          _$PowerShieldTemplateItemImpl value,
          $Res Function(_$PowerShieldTemplateItemImpl) then) =
      __$$PowerShieldTemplateItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'device_type') String deviceType,
      String rating,
      String poles,
      int quantity,
      @JsonKey(name: 'catalog_item') int? catalogItemId,
      @JsonKey(name: 'catalog_item_name') String? catalogItemName});
}

/// @nodoc
class __$$PowerShieldTemplateItemImplCopyWithImpl<$Res>
    extends _$PowerShieldTemplateItemCopyWithImpl<$Res,
        _$PowerShieldTemplateItemImpl>
    implements _$$PowerShieldTemplateItemImplCopyWith<$Res> {
  __$$PowerShieldTemplateItemImplCopyWithImpl(
      _$PowerShieldTemplateItemImpl _value,
      $Res Function(_$PowerShieldTemplateItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceType = null,
    Object? rating = null,
    Object? poles = null,
    Object? quantity = null,
    Object? catalogItemId = freezed,
    Object? catalogItemName = freezed,
  }) {
    return _then(_$PowerShieldTemplateItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      deviceType: null == deviceType
          ? _value.deviceType
          : deviceType // ignore: cast_nullable_to_non_nullable
              as String,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as String,
      poles: null == poles
          ? _value.poles
          : poles // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      catalogItemId: freezed == catalogItemId
          ? _value.catalogItemId
          : catalogItemId // ignore: cast_nullable_to_non_nullable
              as int?,
      catalogItemName: freezed == catalogItemName
          ? _value.catalogItemName
          : catalogItemName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PowerShieldTemplateItemImpl implements _PowerShieldTemplateItem {
  const _$PowerShieldTemplateItemImpl(
      {required this.id,
      @JsonKey(name: 'device_type') required this.deviceType,
      this.rating = '16A',
      this.poles = '1P',
      this.quantity = 1,
      @JsonKey(name: 'catalog_item') this.catalogItemId,
      @JsonKey(name: 'catalog_item_name') this.catalogItemName});

  factory _$PowerShieldTemplateItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PowerShieldTemplateItemImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'device_type')
  final String deviceType;
  @override
  @JsonKey()
  final String rating;
  @override
  @JsonKey()
  final String poles;
  @override
  @JsonKey()
  final int quantity;
  @override
  @JsonKey(name: 'catalog_item')
  final int? catalogItemId;
  @override
  @JsonKey(name: 'catalog_item_name')
  final String? catalogItemName;

  @override
  String toString() {
    return 'PowerShieldTemplateItem(id: $id, deviceType: $deviceType, rating: $rating, poles: $poles, quantity: $quantity, catalogItemId: $catalogItemId, catalogItemName: $catalogItemName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PowerShieldTemplateItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.deviceType, deviceType) ||
                other.deviceType == deviceType) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.poles, poles) || other.poles == poles) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.catalogItemId, catalogItemId) ||
                other.catalogItemId == catalogItemId) &&
            (identical(other.catalogItemName, catalogItemName) ||
                other.catalogItemName == catalogItemName));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, deviceType, rating, poles,
      quantity, catalogItemId, catalogItemName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PowerShieldTemplateItemImplCopyWith<_$PowerShieldTemplateItemImpl>
      get copyWith => __$$PowerShieldTemplateItemImplCopyWithImpl<
          _$PowerShieldTemplateItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PowerShieldTemplateItemImplToJson(
      this,
    );
  }
}

abstract class _PowerShieldTemplateItem implements PowerShieldTemplateItem {
  const factory _PowerShieldTemplateItem(
          {required final int id,
          @JsonKey(name: 'device_type') required final String deviceType,
          final String rating,
          final String poles,
          final int quantity,
          @JsonKey(name: 'catalog_item') final int? catalogItemId,
          @JsonKey(name: 'catalog_item_name') final String? catalogItemName}) =
      _$PowerShieldTemplateItemImpl;

  factory _PowerShieldTemplateItem.fromJson(Map<String, dynamic> json) =
      _$PowerShieldTemplateItemImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'device_type')
  String get deviceType;
  @override
  String get rating;
  @override
  String get poles;
  @override
  int get quantity;
  @override
  @JsonKey(name: 'catalog_item')
  int? get catalogItemId;
  @override
  @JsonKey(name: 'catalog_item_name')
  String? get catalogItemName;
  @override
  @JsonKey(ignore: true)
  _$$PowerShieldTemplateItemImplCopyWith<_$PowerShieldTemplateItemImpl>
      get copyWith => throw _privateConstructorUsedError;
}

LedShieldTemplate _$LedShieldTemplateFromJson(Map<String, dynamic> json) {
  return _LedShieldTemplate.fromJson(json);
}

/// @nodoc
mixin _$LedShieldTemplate {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<LedShieldTemplateItem> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LedShieldTemplateCopyWith<LedShieldTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LedShieldTemplateCopyWith<$Res> {
  factory $LedShieldTemplateCopyWith(
          LedShieldTemplate value, $Res Function(LedShieldTemplate) then) =
      _$LedShieldTemplateCopyWithImpl<$Res, LedShieldTemplate>;
  @useResult
  $Res call(
      {int id,
      String name,
      String description,
      List<LedShieldTemplateItem> items});
}

/// @nodoc
class _$LedShieldTemplateCopyWithImpl<$Res, $Val extends LedShieldTemplate>
    implements $LedShieldTemplateCopyWith<$Res> {
  _$LedShieldTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<LedShieldTemplateItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LedShieldTemplateImplCopyWith<$Res>
    implements $LedShieldTemplateCopyWith<$Res> {
  factory _$$LedShieldTemplateImplCopyWith(_$LedShieldTemplateImpl value,
          $Res Function(_$LedShieldTemplateImpl) then) =
      __$$LedShieldTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      String description,
      List<LedShieldTemplateItem> items});
}

/// @nodoc
class __$$LedShieldTemplateImplCopyWithImpl<$Res>
    extends _$LedShieldTemplateCopyWithImpl<$Res, _$LedShieldTemplateImpl>
    implements _$$LedShieldTemplateImplCopyWith<$Res> {
  __$$LedShieldTemplateImplCopyWithImpl(_$LedShieldTemplateImpl _value,
      $Res Function(_$LedShieldTemplateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? items = null,
  }) {
    return _then(_$LedShieldTemplateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<LedShieldTemplateItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LedShieldTemplateImpl implements _LedShieldTemplate {
  const _$LedShieldTemplateImpl(
      {required this.id,
      required this.name,
      required this.description,
      final List<LedShieldTemplateItem> items = const []})
      : _items = items;

  factory _$LedShieldTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$LedShieldTemplateImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String description;
  final List<LedShieldTemplateItem> _items;
  @override
  @JsonKey()
  List<LedShieldTemplateItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'LedShieldTemplate(id: $id, name: $name, description: $description, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LedShieldTemplateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description,
      const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LedShieldTemplateImplCopyWith<_$LedShieldTemplateImpl> get copyWith =>
      __$$LedShieldTemplateImplCopyWithImpl<_$LedShieldTemplateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LedShieldTemplateImplToJson(
      this,
    );
  }
}

abstract class _LedShieldTemplate implements LedShieldTemplate {
  const factory _LedShieldTemplate(
      {required final int id,
      required final String name,
      required final String description,
      final List<LedShieldTemplateItem> items}) = _$LedShieldTemplateImpl;

  factory _LedShieldTemplate.fromJson(Map<String, dynamic> json) =
      _$LedShieldTemplateImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get description;
  @override
  List<LedShieldTemplateItem> get items;
  @override
  @JsonKey(ignore: true)
  _$$LedShieldTemplateImplCopyWith<_$LedShieldTemplateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LedShieldTemplateItem _$LedShieldTemplateItemFromJson(
    Map<String, dynamic> json) {
  return _LedShieldTemplateItem.fromJson(json);
}

/// @nodoc
mixin _$LedShieldTemplateItem {
  int get id => throw _privateConstructorUsedError;
  String get transformer => throw _privateConstructorUsedError;
  String get zone => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  @JsonKey(name: 'catalog_item')
  int? get catalogItemId => throw _privateConstructorUsedError;
  @JsonKey(name: 'catalog_item_name')
  String? get catalogItemName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LedShieldTemplateItemCopyWith<LedShieldTemplateItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LedShieldTemplateItemCopyWith<$Res> {
  factory $LedShieldTemplateItemCopyWith(LedShieldTemplateItem value,
          $Res Function(LedShieldTemplateItem) then) =
      _$LedShieldTemplateItemCopyWithImpl<$Res, LedShieldTemplateItem>;
  @useResult
  $Res call(
      {int id,
      String transformer,
      String zone,
      int quantity,
      @JsonKey(name: 'catalog_item') int? catalogItemId,
      @JsonKey(name: 'catalog_item_name') String? catalogItemName});
}

/// @nodoc
class _$LedShieldTemplateItemCopyWithImpl<$Res,
        $Val extends LedShieldTemplateItem>
    implements $LedShieldTemplateItemCopyWith<$Res> {
  _$LedShieldTemplateItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? transformer = null,
    Object? zone = null,
    Object? quantity = null,
    Object? catalogItemId = freezed,
    Object? catalogItemName = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      transformer: null == transformer
          ? _value.transformer
          : transformer // ignore: cast_nullable_to_non_nullable
              as String,
      zone: null == zone
          ? _value.zone
          : zone // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      catalogItemId: freezed == catalogItemId
          ? _value.catalogItemId
          : catalogItemId // ignore: cast_nullable_to_non_nullable
              as int?,
      catalogItemName: freezed == catalogItemName
          ? _value.catalogItemName
          : catalogItemName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LedShieldTemplateItemImplCopyWith<$Res>
    implements $LedShieldTemplateItemCopyWith<$Res> {
  factory _$$LedShieldTemplateItemImplCopyWith(
          _$LedShieldTemplateItemImpl value,
          $Res Function(_$LedShieldTemplateItemImpl) then) =
      __$$LedShieldTemplateItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String transformer,
      String zone,
      int quantity,
      @JsonKey(name: 'catalog_item') int? catalogItemId,
      @JsonKey(name: 'catalog_item_name') String? catalogItemName});
}

/// @nodoc
class __$$LedShieldTemplateItemImplCopyWithImpl<$Res>
    extends _$LedShieldTemplateItemCopyWithImpl<$Res,
        _$LedShieldTemplateItemImpl>
    implements _$$LedShieldTemplateItemImplCopyWith<$Res> {
  __$$LedShieldTemplateItemImplCopyWithImpl(_$LedShieldTemplateItemImpl _value,
      $Res Function(_$LedShieldTemplateItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? transformer = null,
    Object? zone = null,
    Object? quantity = null,
    Object? catalogItemId = freezed,
    Object? catalogItemName = freezed,
  }) {
    return _then(_$LedShieldTemplateItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      transformer: null == transformer
          ? _value.transformer
          : transformer // ignore: cast_nullable_to_non_nullable
              as String,
      zone: null == zone
          ? _value.zone
          : zone // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      catalogItemId: freezed == catalogItemId
          ? _value.catalogItemId
          : catalogItemId // ignore: cast_nullable_to_non_nullable
              as int?,
      catalogItemName: freezed == catalogItemName
          ? _value.catalogItemName
          : catalogItemName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LedShieldTemplateItemImpl implements _LedShieldTemplateItem {
  const _$LedShieldTemplateItemImpl(
      {required this.id,
      required this.transformer,
      required this.zone,
      this.quantity = 1,
      @JsonKey(name: 'catalog_item') this.catalogItemId,
      @JsonKey(name: 'catalog_item_name') this.catalogItemName});

  factory _$LedShieldTemplateItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$LedShieldTemplateItemImplFromJson(json);

  @override
  final int id;
  @override
  final String transformer;
  @override
  final String zone;
  @override
  @JsonKey()
  final int quantity;
  @override
  @JsonKey(name: 'catalog_item')
  final int? catalogItemId;
  @override
  @JsonKey(name: 'catalog_item_name')
  final String? catalogItemName;

  @override
  String toString() {
    return 'LedShieldTemplateItem(id: $id, transformer: $transformer, zone: $zone, quantity: $quantity, catalogItemId: $catalogItemId, catalogItemName: $catalogItemName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LedShieldTemplateItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.transformer, transformer) ||
                other.transformer == transformer) &&
            (identical(other.zone, zone) || other.zone == zone) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.catalogItemId, catalogItemId) ||
                other.catalogItemId == catalogItemId) &&
            (identical(other.catalogItemName, catalogItemName) ||
                other.catalogItemName == catalogItemName));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, transformer, zone, quantity,
      catalogItemId, catalogItemName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LedShieldTemplateItemImplCopyWith<_$LedShieldTemplateItemImpl>
      get copyWith => __$$LedShieldTemplateItemImplCopyWithImpl<
          _$LedShieldTemplateItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LedShieldTemplateItemImplToJson(
      this,
    );
  }
}

abstract class _LedShieldTemplateItem implements LedShieldTemplateItem {
  const factory _LedShieldTemplateItem(
          {required final int id,
          required final String transformer,
          required final String zone,
          final int quantity,
          @JsonKey(name: 'catalog_item') final int? catalogItemId,
          @JsonKey(name: 'catalog_item_name') final String? catalogItemName}) =
      _$LedShieldTemplateItemImpl;

  factory _LedShieldTemplateItem.fromJson(Map<String, dynamic> json) =
      _$LedShieldTemplateItemImpl.fromJson;

  @override
  int get id;
  @override
  String get transformer;
  @override
  String get zone;
  @override
  int get quantity;
  @override
  @JsonKey(name: 'catalog_item')
  int? get catalogItemId;
  @override
  @JsonKey(name: 'catalog_item_name')
  String? get catalogItemName;
  @override
  @JsonKey(ignore: true)
  _$$LedShieldTemplateItemImplCopyWith<_$LedShieldTemplateItemImpl>
      get copyWith => throw _privateConstructorUsedError;
}
