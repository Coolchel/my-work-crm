import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_electric_crm/src/features/catalog/data/directory_repository.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/category_model.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/directory_models.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/confirmation_dialog.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  int _currentIndex = 0;
  bool _isSyncingSystemSections = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _synchronizeSystemSections(showSuccessMessage: false);
    });
  }

  Future<void> _synchronizeSystemSections({required bool showSuccessMessage}) async {
    if (_isSyncingSystemSections) return;
    setState(() => _isSyncingSystemSections = true);
    try {
      await ref.read(directoryRepositoryProvider).bootstrapDirectory();
      ref.invalidate(directorySectionsProvider);
      if (mounted && showSuccessMessage) {
        _showSnack('Системные разделы успешно синхронизированы');
      }
    } on DirectorySyncException catch (error) {
      if (mounted) _showSnack(error.message, isError: true);
    } catch (error) {
      if (mounted) _showSnack(_humanizeError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isSyncingSystemSections = false);
    }
  }

  Future<void> _openCreateSectionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _DirectorySectionDialog(
        title: 'Новый раздел',
        onSubmit: (code, name, description) async {
          await ref.read(directoryRepositoryProvider).createSection(
                code: code,
                name: name,
                description: description,
              );
          ref.invalidate(directorySectionsProvider);
        },
      ),
    );
  }

  Future<void> _openCreateCategoryDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _CategoryDialog(
        title: 'Новая категория',
        onSubmit: (name, slug, labor) async {
          await ref.read(directoryRepositoryProvider).createCategory(
                name: name,
                slug: slug,
                laborCoefficient: labor,
              );
          ref.invalidate(catalogCategoriesProvider);
        },
      ),
    );
  }

  void _showSnack(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  String _humanizeError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] != null) return data['error'].toString();
      if (data != null) return data.toString();
      return error.message ?? error.toString();
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.check_rounded),
          tooltip: 'Готово',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Справочник'),
      ),
      floatingActionButton: _buildFab(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _SystemSectionsTab(
            isSyncing: _isSyncingSystemSections,
            onError: (message) => _showSnack(message, isError: true),
          ),
          _CatalogTab(
            onError: (message) => _showSnack(message, isError: true),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.schema_outlined),
            selectedIcon: Icon(Icons.schema),
            label: 'Системные',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Каталог',
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    if (_currentIndex == 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add-system-section',
            onPressed: _openCreateSectionDialog,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'bootstrap-system-sections',
            onPressed: _isSyncingSystemSections
                ? null
                : () => _synchronizeSystemSections(showSuccessMessage: true),
            icon: _isSyncingSystemSections
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(_isSyncingSystemSections ? 'Подождите...' : 'Синхронизировать'),
          ),
        ],
      );
    }

    return FloatingActionButton(
      heroTag: 'add-catalog-category',
      onPressed: _openCreateCategoryDialog,
      child: const Icon(Icons.add),
    );
  }
}

class _SystemSectionsTab extends ConsumerWidget {
  final bool isSyncing;
  final ValueChanged<String> onError;

  const _SystemSectionsTab({
    required this.isSyncing,
    required this.onError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(directorySectionsProvider);

    if (isSyncing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Синхронизируем системные разделы. Пожалуйста, подождите...',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return sectionsAsync.when(
      data: (sections) {
        if (sections.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Разделы не найдены. Нажмите "Синхронизировать" или создайте раздел вручную.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            return _DirectoryCard(
              stripeColor: Colors.indigo,
              icon: Icons.schema,
              title: section.name,
              subtitle: section.code,
              extraText: section.description.isEmpty ? null : section.description,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _SectionEntriesScreen(
                      section: section,
                      onError: onError,
                    ),
                  ),
                );
              },
              actions: [
                _InlineActionButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Редактировать раздел',
                  color: Colors.grey.shade500,
                  hoverColor: Colors.indigo,
                  onTap: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (_) => _DirectorySectionDialog(
                        title: 'Редактирование раздела',
                        initial: section,
                        onSubmit: (code, name, description) async {
                          await ref.read(directoryRepositoryProvider).updateSection(
                                id: section.id,
                                code: code,
                                name: name,
                                description: description,
                              );
                          ref.invalidate(directorySectionsProvider);
                        },
                      ),
                    );
                  },
                ),
                _InlineActionButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Удалить раздел',
                  color: Colors.grey.shade500,
                  hoverColor: Colors.red,
                  onTap: () async {
                    final confirmed = await showConfirmationDialog(
                      context: context,
                      title: 'Удалить раздел?',
                      content:
                          'Раздел будет удален вместе со всеми его записями. Это действие нельзя отменить.',
                      confirmText: 'Удалить',
                      isDangerous: true,
                      themeColor: Colors.red,
                    );
                    if (confirmed != true || !context.mounted) return;

                    try {
                      await ref.read(directoryRepositoryProvider).deleteSection(section.id);
                      ref.invalidate(directorySectionsProvider);
                    } catch (error) {
                      onError(error.toString());
                    }
                  },
                ),
                const Icon(Icons.chevron_right),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Не удалось загрузить разделы: $error', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _SectionEntriesScreen extends ConsumerWidget {
  final DirectorySection section;
  final ValueChanged<String> onError;

