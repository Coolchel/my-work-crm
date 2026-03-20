import 'dart:async'; // For Timer

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_electric_crm/src/core/navigation/app_navigation.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';
import 'package:smart_electric_crm/src/features/catalog/data/catalog_repository.dart';
import 'package:smart_electric_crm/src/features/engineering/data/models/template_models.dart';
import 'package:smart_electric_crm/src/features/engineering/presentation/dialogs/template_selection_dialog.dart';
import 'package:smart_electric_crm/src/features/engineering/presentation/providers/template_providers.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/estimate_item_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/stage_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/repositories/project_repository.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/dialogs/estimate/add_item_dialog.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/dialogs/estimate/edit_item_dialog.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/dialogs/estimate/estimate_actions_dialog.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/dialogs/estimate/quantity_input_dialog.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/dialogs/estimate/stage3_armature_calculator_dialog.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_providers.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/estimate/estimate_app_bar_actions.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/estimate/estimate_tab.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/stages/stage_card.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/confirmation_dialog.dart';
import 'package:smart_electric_crm/src/shared/presentation/dialogs/text_input_dialog.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/compact_section_app_bar.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/content_tab_strip.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/desktop_web_frame.dart';

class EstimateScreen extends ConsumerStatefulWidget {
  final String projectId;
  final StageModel stage;
  final EstimateSection initialTab;
  final ValueChanged<EstimateSection>? onTabChanged;
  final VoidCallback? onBackPressed;

  const EstimateScreen({
    required this.projectId,
    required this.stage,
    this.initialTab = EstimateSection.works,
    this.onTabChanged,
    this.onBackPressed,
    super.key,
  });

