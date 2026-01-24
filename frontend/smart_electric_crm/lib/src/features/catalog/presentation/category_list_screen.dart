import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/features/catalog/data/catalog_repository.dart';
import 'package:smart_electric_crm/src/features/catalog/presentation/item_list_screen.dart';

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
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ItemListScreen(
                        categoryId: category.id,
                        categoryName: category.name,
                      ),
                    ),
                  );
                },
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
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const _CreateCategoryDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CreateCategoryDialog extends ConsumerStatefulWidget {
  const _CreateCategoryDialog();

  @override
  ConsumerState<_CreateCategoryDialog> createState() =>
      _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends ConsumerState<_CreateCategoryDialog> {
  final _nameController = TextEditingController();
  final _coefController = TextEditingController(text: '1.0');

  @override
  void dispose() {
    _nameController.dispose();
    _coefController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Создать категорию'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Название'),
          ),
          TextField(
            controller: _coefController,
            decoration: const InputDecoration(labelText: 'Коэффициент'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              final name = _nameController.text;
              final slug = name.trim().toLowerCase().replaceAll(' ', '-');

              // 1. Пытаемся сохранить
              await ref.read(catalogRepositoryProvider).createCategory(
                    name: name,
                    slug: slug,
                  );

              // 2. Если дошли сюда - значит успешно. Инвалидируем данные.
              ref.invalidate(fetchCategoriesProvider);

              // 3. Закрываем диалог
              if (context.mounted) Navigator.of(context).pop();

              debugPrint('Категория успешно создана и список обновлен');
            } catch (e) {
              // Если упали - окно не закроется, и мы увидим ошибку в консоли
              debugPrint('Ошибка при сохранении в UI: $e');
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
