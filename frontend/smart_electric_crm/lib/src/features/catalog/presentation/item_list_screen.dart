import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/features/catalog/data/catalog_repository.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';

class ItemListScreen extends ConsumerWidget {
  final int categoryId;
  final String categoryName;

  const ItemListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(fetchCategoryItemsProvider(categoryId));

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('В этой категории пока нет товаров'),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading:
                    const Icon(Icons.inventory_2_outlined, color: Colors.blue),
                title: Text(item.name),
                trailing: Text(
                  '${item.defaultPrice.toStringAsFixed(2)}\$ / ${item.unit}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => _CreateItemDialog(categoryId: categoryId),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CreateItemDialog extends ConsumerStatefulWidget {
  final int categoryId;

  const _CreateItemDialog({required this.categoryId});

  @override
  ConsumerState<_CreateItemDialog> createState() => _CreateItemDialogState();
}

class _CreateItemDialogState extends ConsumerState<_CreateItemDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController(text: 'шт');
  String _itemType = 'material'; // work or material

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить товар'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _itemType,
              decoration: const InputDecoration(labelText: 'Тип'),
              items: const [
                DropdownMenuItem(value: 'material', child: Text('Материал')),
                DropdownMenuItem(value: 'work', child: Text('Работа')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _itemType = val);
              },
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Цена (\$)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _unitController,
              decoration: const InputDecoration(labelText: 'Ед. измерения'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = _nameController.text;
            // Важная правка: заменяем запятую на точку перед парсингом
            final priceString = _priceController.text.replaceAll(',', '.');
            final price = double.tryParse(priceString);
            final unit = _unitController.text;

            if (name.isEmpty || price == null || unit.isEmpty) {
              // Просто валидация
              return;
            }

            try {
              await ref.read(catalogRepositoryProvider).createItem(
                    categoryId: widget.categoryId,
                    name: name,
                    price:
                        price, // Already parsed correctly via TextInputType options and user input expectation, but let's double check
                    measurementUnit: unit,
                    itemType: _itemType,
                  );

              // Invalidation is done here in UI
              ref.invalidate(fetchCategoryItemsProvider(widget.categoryId));

              if (context.mounted) Navigator.of(context).pop();
            } catch (e) {
              if (context.mounted) {
                String errorMessage = 'Ошибка: $e';
                if (e is DioException && e.response?.data != null) {
                  // Показываем ответ сервера (валидацию полей)
                  errorMessage = 'Ошибка сервера: ${e.response?.data}';
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
