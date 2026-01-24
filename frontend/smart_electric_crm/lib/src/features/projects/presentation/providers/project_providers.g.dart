// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$projectRepositoryHash() => r'7e4616dc391c7bb9ba82f8c14aae190a6f343a8c';

/// Провайдер репозитория проектов
///
/// Copied from [projectRepository].
@ProviderFor(projectRepository)
final projectRepositoryProvider =
    AutoDisposeProvider<ProjectRepository>.internal(
  projectRepository,
  name: r'projectRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$projectRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProjectRepositoryRef = AutoDisposeProviderRef<ProjectRepository>;
String _$projectListHash() => r'c93522e5603017c97481e8e2bf315c40b705bc9a';

/// Провайдер списка проектов.
/// Использует AsyncNotifier для управления состоянием загрузки и данных.
///
/// Copied from [ProjectList].
@ProviderFor(ProjectList)
final projectListProvider =
    AutoDisposeAsyncNotifierProvider<ProjectList, List<ProjectModel>>.internal(
  ProjectList.new,
  name: r'projectListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$projectListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProjectList = AutoDisposeAsyncNotifier<List<ProjectModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
