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

class _EstimateScreenState extends ConsumerState<EstimateScreen>
    with SingleTickerProviderStateMixin {
  late List<EstimateItemModel> _items;
  late StageModel _stage;
  bool _isLoading = true;
  double _markupPercent = 0.0;
  bool _showPrices = false;
  bool _isFabExpanded = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _stage = widget.stage;
    _items = List.from(widget.stage.estimateItems);
    _markupPercent = widget.stage.markupPercent;
    _showPrices = widget.stage.showPrices;
    
    // Explicit controller for FAB color sync
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.animation != null) {
        setState(() {}); // Rebuild to update FAB color
      }
    });

    // Force refresh on init to ensure data is fresh
    _refresh();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
  
  Color get _activeColor =>
      _tabController.index == 0 ? Colors.green.shade600 : Colors.blue.shade600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _buildSpeedDial(context),
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  title: Text("Смета: ${_stage.title}"),
                  pinned: true,
                  floating: true,
                  forceElevated: innerBoxIsScrolled,
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: _activeColor,
                    labelColor: _activeColor,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: "Работы"),
                      Tab(text: "Материалы"),
                    ],
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () => _showActionsDialog(context),
                        icon: Icon(Icons.widgets_outlined, color: _activeColor),
                        tooltip: "Меню действий",
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    ),
                  ],
                ),
              ];
            },
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      EstimateTab(
                        key: ValueKey('works_tab_${_stage.workNotes.hashCode}'),
                        items: _works,
                        onUpdate: _updateItemFromTab,
                        onDelete: _deleteItemFromTab,
                        title: "Работы",
                        note: _stage.workNotes,
                        onSaveNote: (val) => _saveNotes('work', val),
                      ),
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
                    ],
                  ),
          ),
          
          // Backdrop / Scrim
          if (_isFabExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isFabExpanded = false),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpeedDial(BuildContext context) {
    final themeColor = _activeColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isFabExpanded) ...[
          _buildExtendedFab(
            icon: Icons.delete_forever,
            label: "Очистить смету",
            color: Colors.red.shade700,
            onTap: _deleteAllItems,
          ),
          const SizedBox(height: 12),
          _buildExtendedFab(
            icon: Icons.file_copy_outlined,
            label: "Шаблоны",
            color: themeColor,
            onTap: _showTemplatesDialog,
          ),
          const SizedBox(height: 12),
          _buildExtendedFab(
            icon: Icons.edit_outlined,
            label: "Вручную",
            color: themeColor,
            onTap: () => _showManualAddDialog(context),
          ),
          const SizedBox(height: 12),
          _buildExtendedFab(
            icon: Icons.search,
            label: "Поиск",
            color: themeColor,
            onTap: () => _showAddItemDialog(context),
          ),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          onPressed: () {
            setState(() => _isFabExpanded = !_isFabExpanded);
          },
          heroTag: 'main_fab',
          backgroundColor: themeColor,
          child: Icon(_isFabExpanded ? Icons.close : Icons.add),
        ),
      ],
    );
  }

  Widget _buildExtendedFab(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return SizedBox(
      width: 170, // Fixed width for uniformity
      child: FloatingActionButton.extended(
        onPressed: () {
          setState(() => _isFabExpanded = false);
          onTap();
        },
        heroTag: label,
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 4,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _deleteAllItems() async {
    final isWork = _tabController.index == 0;
    final typeName = isWork ? "РАБОТЫ" : "МАТЕРИАЛЫ";
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Очистить раздел $typeName?"),
        content: const Text("Вы действительно хотите удалить ВСЕ позиции из этого раздела? Это действие необратимо."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Отмена")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Удалить всё", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
    
    if (confirm == true) {
      try {
        final repo = ref.read(projectRepositoryProvider);
        // We need to delete items one by one or have a bulk delete endpoint.
        // Assuming no bulk delete, we iterate. Efficient? No. Working? Yes.
        // Actually, let's filter the current list.
        final itemsToDelete = isWork ? _works : _materials;
        
        // Show loading
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Удаление...")));
        
        for (var item in itemsToDelete) {
          await repo.deleteEstimateItem(item.id);
        }
        
        _refresh();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Раздел очищен")));

      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка удаления: $e")));
      }
    }
  }

  void _showActionsDialog(BuildContext context) {
    final themeColor = _activeColor;
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text("Действия",
                        style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                            color: themeColor)),
                  ),
                  _buildActionTile(context, Icons.description_outlined, "Просмотреть отчеты", () {
                    Navigator.pop(context);
                    _showReport();
                  }),
                  const Divider(indent: 16, endIndent: 16),
                  
                  // Copy Sub-menu simulation (Expanded in dialog is tricky, let's use section)
                  _buildSectionHeader("Копировать"),
                  _buildActionTile(context, Icons.copy_all, "РАБОТЫ (Клиент)", () {
                     Navigator.pop(context);
                    _copyReport('client', itemType: 'work');
                  }, dense: true),
                  _buildActionTile(context, Icons.copy_all, "РАБОТЫ (Для Шефа)", () {
                    Navigator.pop(context);
                    _copyReport('employer', itemType: 'work');
                  }, dense: true),
                   _buildActionTile(context, Icons.copy_all, "МАТЕРИАЛЫ (С наценкой)", () {
                    Navigator.pop(context);
                    _copyReportWithMarkup();
                  }, dense: true),
                   _buildActionTile(context, Icons.copy_all, "МАТЕРИАЛЫ (Список)", () {
                    Navigator.pop(context);
                    _copyReport('client', itemType: 'material');
                  }, dense: true),

                  const Divider(indent: 16, endIndent: 16),
                  _buildActionTile(context, Icons.picture_as_pdf_outlined, "Экспорт в PDF (Скоро)", () {}, enabled: false),
                  _buildActionTile(context, Icons.share_outlined, "Поделиться (Скоро)", () {}, enabled: false),
                  
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Закрыть", style: TextStyle(color: Colors.grey)),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
      );
  }
  
  Widget _buildActionTile(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool dense = false, bool enabled = true}) {
    return ListTile(
      leading: Icon(icon, color: enabled ? Colors.grey.shade700 : Colors.grey.shade300, size: dense ? 20 : 24),
      title: Text(title, style: TextStyle(fontSize: dense ? 14 : 16, color: enabled ? Colors.black87 : Colors.grey.shade300)),
      onTap: enabled ? onTap : null,
      dense: dense,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      horizontalTitleGap: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showManualAddDialog(BuildContext context) async {
    final index = _tabController.index;
    final itemType = index == 0 ? 'work' : 'material';
    final showPrices = itemType == 'work' ? true : _showPrices;
    final hidePrices = !showPrices;

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
        builder: (_) => EditItemDialog(item: tempItem, hidePrices: hidePrices));

    if (result is EstimateItemModel) {
      // Save New Manual Item
      _saveNewItem(result, null);
    }
  }

  void _showAddItemDialog(BuildContext context) {
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
                  _showManualAddDialog(context);
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