  @override
  ConsumerState<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends ConsumerState<EstimateScreen> {
  final ScrollController _worksScrollController = ScrollController();
  final ScrollController _materialsScrollController = ScrollController();
  final SectionAppBarCollapseController _appBarCollapseController =
      SectionAppBarCollapseController();
  Timer? _markupDebounce;

  int _currentIndex = 0;
  bool _showPrices = true;
  double _markupPercent = 0;

  bool _isImportingShields = false;
  bool _isCalculatingWorks = false;
  bool _isApplyingTemplate = false;
  bool _isImportingFromPrecalc = false;
  bool _isApplyingStage3Calculator = false;

  Color _dialogBarrierColor(BuildContext context) =>
      AppDesignTokens.isDark(context)
          ? Colors.black.withOpacity(0.62)
          : Colors.black.withOpacity(0.40);

  // Local state for items (for optimistic updates and display)
  List<EstimateItemModel> _items = [];
  late StageModel _stage;
  List<EstimateItemModel> _precalcWorkItems = const [];
  List<EstimateItemModel> _precalcMaterialItems = const [];

  void _handleBack() {
    widget.onBackPressed?.call();
    if (widget.onBackPressed != null) {
      return;
    }
    Navigator.of(context).maybePop();
  }

  int _tabIndexFromSection(EstimateSection section) {
    return switch (section) {
      EstimateSection.works => 0,
      EstimateSection.materials => 1,
    };
  }

  EstimateSection _sectionFromTabIndex(int index) {
    return index == 1 ? EstimateSection.materials : EstimateSection.works;
  }

  ScrollController get _activeScrollController =>
      _currentIndex == 0 ? _worksScrollController : _materialsScrollController;

  void _handleSectionSelection(int index) {
    if (index == _currentIndex) {
      if (_currentIndex == 0) {
        AppNavigation.worksScrollController.scrollToTop();
      } else {
        AppNavigation.materialsScrollController.scrollToTop();
      }
      return;
    }

    final previousIndex = _currentIndex;
    final nextSection = _sectionFromTabIndex(index);
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    final targetLocation = AppNavigation.estimateLocation(
      projectId: widget.projectId,
      stageId: widget.stage.id.toString(),
      tab: nextSection,
      from: from,
    );

    setState(() {
      _currentIndex = index;
    });
    _appBarCollapseController.bind(_activeScrollController);
    if (previousIndex == 0 && nextSection == EstimateSection.materials) {
      context.push(targetLocation);
      return;
    }
    context.go(targetLocation);
  }

  void _handleAppBarCollapseChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<EstimateItemModel> get _works =>
      _items.where((i) => i.itemType == 'work').toList();
  List<EstimateItemModel> get _materials =>
      _items.where((i) => i.itemType != 'work').toList();
  bool get _isTransferStage =>
      _stage.title == 'stage_1' ||
      _stage.title == 'stage_2' ||
      _stage.title == 'stage_1_2';
  bool get _canImportWorksFromPrecalc =>
      _isTransferStage && _precalcWorkItems.isNotEmpty;
  bool get _canImportMaterialsFromPrecalc =>
      _isTransferStage && _precalcMaterialItems.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _stage = widget.stage;
    _currentIndex = _tabIndexFromSection(widget.initialTab);
    _showPrices = _stage.showPrices;
    _markupPercent = _stage.markupPercent;
    _appBarCollapseController.bind(_activeScrollController);
    _appBarCollapseController.addListener(_handleAppBarCollapseChanged);

    // Load items
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  @override
  void didUpdateWidget(covariant EstimateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = _tabIndexFromSection(widget.initialTab);
    if (nextIndex != _currentIndex) {
      _currentIndex = nextIndex;
      _appBarCollapseController.bind(_activeScrollController);
    }
  }

  Future<void> _refresh() async {
    try {
      final repo = ref.read(projectRepositoryProvider);
      // Fetch stage data including items
      final stage = await repo.fetchStage(widget.stage.id);
      final precalcItems = await _fetchPrecalcItems(repo, stage.title);
      if (mounted) {
        setState(() {
          _items = stage.estimateItems;
          _stage = stage;
          _showPrices = stage.showPrices;
          _markupPercent = stage.markupPercent;
          _precalcWorkItems = precalcItems['work'] ?? const [];
          _precalcMaterialItems = precalcItems['material'] ?? const [];
        });
      }
    } catch (e) {
      debugPrint('Error refreshing estimate: $e');
    }
  }

  Future<Map<String, List<EstimateItemModel>>> _fetchPrecalcItems(
    ProjectRepository repo,
    String stageTitle,
  ) async {
    if (stageTitle != 'stage_1' &&
        stageTitle != 'stage_2' &&
        stageTitle != 'stage_1_2') {
      return const {'work': [], 'material': []};
    }

    try {
      final project = await repo.fetchProject(widget.projectId);
      final precalcStage = project.stages.where((s) => s.title == 'precalc');
      if (precalcStage.isEmpty) {
        return const {'work': [], 'material': []};
      }

      final precalc = await repo.fetchStage(precalcStage.first.id);
      final workItems = precalc.estimateItems
          .where((item) => item.itemType == 'work')
          .toList();
      final materialItems = precalc.estimateItems
          .where((item) => item.itemType != 'work')
          .toList();

      return {
        'work': workItems,
        'material': materialItems,
      };
    } catch (e) {
      debugPrint('Error fetching precalc items: $e');
      return const {'work': [], 'material': []};
    }
  }

  @override
  void dispose() {
    _appBarCollapseController.removeListener(_handleAppBarCollapseChanged);
    _appBarCollapseController.dispose();
    _worksScrollController.dispose();
    _materialsScrollController.dispose();
    _markupDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobileWeb = DesktopWebFrame.isMobileWeb(context, maxWidth: 700);
    final shellSidebarInset = DesktopWebFrame.persistentShellContentInset(
      context,
    );
    final localNavOverlayInset = ContentTabStrip.overlayInset(context);
    // Backdrop filter when FAB is expanded
    // Backdrop filter when FAB is expanded
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
        title: 'Смета',
        subtitle: StageCard.getStageTitleDisplay(widget.stage.title),
        icon: Icons.request_quote_rounded,
        bottomGap: isMobileWeb ? 16 : 30,
        actions: [
          EstimateAppBarActions(
            showPrices: _showPrices,
            currentIndex: _currentIndex,
            canImportWorksFromPrecalc: _canImportWorksFromPrecalc,
            canImportMaterialsFromPrecalc: _canImportMaterialsFromPrecalc,
            isImportingFromPrecalc: _isImportingFromPrecalc,
            stageTitle: _stage.title,
            isApplyingStage3Calculator: _isApplyingStage3Calculator,
            onShowPdfActions: () => _showPdfActionsDialog(context),
            onShowTextActions: () => _showTextActionsDialog(context),
            onMenuSelected: (value) {
              switch (value) {
                case 'toggle_prices':
                  unawaited(_setShowPrices(!_showPrices));
                  break;
                case 'import':
                  if (_currentIndex == 0) {
                    _calculateWorksFromMaterials();
                  } else {
                    _importFromShields();
                  }
                  break;
                case 'apply_template':
                  if (_currentIndex == 0) {
                    _showWorkTemplatesDialog();
                  } else {
                    _showMaterialTemplatesDialog();
                  }
                  break;
                case 'import_from_precalc':
                  _importFromPrecalc();
                  break;
                case 'stage3_armature_calculator':
                  _openStage3ArmatureCalculator();
                  break;
                case 'save_template':
                  _showSaveTemplateDialog(
                      _currentIndex == 0 ? 'work' : 'material');
                  break;
                case 'clear_all':
                  _deleteAllItems();
                  break;
              }
            },
          ),
        ],
      ),
      body: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(left: shellSidebarInset),
        child: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  // Works Tab
                  EstimateTab(
                    scrollController: _worksScrollController,
                    items: _works,
                    title: 'Работы', // Determines view mode inside widget
                    topContentInset: localNavOverlayInset,
                    showPrices: true,
                    onUpdate: _updateItemFromTab,
                    onDelete: _deleteItemFromTab,
                    note: _stage.workNotes,
                    remarks: _stage.workRemarks,
                    onSaveNote: (v) => _saveNotes('work', v),
                    onSaveRemarks: (v) => _saveNotes('work_remarks', v),
                    automationActionLabel: "Рассчитать по материалам",
                    onAutomationAction: _calculateWorksFromMaterials,
                    isAutomationLoading: _isCalculatingWorks,
                    onTemplatesAction: _showWorkTemplatesDialog,
                    isTemplatesLoading: _isApplyingTemplate,
                    onSaveAsTemplate: () => _showSaveTemplateDialog('work'),
                    hideTopActions: true,
                  ),
                  // Materials Tab
                  EstimateTab(
                    scrollController: _materialsScrollController,
                    items: _materials,
                    title: 'Материалы',
                    topContentInset: localNavOverlayInset,
                    showPrices: _showPrices,
                    onUpdate: _updateItemFromTab,
                    onDelete: _deleteItemFromTab,
                    onShowPricesChanged: _setShowPrices,
                    markupPercent: _markupPercent,
                    onMarkupChanged: (val) {
                      setState(() => _markupPercent = val);
                      _saveMarkupDebounced(val);
                    },
                    note: _stage.materialNotes,
                    remarks: _stage.materialRemarks,
                    onSaveNote: (v) => _saveNotes('material', v),
                    onSaveRemarks: (v) => _saveNotes('material_remarks', v),
                    automationActionLabel: "Импорт из инженерки",
                    onAutomationAction: _importFromShields,
                    isAutomationLoading: _isImportingShields,
                    onTemplatesAction: _showMaterialTemplatesDialog,
                    isTemplatesLoading: _isApplyingTemplate,
                    onSaveAsTemplate: () => _showSaveTemplateDialog('material'),
                    hideTopActions: true,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ContentTabStrip(
                key: const ValueKey('estimate_local_nav'),
                selectedIndex: _currentIndex,
                onSelected: _handleSectionSelection,
                items: const [
                  ContentTabStripItem(
                    label: '\u0420\u0430\u0431\u043e\u0442\u044b',
                    icon: Icons.handyman_rounded,
                    keyName: 'estimate_local_nav_works',
                  ),
                  ContentTabStripItem(
                    label:
                        '\u041c\u0430\u0442\u0435\u0440\u0438\u0430\u043b\u044b',
                    icon: Icons.inventory_2_rounded,
                    keyName: 'estimate_local_nav_materials',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Tooltip(
        message: 'Добавить позицию',
        preferBelow: false,
        verticalOffset: 32,
        child: FloatingActionButton(
          heroTag: 'add_estimate_item',
          onPressed: _showSearchDialog,
          backgroundColor:
              _currentIndex == 0 ? Colors.green.shade500 : Colors.blue.shade500,
          foregroundColor: Theme.of(context).colorScheme.surface,
          // tooltip: 'Добавить позицию', // Removed
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showTextActionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EstimateTextActionsDialog(
        projectId: widget.projectId,
        stage: _stage,
        works: _works,
        materials: _materials,
        showPrices: _showPrices,
        markupPercent: _markupPercent,
      ),
    );
  }

  void _showPdfActionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EstimatePdfActionsDialog(
        projectId: widget.projectId,
        stage: _stage,
        works: _works,
        materials: _materials,
        showPrices: _showPrices,
        markupPercent: _markupPercent,
      ),
    );
  }

  // --- Actions ---

  void _deleteAllItems() async {
    final isWork = _currentIndex == 0;
    final themeColor = isWork ? Colors.green : Colors.blue;
    final sectionName = isWork ? "работы" : "материалы";

    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: _dialogBarrierColor(context),
      builder: (context) => ConfirmationDialog(
        title: 'Очистить $sectionName?',
        content: 'Все позиции в разделе $sectionName будут удалены.',
        confirmText: 'Удалить',
        isDestructive: true,
        themeColor: themeColor,
      ),
    );

    if (confirm == true) {
      try {
        final repo = ref.read(projectRepositoryProvider);
        final itemsToDelete = isWork ? _works : _materials;

        for (var item in itemsToDelete) {
          await repo.deleteEstimateItem(item.id);
        }
        _refresh();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Ошибка очистки: $e")));
      }
    }
  }

  void _showManualAddDialog() async {
    // Create new item with defaults
    final newItem = EstimateItemModel(
      id: 0,
      stage: widget.stage.id,
      itemType: _currentIndex == 0 ? 'work' : 'material',
      name: '',
      unit: '',
      totalQuantity: 0,
      contractorQuantity: 0,
      employerQuantity: 0,
      currency: 'USD',
      markupPercent: 0,
      isPreliminary: false,
    );

    final result = await showDialog(
      context: context,
      builder: (_) => EditItemDialog(item: newItem),
    );

    if (result is EstimateItemModel) {
      _saveNewItem(result, null);
    }
  }

  Future<void> _showSearchDialog() async {
    final index = _currentIndex;
    final itemType = index == 0 ? 'work' : 'material';
    final showPrices = itemType == 'work' ? true : _showPrices;
    final hidePrices = !showPrices;

    final catalogItem = await showDialog<CatalogItem>(
      context: context,
      builder: (_) => AddItemDialog(
        itemType: itemType,
        hidePrices: hidePrices,
      ),
    );

    if (!mounted || catalogItem == null) {
      return;
    }

    // ID == 0 is the existing sentinel for manual add.
    if (catalogItem.id == 0) {
      _showManualAddDialog();
      return;
    }

    final quantities = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => QuantityInputDialog(
        item: catalogItem,
        itemType: itemType,
        hidePrices: hidePrices,
      ),
    );

    if (!mounted || quantities == null) {
      return;
    }

    final newItem = EstimateItemModel(
      id: 0,
      stage: widget.stage.id,
      itemType: itemType,
      name: catalogItem.name,
      unit: catalogItem.unit,
      pricePerUnit: quantities['price']?.toDouble() ?? catalogItem.defaultPrice,
      currency:
          quantities['currency'] as String? ?? catalogItem.defaultCurrency,
      totalQuantity: quantities['total']?.toDouble() ?? 0.0,
      employerQuantity: quantities['employer']?.toDouble() ?? 0.0,
      markupPercent: 0,
      isPreliminary: false,
    );

    await _saveNewItem(newItem, catalogItem.id);
  }

  // --- Data Methods ---

  Future<void> _saveNewItem(EstimateItemModel item, int? catalogItemId) async {
    try {
      final repo = ref.read(projectRepositoryProvider);
      await repo.addEstimateItem({
        'stage': widget.stage.id,
        'catalog_item': catalogItemId,
        'item_type': item.itemType,
        'name': item.name,
        'unit': item.unit,
        'price_per_unit': item.pricePerUnit,
        'currency': item.currency,
        'total_quantity': item.totalQuantity,
        'employer_quantity': item.employerQuantity,
      });
      if (!mounted) return;
      ref.invalidate(projectListProvider);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    }
  }

  void _updateItemFromTab(EstimateItemModel updatedItem) {
    final index = _items.indexWhere((i) => i.id == updatedItem.id);
    if (index != -1) {
      _updateItem(index, updatedItem);
    }
  }

  void _deleteItemFromTab(EstimateItemModel item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _deleteItem(index, item.id);
    }
  }

