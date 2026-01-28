import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/estimate_item_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/stage_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/dialogs/estimate/add_item_dialog.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/dialogs/estimate/edit_item_dialog.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/dialogs/estimate/quantity_input_dialog.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_providers.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/estimate/estimate_tab.dart';

class EstimateScreen extends ConsumerStatefulWidget {
  final StageModel stage;
  final String projectId;

  const EstimateScreen(
      {super.key, required this.stage, required this.projectId});

  @override
  ConsumerState<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends ConsumerState<EstimateScreen> {
  late List<EstimateItemModel> _items;
  late StageModel _stage;
  bool _isLoading = true;
  double _markupPercent = 0.0;
  bool _showPrices = false;

  @override
  void initState() {
    super.initState();
    _stage = widget.stage;
    _items = List.from(widget.stage.estimateItems);
    _markupPercent = widget.stage.markupPercent;
    _showPrices = widget.stage.showPrices;

    // Force refresh on init to ensure data is fresh
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final repo = ref.read(projectRepositoryProvider);
      debugPrint("📝 Fetching stage ID: ${widget.stage.id}");
      final updatedStage = await repo.fetchStage(widget.stage.id);

      if (!mounted) return;
      setState(() {
        _stage = updatedStage;
        _items = updatedStage.estimateItems;
        _isLoading = false;
        // Also sync settings if they changed on backend
        _markupPercent = updatedStage.markupPercent;
        _showPrices = updatedStage.showPrices;
      });

      // Invalidate parent providers
      ref.invalidate(projectListProvider);
      ref.invalidate(projectByIdProvider(widget.projectId));
    } catch (e) {
      if (!mounted) return;
      debugPrint("Refresh error: $e");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка обновления: $e")));
    }
  }

  // Filtered lists
  List<EstimateItemModel> get _works =>
      _items.where((i) => i.itemType == 'work').toList();
  List<EstimateItemModel> get _materials =>
      _items.where((i) => i.itemType == 'material').toList();

  Future<void> _saveMarkup(double val) async {
    setState(() => _markupPercent = val);
    try {
      final repo = ref.read(projectRepositoryProvider);
      await repo.updateStage(widget.stage.id, {'markup_percent': val});
    } catch (e) {
      debugPrint("Error saving markup: $e");
    }
  }

