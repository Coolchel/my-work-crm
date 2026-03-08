import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/project_providers.dart';
import '../../data/models/project_model.dart';
import 'project_detail_screen.dart';
import 'add_project_screen.dart';
import '../utils/project_stage_color_resolver.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/confirmation_dialog.dart';
import 'package:smart_electric_crm/src/core/navigation/app_navigation.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/compact_section_app_bar.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/search/project_search_texts.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/project_search_result_tile.dart';

// Filter enums
enum SortOrder { newest, oldest }

class ProjectListScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackPressed;

  const ProjectListScreen({
    this.onBackPressed,
    super.key,
  });

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen>
    with SingleTickerProviderStateMixin {
  static const double _searchHorizontalPadding = 16;

  SortOrder _sortOrder = SortOrder.newest;
  String? _filterSource;
  String? _filterType;
  String? _workSumSort; // 'desc' or 'asc' or null

  // Search
  final _searchController = TextEditingController();

  late AnimationController _searchAnimController;
  late Animation<double> _fadeAnimation;
  final _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final SectionAppBarCollapseController _appBarCollapseController =
      SectionAppBarCollapseController();
  Object? _scrollAttachment;

  static const _objectTypes = {
    'new_building': 'Новостройка',
    'secondary': 'Вторичка',
    'cottage': 'Коттедж',
    'office': 'Офис',
    'other': 'Другое',
  };

  static const _sources = ['Владимир', 'Другое'];

  @override
  void initState() {
    super.initState();
    _appBarCollapseController.bind(_scrollController);
    _scrollAttachment =
        AppNavigation.objectsScrollController.attach(_scrollToTop);
    _searchAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _searchAnimController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    final scrollAttachment = _scrollAttachment;
    if (scrollAttachment != null) {
      AppNavigation.objectsScrollController.detach(scrollAttachment);
    }
    _appBarCollapseController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _searchAnimController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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

  void _toggleSearch() {
    if (_searchAnimController.isDismissed) {
      _searchAnimController.forward().then((_) {
        _searchFocusNode.requestFocus();
      });
    } else {
      _closeSearch();
    }
  }

  void _closeSearch() {
    _searchController.clear();
    ref.read(objectsProjectSearchQueryProvider.notifier).state = null;
    _searchAnimController.reverse();
    FocusScope.of(context).unfocus();
    if (mounted) {
      setState(() {});
    }
  }

  /// Calc total work amount (client_amount) in USD across all stages
  double _calcWorkSumUsd(ProjectModel p) {
    double total = 0;
    for (final stage in p.stages) {
      for (final item in stage.estimateItems) {
        if (item.itemType == 'work' && item.currency == 'USD') {
          total += item.clientAmount ?? 0;
        }
      }
    }
    return total;
  }

  List<ProjectModel> _applyFilters(List<ProjectModel> projects) {
    var result = List<ProjectModel>.from(projects);

    // Source filter
    if (_filterSource != null) {
      result = result.where((p) => p.source == _filterSource).toList();
    }
    // Type filter
    if (_filterType != null) {
      result = result.where((p) => p.objectType == _filterType).toList();
    }

    // Sort
    if (_workSumSort != null) {
      if (_workSumSort == 'desc') {
        result.sort((a, b) => _calcWorkSumUsd(b).compareTo(_calcWorkSumUsd(a)));
      } else {
        result.sort((a, b) => _calcWorkSumUsd(a).compareTo(_calcWorkSumUsd(b)));
      }
    } else {
      switch (_sortOrder) {
        case SortOrder.newest:
          result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case SortOrder.oldest:
          result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
      }
    }

    return result;
  }

  bool get _hasActiveFilters =>
      _filterSource != null ||
      _filterType != null ||
      _workSumSort != null ||
      _sortOrder != SortOrder.newest;

  void _resetFilters() {
    setState(() {
      _sortOrder = SortOrder.newest;
      _filterSource = null;
      _filterType = null;
      _workSumSort = null;
    });
  }

  void _openProjectDetails(ProjectModel project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(
          projectId: project.id.toString(),
        ),
      ),
    );
  }

  Widget _buildBaseList(AsyncValue<List<ProjectModel>> projectListAsync) {
    return RefreshIndicator(
      onRefresh: () async {
        return ref.refresh(projectListProvider.future);
      },
      child: projectListAsync.when(
        data: (projects) {
          final filtered = _applyFilters(projects);
          if (projects.isEmpty) {
            return const FriendlyEmptyState(
              icon: Icons.apartment_outlined,
              title: 'Объекты пока не добавлены',
              subtitle: 'Создайте первый объект, чтобы начать работу.',
              accentColor: Colors.indigo,
            );
          }

          if (filtered.isEmpty) {
            return FriendlyEmptyState(
              icon: Icons.filter_list_off_rounded,
              title: 'Нет объектов по заданным фильтрам',
              subtitle: 'Измените параметры фильтра или сбросьте их.',
              accentColor: Colors.blueGrey,
              action: _hasActiveFilters
                  ? TextButton(
                      onPressed: _resetFilters,
                      child: const Text('Сбросить фильтры'),
                    )
                  : null,
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppDesignTokens.spacingM,
              16,
              AppDesignTokens.spacingM,
              120,
            ),
            itemCount: filtered.length,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return _ProjectCard(
                project: filtered[index],
                workSumUsd: _calcWorkSumUsd(filtered[index]),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ошибка загрузки: $error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(projectListProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchLayer(AsyncValue<List<ProjectModel>> searchResultsAsync) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: RefreshIndicator(
        onRefresh: () async {
          return ref.refresh(objectsProjectSearchResultsProvider.future);
        },
        child: searchResultsAsync.when(
          data: (projects) {
            if (projects.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  _searchHorizontalPadding,
                  16,
                  _searchHorizontalPadding,
                  120,
                ),
                children: const [
                  FriendlyEmptyState(
                    icon: Icons.search_off_rounded,
                    title: ProjectSearchTexts.emptyTitle,
                    subtitle: ProjectSearchTexts.emptySubtitle,
                    accentColor: Colors.blueGrey,
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                _searchHorizontalPadding,
                16,
                _searchHorizontalPadding,
                120,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: projects.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final project = projects[index];
                return ProjectSearchResultTile(
                  project: project,
                  margin: EdgeInsets.zero,
                  onTap: () => _openProjectDetails(project),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              _searchHorizontalPadding,
              16,
              _searchHorizontalPadding,
              120,
            ),
            children: [
              FriendlyEmptyState(
                icon: Icons.error_outline,
                title: 'Не удалось выполнить поиск',
                subtitle: '$error',
                accentColor: Colors.redAccent,
                action: TextButton(
                  onPressed: () =>
                      ref.invalidate(objectsProjectSearchResultsProvider),
                  child: const Text('Повторить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectListAsync = ref.watch(projectListProvider);
    final searchQuery = ref.watch(objectsProjectSearchQueryProvider);
    final normalizedSearchQuery = normalizeProjectSearchQuery(searchQuery);
    final isSearchActive = normalizedSearchQuery != null;
    final searchResultsAsync = ref.watch(objectsProjectSearchResultsProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final handleBack =
        widget.onBackPressed ?? () => Navigator.of(context).maybePop();

    return ListenableBuilder(
      listenable: _appBarCollapseController,
      builder: (context, child) {
        return Scaffold(
          appBar: CompactSectionAppBar(
            collapseProgress: CompactSectionAppBar.resolveCollapseProgress(
              context,
              _appBarCollapseController.progress,
            ),
            leading: IconButton(
              tooltip: 'Назад',
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: handleBack,
            ),
            title: 'Объекты',
            icon: Icons.apartment_rounded,
            gradientColors: AppDesignTokens.subtleSectionGradient,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Поиск',
                onPressed: _toggleSearch,
              ),
              IconButton(
                icon: Badge(
                  isLabelVisible: _hasActiveFilters,
                  smallSize: 8,
                  child: const Icon(Icons.filter_list),
                ),
                tooltip: 'Фильтры',
                onPressed: () => _showFilterDialog(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: child!,
          floatingActionButton: Tooltip(
            message: 'Добавить объект',
            preferBelow: false,
            verticalOffset: 32,
            child: FloatingActionButton(
              heroTag: 'add_project',
              elevation: 4,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddProjectDialog(),
                );
              },
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
      child: Column(
        children: [
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedBuilder(
                animation: _searchAnimController,
                builder: (context, _) {
                  final isOpen = _searchAnimController.value > 0;
                  if (!isOpen) {
                    return const SizedBox(width: double.infinity, height: 0);
                  }
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.fromLTRB(
                        _searchHorizontalPadding,
                        8,
                        _searchHorizontalPadding,
                        10,
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        autofocus: false,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: ProjectSearchTexts.hint,
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade600,
                            size: 22,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  color: Colors.grey.shade500,
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(
                                          objectsProjectSearchQueryProvider
                                              .notifier,
                                        )
                                        .state = null;
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: scheme.surfaceContainerHighest.withOpacity(
                            isDark ? 0.40 : 0.56,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: scheme.outlineVariant.withOpacity(
                                isDark ? 0.34 : 0.26,
                              ),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: scheme.outlineVariant.withOpacity(
                                isDark ? 0.34 : 0.26,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: scheme.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (val) {
                          ref
                              .read(objectsProjectSearchQueryProvider.notifier)
                              .state = normalizeProjectSearchQuery(val);
                          setState(() {});
                        },
                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: _buildBaseList(projectListAsync)),
                if (isSearchActive)
                  Positioned.fill(child: _buildSearchLayer(searchResultsAsync)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            const themeColor = Colors.indigo;
            final isDark = AppDesignTokens.isDark(context);
            final scheme = Theme.of(context).colorScheme;
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.34 : 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
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
                            'Фильтры',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? scheme.onSurface
                                  : themeColor.withOpacity(0.8),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Tooltip(
                              message: 'Закрыть',
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon:
                                    const Icon(Icons.close, color: themeColor),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                iconSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterLabel('Сортировка'),
                          const SizedBox(height: 8),
                          _buildFilterChipGroup<String>(
                            items: {
                              'newest': 'Сначала новые',
                              'oldest': 'Сначала старые',
                              'work_sum_desc': 'Наиболее прибыльные',
                              'work_sum_asc': 'Наименее прибыльные',
                            },
                            selected: _workSumSort != null
                                ? 'work_sum_$_workSumSort'
                                : (_sortOrder == SortOrder.newest
                                    ? 'newest'
                                    : 'oldest'),
                            onSelected: (val) {
                              setDialogState(() => setState(() {
                                    if (val == 'work_sum_desc') {
                                      _workSumSort = 'desc';
                                    } else if (val == 'work_sum_asc') {
                                      _workSumSort = 'asc';
                                    } else {
                                      _workSumSort = null;
                                      _sortOrder = val == 'newest'
                                          ? SortOrder.newest
                                          : SortOrder.oldest;
                                    }
                                  }));
                            },
                            themeColor: themeColor,
                          ),
                          const SizedBox(height: 20),
                          _buildFilterLabel('Источник'),
                          const SizedBox(height: 8),
                          _buildFilterChipGroup<String?>(
                            items: {
                              null: 'Все',
                              for (final s in _sources) s: s,
                            },
                            selected: _filterSource,
                            onSelected: (val) {
                              setDialogState(
                                  () => setState(() => _filterSource = val));
                            },
                            themeColor: themeColor,
                          ),
                          const SizedBox(height: 20),
                          _buildFilterLabel('Тип объекта'),
                          const SizedBox(height: 8),
                          _buildFilterChipGroup<String?>(
                            items: {
                              null: 'Все',
                              ..._objectTypes,
                            },
                            selected: _filterType,
                            onSelected: (val) {
                              setDialogState(
                                  () => setState(() => _filterType = val));
                            },
                            themeColor: themeColor,
                          ),
                        ],
                      ),
                    ),
                    // Footer
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: Row(
                        children: [
                          if (_hasActiveFilters)
                            TextButton(
                              onPressed: () =>
                                  setDialogState(() => _resetFilters()),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey),
                              child: const Text('Сбросить'),
                            ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () => Navigator.pop(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: themeColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Готово'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.indigo.shade700,
      ),
    );
  }

  Widget _buildFilterChipGroup<T>({
    required Map<T, String> items,
    required T selected,
    required ValueChanged<T> onSelected,
    required Color themeColor,
  }) {
    final isDark = AppDesignTokens.isDark(context);
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: items.entries.map((entry) {
        final isActive = entry.key == selected;
        final selectedChipColor = isDark
            ? themeColor.withOpacity(0.24)
            : themeColor.withOpacity(0.12);
        final idleChipColor =
            isDark ? scheme.surfaceContainerHigh : Colors.grey.shade50;
        return _HoverableFilterChip(
          label: entry.value,
          isActive: isActive,
          isDark: isDark,
          idleColor: isActive ? selectedChipColor : idleChipColor,
          borderColor: isActive
              ? themeColor.withOpacity(isDark ? 0.32 : 0.22)
              : (isDark
                  ? Colors.grey.shade600.withOpacity(0.7)
                  : AppDesignTokens.cardBorder(context).withOpacity(0.7)),
          borderWidth: isActive ? 1.0 : (isDark ? 0.7 : 1.0),
          textColor: isActive ? scheme.onSurface : scheme.onSurfaceVariant,
          onTap: () => onSelected(entry.key),
        );
      }).toList(),
    );
  }
}

// Project Card

class _ProjectCard extends StatefulWidget {
  final ProjectModel project;
  final double workSumUsd;

  const _ProjectCard({required this.project, required this.workSumUsd});

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  static const double _titleFontSize = 16;
  static const double _titleLineHeight = 1.2;
  static const double _headerBlockHeight = 58;
  static const double _intercomLineHeight = 14;
  static const double _actionButtonSize = 30;
  static const double _actionIconSize = 18;
  static const double _actionButtonsGap = 2;
  static const double _titleActionsGap = 8;
  static const double _cardHorizontalPadding = 16;
  static const double _cardVerticalPadding = 12;
  static const double _actionIconVerticalInset =
      (_actionButtonSize - _actionIconSize) / 2;
  static const double _actionButtonsReservedWidth =
      (_actionButtonSize * 2) + _actionButtonsGap;

  bool _isHovered = false;

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _getObjectTypeDisplay(String type) {
    const map = {
      'new_building': 'Новостройка',
      'secondary': 'Вторичка',
      'cottage': 'Коттедж',
      'office': 'Офис',
      'other': 'Другое',
    };
    return map[type] ?? type;
  }

  IconData _getObjectTypeIcon(String type) {
    switch (type) {
      case 'new_building':
        return Icons.apartment;
      case 'secondary':
        return Icons.home;
      case 'cottage':
        return Icons.villa;
      case 'office':
        return Icons.business;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final createdAt = project.createdAt;
    final updatedAt = project.updatedAt;
    final stripeColor = ProjectStageColorResolver.resolveStripeColor(
      project.stages,
    );

    final isEdited =
        updatedAt != null && updatedAt.difference(createdAt).abs().inHours >= 2;
    final isMobilePlatform = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final useMobileLayout =
        isMobilePlatform || MediaQuery.sizeOf(context).width < 380;
    final createdLabel = 'Создан: ${_formatDate(createdAt)}';
    final updatedLabel = isEdited ? 'Изменен: ${_formatDate(updatedAt)}' : null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppDesignTokens.cardBackground(context, hovered: _isHovered),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppDesignTokens.cardBorder(context, hovered: _isHovered),
          ),
          boxShadow: [
            BoxShadow(
              color: AppDesignTokens.cardShadow(context, hovered: _isHovered),
              blurRadius: _isHovered ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProjectDetailScreen(projectId: project.id.toString()),
                ),
              );
            },
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Accent Stripe
                  Container(width: 5, color: stripeColor),
                  // Content
                  Expanded(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _cardHorizontalPadding,
                            vertical: _cardVerticalPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Header: address + action buttons (aligned on one line)
                              SizedBox(
                                height: _headerBlockHeight,
                                child: project.intercomCode.isEmpty
                                    ? Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            right: _actionButtonsReservedWidth +
                                                _titleActionsGap,
                                          ),
                                          child: Text(
                                            project.address,
                                            style: TextStyle(
                                              fontSize: _titleFontSize,
                                              height: _titleLineHeight,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                              letterSpacing: -0.3,
                                            ),
                                            strutStyle: const StrutStyle(
                                              fontSize: _titleFontSize,
                                              height: _titleLineHeight,
                                              forceStrutHeight: true,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right:
                                                  _actionButtonsReservedWidth +
                                                      _titleActionsGap,
                                            ),
                                            child: Text(
                                              project.address,
                                              style: TextStyle(
                                                fontSize: _titleFontSize,
                                                height: _titleLineHeight,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                                letterSpacing: -0.3,
                                              ),
                                              strutStyle: const StrutStyle(
                                                fontSize: _titleFontSize,
                                                height: _titleLineHeight,
                                                forceStrutHeight: true,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            height: _intercomLineHeight,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                '\u0434\u043e\u043c\u043e\u0444\u043e\u043d: ${project.intercomCode}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade500,
                                                  letterSpacing: 0.3,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),

                              const SizedBox(height: 12),

                              useMobileLayout
                                  ? _buildMobileInfoSection(
                                      project: project,
                                      createdLabel: createdLabel,
                                      updatedLabel: updatedLabel,
                                    )
                                  : _buildWideInfoSection(
                                      project: project,
                                      createdLabel: createdLabel,
                                      updatedLabel: updatedLabel,
                                    ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: _cardVerticalPadding - _actionIconVerticalInset,
                          right: _cardHorizontalPadding,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ActionButton(
                                icon: Icons.edit_outlined,
                                tooltip:
                                    '\u0420\u0435\u0434\u0430\u043a\u0442\u0438\u0440\u043e\u0432\u0430\u0442\u044c \u043e\u0431\u044a\u0435\u043a\u0442',
                                color: Colors.grey.shade400,
                                hoverColor: Colors.indigo,
                                size: _actionButtonSize,
                                iconSize: _actionIconSize,
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        AddProjectDialog(project: project),
                                  );
                                },
                              ),
                              const SizedBox(width: _actionButtonsGap),
                              Consumer(
                                builder: (context, ref, child) {
                                  return _ActionButton(
                                    icon: Icons.close,
                                    tooltip:
                                        '\u0423\u0434\u0430\u043b\u0438\u0442\u044c \u043e\u0431\u044a\u0435\u043a\u0442',
                                    color: Colors.grey.shade400,
                                    hoverColor: Colors.grey.shade600,
                                    size: _actionButtonSize,
                                    iconSize: _actionIconSize,
                                    onTap: () => deleteProject(context, ref),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileInfoSection({
    required ProjectModel project,
    required String createdLabel,
    String? updatedLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 20,
          runSpacing: 10,
          children: [
            _buildInfoItem(
              icon: _getObjectTypeIcon(project.objectType),
              label: 'Тип',
              value: _getObjectTypeDisplay(project.objectType),
            ),
            _buildInfoItem(
              icon: Icons.layers_outlined,
              label: 'Этапов',
              value: '${project.stages.length}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMobileDateSection(
          createdLabel: createdLabel,
          updatedLabel: updatedLabel,
        ),
      ],
    );
  }

  Widget _buildWideInfoSection({
    required ProjectModel project,
    required String createdLabel,
    String? updatedLabel,
  }) {
    return Row(
      children: [
        _buildInfoItem(
          icon: _getObjectTypeIcon(project.objectType),
          label: 'Тип',
          value: _getObjectTypeDisplay(project.objectType),
        ),
        const SizedBox(width: 24),
        _buildInfoItem(
          icon: Icons.layers_outlined,
          label: 'Этапов',
          value: '${project.stages.length}',
        ),
        const Spacer(),
        _buildDateColumn(
          createdLabel: createdLabel,
          updatedLabel: updatedLabel,
        ),
      ],
    );
  }

  Widget _buildMobileDateSection({
    required String createdLabel,
    String? updatedLabel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.18),
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: _buildDateColumn(
          createdLabel: createdLabel,
          updatedLabel: updatedLabel,
        ),
      ),
    );
  }

  Widget _buildDateColumn({
    required String createdLabel,
    String? updatedLabel,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.end,
  }) {
    final hasUpdated = updatedLabel != null;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            hasUpdated ? MainAxisAlignment.start : MainAxisAlignment.center,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Text(
            createdLabel,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (hasUpdated)
            Text(
              updatedLabel,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> deleteProject(BuildContext context, WidgetRef ref) async {
    final confirm = await showConfirmationDialog(
      context: context,
      title: 'Удалить объект?',
      content:
          'Вы действительно хотите удалить этот объект? Это действие необратимо.',
      confirmText: 'Удалить',
      isDangerous: true,
    );

    if (confirm == true) {
      try {
        await ref
            .read(projectOperationsProvider.notifier)
            .deleteProject(widget.project.id.toString());
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления: $e')),
          );
        }
      }
    }
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final Color hoverColor;
  final double size;
  final double iconSize;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.hoverColor,
    this.size = 30,
    this.iconSize = 18,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
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
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isHovered
                  ? widget.hoverColor.withOpacity(0.1)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: _isHovered ? widget.hoverColor : widget.color,
            ),
          ),
        ),
      ),
    );
  }
}

/// A custom hoverable chip for filter dialogs with explicit hover color transitions.
class _HoverableFilterChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  final Color idleColor;
  final Color borderColor;
  final double borderWidth;
  final Color textColor;
  final VoidCallback onTap;

  const _HoverableFilterChip({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.idleColor,
    required this.borderColor,
    required this.borderWidth,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<_HoverableFilterChip> createState() => _HoverableFilterChipState();
}

class _HoverableFilterChipState extends State<_HoverableFilterChip> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.idleColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.borderColor,
          width: widget.borderWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          hoverColor: Colors.black.withOpacity(widget.isDark ? 0.20 : 0.06),
          splashColor: widget.isDark
              ? Colors.white.withOpacity(0.10)
              : Colors.indigo.withOpacity(0.10),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                color: widget.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
