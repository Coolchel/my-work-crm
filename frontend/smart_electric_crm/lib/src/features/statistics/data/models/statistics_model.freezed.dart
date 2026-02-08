// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'statistics_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StatisticsModel _$StatisticsModelFromJson(Map<String, dynamic> json) {
  return _StatisticsModel.fromJson(json);
}

/// @nodoc
mixin _$StatisticsModel {
  PipelineData get pipeline => throw _privateConstructorUsedError;
  List<SourceData> get sources => throw _privateConstructorUsedError;
  @JsonKey(name: 'object_types')
  List<ObjectTypeData> get objectTypes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StatisticsModelCopyWith<StatisticsModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StatisticsModelCopyWith<$Res> {
  factory $StatisticsModelCopyWith(
          StatisticsModel value, $Res Function(StatisticsModel) then) =
      _$StatisticsModelCopyWithImpl<$Res, StatisticsModel>;
  @useResult
  $Res call(
      {PipelineData pipeline,
      List<SourceData> sources,
      @JsonKey(name: 'object_types') List<ObjectTypeData> objectTypes});

  $PipelineDataCopyWith<$Res> get pipeline;
}

/// @nodoc
class _$StatisticsModelCopyWithImpl<$Res, $Val extends StatisticsModel>
    implements $StatisticsModelCopyWith<$Res> {
  _$StatisticsModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pipeline = null,
    Object? sources = null,
    Object? objectTypes = null,
  }) {
    return _then(_value.copyWith(
      pipeline: null == pipeline
          ? _value.pipeline
          : pipeline // ignore: cast_nullable_to_non_nullable
              as PipelineData,
      sources: null == sources
          ? _value.sources
          : sources // ignore: cast_nullable_to_non_nullable
              as List<SourceData>,
      objectTypes: null == objectTypes
          ? _value.objectTypes
          : objectTypes // ignore: cast_nullable_to_non_nullable
              as List<ObjectTypeData>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $PipelineDataCopyWith<$Res> get pipeline {
    return $PipelineDataCopyWith<$Res>(_value.pipeline, (value) {
      return _then(_value.copyWith(pipeline: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$StatisticsModelImplCopyWith<$Res>
    implements $StatisticsModelCopyWith<$Res> {
  factory _$$StatisticsModelImplCopyWith(_$StatisticsModelImpl value,
          $Res Function(_$StatisticsModelImpl) then) =
      __$$StatisticsModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PipelineData pipeline,
      List<SourceData> sources,
      @JsonKey(name: 'object_types') List<ObjectTypeData> objectTypes});

  @override
  $PipelineDataCopyWith<$Res> get pipeline;
}

/// @nodoc
class __$$StatisticsModelImplCopyWithImpl<$Res>
    extends _$StatisticsModelCopyWithImpl<$Res, _$StatisticsModelImpl>
    implements _$$StatisticsModelImplCopyWith<$Res> {
  __$$StatisticsModelImplCopyWithImpl(
      _$StatisticsModelImpl _value, $Res Function(_$StatisticsModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pipeline = null,
    Object? sources = null,
    Object? objectTypes = null,
  }) {
    return _then(_$StatisticsModelImpl(
      pipeline: null == pipeline
          ? _value.pipeline
          : pipeline // ignore: cast_nullable_to_non_nullable
              as PipelineData,
      sources: null == sources
          ? _value._sources
          : sources // ignore: cast_nullable_to_non_nullable
              as List<SourceData>,
      objectTypes: null == objectTypes
          ? _value._objectTypes
          : objectTypes // ignore: cast_nullable_to_non_nullable
              as List<ObjectTypeData>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StatisticsModelImpl implements _StatisticsModel {
  const _$StatisticsModelImpl(
      {required this.pipeline,
      required final List<SourceData> sources,
      @JsonKey(name: 'object_types')
      required final List<ObjectTypeData> objectTypes})
      : _sources = sources,
        _objectTypes = objectTypes;

  factory _$StatisticsModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StatisticsModelImplFromJson(json);

  @override
  final PipelineData pipeline;
  final List<SourceData> _sources;
  @override
  List<SourceData> get sources {
    if (_sources is EqualUnmodifiableListView) return _sources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sources);
  }

  final List<ObjectTypeData> _objectTypes;
  @override
  @JsonKey(name: 'object_types')
  List<ObjectTypeData> get objectTypes {
    if (_objectTypes is EqualUnmodifiableListView) return _objectTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_objectTypes);
  }

  @override
  String toString() {
    return 'StatisticsModel(pipeline: $pipeline, sources: $sources, objectTypes: $objectTypes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StatisticsModelImpl &&
            (identical(other.pipeline, pipeline) ||
                other.pipeline == pipeline) &&
            const DeepCollectionEquality().equals(other._sources, _sources) &&
            const DeepCollectionEquality()
                .equals(other._objectTypes, _objectTypes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      pipeline,
      const DeepCollectionEquality().hash(_sources),
      const DeepCollectionEquality().hash(_objectTypes));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StatisticsModelImplCopyWith<_$StatisticsModelImpl> get copyWith =>
      __$$StatisticsModelImplCopyWithImpl<_$StatisticsModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StatisticsModelImplToJson(
      this,
    );
  }
}

abstract class _StatisticsModel implements StatisticsModel {
  const factory _StatisticsModel(
      {required final PipelineData pipeline,
      required final List<SourceData> sources,
      @JsonKey(name: 'object_types')
      required final List<ObjectTypeData> objectTypes}) = _$StatisticsModelImpl;

  factory _StatisticsModel.fromJson(Map<String, dynamic> json) =
      _$StatisticsModelImpl.fromJson;

  @override
  PipelineData get pipeline;
  @override
  List<SourceData> get sources;
  @override
  @JsonKey(name: 'object_types')
  List<ObjectTypeData> get objectTypes;
  @override
  @JsonKey(ignore: true)
  _$$StatisticsModelImplCopyWith<_$StatisticsModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PipelineData _$PipelineDataFromJson(Map<String, dynamic> json) {
  return _PipelineData.fromJson(json);
}

/// @nodoc
mixin _$PipelineData {
  CurrencyAmount get paid => throw _privateConstructorUsedError;
  CurrencyAmount get pending => throw _privateConstructorUsedError;
  @JsonKey(name: 'in_work')
  CurrencyAmount get inWork => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PipelineDataCopyWith<PipelineData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PipelineDataCopyWith<$Res> {
  factory $PipelineDataCopyWith(
          PipelineData value, $Res Function(PipelineData) then) =
      _$PipelineDataCopyWithImpl<$Res, PipelineData>;
  @useResult
  $Res call(
      {CurrencyAmount paid,
      CurrencyAmount pending,
      @JsonKey(name: 'in_work') CurrencyAmount inWork});

  $CurrencyAmountCopyWith<$Res> get paid;
  $CurrencyAmountCopyWith<$Res> get pending;
  $CurrencyAmountCopyWith<$Res> get inWork;
}

/// @nodoc
class _$PipelineDataCopyWithImpl<$Res, $Val extends PipelineData>
    implements $PipelineDataCopyWith<$Res> {
  _$PipelineDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? paid = null,
    Object? pending = null,
    Object? inWork = null,
  }) {
    return _then(_value.copyWith(
      paid: null == paid
          ? _value.paid
          : paid // ignore: cast_nullable_to_non_nullable
              as CurrencyAmount,
      pending: null == pending
          ? _value.pending
          : pending // ignore: cast_nullable_to_non_nullable
              as CurrencyAmount,
      inWork: null == inWork
          ? _value.inWork
          : inWork // ignore: cast_nullable_to_non_nullable
              as CurrencyAmount,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $CurrencyAmountCopyWith<$Res> get paid {
    return $CurrencyAmountCopyWith<$Res>(_value.paid, (value) {
      return _then(_value.copyWith(paid: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $CurrencyAmountCopyWith<$Res> get pending {
    return $CurrencyAmountCopyWith<$Res>(_value.pending, (value) {
      return _then(_value.copyWith(pending: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $CurrencyAmountCopyWith<$Res> get inWork {
    return $CurrencyAmountCopyWith<$Res>(_value.inWork, (value) {
      return _then(_value.copyWith(inWork: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PipelineDataImplCopyWith<$Res>
    implements $PipelineDataCopyWith<$Res> {
  factory _$$PipelineDataImplCopyWith(
          _$PipelineDataImpl value, $Res Function(_$PipelineDataImpl) then) =
      __$$PipelineDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {CurrencyAmount paid,
      CurrencyAmount pending,
      @JsonKey(name: 'in_work') CurrencyAmount inWork});

  @override
  $CurrencyAmountCopyWith<$Res> get paid;
  @override
  $CurrencyAmountCopyWith<$Res> get pending;
  @override
  $CurrencyAmountCopyWith<$Res> get inWork;
}

/// @nodoc
class __$$PipelineDataImplCopyWithImpl<$Res>
    extends _$PipelineDataCopyWithImpl<$Res, _$PipelineDataImpl>
    implements _$$PipelineDataImplCopyWith<$Res> {
  __$$PipelineDataImplCopyWithImpl(
      _$PipelineDataImpl _value, $Res Function(_$PipelineDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? paid = null,
    Object? pending = null,
    Object? inWork = null,
  }) {
    return _then(_$PipelineDataImpl(
      paid: null == paid
          ? _value.paid
          : paid // ignore: cast_nullable_to_non_nullable
              as CurrencyAmount,
      pending: null == pending
          ? _value.pending
          : pending // ignore: cast_nullable_to_non_nullable
              as CurrencyAmount,
      inWork: null == inWork
          ? _value.inWork
          : inWork // ignore: cast_nullable_to_non_nullable
              as CurrencyAmount,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PipelineDataImpl implements _PipelineData {
  const _$PipelineDataImpl(
      {required this.paid,
      required this.pending,
      @JsonKey(name: 'in_work') required this.inWork});

  factory _$PipelineDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$PipelineDataImplFromJson(json);

  @override
  final CurrencyAmount paid;
  @override
  final CurrencyAmount pending;
  @override
  @JsonKey(name: 'in_work')
  final CurrencyAmount inWork;

  @override
  String toString() {
    return 'PipelineData(paid: $paid, pending: $pending, inWork: $inWork)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PipelineDataImpl &&
            (identical(other.paid, paid) || other.paid == paid) &&
            (identical(other.pending, pending) || other.pending == pending) &&
            (identical(other.inWork, inWork) || other.inWork == inWork));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, paid, pending, inWork);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PipelineDataImplCopyWith<_$PipelineDataImpl> get copyWith =>
      __$$PipelineDataImplCopyWithImpl<_$PipelineDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PipelineDataImplToJson(
      this,
    );
  }
}

abstract class _PipelineData implements PipelineData {
  const factory _PipelineData(
          {required final CurrencyAmount paid,
          required final CurrencyAmount pending,
          @JsonKey(name: 'in_work') required final CurrencyAmount inWork}) =
      _$PipelineDataImpl;

  factory _PipelineData.fromJson(Map<String, dynamic> json) =
      _$PipelineDataImpl.fromJson;

  @override
  CurrencyAmount get paid;
  @override
  CurrencyAmount get pending;
  @override
  @JsonKey(name: 'in_work')
  CurrencyAmount get inWork;
  @override
  @JsonKey(ignore: true)
  _$$PipelineDataImplCopyWith<_$PipelineDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CurrencyAmount _$CurrencyAmountFromJson(Map<String, dynamic> json) {
  return _CurrencyAmount.fromJson(json);
}

/// @nodoc
mixin _$CurrencyAmount {
  double get usd => throw _privateConstructorUsedError;
  double get byn => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CurrencyAmountCopyWith<CurrencyAmount> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CurrencyAmountCopyWith<$Res> {
  factory $CurrencyAmountCopyWith(
          CurrencyAmount value, $Res Function(CurrencyAmount) then) =
      _$CurrencyAmountCopyWithImpl<$Res, CurrencyAmount>;
  @useResult
  $Res call({double usd, double byn});
}

/// @nodoc
class _$CurrencyAmountCopyWithImpl<$Res, $Val extends CurrencyAmount>
    implements $CurrencyAmountCopyWith<$Res> {
  _$CurrencyAmountCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? usd = null,
    Object? byn = null,
  }) {
    return _then(_value.copyWith(
      usd: null == usd
          ? _value.usd
          : usd // ignore: cast_nullable_to_non_nullable
              as double,
      byn: null == byn
          ? _value.byn
          : byn // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CurrencyAmountImplCopyWith<$Res>
    implements $CurrencyAmountCopyWith<$Res> {
  factory _$$CurrencyAmountImplCopyWith(_$CurrencyAmountImpl value,
          $Res Function(_$CurrencyAmountImpl) then) =
      __$$CurrencyAmountImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double usd, double byn});
}

/// @nodoc
class __$$CurrencyAmountImplCopyWithImpl<$Res>
    extends _$CurrencyAmountCopyWithImpl<$Res, _$CurrencyAmountImpl>
    implements _$$CurrencyAmountImplCopyWith<$Res> {
  __$$CurrencyAmountImplCopyWithImpl(
      _$CurrencyAmountImpl _value, $Res Function(_$CurrencyAmountImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? usd = null,
    Object? byn = null,
  }) {
    return _then(_$CurrencyAmountImpl(
      usd: null == usd
          ? _value.usd
          : usd // ignore: cast_nullable_to_non_nullable
              as double,
      byn: null == byn
          ? _value.byn
          : byn // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CurrencyAmountImpl implements _CurrencyAmount {
  const _$CurrencyAmountImpl({required this.usd, required this.byn});

  factory _$CurrencyAmountImpl.fromJson(Map<String, dynamic> json) =>
      _$$CurrencyAmountImplFromJson(json);

  @override
  final double usd;
  @override
  final double byn;

  @override
  String toString() {
    return 'CurrencyAmount(usd: $usd, byn: $byn)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CurrencyAmountImpl &&
            (identical(other.usd, usd) || other.usd == usd) &&
            (identical(other.byn, byn) || other.byn == byn));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, usd, byn);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CurrencyAmountImplCopyWith<_$CurrencyAmountImpl> get copyWith =>
      __$$CurrencyAmountImplCopyWithImpl<_$CurrencyAmountImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CurrencyAmountImplToJson(
      this,
    );
  }
}

abstract class _CurrencyAmount implements CurrencyAmount {
  const factory _CurrencyAmount(
      {required final double usd,
      required final double byn}) = _$CurrencyAmountImpl;

  factory _CurrencyAmount.fromJson(Map<String, dynamic> json) =
      _$CurrencyAmountImpl.fromJson;

  @override
  double get usd;
  @override
  double get byn;
  @override
  @JsonKey(ignore: true)
  _$$CurrencyAmountImplCopyWith<_$CurrencyAmountImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SourceData _$SourceDataFromJson(Map<String, dynamic> json) {
  return _SourceData.fromJson(json);
}

/// @nodoc
mixin _$SourceData {
  String get name => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  double get usd => throw _privateConstructorUsedError;
  double get byn => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SourceDataCopyWith<SourceData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SourceDataCopyWith<$Res> {
  factory $SourceDataCopyWith(
          SourceData value, $Res Function(SourceData) then) =
      _$SourceDataCopyWithImpl<$Res, SourceData>;
  @useResult
  $Res call({String name, int count, double usd, double byn});
}

/// @nodoc
class _$SourceDataCopyWithImpl<$Res, $Val extends SourceData>
    implements $SourceDataCopyWith<$Res> {
  _$SourceDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? count = null,
    Object? usd = null,
    Object? byn = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      usd: null == usd
          ? _value.usd
          : usd // ignore: cast_nullable_to_non_nullable
              as double,
      byn: null == byn
          ? _value.byn
          : byn // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SourceDataImplCopyWith<$Res>
    implements $SourceDataCopyWith<$Res> {
  factory _$$SourceDataImplCopyWith(
          _$SourceDataImpl value, $Res Function(_$SourceDataImpl) then) =
      __$$SourceDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, int count, double usd, double byn});
}

/// @nodoc
class __$$SourceDataImplCopyWithImpl<$Res>
    extends _$SourceDataCopyWithImpl<$Res, _$SourceDataImpl>
    implements _$$SourceDataImplCopyWith<$Res> {
  __$$SourceDataImplCopyWithImpl(
      _$SourceDataImpl _value, $Res Function(_$SourceDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? count = null,
    Object? usd = null,
    Object? byn = null,
  }) {
    return _then(_$SourceDataImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      usd: null == usd
          ? _value.usd
          : usd // ignore: cast_nullable_to_non_nullable
              as double,
      byn: null == byn
          ? _value.byn
          : byn // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SourceDataImpl implements _SourceData {
  const _$SourceDataImpl(
      {required this.name,
      required this.count,
      required this.usd,
      required this.byn});

  factory _$SourceDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SourceDataImplFromJson(json);

  @override
  final String name;
  @override
  final int count;
  @override
  final double usd;
  @override
  final double byn;

  @override
  String toString() {
    return 'SourceData(name: $name, count: $count, usd: $usd, byn: $byn)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SourceDataImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.usd, usd) || other.usd == usd) &&
            (identical(other.byn, byn) || other.byn == byn));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, count, usd, byn);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SourceDataImplCopyWith<_$SourceDataImpl> get copyWith =>
      __$$SourceDataImplCopyWithImpl<_$SourceDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SourceDataImplToJson(
      this,
    );
  }
}

abstract class _SourceData implements SourceData {
  const factory _SourceData(
      {required final String name,
      required final int count,
      required final double usd,
      required final double byn}) = _$SourceDataImpl;

  factory _SourceData.fromJson(Map<String, dynamic> json) =
      _$SourceDataImpl.fromJson;

  @override
  String get name;
  @override
  int get count;
  @override
  double get usd;
  @override
  double get byn;
  @override
  @JsonKey(ignore: true)
  _$$SourceDataImplCopyWith<_$SourceDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ObjectTypeData _$ObjectTypeDataFromJson(Map<String, dynamic> json) {
  return _ObjectTypeData.fromJson(json);
}

/// @nodoc
mixin _$ObjectTypeData {
  String get name => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;
  double get usd => throw _privateConstructorUsedError;
  double get byn => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ObjectTypeDataCopyWith<ObjectTypeData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ObjectTypeDataCopyWith<$Res> {
  factory $ObjectTypeDataCopyWith(
          ObjectTypeData value, $Res Function(ObjectTypeData) then) =
      _$ObjectTypeDataCopyWithImpl<$Res, ObjectTypeData>;
  @useResult
  $Res call({String name, int count, double usd, double byn});
}

/// @nodoc
class _$ObjectTypeDataCopyWithImpl<$Res, $Val extends ObjectTypeData>
    implements $ObjectTypeDataCopyWith<$Res> {
  _$ObjectTypeDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? count = null,
    Object? usd = null,
    Object? byn = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      usd: null == usd
          ? _value.usd
          : usd // ignore: cast_nullable_to_non_nullable
              as double,
      byn: null == byn
          ? _value.byn
          : byn // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ObjectTypeDataImplCopyWith<$Res>
    implements $ObjectTypeDataCopyWith<$Res> {
  factory _$$ObjectTypeDataImplCopyWith(_$ObjectTypeDataImpl value,
          $Res Function(_$ObjectTypeDataImpl) then) =
      __$$ObjectTypeDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, int count, double usd, double byn});
}

/// @nodoc
class __$$ObjectTypeDataImplCopyWithImpl<$Res>
    extends _$ObjectTypeDataCopyWithImpl<$Res, _$ObjectTypeDataImpl>
    implements _$$ObjectTypeDataImplCopyWith<$Res> {
  __$$ObjectTypeDataImplCopyWithImpl(
      _$ObjectTypeDataImpl _value, $Res Function(_$ObjectTypeDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? count = null,
    Object? usd = null,
    Object? byn = null,
  }) {
    return _then(_$ObjectTypeDataImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      usd: null == usd
          ? _value.usd
          : usd // ignore: cast_nullable_to_non_nullable
              as double,
      byn: null == byn
          ? _value.byn
          : byn // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ObjectTypeDataImpl implements _ObjectTypeData {
  const _$ObjectTypeDataImpl(
      {required this.name,
      required this.count,
      required this.usd,
      required this.byn});

  factory _$ObjectTypeDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$ObjectTypeDataImplFromJson(json);

  @override
  final String name;
  @override
  final int count;
  @override
  final double usd;
  @override
  final double byn;

  @override
  String toString() {
    return 'ObjectTypeData(name: $name, count: $count, usd: $usd, byn: $byn)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ObjectTypeDataImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.usd, usd) || other.usd == usd) &&
            (identical(other.byn, byn) || other.byn == byn));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, count, usd, byn);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ObjectTypeDataImplCopyWith<_$ObjectTypeDataImpl> get copyWith =>
      __$$ObjectTypeDataImplCopyWithImpl<_$ObjectTypeDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ObjectTypeDataImplToJson(
      this,
    );
  }
}

abstract class _ObjectTypeData implements ObjectTypeData {
  const factory _ObjectTypeData(
      {required final String name,
      required final int count,
      required final double usd,
      required final double byn}) = _$ObjectTypeDataImpl;

  factory _ObjectTypeData.fromJson(Map<String, dynamic> json) =
      _$ObjectTypeDataImpl.fromJson;

  @override
  String get name;
  @override
  int get count;
  @override
  double get usd;
  @override
  double get byn;
  @override
  @JsonKey(ignore: true)
  _$$ObjectTypeDataImplCopyWith<_$ObjectTypeDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
