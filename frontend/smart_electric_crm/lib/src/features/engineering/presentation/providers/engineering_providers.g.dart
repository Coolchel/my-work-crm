// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engineering_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$engineeringRepositoryHash() =>
    r'013c5a5bb52a418fef37d437a418967e9d882fc3';

/// Провайдер репозитория
///
/// Copied from [engineeringRepository].
@ProviderFor(engineeringRepository)
final engineeringRepositoryProvider =
    AutoDisposeProvider<EngineeringRepository>.internal(
  engineeringRepository,
  name: r'engineeringRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$engineeringRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef EngineeringRepositoryRef
    = AutoDisposeProviderRef<EngineeringRepository>;
String _$shieldTemplatesHash() => r'62fb602bdcdb873e415d1c0da0dba148195b254c';

/// Провайдер списка шаблонов щитов
///
/// Copied from [shieldTemplates].
@ProviderFor(shieldTemplates)
final shieldTemplatesProvider =
    AutoDisposeFutureProvider<List<ShieldTemplateModel>>.internal(
  shieldTemplates,
  name: r'shieldTemplatesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$shieldTemplatesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ShieldTemplatesRef
    = AutoDisposeFutureProviderRef<List<ShieldTemplateModel>>;
String _$ledTemplatesHash() => r'394c54c35c02d41292b148512e96b7376c27f926';

/// Провайдер списка шаблонов LED
///
/// Copied from [ledTemplates].
@ProviderFor(ledTemplates)
final ledTemplatesProvider =
    AutoDisposeFutureProvider<List<LedTemplateModel>>.internal(
  ledTemplates,
  name: r'ledTemplatesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$ledTemplatesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LedTemplatesRef = AutoDisposeFutureProviderRef<List<LedTemplateModel>>;
String _$shieldGroupsHash() => r'9121f5d16fb8b16ed9cd93742be054c524f19d42';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$ShieldGroups
    extends BuildlessAutoDisposeAsyncNotifier<List<ShieldGroupModel>> {
  late final String projectId;

  FutureOr<List<ShieldGroupModel>> build(
    String projectId,
  );
}

/// Провайдер для получения списка групп щита проекта
///
/// Copied from [ShieldGroups].
@ProviderFor(ShieldGroups)
const shieldGroupsProvider = ShieldGroupsFamily();

/// Провайдер для получения списка групп щита проекта
///
/// Copied from [ShieldGroups].
class ShieldGroupsFamily extends Family<AsyncValue<List<ShieldGroupModel>>> {
  /// Провайдер для получения списка групп щита проекта
  ///
  /// Copied from [ShieldGroups].
  const ShieldGroupsFamily();

  /// Провайдер для получения списка групп щита проекта
  ///
  /// Copied from [ShieldGroups].
  ShieldGroupsProvider call(
    String projectId,
  ) {
    return ShieldGroupsProvider(
      projectId,
    );
  }

  @override
  ShieldGroupsProvider getProviderOverride(
    covariant ShieldGroupsProvider provider,
  ) {
    return call(
      provider.projectId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'shieldGroupsProvider';
}

/// Провайдер для получения списка групп щита проекта
///
/// Copied from [ShieldGroups].
class ShieldGroupsProvider extends AutoDisposeAsyncNotifierProviderImpl<
    ShieldGroups, List<ShieldGroupModel>> {
  /// Провайдер для получения списка групп щита проекта
  ///
  /// Copied from [ShieldGroups].
  ShieldGroupsProvider(
    String projectId,
  ) : this._internal(
          () => ShieldGroups()..projectId = projectId,
          from: shieldGroupsProvider,
          name: r'shieldGroupsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$shieldGroupsHash,
          dependencies: ShieldGroupsFamily._dependencies,
          allTransitiveDependencies:
              ShieldGroupsFamily._allTransitiveDependencies,
          projectId: projectId,
        );

  ShieldGroupsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.projectId,
  }) : super.internal();

  final String projectId;

  @override
  FutureOr<List<ShieldGroupModel>> runNotifierBuild(
    covariant ShieldGroups notifier,
  ) {
    return notifier.build(
      projectId,
    );
  }

  @override
  Override overrideWith(ShieldGroups Function() create) {
    return ProviderOverride(
      origin: this,
      override: ShieldGroupsProvider._internal(
        () => create()..projectId = projectId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        projectId: projectId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<ShieldGroups, List<ShieldGroupModel>>
      createElement() {
    return _ShieldGroupsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShieldGroupsProvider && other.projectId == projectId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, projectId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ShieldGroupsRef
    on AutoDisposeAsyncNotifierProviderRef<List<ShieldGroupModel>> {
  /// The parameter `projectId` of this provider.
  String get projectId;
}

class _ShieldGroupsProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ShieldGroups,
        List<ShieldGroupModel>> with ShieldGroupsRef {
  _ShieldGroupsProviderElement(super.provider);

  @override
  String get projectId => (origin as ShieldGroupsProvider).projectId;
}

String _$ledZonesHash() => r'4ced740de0bdb271376dce789042d946a020782a';

abstract class _$LedZones
    extends BuildlessAutoDisposeAsyncNotifier<List<LedZoneModel>> {
  late final String projectId;

  FutureOr<List<LedZoneModel>> build(
    String projectId,
  );
}

/// Провайдер для получения списка зон LED проекта
///
/// Copied from [LedZones].
@ProviderFor(LedZones)
const ledZonesProvider = LedZonesFamily();

/// Провайдер для получения списка зон LED проекта
///
/// Copied from [LedZones].
class LedZonesFamily extends Family<AsyncValue<List<LedZoneModel>>> {
  /// Провайдер для получения списка зон LED проекта
  ///
  /// Copied from [LedZones].
  const LedZonesFamily();

  /// Провайдер для получения списка зон LED проекта
  ///
  /// Copied from [LedZones].
  LedZonesProvider call(
    String projectId,
  ) {
    return LedZonesProvider(
      projectId,
    );
  }

  @override
  LedZonesProvider getProviderOverride(
    covariant LedZonesProvider provider,
  ) {
    return call(
      provider.projectId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'ledZonesProvider';
}

/// Провайдер для получения списка зон LED проекта
///
/// Copied from [LedZones].
class LedZonesProvider
    extends AutoDisposeAsyncNotifierProviderImpl<LedZones, List<LedZoneModel>> {
  /// Провайдер для получения списка зон LED проекта
  ///
  /// Copied from [LedZones].
  LedZonesProvider(
    String projectId,
  ) : this._internal(
          () => LedZones()..projectId = projectId,
          from: ledZonesProvider,
          name: r'ledZonesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$ledZonesHash,
          dependencies: LedZonesFamily._dependencies,
          allTransitiveDependencies: LedZonesFamily._allTransitiveDependencies,
          projectId: projectId,
        );

  LedZonesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.projectId,
  }) : super.internal();

  final String projectId;

  @override
  FutureOr<List<LedZoneModel>> runNotifierBuild(
    covariant LedZones notifier,
  ) {
    return notifier.build(
      projectId,
    );
  }

  @override
  Override overrideWith(LedZones Function() create) {
    return ProviderOverride(
      origin: this,
      override: LedZonesProvider._internal(
        () => create()..projectId = projectId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        projectId: projectId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<LedZones, List<LedZoneModel>>
      createElement() {
    return _LedZonesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LedZonesProvider && other.projectId == projectId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, projectId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LedZonesRef on AutoDisposeAsyncNotifierProviderRef<List<LedZoneModel>> {
  /// The parameter `projectId` of this provider.
  String get projectId;
}

class _LedZonesProviderElement extends AutoDisposeAsyncNotifierProviderElement<
    LedZones, List<LedZoneModel>> with LedZonesRef {
  _LedZonesProviderElement(super.provider);

  @override
  String get projectId => (origin as LedZonesProvider).projectId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
