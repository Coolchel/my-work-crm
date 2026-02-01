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

import '../widgets/estimate/estimate_speed_dial.dart';
import '../widgets/estimate/estimate_bottom_actions.dart';

class EstimateScreen extends ConsumerStatefulWidget {
  final String projectId;
  final StageModel stage;

  const EstimateScreen(
      {required this.projectId, required this.stage, super.key});

  @override
  ConsumerState<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends ConsumerState<EstimateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  Timer? _markupDebounce;

  bool _isFabExpanded = false;
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
    _tabController = TabController(length: 2, vsync: this);
    _stage = widget.stage;
    _markupPercent = _stage.markupPercent;

    // Load items
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Color get _activeColor =>
      _tabController.index == 0 ? Colors.green.shade400 : Colors.blue.shade400;

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
    _tabController.dispose();
    _scrollController.dispose();
    _markupDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Backdrop filter when FAB is expanded
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.stage.title),
                Text("Смета",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            actions: [
              // PDF Actions Button (Yellowish)
              _buildActionButton(
                context,
                icon: Icons.picture_as_pdf,
                color: Colors.amber,
                onTap: () => _showPdfActionsDialog(context),
                tooltip: "PDF действия",
              ),
              const SizedBox(width: 8),
              // Text Actions Button (Indigo)
              _buildActionButton(
                context,
                icon: Icons.description,
                color: Colors.indigo,
                onTap: () => _showTextActionsDialog(context),
                tooltip: "Текстовые действия",
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Работы"),
                Tab(text: "Материалы"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
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
          // FAB removed from here to place it above Overlay in Stack
        ),

        // Dark overlay when FAB is expanded (Below FAB)
        if (_isFabExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _isFabExpanded = false),
              child: Container(
                color: Colors.black54,
              ),
            ),
          ),

        // FAB and Speed Dial (Above Overlay)
        Positioned(
          right: 16,
          bottom: 16,
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 1) {
                // Materials Tab - New Bottom Actions
                return EstimateBottomActions(
                  onSearchTap: _showSearchDialog,
                  onDeleteAll: _deleteAllItems,
                  onSaveToTemplate: () => _showSaveTemplateDialog('material'),
                  onApplyTemplate: _showMaterialTemplatesDialog,
                  onImport: _importFromShields,
                  showPrices: _showPrices,
                  onTogglePrices: () =>
                      setState(() => _showPrices = !_showPrices),
                );
              } else {
                // Works Tab - Old Speed Dial
                return EstimateSpeedDial(
                  isExpanded: _isFabExpanded,
                  tabController: _tabController,
                  onToggle: () =>
                      setState(() => _isFabExpanded = !_isFabExpanded),
                  onDeleteAll: _deleteAllItems,
                  onShowTemplates: _showTemplatesDialog,
                  onManualAdd: _showManualAddDialog,
                  onSearchAdd: _showSearchDialog,
                );
              }
            },
          ),
        ),
      ],
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
    setState(() => _isFabExpanded = false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить смету?'),
        content: const Text('Все позиции текущего этапа будут удалены.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final repo = ref.read(projectRepositoryProvider);
        for (var item in _items) {
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
    setState(() => _isFabExpanded = false);

    // Create new item with defaults
    final newItem = EstimateItemModel(
      id: 0,
      stage: widget.stage.id,
      itemType: _tabController.index == 0 ? 'work' : 'material',
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
    setState(() => _isFabExpanded = false);

    final index = _tabController.index;
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
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Center(child: Text("Удалить позицию?")),
              content: const Text(
                  "Вы уверены, что хотите удалить эту позицию из сметы?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Отмена")),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("Удалить",
                        style: TextStyle(color: Colors.red))),
              ],
            ));

    if (confirm == true) {
      try {
        final repo = ref.read(projectRepositoryProvider);
        await repo.deleteEstimateItem(itemId);
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
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка сохранения: $e")));
    }
  }

  void _showTemplatesDialog() async {
    setState(() => _isFabExpanded = false);
    try {
      final repo = ref.read(projectRepositoryProvider);
      final templates = await repo.fetchEstimateTemplates();

      if (!mounted) return;
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Center(child: Text("Применить шаблон")),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: templates.length,
                    itemBuilder: (ctx, i) {
                      final t = templates[i];
                      return ListTile(
                        title: Text(t.name),
                        subtitle: Text(t.description ?? ''),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _applyTemplate(t.id);
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Отмена"))
                ],
              ));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    }
  }

  Future<void> _applyTemplate(int templateId) async {
    try {
      final repo = ref.read(projectRepositoryProvider);
      await repo.applyTemplate(widget.stage.id, templateId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Шаблон применен!")));
      _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка применения: $e")));
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
          title: "Выберите шаблон работ",
          templates: templates,
          getName: (t) => t.name,
          getDescription: (t) => t.description ?? '',
          onSelected: (t) => _applyWorkTemplate(t.id),
          onDelete: (t) => _deleteWorkTemplate(t),
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
          title: "Выберите шаблон материалов",
          templates: templates,
          getName: (t) => t.name,
          getDescription: (t) => t.description ?? '',
          onSelected: (t) => _applyMaterialTemplate(t.id),
          onDelete: (t) => _deleteMaterialTemplate(t),
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
      if (mounted) Navigator.pop(context); // Close dialog to refresh or re-open
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
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Шаблон '${t.name}' удален")));
      ref.invalidate(materialTemplatesProvider);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка удаления: $e")));
    }
  }

  void _showSaveTemplateDialog(String type) {
    final TextEditingController nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Сохранить как шаблон"),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: "Название шаблона",
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена"),
          ),
          FilledButton(
            onPressed: () => _saveTemplate(type, nameCtrl.text),
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTemplate(String type, String name) async {
    if (name.trim().isEmpty) return;

    Navigator.pop(context); // Close dialog

    // Show spinner if needed or just snackbar logic
    // We don't have a loading state for this specifically, but it's quick.

    try {
      if (type == 'work') {
        if (_stage == null) throw Exception("Этап не выбран");
        await ref
            .read(templateRepositoryProvider)
            .createWorkTemplateFromStage(_stage!.id, name);
        ref.invalidate(workTemplatesProvider);
      } else if (type == 'material') {
        if (_stage == null) throw Exception("Этап не выбран");
        await ref
            .read(templateRepositoryProvider)
            .createMaterialTemplateFromStage(_stage!.id, name);
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
    setState(() => _isApplyingTemplate = true);
    try {
      await ref
          .read(templateRepositoryProvider)
          .applyWorkTemplate(widget.stage.id, templateId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Шаблон работ применен!")));
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
    setState(() => _isApplyingTemplate = true);
    try {
      await ref
          .read(templateRepositoryProvider)
          .applyMaterialTemplate(widget.stage.id, templateId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Шаблон материалов применен!")));
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
