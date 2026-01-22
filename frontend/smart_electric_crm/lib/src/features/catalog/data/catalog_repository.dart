import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_electric_crm/src/core/api/dio_client.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/category_model.dart';

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
}

@riverpod
CatalogRepository catalogRepository(CatalogRepositoryRef ref) {
  final dio = ref.watch(dioProvider);
  return CatalogRepository(client: dio);
}

@riverpod
Future<List<CatalogCategory>> fetchCategories(FetchCategoriesRef ref) {
  final repository = ref.watch(catalogRepositoryProvider);
  return repository.getCategories();
}
