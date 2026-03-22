import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_electric_crm/src/core/navigation/app_navigation.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/core/utils/app_number_formatter.dart';
import 'package:smart_electric_crm/src/features/catalog/data/directory_repository.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/category_model.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/directory_models.dart';
import 'package:smart_electric_crm/src/features/settings/application/app_settings_controller.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/confirmation_dialog.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/app_popup_select_field.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/compact_section_app_bar.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/content_tab_strip.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/desktop_side_menu.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/desktop_web_frame.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';

part 'widgets/category_list_screen_components.dart';

const double _catalogDesktopMenuTop = 20;
const double _catalogContentMaxWidth = 1380;
const double _catalogDesktopViewportFadeHeight = 28;

double _catalogHorizontalContentPadding(BuildContext context) {
  return DesktopWebFrame.contentHorizontalPadding(context);
}

EdgeInsetsDirectional _catalogScrollableContentPadding(
  BuildContext context, {
  required double top,
  required double bottom,
  double scrollableEndInset = 0,
}) {
  return EdgeInsetsDirectional.fromSTEB(
    _catalogHorizontalContentPadding(context),
    top,
    _catalogHorizontalContentPadding(context) + scrollableEndInset,
    bottom,
  );
}

Widget _buildCatalogDesktopSideMenu(
  BuildContext context, {
  required bool showWelcome,
}) {
  final isWideSidebar = DesktopWebFrame.supportsWideShellSidebar(context);

  return DesktopSideMenu(
    compact: !isWideSidebar,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
    items: [
      if (showWelcome)
        DesktopSideMenuItem(
          label: 'Главная',
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          onTap: () => AppNavigation.goHome(scrollToTop: false),
        ),
      DesktopSideMenuItem(
        label: 'Объекты',
        icon: const Icon(Icons.description_outlined),
        selectedIcon: const Icon(Icons.description),
        onTap: () =>
            AppNavigation.goToShellSection(context, AppShellSection.projects),
      ),
      DesktopSideMenuItem(
        label: 'Финансы',
        icon: const Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: const Icon(Icons.account_balance_wallet),
        onTap: () =>
            AppNavigation.goToShellSection(context, AppShellSection.finance),
      ),
      DesktopSideMenuItem(
        label: 'Статистика',
        icon: const Icon(Icons.bar_chart_outlined),
        selectedIcon: const Icon(Icons.bar_chart),
        onTap: () => AppNavigation.goToShellSection(
          context,
          AppShellSection.statistics,
        ),
      ),
      DesktopSideMenuItem(
        label: 'Настройки',
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        isSelected: true,
        onTap: () =>
            AppNavigation.goToShellSection(context, AppShellSection.settings),
      ),
    ],
  );
}

Widget _buildCatalogOverlayActionButton(
  BuildContext context, {
  required String heroTag,
  required String tooltip,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);
  final backgroundColor = theme.floatingActionButtonTheme.backgroundColor ??
      theme.colorScheme.primary;
  final foregroundColor = theme.floatingActionButtonTheme.foregroundColor ??
      theme.colorScheme.surface;
  final isMobileWeb = DesktopWebFrame.isMobileWeb(context, maxWidth: 700);

  return Tooltip(
    message: tooltip,
    preferBelow: false,
    verticalOffset: 32,
    child: isMobileWeb
        ? FloatingActionButton.small(
            heroTag: heroTag,
            onPressed: onTap,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            child: const Icon(Icons.add),
          )
        : FloatingActionButton(
            heroTag: heroTag,
            onPressed: onTap,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            child: const Icon(Icons.add),
          ),
  );
}

