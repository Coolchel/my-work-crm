import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/features/catalog/data/catalog_repository.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';

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
            return const FriendlyEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'В этой категории пока нет товаров',
              subtitle: 'Добавьте первый элемент каталога.',
              accentColor: Colors.blue,
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
        heroTag: null,
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

class _PopupSelectOption<T> {
  final T value;
  final String label;

  const _PopupSelectOption({
    required this.value,
    required this.label,
  });
}

class _PopupSelectField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<_PopupSelectOption<T>> options;
  final ValueChanged<T> onChanged;

  const _PopupSelectField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = options.cast<_PopupSelectOption<T>?>().firstWhere(
          (option) => option?.value == value,
          orElse: () => null,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 6),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () async {
                    final box = context.findRenderObject() as RenderBox;
                    final position = box.localToGlobal(Offset.zero);
                    final size = box.size;

                    final selectedValue = await showMenu<T>(
                      context: context,
                      position: RelativeRect.fromLTRB(
                        position.dx,
                        position.dy + size.height + 4,
                        position.dx + size.width,
                        position.dy + size.height + 280,
                      ),
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.2),
                      surfaceTintColor: Colors.transparent,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                        maxWidth: constraints.maxWidth,
                      ),
                      items: options
                          .map(
                            (option) => PopupMenuItem<T>(
                              value: option.value,
                              child: Text(option.label),
                            ),
                          )
                          .toList(),
                    );
                    if (selectedValue != null) {
                      onChanged(selectedValue);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  mouseCursor: SystemMouseCursors.click,
                  hoverColor: Colors.indigo.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selected?.label ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
  String _itemType = 'material';

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
            _PopupSelectField<String>(
              label: 'Тип',
              value: _itemType,
              options: const [
                _PopupSelectOption(value: 'material', label: 'Материал'),
                _PopupSelectOption(value: 'work', label: 'Работа'),
              ],
              onChanged: (val) => setState(() => _itemType = val),
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
            final priceString = _priceController.text.replaceAll(',', '.');
            final price = double.tryParse(priceString);
            final unit = _unitController.text;

            if (name.isEmpty || price == null || unit.isEmpty) {
              return;
            }

            try {
              await ref.read(catalogRepositoryProvider).createItem(
                    categoryId: widget.categoryId,
                    name: name,
                    price: price,
                    measurementUnit: unit,
                    itemType: _itemType,
                  );

              ref.invalidate(fetchCategoryItemsProvider(widget.categoryId));

              if (context.mounted) Navigator.of(context).pop();
            } catch (e) {
              if (context.mounted) {
                var errorMessage = 'Ошибка: $e';
                if (e is DioException && e.response?.data != null) {
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
