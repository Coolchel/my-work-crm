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
String _$projectByIdHash() => r'59ac53b67415c55a763f2af80143ee4766c63d6d';

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

/// See also [projectById].
@ProviderFor(projectById)
const projectByIdProvider = ProjectByIdFamily();

/// See also [projectById].
class ProjectByIdFamily extends Family<AsyncValue<ProjectModel>> {
  /// See also [projectById].
  const ProjectByIdFamily();

  /// See also [projectById].
  ProjectByIdProvider call(
    String id,
  ) {
    return ProjectByIdProvider(
      id,
    );
  }

  @override
  ProjectByIdProvider getProviderOverride(
    covariant ProjectByIdProvider provider,
  ) {
    return call(
      provider.id,
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
  String? get name => r'projectByIdProvider';
}

/// See also [projectById].
class ProjectByIdProvider extends AutoDisposeFutureProvider<ProjectModel> {
  /// See also [projectById].
  ProjectByIdProvider(
    String id,
  ) : this._internal(
          (ref) => projectById(
            ref as ProjectByIdRef,
            id,
          ),
          from: projectByIdProvider,
          name: r'projectByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$projectByIdHash,
          dependencies: ProjectByIdFamily._dependencies,
          allTransitiveDependencies:
              ProjectByIdFamily._allTransitiveDependencies,
          id: id,
        );

  ProjectByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<ProjectModel> Function(ProjectByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProjectByIdProvider._internal(
        (ref) => create(ref as ProjectByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ProjectModel> createElement() {
    return _ProjectByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ProjectByIdRef on AutoDisposeFutureProviderRef<ProjectModel> {
  /// The parameter `id` of this provider.
  String get id;
}

class _ProjectByIdProviderElement
    extends AutoDisposeFutureProviderElement<ProjectModel> with ProjectByIdRef {
  _ProjectByIdProviderElement(super.provider);

  @override
  String get id => (origin as ProjectByIdProvider).id;
}

String _$projectListHash() => r'82ae81e798722dadbea354090d3f43992cd1f7e4';

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
