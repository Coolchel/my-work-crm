import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_electric_crm/src/features/catalog/data/directory_repository.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/category_model.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/directory_models.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/navigation/app_navigation.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/confirmation_dialog.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/compact_section_app_bar.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/desktop_web_frame.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';
import 'package:smart_electric_crm/src/features/settings/application/app_settings_controller.dart';

part 'widgets/category_list_screen_components.dart';

double _catalogHorizontalContentPadding(BuildContext context) {
  return DesktopWebFrame.contentHorizontalPadding(context);
}

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({
    this.initialTab = CatalogSection.system,
    this.onTabChanged,
    this.onBackPressed,
    super.key,
  });

  final CatalogSection initialTab;
  final ValueChanged<CatalogSection>? onTabChanged;
  final VoidCallback? onBackPressed;

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  int _currentIndex = 0;
  bool _isSyncingSystemSections = false;
  final ScrollController _systemScrollController = ScrollController();
  final ScrollController _catalogScrollController = ScrollController();
  final SectionAppBarCollapseController _appBarCollapseController =
      SectionAppBarCollapseController();

  void _handleBack() {
    widget.onBackPressed?.call();
    if (widget.onBackPressed != null) {
      return;
    }
    Navigator.of(context).maybePop();
  }

  int _tabIndexFromSection(CatalogSection section) {
    return switch (section) {
      CatalogSection.system => 0,
      CatalogSection.catalog => 1,
    };
  }

  CatalogSection _sectionFromTabIndex(int index) {
    return index == 1 ? CatalogSection.catalog : CatalogSection.system;
  }

  ScrollController get _activeScrollController =>
      _currentIndex == 0 ? _systemScrollController : _catalogScrollController;

  void _handleAppBarCollapseChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = _tabIndexFromSection(widget.initialTab);
    _appBarCollapseController.bind(_activeScrollController);
    _appBarCollapseController.addListener(_handleAppBarCollapseChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _synchronizeSystemSections(showSuccessMessage: false);
    });
  }

  @override
  void didUpdateWidget(covariant CategoryListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = _tabIndexFromSection(widget.initialTab);
    if (nextIndex != _currentIndex) {
      _currentIndex = nextIndex;
      _appBarCollapseController.bind(_activeScrollController);
    }
  }

  @override
  void dispose() {
    _appBarCollapseController.removeListener(_handleAppBarCollapseChanged);
    _appBarCollapseController.dispose();
    _systemScrollController.dispose();
    _catalogScrollController.dispose();
    super.dispose();
  }

  Future<void> _synchronizeSystemSections(
      {required bool showSuccessMessage}) async {
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

  Future<void> _scrollCurrentTabToTop() {
    if (_currentIndex == 0) {
      return AppNavigation.directorySystemScrollController.scrollToTop();
    }
    return AppNavigation.directoryCatalogScrollController.scrollToTop();
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: _handleBack,
        ),
        title: 'Справочник',
        icon: Icons.menu_book_rounded,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _AppBarActionButton(
              icon: Icons.sync,
              tooltip: _isSyncingSystemSections
                  ? 'Синхронизация...'
                  : 'Синхронизировать',
              color: AppDesignTokens.surface2(context),
              isLoading: _isSyncingSystemSections,
              onTap: _isSyncingSystemSections
                  ? null
                  : () => _synchronizeSystemSections(showSuccessMessage: true),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _SystemSectionsTab(
            scrollController: _systemScrollController,
            isSyncing: _isSyncingSystemSections,
            onError: (message) => _showSnack(message, isError: true),
            onSelectTab: (index) => setState(() => _currentIndex = index),
          ),
          _CatalogTab(
            scrollController: _catalogScrollController,
            onError: (message) => _showSnack(message, isError: true),
            onSelectTab: (index) => setState(() => _currentIndex = index),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: showWelcome ? _currentIndex + 1 : _currentIndex,
        onDestinationSelected: (index) {
          if (showWelcome && index == 0) {
            AppNavigation.goHome();
            return;
          }
          final mappedIndex = showWelcome ? index - 1 : index;
          if (mappedIndex == _currentIndex) {
            _scrollCurrentTabToTop();
            return;
          }
          setState(() => _currentIndex = mappedIndex);
          widget.onTabChanged?.call(_sectionFromTabIndex(mappedIndex));
          _appBarCollapseController.bind(_activeScrollController);
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

  Widget _buildFab() {
    if (_currentIndex == 0) {
      return Tooltip(
        message: 'Добавить раздел',
        preferBelow: false,
        verticalOffset: 32,
        child: FloatingActionButton(
          heroTag: 'add-system-section',
          onPressed: _openCreateSectionDialog,
          child: const Icon(Icons.add),
        ),
      );
    }

    return Tooltip(
      message: 'Добавить категорию',
      preferBelow: false,
      verticalOffset: 32,
      child: FloatingActionButton(
        heroTag: 'add-catalog-category',
        onPressed: _openCreateCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