  const _SectionEntriesScreen({
    required this.section,
    required this.onError,
  });

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
              title: 'Новая запись',
              onSubmit: (code, name, order, isActive, metadata) async {
                await ref.read(directoryRepositoryProvider).createEntry(
                      section: section.id,
                      code: code,
                      name: name,
                      sortOrder: order,
                      isActive: isActive,
                      metadata: metadata,
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

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final metadataPreview = entry.metadata.isEmpty
                  ? null
                  : const JsonEncoder.withIndent('  ').convert(entry.metadata);

              return _DirectoryCard(
                stripeColor: entry.isActive ? Colors.teal : Colors.orange,
                icon: entry.isActive ? Icons.check_circle_outline : Icons.block,
                title: entry.name,
                subtitle: '${entry.code} | order: ${entry.sortOrder}',
                extraText: metadataPreview,
                actions: [
                  _InlineActionButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Редактировать запись',
                    color: Colors.grey.shade500,
                    hoverColor: Colors.indigo,
                    onTap: () async {
                      await showDialog<void>(
                        context: context,
                        builder: (_) => _DirectoryEntryDialog(
                          title: 'Редактирование записи',
                          initial: entry,
                          onSubmit: (code, name, order, isActive, metadata) async {
                            await ref.read(directoryRepositoryProvider).updateEntry(
                                  id: entry.id,
                                  section: section.id,
                                  code: code,
                                  name: name,
                                  sortOrder: order,
                                  isActive: isActive,
                                  metadata: metadata,
                                );
                            ref.invalidate(directoryEntriesProvider(section.id));
                          },
                        ),
                      );
                    },
                  ),
                  _InlineActionButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Удалить запись',
                    color: Colors.grey.shade500,
                    hoverColor: Colors.red,
                    onTap: () async {
                      final confirmed = await showConfirmationDialog(
                        context: context,
                        title: 'Удалить запись?',
                        content: 'Действие необратимо.',
                        confirmText: 'Удалить',
                        isDangerous: true,
                        themeColor: Colors.red,
                      );
                      if (confirmed != true || !context.mounted) return;

                      try {
                        await ref.read(directoryRepositoryProvider).deleteEntry(entry.id);
                        ref.invalidate(directoryEntriesProvider(section.id));
                      } catch (error) {
                        onError(error.toString());
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Ошибка: $error')),
      ),
    );
  }
}

class _CatalogTab extends ConsumerWidget {
  final ValueChanged<String> onError;

  const _CatalogTab({required this.onError});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(catalogCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(
            child: Text('Категории справочника не созданы'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _DirectoryCard(
              stripeColor: Colors.blue,
              icon: Icons.folder_outlined,
              title: category.name,
              subtitle: 'slug: ${category.slug}',
              extraText: 'Коэффициент труда: ${category.laborCoefficient.toStringAsFixed(2)}',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _CategoryItemsScreen(
                      category: category,
                      onError: onError,
                    ),
                  ),
                );
              },
              actions: [
                _InlineActionButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Редактировать категорию',
                  color: Colors.grey.shade500,
                  hoverColor: Colors.indigo,
                  onTap: () async {
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
                _InlineActionButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Удалить категорию',
                  color: Colors.grey.shade500,
                  hoverColor: Colors.red,
                  onTap: () async {
                    final confirmed = await showConfirmationDialog(
                      context: context,
                      title: 'Удалить категорию?',
                      content:
                          'Категория будет удалена. Убедитесь, что с ней не связаны нужные позиции.',
                      confirmText: 'Удалить',
                      isDangerous: true,
                      themeColor: Colors.red,
                    );
                    if (confirmed != true || !context.mounted) return;

                    try {
                      await ref.read(directoryRepositoryProvider).deleteCategory(category.id);
                      ref.invalidate(catalogCategoriesProvider);
                    } catch (error) {
                      onError(error.toString());
                    }
                  },
                ),
                const Icon(Icons.chevron_right),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Ошибка: $error')),
    );
  }
}

class _CategoryItemsScreen extends ConsumerWidget {
  final CatalogCategory category;
  final ValueChanged<String> onError;

  const _CategoryItemsScreen({
    required this.category,
    required this.onError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(catalogItemsByCategoryProvider(category.id));
    final workItemsAsync = ref.watch(catalogWorkItemsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final workItems = workItemsAsync.value ?? const <CatalogItem>[];
          await showDialog<void>(
            context: context,
            builder: (_) => _CatalogItemDialog(
              title: 'Новая позиция',
              workItems: workItems,
              onSubmit: (form) async {
                await ref.read(directoryRepositoryProvider).createItem(
                      categoryId: category.id,
                      name: form.name,
                      price: form.price,
                      unit: form.unit,
                      itemType: form.itemType,
                      currency: form.currency,
                      mappingKey: form.mappingKey,
                      aggregationKey: form.aggregationKey,
                      relatedWorkItem: form.relatedWorkItem,
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
            return const Center(child: Text('В этой категории пока нет позиций'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _DirectoryCard(
                stripeColor: item.itemType == 'work' ? Colors.teal : Colors.blue,
                icon: item.itemType == 'work' ? Icons.engineering : Icons.inventory_2_outlined,
                title: item.name,
                subtitle:
                    '${item.itemType} | ${item.defaultPrice.toStringAsFixed(2)} ${item.defaultCurrency} / ${item.unit}',
                extraText: _itemDetails(item),
                actions: [
                  _InlineActionButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Редактировать позицию',
                    color: Colors.grey.shade500,
                    hoverColor: Colors.indigo,
                    onTap: () async {
                      final workItems = workItemsAsync.value ?? const <CatalogItem>[];
                      await showDialog<void>(
                        context: context,
                        builder: (_) => _CatalogItemDialog(
                          title: 'Редактирование позиции',
                          initial: item,
                          workItems: workItems,
                          onSubmit: (form) async {
                            await ref.read(directoryRepositoryProvider).updateItem(
                                  id: item.id,
                                  categoryId: category.id,
                                  name: form.name,
                                  price: form.price,
                                  unit: form.unit,
                                  itemType: form.itemType,
                                  currency: form.currency,
                                  mappingKey: form.mappingKey,
                                  aggregationKey: form.aggregationKey,
                                  relatedWorkItem: form.relatedWorkItem,
                                );
                            ref.invalidate(catalogItemsByCategoryProvider(category.id));
                          },
                        ),
                      );
                    },
                  ),
                  _InlineActionButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Удалить позицию',
                    color: Colors.grey.shade500,
                    hoverColor: Colors.red,
                    onTap: () async {
                      final confirmed = await showConfirmationDialog(
                        context: context,
                        title: 'Удалить позицию?',
                        content: 'Действие необратимо.',
                        confirmText: 'Удалить',
                        isDangerous: true,
                        themeColor: Colors.red,
                      );
                      if (confirmed != true || !context.mounted) return;
                      try {
                        await ref.read(directoryRepositoryProvider).deleteItem(item.id);
                        ref.invalidate(catalogItemsByCategoryProvider(category.id));
                      } catch (error) {
                        onError(error.toString());
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Ошибка: $error')),
      ),
    );
  }

  String _itemDetails(CatalogItem item) {
    final mapping = item.mappingKey == null ? '-' : item.mappingKey!;
    final aggregation = item.aggregationKey == null ? '-' : item.aggregationKey!;
    final related = item.relatedWorkItem == null ? '-' : item.relatedWorkItem.toString();
    return 'mapping: $mapping | aggregation: $aggregation | related_work: $related';
  }
}

class _DirectoryCard extends StatefulWidget {
  final Color stripeColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? extraText;
  final VoidCallback? onTap;
  final List<Widget> actions;

  const _DirectoryCard({
    required this.stripeColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.extraText,
    this.onTap,
  });

  @override
  State<_DirectoryCard> createState() => _DirectoryCardState();
}

class _DirectoryCardState extends State<_DirectoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final content = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 5, color: widget.stripeColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(widget.icon, size: 18, color: widget.stripeColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Row(mainAxisSize: MainAxisSize.min, children: widget.actions),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (widget.extraText != null && widget.extraText!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.extraText!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _isHovered ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isHovered ? 0.07 : 0.04),
            blurRadius: _isHovered ? 14 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(onTap: widget.onTap, child: content),
            ),
    );

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: card,
      ),
    );
  }
}

class _InlineActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final Color hoverColor;
  final VoidCallback onTap;

  const _InlineActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.hoverColor,
    required this.onTap,
  });

  @override
  State<_InlineActionButton> createState() => _InlineActionButtonState();
}

class _InlineActionButtonState extends State<_InlineActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _isHovered ? widget.hoverColor.withOpacity(0.12) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: _isHovered ? widget.hoverColor : widget.color,
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogShell extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget> actions;
  final Color themeColor;

  const _DialogShell({
    required this.title,
    required this.child,
    required this.actions,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.12),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeColor.withOpacity(0.8),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: themeColor),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: child,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _dialogInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    isDense: true,
  );
}

class _DirectorySectionDialog extends StatefulWidget {
  final String title;
  final DirectorySection? initial;
  final Future<void> Function(String code, String name, String description) onSubmit;

