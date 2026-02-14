import 'dart:async'; // For Timer

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/estimate_item_model.dart';
import '../../data/models/stage_model.dart';
import '../providers/project_providers.dart';
import '../widgets/estimate/estimate_tab.dart';
import '../dialogs/estimate/add_item_dialog.dart';
import '../dialogs/estimate/quantity_input_dialog.dart';
import '../dialogs/estimate/edit_item_dialog.dart';
import '../dialogs/estimate/estimate_actions_dialog.dart';
import '../../../engineering/presentation/dialogs/template_selection_dialog.dart';
import '../../../engineering/presentation/providers/template_providers.dart';
import '../../../engineering/data/models/template_models.dart';
import '../../../../shared/presentation/dialogs/text_input_dialog.dart';
import '../../../../shared/presentation/dialogs/confirmation_dialog.dart';

import '../widgets/stages/stage_card.dart';

class EstimateScreen extends ConsumerStatefulWidget {
  final String projectId;
  final StageModel stage;

  const EstimateScreen(
      {required this.projectId, required this.stage, super.key});

  @override
  ConsumerState<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends ConsumerState<EstimateScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _markupDebounce;

  int _currentIndex = 0;
  bool _showPrices = true;
  double _markupPercent = 0;

  bool _isImportingShields = false;
  bool _isCalculatingWorks = false;
  bool _isApplyingTemplate = false;

  // Local state for items (for optimistic updates and display)
  List<EstimateItemModel> _items = [];
  late StageModel _stage;

  List<EstimateItemModel> get _works =>
      _items.where((i) => i.itemType == 'work').toList();
  List<EstimateItemModel> get _materials =>
      _items.where((i) => i.itemType != 'work').toList();

