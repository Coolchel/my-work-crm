import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_electric_crm/src/core/api/dio_client.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/category_model.dart';

part 'catalog_repository.g.dart';

class CatalogRepository {
  final Dio _client;
  final Ref _ref;

  CatalogRepository({required Dio client, required Ref ref})
      : _client = client,
        _ref = ref;

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
}

@riverpod
CatalogRepository catalogRepository(CatalogRepositoryRef ref) {
  final dio = ref.watch(dioProvider);
  return CatalogRepository(client: dio, ref: ref);
}

@riverpod
Future<List<CatalogCategory>> fetchCategories(FetchCategoriesRef ref) {
  final repository = ref.watch(catalogRepositoryProvider);
  return repository.getCategories();
}
