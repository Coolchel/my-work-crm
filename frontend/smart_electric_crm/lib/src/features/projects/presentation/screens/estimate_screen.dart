import 'dart:async'; // For Timer

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/estimate_item_model.dart';
import '../../data/models/stage_model.dart';
import '../../../catalog/domain/catalog_item.dart';
import '../providers/project_providers.dart';
import '../widgets/estimate/estimate_tab.dart';
import '../dialogs/estimate/add_item_dialog.dart';
import '../dialogs/estimate/quantity_input_dialog.dart';
import '../dialogs/estimate/edit_item_dialog.dart';
import '../dialogs/estimate/estimate_actions_dialog.dart';

import '../widgets/estimate/estimate_speed_dial.dart';

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
              children: [
                Text(widget.stage.title),
                Text("Смета",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            actions: [
              // Removed manual Refresh button as per user request (pull-to-refresh or back navigation is enough)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _showActionsDialog(context),
                  icon:
                      const Icon(Icons.widgets_outlined, color: Colors.indigo),
                  tooltip: "Меню действий",
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ),
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
          child: EstimateSpeedDial(
            isExpanded: _isFabExpanded,
            tabController: _tabController,
            onToggle: () => setState(() => _isFabExpanded = !_isFabExpanded),
            onDeleteAll: _deleteAllItems,
            onShowTemplates: _showTemplatesDialog,
            onManualAdd: _showManualAddDialog,
            onSearchAdd: _showSearchDialog,
          ),
        ),
      ],
    );
  }

  void _showActionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => EstimateActionsDialog(
        projectId: widget.projectId,
        stage: _stage,
        works: _works,
        materials: _materials,
        markupPercent: _markupPercent,
        showPrices: _showPrices,
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

  Future<void> _saveMarkup(double value) async {
    try {
      final repo = ref.read(projectRepositoryProvider);
      await repo.updateStage(widget.stage.id, {'markup_percent': value});
    } catch (e) {
      debugPrint("Error saving markup: $e");
    }
  }
}