  void _deleteItem(int index, int itemId) async {
    final themeColor = _currentIndex == 0 ? Colors.green : Colors.blue;
    final confirm = await showDialog<bool>(
        context: context,
        barrierColor: _dialogBarrierColor(context),
        builder: (ctx) => ConfirmationDialog(
              title: "Удалить позицию?",
              content: "Вы уверены, что хотите удалить эту позицию из сметы?",
              confirmText: "Удалить",
              isDestructive: true,
              themeColor: themeColor,
            ));

    if (confirm == true) {
      try {
        final repo = ref.read(projectRepositoryProvider);
        await repo.deleteEstimateItem(itemId);
        ref.invalidate(projectListProvider);
        _refresh();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Ошибка удаления: $e")));
      }
    }
  }

  void _updateItem(int index, EstimateItemModel updatedItem) async {
    setState(() => _items[index] = updatedItem);
    try {
      final data = {
        'total_quantity': updatedItem.totalQuantity,
        'employer_quantity': updatedItem.employerQuantity,
        'currency': updatedItem.currency,
        'price_per_unit': updatedItem.pricePerUnit,
      };

      final repo = ref.read(projectRepositoryProvider);
      await repo.updateEstimateItem(updatedItem.id, data);
      ref.invalidate(projectListProvider);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка сохранения: $e")));
    }
  }

