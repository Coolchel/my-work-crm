import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_electric_crm/src/core/api/dio_client.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/category_model.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';

part 'catalog_repository.g.dart';

class CatalogRepository {
  final Dio _client;
  CatalogRepository({required Dio client}) : _client = client;

  Future<List<CatalogCategory>> getCategories() async {
    final response = await _client.get('/categories/');
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => CatalogCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createCategory(
      {required String name, required String slug}) async {
    try {
      await _client.post('/categories/', data: {
        'name': name,
        'slug': slug,
        'labor_coefficient': 1.0,
      });
      // Не делай invalidate здесь, сделаем его в UI для надежности
    } on DioException catch (e) {
      debugPrint('Ошибка сервера: ${e.response?.data}');
      rethrow; // Обязательно пробрасываем ошибку дальше!
    }
  }

  Future<List<CatalogItem>> fetchItems(int categoryId) async {
    final response = await _client.get('/catalog-items/', queryParameters: {
      'category_id': categoryId,
    });
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CatalogItem>> searchItems(String query,
      {String? itemType}) async {
    final queryParams = {'search': query};
    if (itemType != null) {
      queryParams['item_type'] = itemType;
    }

    final response =
        await _client.get('/catalog-items/', queryParameters: queryParams);
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CatalogItem>> fetchItemsByType(String itemType) async {
    final response = await _client
        .get('/catalog-items/', queryParameters: {'item_type': itemType});
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createItem({
    required int categoryId,
    required String name,
    required double price,
    required String measurementUnit,
    required String itemType,
  }) async {
    try {
      final data = {
        'category': categoryId, // Send ID directly as 'category'
        'name': name,
        'default_price': price, // Rename to default_price
        'unit': measurementUnit, // Rename to unit
        'item_type': itemType, // 'work' or 'material'
      };

      debugPrint('Данные для отправки: $data');

      await _client.post('/catalog-items/', data: data);
    } on DioException catch (e) {
      debugPrint('Ошибка сервера при создании товара: ${e.response?.data}');
      rethrow;
    }
  }
}

@riverpod
CatalogRepository catalogRepository(CatalogRepositoryRef ref) {
  final dio = ref.watch(dioProvider);
  return CatalogRepository(client: dio);
}

@riverpod
Future<List<CatalogItem>> fetchCategoryItems(
    FetchCategoryItemsRef ref, int categoryId) {
  return ref.watch(catalogRepositoryProvider).fetchItems(categoryId);
}

@riverpod
Future<List<CatalogCategory>> fetchCategories(FetchCategoriesRef ref) {
  final repository = ref.watch(catalogRepositoryProvider);
  return repository.getCategories();
}
