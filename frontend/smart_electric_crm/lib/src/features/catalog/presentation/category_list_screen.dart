import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/features/catalog/data/catalog_repository.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(fetchCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Категории справочника'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Text('Категорий пока нет'),
            );
          }
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                leading: const Icon(Icons.folder, color: Colors.amber),
                title: Text(category.name),
                subtitle: Text('Коэф: ${category.laborCoefficient}'),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Ошибка: $error'),
        ),
      ),
    );
  }
}