  Future<void> _saveNotes(String type, String value) async {
    // Optimistic update
    setState(() {
      if (type == 'work') {
        _stage = _stage.copyWith(workNotes: value);
      } else if (type == 'material') {
        _stage = _stage.copyWith(materialNotes: value);
      } else if (type == 'work_remarks') {
        _stage = _stage.copyWith(workRemarks: value);
      } else if (type == 'material_remarks') {
        _stage = _stage.copyWith(materialRemarks: value);
      }
    });

    try {
      final repo = ref.read(projectRepositoryProvider);
      final data = <String, dynamic>{};

      if (type == 'work') {
        data['work_notes'] = value;
      } else if (type == 'material') {
        data['material_notes'] = value;
      } else if (type == 'work_remarks') {
        data['work_remarks'] = value;
      } else if (type == 'material_remarks') {
        data['material_remarks'] = value;
      }

      await repo.updateStage(widget.stage.id, data);
      ref.invalidate(projectListProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка сохранения заметки: $e")));
    }
  }

  void _saveMarkupDebounced(double value) {
    if (_markupDebounce?.isActive ?? false) _markupDebounce!.cancel();
    _markupDebounce = Timer(const Duration(milliseconds: 1000), () {
      _saveMarkup(value);
    });
  }

  Future<void> _importFromShields() async {
    if (_materials.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        barrierColor: _dialogBarrierColor(context),
        builder: (ctx) => const ConfirmationDialog(
          title: "Импортировать оборудование?",
          content:
              "Импорт приведет к замене всех идентичных позиций на соответствующие позиции из инженерного раздела. Продолжить?",
          confirmText: "Импортировать",
          themeColor: Colors.blue,
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isImportingShields = true);
    try {
      final repo = ref.read(projectRepositoryProvider);
      final result = await repo.importFromShields(widget.stage.id);

      final created = result['created'] ?? 0;
      final updated = result['updated'] ?? 0;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Импорт завершен: Создано $created, Обновлено $updated")),
      );
      ref.invalidate(projectListProvider);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка импорта: $e")));
    } finally {
      if (mounted) setState(() => _isImportingShields = false);
    }
  }

  Future<void> _calculateWorksFromMaterials() async {
    if (_works.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        barrierColor: _dialogBarrierColor(context),
        builder: (ctx) => const ConfirmationDialog(
          title: "Рассчитать работы?",
          content:
              "Расчет приведет к замене всех идентичных позиций на рассчитанные позиции. Продолжить?",
          confirmText: "Рассчитать",
          themeColor: Colors.green,
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isCalculatingWorks = true);
    try {
      final repo = ref.read(projectRepositoryProvider);
      final result = await repo.calculateWorks(widget.stage.id);

      final created = result['created'] ?? 0;
      final updated = result['updated'] ?? 0;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Расчет завершен: Создано $created, Обновлено $updated")),
      );
      ref.invalidate(projectListProvider);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка расчета: $e")));
    } finally {
      if (mounted) setState(() => _isCalculatingWorks = false);
    }
  }

  Future<void> _importFromPrecalc() async {
    final isWork = _currentIndex == 0;
    final sourceItems = isWork ? _precalcWorkItems : _precalcMaterialItems;
    final sectionName = isWork ? 'работ' : 'материалов';
    final themeColor = isWork ? Colors.green : Colors.blue;

    if (sourceItems.isEmpty) return;

    if ((isWork ? _works : _materials).isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        barrierColor: _dialogBarrierColor(context),
        builder: (ctx) => ConfirmationDialog(
          title: 'Перенос',
          content:
              'Текущие позиции раздела $sectionName будут удалены и заменены позициями из этапа "Предпросчет". Продолжить?',
          confirmText: 'Перенести',
          themeColor: themeColor,
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isImportingFromPrecalc = true);
    try {
      final repo = ref.read(projectRepositoryProvider);
      final result = await repo.importFromPrecalcSection(
        widget.stage.id,
        itemType: isWork ? 'work' : 'material',
      );
      final created = result['created'] ?? 0;
      final deleted = result['deleted'] ?? 0;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Позиции $sectionName перенесены из этапа "Предпросчет": удалено $deleted, создано $created',
          ),
        ),
      );
      ref.invalidate(projectListProvider);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка переноса из предпросчета: $e')),
      );
    } finally {
      if (mounted) setState(() => _isImportingFromPrecalc = false);
    }
  }

  Future<void> _openStage3ArmatureCalculator() async {
    if (_stage.title != 'stage_3' || _currentIndex != 1) {
      return;
    }

    try {
      final catalogRepo = ref.read(catalogRepositoryProvider);
      final materialCatalogItems =
          await catalogRepo.fetchItemsByType('material');

      if (!mounted) return;
      final result = await showDialog<List<Stage3ArmatureCalculatorResult>>(
        context: context,
        builder: (context) => Stage3ArmatureCalculatorDialog(
          materialCatalogItems: materialCatalogItems,
        ),
      );

      if (result == null || result.isEmpty) return;
      await _applyStage3ArmatureCalculator(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки калькулятора: $e')),
      );
    }
  }

  Future<void> _applyStage3ArmatureCalculator(
    List<Stage3ArmatureCalculatorResult> rows,
  ) async {
    if (_materials.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        barrierColor: _dialogBarrierColor(context),
        builder: (ctx) => const ConfirmationDialog(
          title: 'Перенос',
          content:
              'Все текущие позиции материалов этапа 3 будут удалены и заменены позициями из калькулятора. Продолжить?',
          confirmText: 'Перенести',
          themeColor: Colors.blue,
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isApplyingStage3Calculator = true);
    try {
      final repo = ref.read(projectRepositoryProvider);
      final payload = rows
          .map(
            (row) => {
              'catalog_item': row.item.id,
              'quantity': row.quantity,
            },
          )
          .toList();
      final result = await repo.applyStage3Armature(widget.stage.id, payload);
      final created = result['created'] ?? 0;
      final deleted = result['deleted'] ?? 0;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Позиции материалов перенесены из калькулятора: удалено $deleted, создано $created',
          ),
        ),
      );
      ref.invalidate(projectListProvider);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка переноса из калькулятора: $e')),
      );
    } finally {
      if (mounted) setState(() => _isApplyingStage3Calculator = false);
    }
  }

  Future<void> _saveMarkup(double value) async {
    try {
      final repo = ref.read(projectRepositoryProvider);
      await repo.updateStage(widget.stage.id, {'markup_percent': value});
      ref.invalidate(projectListProvider);
    } catch (e) {
      debugPrint("Error saving markup: $e");
    }
  }

  Future<void> _setShowPrices(bool value) async {
    if (_showPrices == value) return;

    final previous = _showPrices;
    setState(() {
      _showPrices = value;
      _stage = _stage.copyWith(showPrices: value);
    });

    try {
      final repo = ref.read(projectRepositoryProvider);
      await repo.updateStage(widget.stage.id, {'show_prices': value});
      ref.invalidate(projectListProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _showPrices = previous;
        _stage = _stage.copyWith(showPrices: previous);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка сохранения: $e")),
      );
    }
  }

  // --- Template Methods ---

  void _showWorkTemplatesDialog() async {
    try {
      final templates = await ref.read(workTemplatesProvider.future);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => TemplateSelectionDialog<WorkTemplate>(
          title: "Шаблоны работ",
          templates: templates,
          getName: (t) => t.name,
          getDescription: (t) => t.description,
          onSelected: (t) => _applyWorkTemplate(t.id),
          onDelete: (t) => _deleteWorkTemplate(t),
          themeColor: Colors.green, // Theme color for Work
          onCreate: () => _showSaveTemplateDialog('work'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка загрузки шаблонов: $e")));
    }
  }

  void _showMaterialTemplatesDialog() async {
    try {
      final templates = await ref.read(materialTemplatesProvider.future);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => TemplateSelectionDialog<MaterialTemplate>(
          title: "Шаблоны материалов",
          templates: templates,
          getName: (t) => t.name,
          getDescription: (t) => t.description,
          onSelected: (t) => _applyMaterialTemplate(t.id),
          onDelete: (t) => _deleteMaterialTemplate(t),
          themeColor: Colors.blue, // Theme color for Material
          onCreate: () => _showSaveTemplateDialog('material'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка загрузки шаблонов: $e")));
    }
  }

  Future<void> _deleteWorkTemplate(WorkTemplate t) async {
    try {
      await ref.read(templateRepositoryProvider).deleteWorkTemplate(t.id);
      if (!mounted) return;
      Navigator.pop(context); // Close dialog to refresh or re-open
      ref.invalidate(workTemplatesProvider);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка удаления: $e")));
    }
  }

  Future<void> _deleteMaterialTemplate(MaterialTemplate t) async {
    try {
      await ref.read(templateRepositoryProvider).deleteMaterialTemplate(t.id);
      if (!mounted) return;
      Navigator.pop(context);
      ref.invalidate(materialTemplatesProvider);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка удаления: $e")));
    }
  }

  void _showSaveTemplateDialog(String type) async {
    final themeColor = type == 'work' ? Colors.green : Colors.blue;
    final result = await showDialog<dynamic>(
      context: context,
      barrierColor: _dialogBarrierColor(context),
      builder: (context) => TextInputDialog(
        title: "Сохранить как шаблон",
        labelText: "Название шаблона",
        descriptionLabelText: "Описание (опционально)",
        themeColor: themeColor,
      ),
    );

    if (result == null) return;

    final name = result is Map ? result['text'] : result;
    final description = result is Map ? result['description'] : '';

    _saveTemplate(type, name, description);
  }

  Future<void> _saveTemplate(
      String type, String name, String description) async {
    if (name.trim().isEmpty) return;

    Navigator.pop(context); // Close dialog

    try {
      if (type == 'work') {
        await ref.read(templateRepositoryProvider).createWorkTemplateFromStage(
            _stage.id, name,
            description: description);
        ref.invalidate(workTemplatesProvider);
      } else if (type == 'material') {
        await ref
            .read(templateRepositoryProvider)
            .createMaterialTemplateFromStage(_stage.id, name,
                description: description);
        ref.invalidate(materialTemplatesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ошибка создания шаблона: $e")));
      }
    }
  }

  Future<void> _applyWorkTemplate(int templateId) async {
    if (_works.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        barrierColor: _dialogBarrierColor(context),
        builder: (ctx) => const ConfirmationDialog(
          title: "Применить шаблон?",
          content:
              "Применение шаблона приведет к удалению всех текущих позиций в разделе работ. Продолжить?",
          confirmText: "Применить",
          // isDestructive removed to use themeColor
          themeColor: Colors.green,
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isApplyingTemplate = true);
    try {
      await ref
          .read(templateRepositoryProvider)
          .applyWorkTemplate(widget.stage.id, templateId);
      if (!mounted) return;
      ref.invalidate(projectListProvider);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка применения: $e")));
    } finally {
      if (mounted) setState(() => _isApplyingTemplate = false);
    }
  }

  Future<void> _applyMaterialTemplate(int templateId) async {
    if (_materials.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        barrierColor: _dialogBarrierColor(context),
        builder: (ctx) => const ConfirmationDialog(
          title: "Применить шаблон?",
          content:
              "Применение шаблона приведет к удалению всех текущих позиций в разделе материалов. Продолжить?",
          confirmText: "Применить",
          // isDestructive removed to use themeColor
          themeColor: Colors.blue,
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isApplyingTemplate = true);
    try {
      await ref
          .read(templateRepositoryProvider)
          .applyMaterialTemplate(widget.stage.id, templateId);
      if (!mounted) return;
      ref.invalidate(projectListProvider);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка применения: $e")));
    } finally {
      if (mounted) setState(() => _isApplyingTemplate = false);
    }
  }
}