  @override
  void initState() {
    super.initState();
    _stage = widget.stage;
    _markupPercent = _stage.markupPercent;

    // Load items
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    try {
      final repo = ref.read(projectRepositoryProvider);
      // Fetch stage data including items
      final stage = await repo.fetchStage(widget.stage.id);
      if (mounted) {
        setState(() {
          _items = stage.estimateItems;
          _stage = stage;
          _markupPercent = stage.markupPercent;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing estimate: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _markupDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Backdrop filter when FAB is expanded
    // Backdrop filter when FAB is expanded
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          tooltip: 'Назад',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(StageCard.getStageTitleDisplay(widget.stage.title)),
        actions: [
          // PDF Actions Button (Deep Purple - Analytics/Graph)
          _buildActionButton(
            context,
            icon: Icons.auto_graph_rounded,
            color: Colors.deepPurple,
            onTap: () => _showPdfActionsDialog(context),
            tooltip: "PDF смета",
          ),
          const SizedBox(width: 8),
          // Text Actions Button (Orange - Structure/Segments)
          _buildActionButton(
            context,
            icon: Icons.segment_rounded,
            color: Colors.orange,
            onTap: () => _showTextActionsDialog(context),
            tooltip: "Текстовые сметы",
          ),
          const SizedBox(width: 8),
          // Overflow Menu
          PopupMenuButton<String>(
            tooltip: 'Действия',
            icon: const Icon(Icons.more_vert),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            surfaceTintColor: Colors.white,
            onSelected: (value) {
              switch (value) {
                case 'toggle_prices':
                  setState(() => _showPrices = !_showPrices);
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
                case 'save_template':
                  _showSaveTemplateDialog(
                      _currentIndex == 0 ? 'work' : 'material');
                  break;
                case 'clear_all':
                  _deleteAllItems();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              final isWork = _currentIndex == 0;
              return [
                if (!isWork) ...[
                  CheckedPopupMenuItem(
                    value: 'toggle_prices',
                    checked: _showPrices,
                    child: const Text('Показывать цены'),
                  ),
                  const PopupMenuDivider(),
                ],
                PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(
                        isWork ? Icons.auto_awesome : Icons.download_rounded,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                          isWork ? "Рассчитать работы" : "Импорт из инженерки"),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'apply_template',
                  child: Row(
                    children: [
                      Icon(Icons.copy_all_rounded,
                          color: Colors.grey.shade600, size: 20),
                      const SizedBox(width: 12),
                      const Text('Применить шаблон...'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'save_template',
                  child: Row(
                    children: [
                      Icon(Icons.save_as,
                          color: Colors.grey.shade600, size: 20),
                      const SizedBox(width: 12),
                      const Text('Сохранить как шаблон...'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever,
                          color: Colors.red.shade300, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Очистить смету...', // Destructive
                        style: TextStyle(color: Colors.red.shade400),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Works Tab
          EstimateTab(
            items: _works,
            title: 'Работы', // Determines view mode inside widget
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
            items: _materials,
            title: 'Материалы',
            showPrices: _showPrices,
            onUpdate: _updateItemFromTab,
            onDelete: _deleteItemFromTab,
            onShowPricesChanged: (v) => setState(() => _showPrices = v),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman),
            label: 'Работы',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Материалы',
          ),
        ],
      ),
      floatingActionButton: Tooltip(
        message: 'Добавить позицию',
        preferBelow: false,
        verticalOffset: 32,
        child: FloatingActionButton(
          heroTag: 'add_estimate_item',
          onPressed: _showSearchDialog,
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
      barrierColor: Colors.transparent,
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

  void _showSearchDialog() {
    final index = _currentIndex;
    final itemType = index == 0 ? 'work' : 'material';
    final showPrices = itemType == 'work' ? true : _showPrices;
    final hidePrices = !showPrices;

    showDialog(
      context: context,
      builder: (_) => AddItemDialog(
        itemType: itemType,
        hidePrices: hidePrices,
        onAdd: (catalogItem) async {
          // If ID == 0, it's manual.
          if (catalogItem.id == 0) {
            Navigator.pop(context); // Close Add Dialog
            _showManualAddDialog();
            return;
          }

          Navigator.pop(context); // Close search dialog

          final quantities = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (_) => QuantityInputDialog(
              item: catalogItem,
              itemType: itemType,
              hidePrices: hidePrices,
            ),
          );

          if (quantities == null) return;

          // Create model for _saveNewItem
          final newItem = EstimateItemModel(
            id: 0,
            stage: widget.stage.id,
            itemType: itemType,
            name: catalogItem.name,
            unit: catalogItem.unit,
            pricePerUnit:
                quantities['price']?.toDouble() ?? catalogItem.defaultPrice,
            currency: quantities['currency'] as String? ??
                catalogItem.defaultCurrency,
            totalQuantity: quantities['total']?.toDouble() ?? 0.0,
            employerQuantity: quantities['employer']?.toDouble() ?? 0.0,
            markupPercent: 0,
            isPreliminary: false,
          );

          _saveNewItem(newItem, catalogItem.id);
        },
      ),
    );
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
      _refresh();
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
        barrierColor: Colors.transparent,
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
        barrierColor: Colors.transparent,
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
        barrierColor: Colors.transparent,
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

  Future<void> _saveMarkup(double value) async {
    try {
      final repo = ref.read(projectRepositoryProvider);
      await repo.updateStage(widget.stage.id, {'markup_percent': value});
      ref.invalidate(projectListProvider);
    } catch (e) {
      debugPrint("Error saving markup: $e");
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
      // Re-open/Refresh logic could be better, but closing is safe.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Шаблон '${t.name}' удален")));
      // Force refresh of provider?
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Шаблон '${t.name}' удален")));
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
      barrierColor: Colors.transparent,
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

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Шаблон '$name' создан")));
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
        barrierColor: Colors.transparent,
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Шаблон работ применен!")));
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
        barrierColor: Colors.transparent,
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Шаблон материалов применен!")));
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

  Widget _buildActionButton(BuildContext context,
      {required IconData icon,
      required MaterialColor color,
      required VoidCallback onTap,
      required String tooltip}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      iconSize: 28,
      color: color,
      tooltip: tooltip,
    );
  }
}
