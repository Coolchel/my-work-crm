part of '../category_list_screen.dart';

class _AppBarActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  const _AppBarActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_AppBarActionButton> createState() => _AppBarActionButtonState();
}

class _AppBarActionButtonState extends State<_AppBarActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: Tooltip(
        message: widget.tooltip,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovered
                  ? Colors.grey.shade500.withOpacity(0.1)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.color,
                    ),
                  )
                : Icon(
                    widget.icon,
                    size: 24,
                    color: widget.color,
                  ),
          ),
        ),
      ),
    );
  }
}

class _SystemSectionsTab extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final bool isSyncing;
  final ValueChanged<String> onError;
  final ValueChanged<int> onSelectTab;

  const _SystemSectionsTab({
    required this.scrollController,
    required this.isSyncing,
    required this.onError,
    required this.onSelectTab,
  });

  @override
  ConsumerState<_SystemSectionsTab> createState() => _SystemSectionsTabState();
}

class _SystemSectionsTabState extends ConsumerState<_SystemSectionsTab> {
  Object? _scrollAttachment;

  @override
  void initState() {
    super.initState();
    _scrollAttachment =
        AppNavigation.directorySystemScrollController.attach(_scrollToTop);
  }

  @override
  void dispose() {
    final scrollAttachment = _scrollAttachment;
    if (scrollAttachment != null) {
      AppNavigation.directorySystemScrollController.detach(scrollAttachment);
    }
    super.dispose();
  }