  const _DirectorySectionDialog({
    required this.title,
    required this.onSubmit,
    this.initial,
  });

  @override
  State<_DirectorySectionDialog> createState() => _DirectorySectionDialogState();
}

class _DirectorySectionDialogState extends State<_DirectorySectionDialog> {
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.initial?.code ?? '');
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _description = TextEditingController(text: widget.initial?.description ?? '');
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: widget.title,
      themeColor: Colors.indigo,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () async {
            await widget.onSubmit(_code.text.trim(), _name.text.trim(), _description.text.trim());
            if (context.mounted) Navigator.pop(context);
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
          child: const Text('Сохранить'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _name, decoration: _dialogInputDecoration('Название')),
          const SizedBox(height: 10),
          TextField(controller: _code, decoration: _dialogInputDecoration('Код')),
          const SizedBox(height: 10),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: _dialogInputDecoration('Описание'),
          ),
        ],
      ),
    );
  }
}

class _DirectoryEntryDialog extends StatefulWidget {
  final String title;
  final DirectoryEntry? initial;
  final Future<void> Function(
    String code,
    String name,
    int order,
    bool isActive,
    Map<String, dynamic> metadata,
  ) onSubmit;

  const _DirectoryEntryDialog({
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
  late final TextEditingController _metadata;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.initial?.code ?? '');
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _order = TextEditingController(text: '${widget.initial?.sortOrder ?? 100}');
    _metadata = TextEditingController(
      text: const JsonEncoder.withIndent('  ')
          .convert(widget.initial?.metadata ?? const <String, dynamic>{}),
    );
    _isActive = widget.initial?.isActive ?? true;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _order.dispose();
    _metadata.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: widget.title,
      themeColor: Colors.indigo,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () async {
            final metadata = _parseMetadata(_metadata.text);
            if (metadata == null) return;
            await widget.onSubmit(
              _code.text.trim(),
              _name.text.trim(),
              int.tryParse(_order.text.trim()) ?? 100,
              _isActive,
              metadata,
            );
            if (context.mounted) Navigator.pop(context);
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
          child: const Text('Сохранить'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _name, decoration: _dialogInputDecoration('Название')),
          const SizedBox(height: 10),
          TextField(controller: _code, decoration: _dialogInputDecoration('Код')),
          const SizedBox(height: 10),
          TextField(
            controller: _order,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _dialogInputDecoration('Порядок'),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Активно'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _metadata,
            maxLines: 5,
            decoration: _dialogInputDecoration('Metadata JSON'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _parseMetadata(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metadata должно быть JSON-объектом')),
      );
      return null;
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Некорректный JSON в metadata')),
      );
      return null;
    }
  }
}

class _CategoryDialog extends StatefulWidget {
  final String title;
  final CatalogCategory? initial;
  final Future<void> Function(String name, String slug, double labor) onSubmit;