  Future<void> _saveShowPrices(bool val) async {
    setState(() => _showPrices = val);
    try {
      final repo = ref.read(projectRepositoryProvider);
      await repo.updateStage(widget.stage.id, {'show_prices': val});
    } catch (e) {
      debugPrint("Error saving showPrices: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(builder: (context) {
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddItemDialog(context),
            child: const Icon(Icons.add),
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  title: Text("Смета: ${_stage.title}"),
                  pinned: true,
                  floating: true,
                  forceElevated: innerBoxIsScrolled,
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: "Материалы"),
                      Tab(text: "Работы"),
                    ],
                  ),
                  actions: [
                    IconButton(
                        onPressed: _showTemplatesDialog,
                        icon: const Icon(Icons.file_copy_outlined),
                        tooltip: "Шаблоны"),
                    _buildCopyMenu(),
                    IconButton(
                        onPressed: _showReport,
                        icon: const Icon(Icons.description)),
                  ],
                ),
              ];
            },
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      EstimateTab(
                        key: ValueKey(
                            'materials_tab_${_stage.materialNotes.hashCode}'),
                        items: _materials,
                        onUpdate: _updateItemFromTab,
                        onDelete: _deleteItemFromTab,
                        title: "Материалы",
                        note: _stage.materialNotes,
                        onSaveNote: (val) => _saveNotes('material', val),
                        markupPercent: _markupPercent,
                        onMarkupChanged: _saveMarkup,
                        showPrices: _showPrices,
                        onShowPricesChanged: _saveShowPrices,
                      ),
                      EstimateTab(
                        key: ValueKey('works_tab_${_stage.workNotes.hashCode}'),
                        items: _works,
                        onUpdate: _updateItemFromTab,
                        onDelete: _deleteItemFromTab,
                        title: "Работы",
                        note: _stage.workNotes,
                        onSaveNote: (val) => _saveNotes('work', val),
                      ),
                    ],
                  ),
          ),
        );
      }),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final tabController = DefaultTabController.of(context);
    final index = tabController.index;
    final itemType = index == 0 ? 'material' : 'work';
    // Logic: if Work tab, always show prices. If Material, check local state.
    final showPrices = itemType == 'work' ? true : _showPrices;
    final hidePrices = !showPrices;

    showDialog(
        context: context,
        builder: (_) => AddItemDialog(
              itemType: itemType,
              hidePrices: hidePrices,
              onAdd: (catalogItem) async {
                // If ID == 0, it's manual. We need to ASK for Name/Unit/Price immediately.
                // Reusing EditItemDialog is best, but EditItemDialog takes EstimateItemModel.
                // Let's create a temporary EstimateItemModel.

                if (catalogItem.id == 0) {
                  Navigator.pop(context); // Close Add Dialog

                  final tempItem = EstimateItemModel(
                    id: 0,
                    stage: widget.stage.id,
                    itemType: itemType,
                    name: '',
                    unit: 'шт',
                    totalQuantity: 1,
                    pricePerUnit: 0,
                  );

                  // Open Edit Dialog directly
                  final result = await showDialog<dynamic>(
                      context: context,
                      builder: (_) => EditItemDialog(
                          item: tempItem, hidePrices: hidePrices));

                  if (result is EstimateItemModel) {
                    // Save New Manual Item
                    _saveNewItem(result, null);
                  }
                  return;
                }

                Navigator.pop(context); // Close search dialog

                final quantities = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (_) => QuantityInputDialog(
                          item: catalogItem,
                          itemType: itemType,
                          hidePrices: hidePrices,
                        ));

                if (quantities == null) return;

                // Add Catalog Item
                try {
                  final repo = ref.read(projectRepositoryProvider);
                  await repo.addEstimateItem({
                    'stage': widget.stage.id,
                    'catalog_item': catalogItem.id,
                    'item_type': catalogItem.itemType,
                    'total_quantity': quantities['total'],
                    'employer_quantity': quantities['employer'],
                    'price_per_unit': quantities['price'],
                    'currency': quantities['currency'],
                  });
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Добавлено!")));
                  _refresh();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Ошибка добавления: $e")));
                }
              },
            ));
  }

  Future<void> _saveNewItem(EstimateItemModel item, int? catalogItemId) async {
    try {
      final repo = ref.read(projectRepositoryProvider);
      // If catalogItemId is null, we send fields manually.
      await repo.addEstimateItem({
        'stage': widget.stage.id,
        'catalog_item': catalogItemId, // null if manual
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

  Widget _buildCopyMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.copy),
      itemBuilder: (context) => [
        PopupMenuItem(
            child: const Text("Копировать РАБОТЫ (Клиент)"),
            onTap: () => _copyReport('client', itemType: 'work')),
        PopupMenuItem(
            child: const Text("Копировать РАБОТЫ (Для Шефа)"),
            onTap: () => _copyReport('employer', itemType: 'work')),
        const PopupMenuItem<String>(
          value: 'markup',
          child: Text("Копировать МАТЕРИАЛЫ (С наценкой)"),
        ),
        PopupMenuItem(
            child: const Text("Копировать Список МАТЕРИАЛОВ"),
            onTap: () => _copyReport('client', itemType: 'material')),
      ],
      onSelected: (value) {
        if (value == 'markup') {
          _copyReportWithMarkup();
        }
      },
    );
  }

  void _copyReportWithMarkup() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln(
          "Список материалов (с наценкой ${_markupPercent.toStringAsFixed(1)}%):");

      // Calculate displayed items with markup
      List<EstimateItemModel> itemsToCopy = _materials;
      if (_markupPercent > 0) {
        itemsToCopy = _materials.map((item) {
          final boostedPrice =
              (item.pricePerUnit ?? 0) * (1 + (_markupPercent / 100));
          return item.copyWith(pricePerUnit: boostedPrice);
        }).toList();
      }

      // Group by category
      final Map<String, List<EstimateItemModel>> grouped = {};
      for (var item in itemsToCopy) {
        final cat = item.categoryName ?? 'Разное';
        if (!grouped.containsKey(cat)) grouped[cat] = [];
        grouped[cat]!.add(item);
      }

      final sortedCats = grouped.keys.toList()..sort();
      if (sortedCats.contains('Разное')) {
        sortedCats.remove('Разное');
        sortedCats.add('Разное');
      }

      double totalSum = 0;

      for (var cat in sortedCats) {
        buffer.writeln("\n--- $cat ---");
        for (var item in grouped[cat]!) {
          final price = item.pricePerUnit ?? 0;
          final sum = (item.totalQuantity) * price;
          totalSum += sum;
          final currency = item.currency == 'USD' ? '\$' : 'р';

          // Clean format
          String fmt(double v) =>
              v.toStringAsFixed(2).replaceAll(RegExp(r"\.?0+$"), "");

          buffer.writeln(
              "- ${item.name}: ${fmt(item.totalQuantity)} ${item.unit} x ${fmt(price)}$currency = ${fmt(sum)}$currency");
        }
      }

      buffer.writeln("\nИТОГО: ${totalSum.toStringAsFixed(2)}");

      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Скопировано с учетом наценки!")),
      );
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
        _refresh(); // Auto-refresh logic replaces manual list manipulation for consistency
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
      _refresh(); // Auto-refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка сохранения: $e")));
    }
  }

  void _showTemplatesDialog() async {
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
      _refresh(); // Auto-refresh
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка применения: $e")));
    }
  }

  void _showReport() async {
    try {
      final repo = ref.read(projectRepositoryProvider);
      final reports = await repo.fetchStageReport(widget.stage.id);
      if (!mounted) return;
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Center(child: Text("Отчеты")),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("--- Клиент ---",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SelectableText(reports['client_report'] ?? ''),
                    const SizedBox(height: 20),
                    const Text("--- Работодатель ---",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SelectableText(reports['employer_report'] ?? ''),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Закрыть"))
              ],
            );
          });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    }
  }

  void _copyReport(String reportType, {String? itemType}) async {
    try {
      final repo = ref.read(projectRepositoryProvider);
      final reports =
          await repo.fetchStageReport(widget.stage.id, type: itemType);
      final text = reportType == 'client'
          ? reports['client_report']
          : reports['employer_report'];

      if (text != null) {
        await Clipboard.setData(ClipboardData(text: text));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Отчет скопирован!")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка копирования: $e")));
    }
  }

  Future<void> _saveNotes(String type, String value) async {
    debugPrint("💾 Saving note: type='$type', value='$value'");

    // Optimistic update
    setState(() {
      if (type == 'work') {
        _stage = _stage.copyWith(workNotes: value);
      } else {
        _stage = _stage.copyWith(materialNotes: value);
      }
    });

    try {
      final repo = ref.read(projectRepositoryProvider);
      final data =
          type == 'work' ? {'work_notes': value} : {'material_notes': value};

      await repo.updateStage(widget.stage.id, data);
      debugPrint("✅ Note saved successfully");

      // Optimistic update already applied, no need to refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка сохранения заметки: $e")));
    }
  }
}
