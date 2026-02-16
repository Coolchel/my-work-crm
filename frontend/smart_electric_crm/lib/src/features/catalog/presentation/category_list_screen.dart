import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_electric_crm/src/features/catalog/data/directory_repository.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/category_model.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/directory_models.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Справочник'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Системные разделы'),
            Tab(text: 'Каталог'),
          ],
        ),
      ),
      floatingActionButton: _buildFab(context),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DirectorySectionTab(),
          _CatalogTab(),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    if (_tabController.index == 0) {
      return FloatingActionButton.extended(
        heroTag: 'bootstrap',
        onPressed: () async {
          try {
            await ref.read(directoryRepositoryProvider).bootstrapDirectory();
            ref.invalidate(directorySectionsProvider);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Системные разделы синхронизированы')),
              );
            }
          } catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Не удалось синхронизировать: $error')),
              );
            }
          }
        },
        icon: const Icon(Icons.sync),
        label: const Text('Синхронизировать'),
      );
    }

    return FloatingActionButton(
      heroTag: 'add-category',
      onPressed: () async {
        await showDialog<void>(
          context: context,
          builder: (_) => _CategoryDialog(
            title: 'Новая категория',
            onSubmit: (name, slug, labor) async {
              await ref
                  .read(directoryRepositoryProvider)
                  .createCategory(name: name, slug: slug);
              ref.invalidate(catalogCategoriesProvider);
            },
          ),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}

class _DirectorySectionTab extends ConsumerWidget {
  const _DirectorySectionTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(directorySectionsProvider);

    return sectionsAsync.when(
      data: (sections) {
        if (sections.isEmpty) {
          return const Center(child: Text('Разделы справочника пока не созданы'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: sections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final section = sections[index];
            return _CompactCard(
              icon: Icons.view_list_outlined,
              title: section.name,
              subtitle: section.code,
              trailing: IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _SectionEntriesScreen(section: section),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка: $e')),
    );
  }
}

class _SectionEntriesScreen extends ConsumerWidget {
  final DirectorySection section;

  const _SectionEntriesScreen({required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(directoryEntriesProvider(section.id));

    return Scaffold(
      appBar: AppBar(title: Text(section.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog<void>(
            context: context,
            builder: (_) => _DirectoryEntryDialog(
              sectionId: section.id,
              title: 'Новая позиция',
              onSubmit: (code, name, order, isActive) async {
                await ref.read(directoryRepositoryProvider).createEntry(
                      section: section.id,
                      code: code,
                      name: name,
                      sortOrder: order,
                      isActive: isActive,
                    );
                ref.invalidate(directoryEntriesProvider(section.id));
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('В этом разделе пока нет записей'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _CompactCard(
                icon: entry.isActive ? Icons.check_circle_outline : Icons.block,
                title: entry.name,
                subtitle: '${entry.code} • порядок ${entry.sortOrder}',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () async {
                        await showDialog<void>(
                          context: context,
                          builder: (_) => _DirectoryEntryDialog(
                            sectionId: section.id,
                            title: 'Редактирование',
                            initial: entry,
                            onSubmit: (code, name, order, isActive) async {
                              await ref.read(directoryRepositoryProvider).updateEntry(
                                    id: entry.id,
                                    section: section.id,
                                    code: code,
                                    name: name,
                                    sortOrder: order,
                                    isActive: isActive,
                                  );
                              ref.invalidate(directoryEntriesProvider(section.id));
                            },
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await ref.read(directoryRepositoryProvider).deleteEntry(entry.id);
                        ref.invalidate(directoryEntriesProvider(section.id));
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }
}

class _CatalogTab extends ConsumerWidget {
  const _CatalogTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(catalogCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(child: Text('Категории справочника не созданы'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
            return _CompactCard(
              icon: Icons.folder_outlined,
              title: category.name,
              subtitle: 'slug: ${category.slug}',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      await showDialog<void>(
                        context: context,
                        builder: (_) => _CategoryDialog(
                          title: 'Редактирование категории',
                          initial: category,
                          onSubmit: (name, slug, labor) async {
                            await ref.read(directoryRepositoryProvider).updateCategory(
                                  id: category.id,
                                  name: name,
                                  slug: slug,
                                  laborCoefficient: labor,
                                );
                            ref.invalidate(catalogCategoriesProvider);
                          },
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ref.read(directoryRepositoryProvider).deleteCategory(category.id);
                      ref.invalidate(catalogCategoriesProvider);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _CategoryItemsScreen(category: category),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка: $e')),
    );
  }
}

class _CategoryItemsScreen extends ConsumerWidget {
  final CatalogCategory category;

  const _CategoryItemsScreen({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(catalogItemsByCategoryProvider(category.id));

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog<void>(
            context: context,
            builder: (_) => _CatalogItemDialog(
              title: 'Новая позиция',
              categoryId: category.id,
              onSubmit: (name, unit, type, currency, price) async {
                await ref.read(directoryRepositoryProvider).createItem(
                      categoryId: category.id,
                      name: name,
                      price: price,
                      unit: unit,
                      itemType: type,
                    );
                ref.invalidate(catalogItemsByCategoryProvider(category.id));
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('В этой категории нет позиций'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return _CompactCard(
                icon: item.itemType == 'work' ? Icons.engineering : Icons.inventory_2_outlined,
                title: item.name,
                subtitle:
                    '${item.itemType} • ${item.defaultPrice.toStringAsFixed(2)} ${item.defaultCurrency} / ${item.unit}',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () async {
                        await showDialog<void>(
                          context: context,
                          builder: (_) => _CatalogItemDialog(
                            title: 'Редактирование позиции',
                            categoryId: category.id,
                            initial: item,
                            onSubmit: (name, unit, type, currency, price) async {
                              await ref.read(directoryRepositoryProvider).updateItem(
                                    id: item.id,
                                    categoryId: category.id,
                                    name: name,
                                    price: price,
                                    unit: unit,
                                    itemType: type,
                                    currency: currency,
                                  );
                              ref.invalidate(catalogItemsByCategoryProvider(category.id));
                            },
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await ref.read(directoryRepositoryProvider).deleteItem(item.id);
                        ref.invalidate(catalogItemsByCategoryProvider(category.id));
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }
}

class _CompactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _CompactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: trailing,
      ),
    );
  }
}

class _DialogShell extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget> actions;

  const _DialogShell({required this.title, required this.child, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),
            Padding(padding: const EdgeInsets.all(16), child: child),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
            )
          ],
        ),
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final String title;
  final CatalogCategory? initial;
  final Future<void> Function(String name, String slug, double labor) onSubmit;

  const _CategoryDialog({required this.title, required this.onSubmit, this.initial});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _name;
  late final TextEditingController _slug;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _slug = TextEditingController(text: widget.initial?.slug ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Название')),
          const SizedBox(height: 12),
          TextField(controller: _slug, decoration: const InputDecoration(labelText: 'Slug')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        ElevatedButton(
          onPressed: () async {
            final slug = _slug.text.trim().isEmpty
                ? _name.text.trim().toLowerCase().replaceAll(' ', '-')
                : _slug.text.trim();
            await widget.onSubmit(_name.text.trim(), slug, widget.initial?.laborCoefficient ?? 1.0);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _DirectoryEntryDialog extends StatefulWidget {
  final int sectionId;
  final String title;
  final DirectoryEntry? initial;
  final Future<void> Function(String code, String name, int order, bool isActive) onSubmit;

  const _DirectoryEntryDialog({
    required this.sectionId,
    required this.title,
    required this.onSubmit,
    this.initial,
  });

  @override
  State<_DirectoryEntryDialog> createState() => _DirectoryEntryDialogState();
}

class _DirectoryEntryDialogState extends State<_DirectoryEntryDialog> {
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _order;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.initial?.code ?? '');
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _order = TextEditingController(text: '${widget.initial?.sortOrder ?? 100}');
    _isActive = widget.initial?.isActive ?? true;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _order.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Название')),
          const SizedBox(height: 12),
          TextField(controller: _code, decoration: const InputDecoration(labelText: 'Код')),
          const SizedBox(height: 12),
          TextField(controller: _order, decoration: const InputDecoration(labelText: 'Порядок'), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            title: const Text('Активно'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        ElevatedButton(
          onPressed: () async {
            await widget.onSubmit(
              _code.text.trim(),
              _name.text.trim(),
              int.tryParse(_order.text.trim()) ?? 100,
              _isActive,
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _CatalogItemDialog extends StatefulWidget {
  final String title;
  final int categoryId;
  final CatalogItem? initial;
  final Future<void> Function(
    String name,
    String unit,
    String itemType,
    String currency,
    double price,
  ) onSubmit;

  const _CatalogItemDialog({
    required this.title,
    required this.categoryId,
    required this.onSubmit,
    this.initial,
  });

  @override
  State<_CatalogItemDialog> createState() => _CatalogItemDialogState();
}

class _CatalogItemDialogState extends State<_CatalogItemDialog> {
  late final TextEditingController _name;
  late final TextEditingController _unit;
  late final TextEditingController _price;
  String _itemType = 'material';
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _unit = TextEditingController(text: widget.initial?.unit ?? 'шт');
    _price = TextEditingController(text: '${widget.initial?.defaultPrice ?? 0}');
    _itemType = widget.initial?.itemType ?? 'material';
    _currency = widget.initial?.defaultCurrency ?? 'USD';
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Название')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _itemType,
                  items: const [
                    DropdownMenuItem(value: 'material', child: Text('Материал')),
                    DropdownMenuItem(value: 'work', child: Text('Работа')),
                  ],
                  onChanged: (value) => setState(() => _itemType = value ?? 'material'),
                  decoration: const InputDecoration(labelText: 'Тип'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(controller: _unit, decoration: const InputDecoration(labelText: 'Ед. изм.')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Цена'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _currency,
                  items: const [
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                    DropdownMenuItem(value: 'BYN', child: Text('BYN')),
                  ],
                  onChanged: (value) => setState(() => _currency = value ?? 'USD'),
                  decoration: const InputDecoration(labelText: 'Валюта'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        ElevatedButton(
          onPressed: () async {
            await widget.onSubmit(
              _name.text.trim(),
              _unit.text.trim(),
              _itemType,
              _currency,
              double.tryParse(_price.text.trim().replaceAll(',', '.')) ?? 0,
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
