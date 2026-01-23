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
String _$fetchCategoryItemsHash() =>
    r'6fb1f7b9ec3323520c7564ff008db3a139044ae8';

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

/// See also [fetchCategoryItems].
@ProviderFor(fetchCategoryItems)
const fetchCategoryItemsProvider = FetchCategoryItemsFamily();

/// See also [fetchCategoryItems].
class FetchCategoryItemsFamily extends Family<AsyncValue<List<CatalogItem>>> {
  /// See also [fetchCategoryItems].
  const FetchCategoryItemsFamily();

  /// See also [fetchCategoryItems].
  FetchCategoryItemsProvider call(
    int categoryId,
  ) {
    return FetchCategoryItemsProvider(
      categoryId,
    );
  }

  @override
  FetchCategoryItemsProvider getProviderOverride(
    covariant FetchCategoryItemsProvider provider,
  ) {
    return call(
      provider.categoryId,
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
  String? get name => r'fetchCategoryItemsProvider';
}

/// See also [fetchCategoryItems].
class FetchCategoryItemsProvider
    extends AutoDisposeFutureProvider<List<CatalogItem>> {
  /// See also [fetchCategoryItems].
  FetchCategoryItemsProvider(
    int categoryId,
  ) : this._internal(
          (ref) => fetchCategoryItems(
            ref as FetchCategoryItemsRef,
            categoryId,
          ),
          from: fetchCategoryItemsProvider,
          name: r'fetchCategoryItemsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fetchCategoryItemsHash,
          dependencies: FetchCategoryItemsFamily._dependencies,
          allTransitiveDependencies:
              FetchCategoryItemsFamily._allTransitiveDependencies,
          categoryId: categoryId,
        );

  FetchCategoryItemsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.categoryId,
  }) : super.internal();

  final int categoryId;

  @override
  Override overrideWith(
    FutureOr<List<CatalogItem>> Function(FetchCategoryItemsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FetchCategoryItemsProvider._internal(
        (ref) => create(ref as FetchCategoryItemsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        categoryId: categoryId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<CatalogItem>> createElement() {
    return _FetchCategoryItemsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchCategoryItemsProvider &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, categoryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FetchCategoryItemsRef on AutoDisposeFutureProviderRef<List<CatalogItem>> {
  /// The parameter `categoryId` of this provider.
  int get categoryId;
}

class _FetchCategoryItemsProviderElement
    extends AutoDisposeFutureProviderElement<List<CatalogItem>>
    with FetchCategoryItemsRef {
  _FetchCategoryItemsProviderElement(super.provider);

  @override
  int get categoryId => (origin as FetchCategoryItemsProvider).categoryId;
}

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