  const _CategoryDialog({
    required this.title,
    required this.onSubmit,
    this.initial,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _name;
  late final TextEditingController _slug;
  late final TextEditingController _labor;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _slug = TextEditingController(text: widget.initial?.slug ?? '');
    _labor = TextEditingController(text: (widget.initial?.laborCoefficient ?? 1.0).toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _labor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: widget.title,
      themeColor: Colors.indigo,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () async {
            final generatedSlug = _name.text.trim().toLowerCase().replaceAll(' ', '-');
            await widget.onSubmit(
              _name.text.trim(),
              _slug.text.trim().isEmpty ? generatedSlug : _slug.text.trim(),
              double.tryParse(_labor.text.trim().replaceAll(',', '.')) ?? 1.0,
            );
            if (context.mounted) Navigator.pop(context);
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
          child: const Text('Сохранить'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _name, decoration: _dialogInputDecoration('Название')),
          const SizedBox(height: 10),
          TextField(controller: _slug, decoration: _dialogInputDecoration('Slug')),
          const SizedBox(height: 10),
          TextField(
            controller: _labor,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _dialogInputDecoration('Коэффициент труда'),
          ),
        ],
      ),
    );
  }
}

class _CatalogItemDialogFormData {
  final String name;
  final String unit;
  final String itemType;
  final String currency;
  final double price;
  final String? mappingKey;
  final String? aggregationKey;
  final int? relatedWorkItem;

