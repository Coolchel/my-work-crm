import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_electric_crm/src/core/api/api_exception.dart';
import 'package:smart_electric_crm/src/core/api/dio_client.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/category_model.dart';

part 'catalog_repository.g.dart';

class CatalogRepository {
  final Dio _client;

  CatalogRepository({required Dio client}) : _client = client;

  Never _throwApiError(
    Object error,
    StackTrace stackTrace, {
    required String fallbackMessage,
  }) {
    if (error is DioException) {
      throw ApiException.fromDio(error, fallbackMessage: fallbackMessage);
    }
    Error.throwWithStackTrace(error, stackTrace);
  }

  Future<List<CatalogCategory>> getCategories() async {
    try {
      final response = await _client.get('/categories/');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((e) => CatalogCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to load categories');
    }
  }

  Future<void> createCategory({
    required String name,
    required String slug,
  }) async {
    try {
      await _client.post('/categories/', data: {
        'name': name,
        'slug': slug,
        'labor_coefficient': 1.0,
      });
      // Не делай invalidate здесь, сделаем его в UI для надежности
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to create category');
    }
  }

  Future<List<CatalogItem>> fetchItems(int categoryId) async {
    try {
      final response = await _client.get('/catalog-items/', queryParameters: {
        'category': categoryId,
      });
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _throwApiError(
        e,
        st,
        fallbackMessage: 'Failed to load catalog items',
      );
    }
  }

  Future<List<CatalogItem>> searchItems(String query,
      {String? itemType}) async {
    try {
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
    } catch (e, st) {
      _throwApiError(
        e,
        st,
        fallbackMessage: 'Failed to search catalog items',
      );
    }
  }

  Future<List<CatalogItem>> fetchItemsByType(String itemType) async {
    try {
      final response = await _client
          .get('/catalog-items/', queryParameters: {'item_type': itemType});
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _throwApiError(
        e,
        st,
        fallbackMessage: 'Failed to load catalog items by type',
      );
    }
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
        'category': categoryId,
        'name': name,
        'default_price': price,
        'unit': measurementUnit,
        'item_type': itemType,
      };

      // Local diagnostic payload log (non-API error handling).
      debugPrint('Данные для отправки: $data');

      await _client.post('/catalog-items/', data: data);
    } catch (e, st) {
      _throwApiError(e, st, fallbackMessage: 'Failed to create catalog item');
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
  FetchCategoryItemsRef ref,
  int categoryId,
) {
  return ref.watch(catalogRepositoryProvider).fetchItems(categoryId);
}

@riverpod
Future<List<CatalogCategory>> fetchCategories(FetchCategoriesRef ref) {
  final repository = ref.watch(catalogRepositoryProvider);
  return repository.getCategories();
}
