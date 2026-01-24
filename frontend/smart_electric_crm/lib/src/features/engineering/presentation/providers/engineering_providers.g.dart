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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
