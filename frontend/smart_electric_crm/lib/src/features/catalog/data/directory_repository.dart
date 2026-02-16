import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_electric_crm/src/core/api/dio_client.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/category_model.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/directory_models.dart';

class DirectoryRepository {
  final Dio _client;

  DirectoryRepository({required Dio client}) : _client = client;

  Future<void> bootstrapDirectory() async {
    await _client.post('/directory-sections/bootstrap/');
  }

  Future<List<DirectorySection>> getSections() async {
    try {
      final response = await _client.get('/directory-sections/');
      final data = response.data as List<dynamic>;
      return data
          .map((raw) => DirectorySection.fromJson(raw as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      if (error.response?.statusCode == 500 || error.response?.statusCode == 503) {
        return const <DirectorySection>[];
      }
      rethrow;
    }
  }

  Future<List<DirectoryEntry>> getEntries(int sectionId) async {
    try {
      final response = await _client.get(
        '/directory-entries/',
        queryParameters: {'section': sectionId},
      );
      final data = response.data as List<dynamic>;
      return data
          .map((raw) => DirectoryEntry.fromJson(raw as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      if (error.response?.statusCode == 500 || error.response?.statusCode == 503) {
        return const <DirectoryEntry>[];
      }
      rethrow;
    }
  }

  Future<void> createEntry({
    required int section,
    required String code,
    required String name,
    required int sortOrder,
    required bool isActive,
  }) async {
    await _client.post('/directory-entries/', data: {
      'section': section,
      'code': code,
      'name': name,
      'sort_order': sortOrder,
      'is_active': isActive,
      'metadata': <String, dynamic>{},
    });
  }

  Future<void> updateEntry({
    required int id,
    required int section,
    required String code,
    required String name,
    required int sortOrder,
    required bool isActive,
  }) async {
    await _client.put('/directory-entries/$id/', data: {
      'section': section,
      'code': code,
      'name': name,
      'sort_order': sortOrder,
      'is_active': isActive,
      'metadata': <String, dynamic>{},
    });
  }

  Future<void> deleteEntry(int id) async {
    await _client.delete('/directory-entries/$id/');
  }

  Future<List<CatalogCategory>> getCategories() async {
    final response = await _client.get('/categories/');
    final data = response.data as List<dynamic>;
    return data
        .map((raw) => CatalogCategory.fromJson(raw as Map<String, dynamic>))
        .toList();
  }

  Future<void> createCategory({required String name, required String slug}) async {
    await _client.post('/categories/', data: {
      'name': name,
      'slug': slug,
      'labor_coefficient': 1.0,
    });
  }

  Future<void> updateCategory({
    required int id,
    required String name,
    required String slug,
    required double laborCoefficient,
  }) async {
    await _client.put('/categories/$id/', data: {
      'name': name,
      'slug': slug,
      'labor_coefficient': laborCoefficient,
    });
  }

  Future<void> deleteCategory(int id) async {
    await _client.delete('/categories/$id/');
  }

  Future<List<CatalogItem>> getCategoryItems(int categoryId) async {
    final response = await _client.get(
      '/catalog-items/',
      queryParameters: {'category': categoryId},
    );
    final data = response.data as List<dynamic>;
    return data
        .map((raw) => CatalogItem.fromJson(raw as Map<String, dynamic>))
        .toList();
  }

  Future<void> createItem({
    required int categoryId,
    required String name,
    required double price,
    required String unit,
    required String itemType,
  }) async {
    await _client.post('/catalog-items/', data: {
      'category': categoryId,
      'name': name,
      'default_price': price,
      'unit': unit,
      'item_type': itemType,
      'default_currency': 'USD',
    });
  }

  Future<void> updateItem({
    required int id,
    required int categoryId,
    required String name,
    required double price,
    required String unit,
    required String itemType,
    required String currency,
  }) async {
    await _client.put('/catalog-items/$id/', data: {
      'category': categoryId,
      'name': name,
      'default_price': price,
      'unit': unit,
      'item_type': itemType,
      'default_currency': currency,
    });
  }

  Future<void> deleteItem(int id) async {
    await _client.delete('/catalog-items/$id/');
  }
}

final directoryRepositoryProvider = Provider<DirectoryRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return DirectoryRepository(client: dio);
});

final directorySectionsProvider = FutureProvider<List<DirectorySection>>((ref) async {
  final repository = ref.watch(directoryRepositoryProvider);
  return repository.getSections();
});

final directoryEntriesProvider = FutureProvider.family<List<DirectoryEntry>, int>((ref, sectionId) async {
  final repository = ref.watch(directoryRepositoryProvider);
  return repository.getEntries(sectionId);
});

final catalogCategoriesProvider = FutureProvider<List<CatalogCategory>>((ref) async {
  final repository = ref.watch(directoryRepositoryProvider);
  return repository.getCategories();
});

final catalogItemsByCategoryProvider = FutureProvider.family<List<CatalogItem>, int>((ref, categoryId) async {
  final repository = ref.watch(directoryRepositoryProvider);
  return repository.getCategoryItems(categoryId);
});