Widget _buildCatalogDesktopBottomFadeMask(BuildContext context) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final background = theme.scaffoldBackgroundColor;
  final isDark = theme.brightness == Brightness.dark;

  return IgnorePointer(
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: _catalogDesktopViewportFadeHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              background.withOpacity(0),
              Color.alphaBlend(
                scheme.surface.withOpacity(isDark ? 0.16 : 0.08),
                background,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

bool _useCatalogNestedShellLayout() => true;

class _CatalogScreenScaffoldBody extends StatefulWidget {
  const _CatalogScreenScaffoldBody({
    required this.showWelcome,
    required this.content,
    required this.localNavigation,
    this.scrollController,
    this.localNavigationRightInset = 0,
  });

  final bool showWelcome;
  final Widget content;
  final Widget localNavigation;
  final ScrollController? scrollController;
  final double localNavigationRightInset;

  @override
  State<_CatalogScreenScaffoldBody> createState() =>
      _CatalogScreenScaffoldBodyState();
}

class _CatalogScreenScaffoldBodyState
    extends State<_CatalogScreenScaffoldBody> {
  double _desktopBottomFadeOpacity = 0;

  @override
  void initState() {
    super.initState();
    _bindScrollController(widget.scrollController);
  }

  @override
  void didUpdateWidget(covariant _CatalogScreenScaffoldBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.scrollController, widget.scrollController)) {
      oldWidget.scrollController?.removeListener(_handleBoundScroll);
      _bindScrollController(widget.scrollController);
    } else {
      _syncFadeFromBoundScroll();
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_handleBoundScroll);
    super.dispose();
  }

  void _bindScrollController(ScrollController? controller) {
    controller?.addListener(_handleBoundScroll);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _syncFadeFromBoundScroll());
  }

  void _handleBoundScroll() {
    _syncFadeFromBoundScroll();
  }

  void _syncFadeFromBoundScroll() {
    final controller = widget.scrollController;
    if (controller == null || !controller.hasClients) {
      _updateDesktopBottomFadeOpacity(0);
      return;
    }
    _updateDesktopBottomFadeOpacity(controller.position.extentAfter);
  }

  void _updateDesktopBottomFadeOpacity(double extentAfter) {
    final nextOpacity = ((extentAfter - 4) / 24).clamp(0.0, 1.0);
    if ((_desktopBottomFadeOpacity - nextOpacity).abs() < 0.01 || !mounted) {
      return;
    }

    setState(() {
      _desktopBottomFadeOpacity = nextOpacity;
    });
  }

  bool _handleDesktopScrollMetrics(ScrollMetrics metrics) {
    if (axisDirectionToAxis(metrics.axisDirection) != Axis.vertical) {
      return false;
    }
    _updateDesktopBottomFadeOpacity(metrics.extentAfter);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final hasSidebar = DesktopWebFrame.hasPersistentShellSidebar(context);
    final shellSidebarInset = DesktopWebFrame.persistentShellContentInset(
      context,
    );
    final shellViewportBottomInset =
        DesktopWebFrame.persistentShellViewportBottomInset(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final constrainedHost = hasSidebar
            ? SizedBox(
                width: (constraints.maxWidth - shellSidebarInset)
                    .clamp(0.0, double.infinity),
                height: constraints.maxHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DesktopWebPageFrame(
                        maxWidth: _catalogContentMaxWidth,
                        padding: EdgeInsets.zero,
                        child: widget.content,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: DesktopWebPageFrame(
                        maxWidth: _catalogContentMaxWidth,
                        padding: EdgeInsets.zero,
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: widget.localNavigationRightInset,
                          ),
                          child: widget.localNavigation,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  Positioned.fill(
                    child: DesktopWebPageFrame(
                      maxWidth: _catalogContentMaxWidth,
                      padding: EdgeInsets.zero,
                      child: widget.content,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: DesktopWebPageFrame(
                      maxWidth: _catalogContentMaxWidth,
                      padding: EdgeInsets.zero,
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: widget.localNavigationRightInset,
                        ),
                        child: widget.localNavigation,
                      ),
                    ),
                  ),
                ],
              );

        return Stack(
          children: [
            Positioned.fill(
              bottom: hasSidebar ? shellViewportBottomInset : 0,
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: (notification) =>
                    _handleDesktopScrollMetrics(notification.metrics),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) =>
                      _handleDesktopScrollMetrics(notification.metrics),
                  child: Stack(
                    children: [
                      AnimatedPadding(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.only(left: shellSidebarInset),
                        child: constrainedHost,
                      ),
                      if (hasSidebar)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          opacity: _desktopBottomFadeOpacity,
                          child: _buildCatalogDesktopBottomFadeMask(context),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasSidebar)
              Positioned(
                left: DesktopWebFrame.shellSidebarLeftOffset,
                top: _catalogDesktopMenuTop,
                bottom: shellViewportBottomInset,
                child: SafeArea(
                  top: false,
                  child: _buildCatalogDesktopSideMenu(
                    context,
                    showWelcome: widget.showWelcome,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
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

  void _handleSectionSelection(int index) {
    if (index == _currentIndex) {
      _scrollCurrentTabToTop();
      return;
    }

    setState(() => _currentIndex = index);
    widget.onTabChanged?.call(_sectionFromTabIndex(index));
    _appBarCollapseController.bind(_activeScrollController);
  }

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

  Future<void> _synchronizeSystemSections({
    required bool showSuccessMessage,
  }) async {
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
    final useOverlayPrimaryAction = DesktopWebFrame.usesOverlayPrimaryAction(
      context,
    );
    final localNavSpacing = ContentTabStrip.balancedSpacing(context);
    final localNavItemWidth = ContentTabStrip.standardItemWidth(context);
    final scrollableEndInset =
        DesktopWebFrame.scrollableContentEndInset(context);
    final bottomPadding = DesktopWebFrame.scrollableContentBottomPadding(
      context,
      hasOverlayAction: useOverlayPrimaryAction,
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
      body: _CatalogScreenScaffoldBody(
        showWelcome: showWelcome,
        scrollController: _activeScrollController,
        localNavigationRightInset: scrollableEndInset,
        content: IndexedStack(
          index: _currentIndex,
          children: [
            _SystemSectionsTab(
              scrollController: _systemScrollController,
              isSyncing: _isSyncingSystemSections,
              onError: (message) => _showSnack(message, isError: true),
              onSelectTab: (index) => setState(() => _currentIndex = index),
              topContentInset: localNavSpacing.contentInset,
              scrollableEndInset: scrollableEndInset,
              bottomContentPadding: bottomPadding,
            ),
            _CatalogTab(
              scrollController: _catalogScrollController,
              onError: (message) => _showSnack(message, isError: true),
              onSelectTab: (index) => setState(() => _currentIndex = index),
              topContentInset: localNavSpacing.contentInset,
              scrollableEndInset: scrollableEndInset,
              bottomContentPadding: bottomPadding,
            ),
          ],
        ),
        localNavigation: ContentTabStrip(
          key: const ValueKey('catalog_local_nav'),
          selectedIndex: _currentIndex,
          onSelected: _handleSectionSelection,
          topPadding: localNavSpacing.topPadding,
          bottomPadding: localNavSpacing.bottomPadding,
          itemWidth: localNavItemWidth,
          trailing:
              useOverlayPrimaryAction ? null : _buildTopAddAction(context),
          trailingReservedWidth:
              useOverlayPrimaryAction ? null : localNavItemWidth,
          items: const [
            ContentTabStripItem(
              label: 'Система',
              icon: Icons.schema_outlined,
              keyName: 'catalog_local_nav_system',
            ),
            ContentTabStripItem(
              label: 'Каталог',
              icon: Icons.inventory_2_outlined,
              keyName: 'catalog_local_nav_catalog',
            ),
          ],
        ),
      ),
      floatingActionButton: useOverlayPrimaryAction
          ? _buildCatalogOverlayActionButton(
              context,
              heroTag: _currentIndex == 0
                  ? 'add-system-section'
                  : 'add-catalog-category',
              tooltip:
                  _currentIndex == 0 ? 'Добавить раздел' : 'Добавить категорию',
              onTap: _currentIndex == 0
                  ? _openCreateSectionDialog
                  : _openCreateCategoryDialog,
            )
          : null,
    );
  }

  Widget _buildTopAddAction(BuildContext context) {
    if (_currentIndex == 0) {
      return ContentTabStripActionButton(
        key: const ValueKey('catalog_local_nav_add_action'),
        icon: Icons.add,
        label: 'Добавить',
        tooltip: 'Добавить раздел',
        width: ContentTabStrip.standardItemWidth(context),
        onTap: _openCreateSectionDialog,
      );
    }

    return ContentTabStripActionButton(
      key: const ValueKey('catalog_local_nav_add_action'),
      icon: Icons.add,
      label: 'Добавить',
      tooltip: 'Добавить категорию',
      width: ContentTabStrip.standardItemWidth(context),
      onTap: _openCreateCategoryDialog,
    );
  }
}
