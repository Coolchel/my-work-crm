// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$catalogRepositoryHash() => r'85d1a9859aa3359f020265cc140e9ab057243b54';

/// See also [catalogRepository].
@ProviderFor(catalogRepository)
final catalogRepositoryProvider =
    AutoDisposeProvider<CatalogRepository>.internal(
  catalogRepository,
  name: r'catalogRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$catalogRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CatalogRepositoryRef = AutoDisposeProviderRef<CatalogRepository>;
String _$fetchCategoriesHash() => r'd75b6afeed746e7fd33db4cd432628a162abc558';

/// See also [fetchCategories].
@ProviderFor(fetchCategories)
final fetchCategoriesProvider =
    AutoDisposeFutureProvider<List<CatalogCategory>>.internal(
  fetchCategories,
  name: r'fetchCategoriesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fetchCategoriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FetchCategoriesRef
    = AutoDisposeFutureProviderRef<List<CatalogCategory>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