  Future<void> _scrollToTop({bool animated = true}) async {
    if (!widget.scrollController.hasClients) {
      return;
    }
    if (animated) {
      await widget.scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    widget.scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(directorySectionsProvider);

    if (widget.isSyncing) {
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
          return const FriendlyEmptyState(
            icon: Icons.schema_outlined,
            title: 'Разделы не найдены',
            subtitle: 'Нажмите "Синхронизировать" или создайте раздел вручную.',
            accentColor: Colors.indigo,
            padding: EdgeInsets.all(24),
          );
        }

        return ListView.builder(
          controller: widget.scrollController,
          padding: EdgeInsets.fromLTRB(
            _catalogHorizontalContentPadding(context),
            20,
            _catalogHorizontalContentPadding(context),
            112,
          ),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            return _DirectoryCard(
              stripeColor: Colors.indigo,
              icon: Icons.schema,
              title: section.name,
              subtitle: section.code,
              extraText:
                  section.description.isEmpty ? null : section.description,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _SectionEntriesScreen(
                      section: section,
                      onError: widget.onError,
                      onSelectTab: widget.onSelectTab,
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
                          await ref
                              .read(directoryRepositoryProvider)
                              .updateSection(
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
                  icon: Icons.close,
                  tooltip: 'Удалить раздел',
                  color: Colors.grey.shade500,
                  hoverColor: Colors.grey.shade600,
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
                      await ref
                          .read(directoryRepositoryProvider)
                          .deleteSection(section.id);
                      ref.invalidate(directorySectionsProvider);
                    } catch (error) {
                      widget.onError(error.toString());
                    }
                  },
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Не удалось загрузить разделы: $error',
              textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _SectionEntriesScreen extends ConsumerStatefulWidget {
  final DirectorySection section;
  final ValueChanged<String> onError;
  final ValueChanged<int> onSelectTab;

  const _SectionEntriesScreen({
    required this.section,
    required this.onError,
    required this.onSelectTab,
  });

  @override
  ConsumerState<_SectionEntriesScreen> createState() =>
      _SectionEntriesScreenState();
}

class _SectionEntriesScreenState extends ConsumerState<_SectionEntriesScreen> {
  final ScrollController _scrollController = ScrollController();
  final SectionAppBarCollapseController _appBarCollapseController =
      SectionAppBarCollapseController();
  Object? _scrollAttachment;

  void _handleAppBarCollapseChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _appBarCollapseController.bind(_scrollController);
    _appBarCollapseController.addListener(_handleAppBarCollapseChanged);
    _scrollAttachment =
        AppNavigation.directorySystemScrollController.attach(_scrollToTop);
  }

  @override
  void dispose() {
    final scrollAttachment = _scrollAttachment;
    if (scrollAttachment != null) {
      AppNavigation.directorySystemScrollController.detach(scrollAttachment);
    }
    _appBarCollapseController.removeListener(_handleAppBarCollapseChanged);
    _appBarCollapseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleBack(BuildContext context) {
    Navigator.of(context).maybePop();
  }

  Future<void> _scrollToTop({bool animated = true}) async {
    if (!_scrollController.hasClients) {
      return;
    }
    if (animated) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(directoryEntriesProvider(widget.section.id));
    final showWelcome = ref.watch(
      appSettingsProvider.select((value) => value.showWelcome),
    );

    return Scaffold(
      appBar: CompactSectionAppBar(
        collapseProgress: CompactSectionAppBar.resolveCollapseProgress(
          context,
          _appBarCollapseController.progress,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          tooltip: 'Назад',
          onPressed: () => _handleBack(context),
        ),
        title: 'Справочник',
        subtitle: widget.section.name,
      ),
      floatingActionButton: Tooltip(
        message: 'Добавить запись',
        preferBelow: false,
        verticalOffset: 32,
        child: FloatingActionButton(
          onPressed: () async {
            await showDialog<void>(
              context: context,
              builder: (_) => _DirectoryEntryDialog(
                title: 'Новая запись',
                onSubmit: (code, name, order, isActive, metadata) async {
                  await ref.read(directoryRepositoryProvider).createEntry(
                        section: widget.section.id,
                        code: code,
                        name: name,
                        sortOrder: order,
                        isActive: isActive,
                        metadata: metadata,
                      );
                  ref.invalidate(directoryEntriesProvider(widget.section.id));
                },
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const FriendlyEmptyState(
              icon: Icons.list_alt_rounded,
              title: 'В этом разделе пока нет записей',
              subtitle: 'Добавьте первую запись, чтобы заполнить справочник.',
              accentColor: Colors.teal,
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              _catalogHorizontalContentPadding(context),
              20,
              _catalogHorizontalContentPadding(context),
              100,
            ),
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
                onTap: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (_) => _DirectoryEntryDialog(
                      title: 'Редактирование записи',
                      initial: entry,
                      onSubmit: (code, name, order, isActive, metadata) async {
                        await ref.read(directoryRepositoryProvider).updateEntry(
                              id: entry.id,
                              section: widget.section.id,
                              code: code,
                              name: name,
                              sortOrder: order,
                              isActive: isActive,
                              metadata: metadata,
                            );
                        ref.invalidate(
                            directoryEntriesProvider(widget.section.id));
                      },
                    ),
                  );
                },
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
                          onSubmit:
                              (code, name, order, isActive, metadata) async {
                            await ref
                                .read(directoryRepositoryProvider)
                                .updateEntry(
                                  id: entry.id,
                                  section: widget.section.id,
                                  code: code,
                                  name: name,
                                  sortOrder: order,
                                  isActive: isActive,
                                  metadata: metadata,
                                );
                            ref.invalidate(
                                directoryEntriesProvider(widget.section.id));
                          },
                        ),
                      );
                    },
                  ),
                  _InlineActionButton(
                    icon: Icons.close,
                    tooltip: 'Удалить запись',
                    color: Colors.grey.shade500,
                    hoverColor: Colors.grey.shade600,
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
                        await ref
                            .read(directoryRepositoryProvider)
                            .deleteEntry(entry.id);
                        ref.invalidate(
                            directoryEntriesProvider(widget.section.id));
                      } catch (error) {
                        widget.onError(error.toString());
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: showWelcome ? 1 : 0,
        onDestinationSelected: (index) {
          if (showWelcome && index == 0) {
            AppNavigation.goHome();
            return;
          }
          final mappedIndex = showWelcome ? index - 1 : index;
          if (mappedIndex == 0) {
            AppNavigation.directorySystemScrollController.scrollToTop();
            return;
          }
          widget.onSelectTab(mappedIndex);
          Navigator.of(context).pop();
        },
        destinations: [
          if (showWelcome)
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '\u0413\u043b\u0430\u0432\u043d\u0430\u044f',
            ),
          const NavigationDestination(
            icon: Icon(Icons.schema_outlined),
            selectedIcon: Icon(Icons.schema),
            label: '\u0421\u0438\u0441\u0442\u0435\u043c\u0430',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: '\u041a\u0430\u0442\u0430\u043b\u043e\u0433',
          ),
        ],
      ),
    );
  }
}

class _CatalogTab extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final ValueChanged<String> onError;
  final ValueChanged<int> onSelectTab;

  const _CatalogTab({
    required this.scrollController,
    required this.onError,
    required this.onSelectTab,
  });

  @override
  ConsumerState<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends ConsumerState<_CatalogTab> {
  Object? _scrollAttachment;

  @override
  void initState() {
    super.initState();
    _scrollAttachment =
        AppNavigation.directoryCatalogScrollController.attach(_scrollToTop);
  }

  @override
  void dispose() {
    final scrollAttachment = _scrollAttachment;
    if (scrollAttachment != null) {
      AppNavigation.directoryCatalogScrollController.detach(scrollAttachment);
    }
    super.dispose();
  }

  Future<void> _scrollToTop({bool animated = true}) async {
    if (!widget.scrollController.hasClients) {
      return;
    }
    if (animated) {
      await widget.scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    widget.scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(catalogCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const FriendlyEmptyState(
            icon: Icons.folder_open_rounded,
            title: 'Категории справочника не созданы',
            subtitle: 'Добавьте первую категорию каталога.',
            accentColor: Colors.indigo,
          );
        }

        return ListView.builder(
          controller: widget.scrollController,
          padding: EdgeInsets.fromLTRB(
            _catalogHorizontalContentPadding(context),
            20,
            _catalogHorizontalContentPadding(context),
            100,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _DirectoryCard(
              stripeColor: Colors.blue,
              icon: Icons.folder_outlined,
              title: category.name,
              subtitle: 'slug: ${category.slug}',
              extraText:
                  'Коэффициент труда: ${AppNumberFormatter.decimal(category.laborCoefficient)}',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _CategoryItemsScreen(
                      category: category,
                      onError: widget.onError,
                      onSelectTab: widget.onSelectTab,
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
                          await ref
                              .read(directoryRepositoryProvider)
                              .updateCategory(
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
                  icon: Icons.close,
                  tooltip: 'Удалить категорию',
                  color: Colors.grey.shade500,
                  hoverColor: Colors.grey.shade600,
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
                      await ref
                          .read(directoryRepositoryProvider)
                          .deleteCategory(category.id);
                      ref.invalidate(catalogCategoriesProvider);
                    } catch (error) {
                      widget.onError(error.toString());
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
    );
  }
}

class _CategoryItemsScreen extends ConsumerStatefulWidget {
  final CatalogCategory category;
  final ValueChanged<String> onError;
  final ValueChanged<int> onSelectTab;

  const _CategoryItemsScreen({
    required this.category,
    required this.onError,
    required this.onSelectTab,
  });

  @override
  ConsumerState<_CategoryItemsScreen> createState() =>
      _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends ConsumerState<_CategoryItemsScreen> {
  final ScrollController _scrollController = ScrollController();
  final SectionAppBarCollapseController _appBarCollapseController =
      SectionAppBarCollapseController();
  Object? _scrollAttachment;

  void _handleAppBarCollapseChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _appBarCollapseController.bind(_scrollController);
    _appBarCollapseController.addListener(_handleAppBarCollapseChanged);
    _scrollAttachment =
        AppNavigation.directoryCatalogScrollController.attach(_scrollToTop);
  }

  @override
  void dispose() {
    final scrollAttachment = _scrollAttachment;
    if (scrollAttachment != null) {
      AppNavigation.directoryCatalogScrollController.detach(scrollAttachment);
    }
    _appBarCollapseController.removeListener(_handleAppBarCollapseChanged);
    _appBarCollapseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleBack(BuildContext context) {
    Navigator.of(context).maybePop();
  }

  Future<void> _scrollToTop({bool animated = true}) async {
    if (!_scrollController.hasClients) {
      return;
    }
    if (animated) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync =
        ref.watch(catalogItemsByCategoryProvider(widget.category.id));
    final workItemsAsync = ref.watch(catalogWorkItemsProvider);
    final showWelcome = ref.watch(
      appSettingsProvider.select((value) => value.showWelcome),
    );

    return Scaffold(
      appBar: CompactSectionAppBar(
        collapseProgress: CompactSectionAppBar.resolveCollapseProgress(
          context,
          _appBarCollapseController.progress,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          tooltip: 'Назад',
          onPressed: () => _handleBack(context),
        ),
        title: 'Каталог',
        subtitle: widget.category.name,
      ),
      floatingActionButton: Tooltip(
        message: 'Добавить позицию',
        preferBelow: false,
        verticalOffset: 32,
        child: FloatingActionButton(
          onPressed: () async {
            final workItems = workItemsAsync.value ?? const <CatalogItem>[];
            await showDialog<void>(
              context: context,
              builder: (_) => _CatalogItemDialog(
                title: 'Новая позиция',
                workItems: workItems,
                onSubmit: (form) async {
                  await ref.read(directoryRepositoryProvider).createItem(
                        categoryId: widget.category.id,
                        name: form.name,
                        price: form.price,
                        unit: form.unit,
                        itemType: form.itemType,
                        currency: form.currency,
                        mappingKey: form.mappingKey,
                        aggregationKey: form.aggregationKey,
                        relatedWorkItem: form.relatedWorkItem,
                      );
                  ref.invalidate(
                      catalogItemsByCategoryProvider(widget.category.id));
                },
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const FriendlyEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'В этой категории пока нет позиций',
              subtitle: 'Добавьте первую позицию в эту категорию.',
              accentColor: Colors.blue,
            );
          }
          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              _catalogHorizontalContentPadding(context),
              20,
              _catalogHorizontalContentPadding(context),
              96,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _DirectoryCard(
                stripeColor:
                    item.itemType == 'work' ? Colors.teal : Colors.blue,
                icon: item.itemType == 'work'
                    ? Icons.engineering
                    : Icons.inventory_2_outlined,
                title: item.name,
                subtitle:
                    '${item.itemType} | ${AppNumberFormatter.decimal(item.defaultPrice)} ${item.defaultCurrency} / ${item.unit}',
                extraText: _itemDetails(item),
                onTap: () async {
                  final workItems =
                      workItemsAsync.value ?? const <CatalogItem>[];
                  await showDialog<void>(
                    context: context,
                    builder: (_) => _CatalogItemDialog(
                      title: 'Редактирование позиции',
                      initial: item,
                      workItems: workItems,
                      onSubmit: (form) async {
                        await ref.read(directoryRepositoryProvider).updateItem(
                              id: item.id,
                              categoryId: widget.category.id,
                              name: form.name,
                              price: form.price,
                              unit: form.unit,
                              itemType: form.itemType,
                              currency: form.currency,
                              mappingKey: form.mappingKey,
                              aggregationKey: form.aggregationKey,
                              relatedWorkItem: form.relatedWorkItem,
                            );
                        ref.invalidate(
                            catalogItemsByCategoryProvider(widget.category.id));
                      },
                    ),
                  );
                },
                actions: [
                  _InlineActionButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Редактировать позицию',
                    color: Colors.grey.shade500,
                    hoverColor: Colors.indigo,
                    onTap: () async {
                      final workItems =
                          workItemsAsync.value ?? const <CatalogItem>[];
                      await showDialog<void>(
                        context: context,
                        builder: (_) => _CatalogItemDialog(
                          title: 'Редактирование позиции',
                          initial: item,
                          workItems: workItems,
                          onSubmit: (form) async {
                            await ref
                                .read(directoryRepositoryProvider)
                                .updateItem(
                                  id: item.id,
                                  categoryId: widget.category.id,
                                  name: form.name,
                                  price: form.price,
                                  unit: form.unit,
                                  itemType: form.itemType,
                                  currency: form.currency,
                                  mappingKey: form.mappingKey,
                                  aggregationKey: form.aggregationKey,
                                  relatedWorkItem: form.relatedWorkItem,
                                );
                            ref.invalidate(catalogItemsByCategoryProvider(
                                widget.category.id));
                          },
                        ),
                      );
                    },
                  ),
                  _InlineActionButton(
                    icon: Icons.close,
                    tooltip: 'Удалить позицию',
                    color: Colors.grey.shade500,
                    hoverColor: Colors.grey.shade600,
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
                        await ref
                            .read(directoryRepositoryProvider)
                            .deleteItem(item.id);
                        ref.invalidate(
                            catalogItemsByCategoryProvider(widget.category.id));
                      } catch (error) {
                        widget.onError(error.toString());
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: showWelcome ? 2 : 1,
        onDestinationSelected: (index) {
          if (showWelcome && index == 0) {
            AppNavigation.goHome();
            return;
          }
          final mappedIndex = showWelcome ? index - 1 : index;
          if (mappedIndex == 1) {
            AppNavigation.directoryCatalogScrollController.scrollToTop();
            return;
          }
          widget.onSelectTab(mappedIndex);
          Navigator.of(context).pop();
        },
        destinations: [
          if (showWelcome)
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '\u0413\u043b\u0430\u0432\u043d\u0430\u044f',
            ),
          const NavigationDestination(
            icon: Icon(Icons.schema_outlined),
            selectedIcon: Icon(Icons.schema),
            label: '\u0421\u0438\u0441\u0442\u0435\u043c\u0430',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: '\u041a\u0430\u0442\u0430\u043b\u043e\u0433',
          ),
        ],
      ),
    );
  }

  String _itemDetails(CatalogItem item) {
    final mapping = item.mappingKey == null ? '-' : item.mappingKey!;
    final aggregation =
        item.aggregationKey == null ? '-' : item.aggregationKey!;
    final related =
        item.relatedWorkItem == null ? '-' : item.relatedWorkItem.toString();
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
    final textStyles = context.appTextStyles;
    final scheme = Theme.of(context).colorScheme;
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 460 ||
            DesktopWebFrame.isMobileWeb(context, maxWidth: 500);
        final actions = widget.actions.isEmpty
            ? const SizedBox.shrink()
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.actions,
              );
        final textBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              maxLines: isCompact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: textStyles.cardTitle.copyWith(
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              maxLines: isCompact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: textStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (widget.extraText != null && widget.extraText!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                widget.extraText!,
                maxLines: isCompact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: textStyles.caption.copyWith(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant.withOpacity(0.9),
                ),
              ),
            ],
          ],
        );

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: widget.stripeColor),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: isCompact ? 12 : 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Icon(
                              widget.icon,
                              size: 18,
                              color: widget.stripeColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: textBlock),
                          if (widget.actions.isNotEmpty) ...[
                            SizedBox(width: isCompact ? 6 : 8),
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: actions,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppDesignTokens.cardBackground(context, hovered: _isHovered),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppDesignTokens.cardBorder(context, hovered: _isHovered),
        ),
        boxShadow: [
          BoxShadow(
            color: AppDesignTokens.cardShadow(context, hovered: _isHovered),
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
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: card,
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
              color: _isHovered
                  ? widget.hoverColor.withOpacity(0.12)
                  : Colors.transparent,
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
    final textStyles = context.appTextStyles;
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final maxDialogHeight = MediaQuery.sizeOf(context).height * 0.82;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: maxDialogHeight,
        ),
        decoration: BoxDecoration(
          color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppDesignTokens.softBorder(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
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
                    style: textStyles.dialogTitle.copyWith(
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
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: child,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const double _catalogDialogSingleLineFieldHeight = 56;

Color _dialogFieldFillColor(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return AppDesignTokens.isDark(context)
      ? scheme.surfaceContainerHigh
      : scheme.surfaceContainer.withOpacity(0.4);
}

InputDecoration _dialogInputDecoration(
  BuildContext context, {
  required String label,
  String? errorText,
  bool alignLabelWithHint = false,
  BoxConstraints? constraints,
  EdgeInsetsGeometry? contentPadding,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final textStyles = context.appTextStyles;
  final labelStyle = textStyles.fieldLabel.copyWith(
    fontSize: 12.5,
    color: Colors.indigo.shade400,
  );
  return InputDecoration(
    labelText: label,
    labelStyle: labelStyle,
    floatingLabelStyle: labelStyle,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    alignLabelWithHint: alignLabelWithHint,
    constraints: constraints,
    errorText: errorText,
    isDense: true,
    filled: true,
    fillColor: _dialogFieldFillColor(context),
    hintStyle: textStyles.secondaryBody.copyWith(
      color: scheme.onSurfaceVariant.withOpacity(0.75),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppDesignTokens.softBorder(context)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppDesignTokens.softBorder(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.indigo, width: 2),
    ),
    errorStyle: theme.inputDecorationTheme.errorStyle,
    contentPadding: contentPadding ?? const EdgeInsets.fromLTRB(16, 18, 16, 10),
  );
}

class _DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const _DialogTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = context.appTextStyles;
    final isSingleLine = maxLines == 1;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      onChanged: onChanged,
      textAlignVertical:
          isSingleLine ? TextAlignVertical.center : TextAlignVertical.top,
      style: textStyles.input,
      decoration: _dialogInputDecoration(
        context,
        label: label,
        errorText: errorText,
        alignLabelWithHint: !isSingleLine,
        constraints: isSingleLine
            ? const BoxConstraints(
                minHeight: _catalogDialogSingleLineFieldHeight,
                maxHeight: _catalogDialogSingleLineFieldHeight,
              )
            : null,
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

class _DialogPopupSelectField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<_PopupSelectOption<T>> options;
  final ValueChanged<T> onChanged;
  final String? placeholder;

  const _DialogPopupSelectField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final selected = options.cast<_PopupSelectOption<T>?>().firstWhere(
          (option) => option?.value == value,
          orElse: () => null,
        );
    return AppPopupSelectField<T>(
      fieldLabel: label,
      valueLabel: selected?.label ?? placeholder ?? '',
      items: buildPopupMenuEntriesWithDividers(
        options
            .map(
              (option) => PopupMenuItem<T>(
                value: option.value,
                height: 40,
                mouseCursor: SystemMouseCursors.click,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    option.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            )
            .toList(),
      ),
      onSelected: onChanged,
    );
  }
}

class _DirectorySectionDialog extends StatefulWidget {
  final String title;
  final DirectorySection? initial;
  final Future<void> Function(String code, String name, String description)
      onSubmit;

  const _DirectorySectionDialog({
    required this.title,
    required this.onSubmit,
    this.initial,
  });

  @override
  State<_DirectorySectionDialog> createState() =>
      _DirectorySectionDialogState();
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
    _description =
        TextEditingController(text: widget.initial?.description ?? '');
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
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена')),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () async {
            await widget.onSubmit(
                _code.text.trim(), _name.text.trim(), _description.text.trim());
            if (context.mounted) Navigator.pop(context);
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
          child: const Text('Сохранить'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DialogTextField(
            controller: _name,
            label: 'Название',
          ),
          const SizedBox(height: 16),
          _DialogTextField(
            controller: _code,
            label: 'Код',
          ),
          const SizedBox(height: 16),
          _DialogTextField(
            controller: _description,
            label: 'Описание',
            maxLines: 3,
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
  String? _metadataError;

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
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    return _DialogShell(
      title: widget.title,
      themeColor: Colors.indigo,
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена')),
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
          _DialogTextField(
            controller: _name,
            label: 'Название',
          ),
          const SizedBox(height: 16),
          _DialogTextField(
            controller: _code,
            label: 'Код',
          ),
          const SizedBox(height: 16),
          _DialogTextField(
            controller: _order,
            label: 'Порядок',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? scheme.surfaceContainerHigh
                  : scheme.surfaceContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppDesignTokens.softBorder(context)),
            ),
            child: SwitchListTile(
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              dense: true,
              activeColor: Colors.indigo,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              title: const Text('Активно'),
            ),
          ),
          const SizedBox(height: 16),
          _DialogTextField(
            controller: _metadata,
            label: 'Metadata JSON',
            maxLines: 5,
            errorText: _metadataError,
            onChanged: (_) {
              if (_metadataError != null) {
                setState(() => _metadataError = null);
              }
            },
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _parseMetadata(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      setState(() => _metadataError = null);
      return <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        setState(() => _metadataError = null);
        return decoded;
      }
      setState(() {
        _metadataError = 'Metadata должно быть JSON-объектом';
      });
      return null;
    } catch (_) {
      setState(() {
        _metadataError = 'Некорректный JSON в metadata';
      });
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
    _labor = TextEditingController(
        text: (widget.initial?.laborCoefficient ?? 1.0).toString());
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
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена')),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () async {
            final generatedSlug =
                _name.text.trim().toLowerCase().replaceAll(' ', '-');
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
          _DialogTextField(
            controller: _name,
            label: 'Название',
          ),
          const SizedBox(height: 16),
          _DialogTextField(
            controller: _slug,
            label: 'Slug',
          ),
          const SizedBox(height: 16),
          _DialogTextField(
            controller: _labor,
            label: 'Коэффициент труда',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
    _price =
        TextEditingController(text: '${widget.initial?.defaultPrice ?? 0}');
    _mappingKey = TextEditingController(text: widget.initial?.mappingKey ?? '');
    _aggregationKey =
        TextEditingController(text: widget.initial?.aggregationKey ?? '');
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
    final hasRelated =
        widget.workItems.any((item) => item.id == _relatedWorkItem);
    return _DialogShell(
      title: widget.title,
      themeColor: Colors.indigo,
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена')),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () async {
            await widget.onSubmit(
              _CatalogItemDialogFormData(
                name: _name.text.trim(),
                unit: _unit.text.trim(),
                itemType: _itemType,
                currency: _currency,
                price:
                    double.tryParse(_price.text.trim().replaceAll(',', '.')) ??
                        0,
                mappingKey: _mappingKey.text.trim().isEmpty
                    ? null
                    : _mappingKey.text.trim(),
                aggregationKey: _aggregationKey.text.trim().isEmpty
                    ? null
                    : _aggregationKey.text.trim(),
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
          _DialogTextField(
            controller: _name,
            label: 'Название',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DialogPopupSelectField<String>(
                  label: 'Тип',
                  value: _itemType,
                  options: const [
                    _PopupSelectOption(value: 'material', label: 'Материал'),
                    _PopupSelectOption(value: 'work', label: 'Работа'),
                  ],
                  onChanged: (value) => setState(() => _itemType = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DialogTextField(
                  controller: _unit,
                  label: 'Ед. изм.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DialogTextField(
                  controller: _price,
                  label: 'Цена',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DialogPopupSelectField<String>(
                  label: 'Валюта',
                  value: _currency,
                  options: const [
                    _PopupSelectOption(value: 'USD', label: 'USD'),
                    _PopupSelectOption(value: 'BYN', label: 'BYN'),
                  ],
                  onChanged: (value) => setState(() => _currency = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DialogTextField(
            controller: _mappingKey,
            label: 'mapping_key',
          ),
          const SizedBox(height: 16),
          _DialogTextField(
            controller: _aggregationKey,
            label: 'aggregation_key',
          ),
          const SizedBox(height: 16),
          _DialogPopupSelectField<int?>(
            label: 'related_work_item',
            value: hasRelated ? _relatedWorkItem : null,
            options: [
              const _PopupSelectOption<int?>(value: null, label: 'Не задано'),
              ...widget.workItems.map(
                (item) => _PopupSelectOption<int?>(
                  value: item.id,
                  label: '${item.id}: ${item.name}',
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