  const _CatalogItemDialogFormData({
    required this.name,
    required this.unit,
    required this.itemType,
    required this.currency,
    required this.price,
    this.mappingKey,
    this.aggregationKey,
    this.relatedWorkItem,
  });
}

class _CatalogItemDialog extends StatefulWidget {
  final String title;
  final CatalogItem? initial;
  final List<CatalogItem> workItems;
  final Future<void> Function(_CatalogItemDialogFormData data) onSubmit;

  const _CatalogItemDialog({
    required this.title,
    required this.workItems,
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
  late final TextEditingController _mappingKey;
  late final TextEditingController _aggregationKey;

  String _itemType = 'material';
  String _currency = 'USD';
  int? _relatedWorkItem;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _unit = TextEditingController(text: widget.initial?.unit ?? 'шт');
    _price = TextEditingController(text: '${widget.initial?.defaultPrice ?? 0}');
    _mappingKey = TextEditingController(text: widget.initial?.mappingKey ?? '');
    _aggregationKey = TextEditingController(text: widget.initial?.aggregationKey ?? '');
    _itemType = widget.initial?.itemType ?? 'material';
    _currency = widget.initial?.defaultCurrency ?? 'USD';
    _relatedWorkItem = widget.initial?.relatedWorkItem;
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _price.dispose();
    _mappingKey.dispose();
    _aggregationKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasRelated = widget.workItems.any((item) => item.id == _relatedWorkItem);
    return _DialogShell(
      title: widget.title,
      themeColor: Colors.indigo,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () async {
            await widget.onSubmit(
              _CatalogItemDialogFormData(
                name: _name.text.trim(),
                unit: _unit.text.trim(),
                itemType: _itemType,
                currency: _currency,
                price: double.tryParse(_price.text.trim().replaceAll(',', '.')) ?? 0,
                mappingKey: _mappingKey.text.trim().isEmpty ? null : _mappingKey.text.trim(),
                aggregationKey:
                    _aggregationKey.text.trim().isEmpty ? null : _aggregationKey.text.trim(),
                relatedWorkItem: _relatedWorkItem,
              ),
            );
            if (context.mounted) Navigator.pop(context);
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
          child: const Text('Сохранить'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _name, decoration: _dialogInputDecoration('Название')),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _itemType,
                  decoration: _dialogInputDecoration('Тип'),
                  items: const [
                    DropdownMenuItem(value: 'material', child: Text('Материал')),
                    DropdownMenuItem(value: 'work', child: Text('Работа')),
                  ],
                  onChanged: (value) => setState(() => _itemType = value ?? 'material'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(controller: _unit, decoration: _dialogInputDecoration('Ед. изм.')),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _dialogInputDecoration('Цена'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _currency,
                  decoration: _dialogInputDecoration('Валюта'),
                  items: const [
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                    DropdownMenuItem(value: 'BYN', child: Text('BYN')),
                  ],
                  onChanged: (value) => setState(() => _currency = value ?? 'USD'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(controller: _mappingKey, decoration: _dialogInputDecoration('mapping_key')),
          const SizedBox(height: 10),
          TextField(
            controller: _aggregationKey,
            decoration: _dialogInputDecoration('aggregation_key'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            value: hasRelated ? _relatedWorkItem : null,
            decoration: _dialogInputDecoration('related_work_item'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Не задано')),
              ...widget.workItems.map(
                (item) => DropdownMenuItem<int?>(
                  value: item.id,
                  child: Text('${item.id}: ${item.name}', overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _relatedWorkItem = value),
          ),
        ],
      ),
    );
  }
}
