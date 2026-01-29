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
      _tabController.index == 0 ? Colors.green.shade400 : Colors.blue.shade400;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _buildSpeedDial(context),
      body: Stack(
        children: [
          GestureDetector(
            onTap: _isFabExpanded
                ? () => setState(() => _isFabExpanded = false)
                : null,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    title: Text("Смета: ${_stage.title}"),
                    pinned: true,
                    floating: true,
                  forceElevated: innerBoxIsScrolled,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(kTextTabBarHeight),
                    child: AbsorbPointer(
                      absorbing: _isFabExpanded,
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: _activeColor,
                        labelColor: _activeColor,
                        unselectedLabelColor: Colors.grey,
                        tabs: const [
                          Tab(text: "Работы"),
                          Tab(text: "Материалы"),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AbsorbPointer(
                        absorbing: _isFabExpanded,
                        child: IconButton(
                          onPressed: () => _showActionsDialog(context),
                          icon: Icon(Icons.widgets_outlined, color: _activeColor),
                          tooltip: "Меню действий",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
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
                        key: const ValueKey('works_tab'),
                        items: _works,
                        onUpdate: _updateItemFromTab,
                        onDelete: _deleteItemFromTab,
                        title: "Работы",
                        note: _stage.workNotes,
                        onSaveNote: (val) => _saveNotes('work', val),
                        isDisabled: _isFabExpanded,
                        onDismissRequest: () => setState(() => _isFabExpanded = false),
                      ),
                      EstimateTab(
                        key: const ValueKey('materials_tab'),
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
                        isDisabled: _isFabExpanded,
                        onDismissRequest: () => setState(() => _isFabExpanded = false),
                      ),

                    ],
                  ),
            ),
          ),
          
          // Backdrop / Scrim
          if (_isFabExpanded)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withOpacity(0.15),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpeedDial(BuildContext context) {
    // Pastel colors for Main FAB based on active tab
    final isWorks = _tabController.index == 0;
    final mainFabColor = isWorks ? Colors.green.shade200 : Colors.blue.shade200;
    
    // Contextual soft colors for SpeedDial buttons
    // Using shade50 for a very light pastel background
    final actionBtnColor = isWorks ? Colors.green.shade50 : Colors.blue.shade50;
    final actionBtnTextColor = isWorks ? Colors.green.shade800 : Colors.blue.shade800;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isFabExpanded) ...[
          _buildExtendedFab(
            icon: Icons.delete_forever,
            label: "Очистить",
            // Red style for destructive action
            color: Colors.red.shade50, 
            textColor: Colors.red,
            onTap: _deleteAllItems,
          ),
          const SizedBox(height: 8), 
          _buildExtendedFab(
            icon: Icons.file_copy_outlined,
            label: "Шаблоны",
            color: actionBtnColor, 
            textColor: actionBtnTextColor,
            onTap: _showTemplatesDialog,
          ),
          const SizedBox(height: 8),
          _buildExtendedFab(
            icon: Icons.edit_outlined,
            label: "Вручную",
            color: actionBtnColor, 
            textColor: actionBtnTextColor,
            onTap: () => _showManualAddDialog(context),
          ),
          const SizedBox(height: 8),
          _buildExtendedFab(
            icon: Icons.search,
            label: "Поиск",
            color: actionBtnColor, 
            textColor: actionBtnTextColor,
            onTap: () => _showAddItemDialog(context),
          ),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          onPressed: () {
            setState(() => _isFabExpanded = !_isFabExpanded);
          },
          heroTag: 'main_fab',
          // Pastel Main FAB
          backgroundColor: mainFabColor, 
          foregroundColor: Colors.black87, // Ensure icon is visible on pastel
          elevation: 2,
          child: Icon(_isFabExpanded ? Icons.close : Icons.add),
        ),
      ],
    );
  }

  Widget _buildExtendedFab(
      {required IconData icon,
      required String label,
      required Color color, // This will be the pastel background
      Color? textColor,
      required VoidCallback onTap}) {
      
    final fgColor = textColor ?? Colors.black87;
    
    return SizedBox(
      width: 135, // Smaller width
      height: 36, // Smaller height
      child: FloatingActionButton.extended(
        onPressed: () {
          setState(() => _isFabExpanded = false);
          onTap();
        },
        heroTag: label,
        // Solid Background
        backgroundColor: color, 
        foregroundColor: fgColor, 
        elevation: 2,
        hoverColor: Colors.grey.shade100, // Explicit hover for standard feel
        icon: Icon(icon, size: 18), // Smaller icon
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), // Smaller text
      ),
    );
  }

  Future<void> _deleteAllItems() async {
    final isWork = _tabController.index == 0;
    final typeName = isWork ? "РАБОТЫ" : "МАТЕРИАЛЫ";
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Очистить раздел $typeName?", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 300), // Narrow width
          child: const Text("Вы действительно хотите удалить ВСЕ позиции из этого раздела? Это действие необратимо."),
        ),
        actions: [
          // Delete button (Less prominent)
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Удалить всё", style: TextStyle(color: Colors.red))
          ),
          // Cancel button (Prominent)
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: isWork ? Colors.green : Colors.blue, // Contextual color
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text("Отмена"),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceBetween,
      )
    );
    
    if (confirm == true) {
      try {
        final repo = ref.read(projectRepositoryProvider);
        final itemsToDelete = isWork ? _works : _materials;
        
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
                  
                  _buildSectionHeader("Копировать"),
                  _buildActionTile(context, Icons.copy_all, "РАБОТЫ (Для заказчика)", () async {
                     Navigator.pop(context);
                     final project = await ref.read(projectByIdProvider(widget.projectId).future);
                     final stageTitle = await _formatStageTitle(widget.stage.title);
                     final title = "${project.address} - Работы - $stageTitle";
                     
                     final text = _generateReportText(_works, title, showPrices: true, quantityType: 'total');
                     _copyText(text);
                  }, dense: true),
                  _buildActionTile(context, Icons.copy_all, "РАБОТЫ (Для Контрагента)", () async {
                    Navigator.pop(context);
                     final project = await ref.read(projectByIdProvider(widget.projectId).future);
                     final stageTitle = await _formatStageTitle(widget.stage.title);
                     final title = "${project.address} - Работы - $stageTitle";

                    final text = _generateReportText(_works, title, showPrices: true, quantityType: 'employer');
                    _copyText(text);
                  }, dense: true),
                   _buildActionTile(context, Icons.copy_all, "МАТЕРИАЛЫ (С наценкой)", () async {
                    Navigator.pop(context);
                     final project = await ref.read(projectByIdProvider(widget.projectId).future);
                     final stageTitle = await _formatStageTitle(widget.stage.title);
                     final title = "${project.address} - Материалы - $stageTitle";

                    final text = _generateReportText(_materials, title, showPrices: true, markup: _markupPercent, quantityType: 'total');
                    _copyText(text);
                  }, dense: true),
                   _buildActionTile(context, Icons.copy_all, "МАТЕРИАЛЫ (Текущий вид)", () async {
                    Navigator.pop(context);
                     final project = await ref.read(projectByIdProvider(widget.projectId).future);
                     final stageTitle = await _formatStageTitle(widget.stage.title);
                    
                    final title = "${project.address} - Материалы - $stageTitle";

                    final text = _generateReportText(_materials, title, showPrices: _showPrices, markup: _markupPercent, quantityType: 'total');
                    _copyText(text);
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

  Future<void> _copyText(String text) async {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Скопировано в буфер обмена!")),
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

  Future<String> _formatStageTitle(String rawTitle) async {
    // Basic formatting
    String title = rawTitle;
    if (title.startsWith('stage_')) {
      title = title.replaceAll('stage_', 'Этап ');
    } else if (title.startsWith('additional_')) {
      title = title.replaceAll('additional_', 'Доп. работы ');
    } else if (title.startsWith('pre_') || title.contains('preliminary')) {
       title = title.replaceAll('pre_', 'Предпросчет ');
       if (!title.contains('ориентировочно')) {
         title += " (ориентировочно)";
       }
    }
    return title;
  }

  String _generateReportText(List<EstimateItemModel> items, String fullTitle,
      {bool showPrices = true,
      double markup = 0.0,
      String quantityType = 'total' // 'total', 'employer', 'our'
      }) {
    final buffer = StringBuffer();
    buffer.writeln(fullTitle);
    buffer.writeln("----------------------------------------");

    // 1. Process items (Filter & Markup)
    double totalUsd = 0;
    double totalByn = 0;
    
    // For formulae and "Ours" calculation
    final List<double> usdParts = [];
    final List<double> bynParts = [];
    double totalClientUsd = 0;
    double totalClientByn = 0;
    
    // Pre-calculate Total Client Amount (Whole Stage) for "Ours" calc
    // This allows "Ours" = "Total Stage" - "Contractor Share"
    // even if some items are not assigned to contractor at all.
    for (var item in items) {
       double p = item.pricePerUnit ?? 0;
       if (markup > 0) p = p * (1 + (markup / 100));
       
       // Accumulate for all items that have > 0 total quantity
       if (item.totalQuantity > 0.001) {
          if (item.currency == 'USD') {
             totalClientUsd += item.totalQuantity * p;
          } else {
             totalClientByn += item.totalQuantity * p;
          }
       }
    }
    
    // We want a flat list, no categories.
    // Just filter and process.
    List<EstimateItemModel> finalItems = [];

    for (var item in items) {
      double quantity = 0;
      if (quantityType == 'total') {
        quantity = item.totalQuantity;
      } else if (quantityType == 'employer') {
        quantity = item.employerQuantity;
      } else if (quantityType == 'our') {
        quantity = item.totalQuantity - item.employerQuantity;
      }

      // Skip empty
      if (quantity <= 0.001) continue;

      double price = item.pricePerUnit ?? 0;
      // Apply markup
      if (markup > 0) {
        price = price * (1 + (markup / 100));
      }
      
      final processedItem = item.copyWith(
          totalQuantity: quantity, 
          pricePerUnit: price
      );
      finalItems.add(processedItem);
      
      final sum = quantity * price;

      // Calculate displayed totals
      if (item.currency == 'USD') {
        totalUsd += sum;
        usdParts.add(sum);
      } else {
        totalByn += sum;
        bynParts.add(sum);
      }
    }

    if (finalItems.isEmpty) {
      buffer.writeln("(Список пуст)");
      return buffer.toString();
    }

    // 2. Output Flat List
  String fmt(double v) =>
      v.toStringAsFixed(2).replaceAll(RegExp(r"\.?0+$"), "");

  // Split into groups
  final usdItems = finalItems.where((i) => i.currency == 'USD').toList();
  final otherItems = finalItems.where((i) => i.currency != 'USD').toList();
  
  int globalIndex = 0;

  void writeItems(List<EstimateItemModel> groupItems) {
    for (var item in groupItems) {
      globalIndex++;
      final q = item.totalQuantity;
      final p = item.pricePerUnit ?? 0;
      final sum = q * p;
      final currencySymbol = item.currency == 'USD' ? '\$' : 'р';
      
      buffer.write("${globalIndex}. ${item.name}: ${fmt(q)} ${item.unit}");
      
      if (showPrices) {
        buffer.write(" x ${fmt(p)}$currencySymbol = ${fmt(sum)}$currencySymbol");
      }
      
      if (!item.name.trim().endsWith('.')) {
         buffer.write(";");
      }
      buffer.writeln("");
    }
  }

  // Write USD items
  if (usdItems.isNotEmpty) {
    writeItems(usdItems);
  }

  // Separator if needed
  if (usdItems.isNotEmpty && otherItems.isNotEmpty) {
    buffer.writeln(""); // Empty line
  }

  // Write Other items
  if (otherItems.isNotEmpty) {
    writeItems(otherItems);
  }
  
  buffer.writeln("----------------------------------------");
  
  // 3. Totals
  if (showPrices) {
    if (quantityType == 'employer') {
      // --- CONTRACTOR REPORT FORMAT ---
      
      // I. YOURS (Contractor)
      final yoursParts = <String>[];
      
      // USD Formula
      if (usdParts.isNotEmpty) {
        final formula = usdParts.map((e) => "${fmt(e)}\$").join(" + ");
        yoursParts.add("$formula = ${fmt(totalUsd)}\$");
      }
      // BYN Formula
      if (bynParts.isNotEmpty) {
        final formula = bynParts.map((e) => "${fmt(e)}р").join(" + ");
        yoursParts.add("$formula = ${fmt(totalByn)}р");
      }
      
      if (yoursParts.isNotEmpty) {
         buffer.writeln("Итого Твои: ${yoursParts.join("; ")}");
      } else {
         buffer.writeln("Итого Твои: 0");
      }

      // II. OURS (Calculated: Total Client - Yours)
      final oursParts = <String>[];
      final totalOursUsd = totalClientUsd - totalUsd;
      final totalOursByn = totalClientByn - totalByn;

      // USD Calc
      // Only show if there was any client amount involved.
      if (totalClientUsd > 0.001 || totalUsd > 0.001) {
         oursParts.add("${fmt(totalClientUsd)}\$ - ${fmt(totalUsd)}\$ = ${fmt(totalOursUsd)}\$");
      }

      // BYN Calc
      if (totalClientByn > 0.001 || totalByn > 0.001) {
         oursParts.add("${fmt(totalClientByn)}р - ${fmt(totalByn)}р = ${fmt(totalOursByn)}р");
      }
      
      if (oursParts.isNotEmpty) {
        buffer.writeln("Итого Наши: ${oursParts.join("; ")}");
      }

    } else {
      // --- STANDARD FORMAT ---
      final parts = <String>[];
      // Rounding logic: <0.5 down, >=0.5 up (standard .round())
      if (totalUsd > 0.4) parts.add("${totalUsd.round()}\$");
      if (totalByn > 0.4) parts.add("${totalByn.round()}р");
      
      if (parts.isNotEmpty) {
        buffer.writeln("Итого: ${parts.join(" + ")}");
      } else {
        buffer.writeln("Итого: 0");
      }
    }
  }

  return buffer.toString();
}

  Future<void> _showReport() async {
    try {
      final project = await ref.read(projectByIdProvider(widget.projectId).future);
      final address = project.address;
      final rawStageTitle = widget.stage.title;
      final formattedStage = await _formatStageTitle(rawStageTitle);
      
      final List<_ReportTabInfo> tabs = [];
      
      final matBaseTitle = "$address - Материалы - $formattedStage";
      final workBaseTitle = "$address - Работы - $formattedStage";
      
      // --- ORDER: Works First, then Materials (V6) ---

      // 1. WORKS
      tabs.add(_ReportTabInfo(
        title: "Наши", 
        text: _generateReportText(_works, workBaseTitle, showPrices: true, quantityType: 'our'),
        color: Colors.green
      ));
      
      tabs.add(_ReportTabInfo(
        title: "Контрагент", 
        // ADDED: " - ТВОИ" suffix
        text: _generateReportText(_works, "$workBaseTitle - ТВОИ", showPrices: true, quantityType: 'employer'),
        color: Colors.green
      ));

      tabs.add(_ReportTabInfo(
        title: "Заказчик", 
        text: _generateReportText(_works, workBaseTitle, showPrices: true, quantityType: 'total'),
        color: Colors.green
      ));
      
      // 2. MATERIALS
      if (_showPrices) {
         // Case 1: With Prices
         
         // No Prices (Renamed V6: Материал)
         tabs.add(_ReportTabInfo(
            title: "Материал", 
            text: _generateReportText(_materials, matBaseTitle, showPrices: false, markup: 0, quantityType: 'total'),
             color: Colors.blue
         )); 

         // Base Prices (Renamed V6: Материал с ценами)
         tabs.add(_ReportTabInfo(
            title: "Материал с ценами", 
            text: _generateReportText(_materials, matBaseTitle, showPrices: true, markup: 0, quantityType: 'total'),
            color: Colors.blue
         ));
         
         if (_markupPercent > 0) {
            // Renamed V6: Материал с + %
            tabs.add(_ReportTabInfo(
              title: "Материал с + %", 
              text: _generateReportText(_materials, matBaseTitle, showPrices: true, markup: _markupPercent, quantityType: 'total'),
              color: Colors.blue
            ));
         }

      } else {
        // Case 2: Only No Prices
        tabs.add(_ReportTabInfo(
           title: "Материал", 
           text: _generateReportText(_materials, matBaseTitle, showPrices: false, markup: 0, quantityType: 'total'),
           color: Colors.blue
        ));
      }

      if (!mounted) return;
      
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Center(child: Text("Отчеты")),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: _ReportDialogContent(tabs: tabs),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    // V7: Black close button
                    style: TextButton.styleFrom(foregroundColor: Colors.black),
                    child: const Text("Закрыть"))
              ],
            );
          });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка подготовки отчета: $e")));
    }
  }

  // Legacy copy placeholder to keep code compiling if referenced elsewhere, 
  // though we removed references in _showActionsDialog.
  void _copyReport(String type) async {}

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

class _ReportTabInfo {
  final String title;
  final String text;
  final MaterialColor color;

  _ReportTabInfo({required this.title, required this.text, required this.color});
}

class _ReportDialogContent extends StatefulWidget {
  final List<_ReportTabInfo> tabs;
  
  const _ReportDialogContent({super.key, required this.tabs});

  @override
  State<_ReportDialogContent> createState() => _ReportDialogContentState();
}

class _ReportDialogContentState extends State<_ReportDialogContent> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentTab = widget.tabs[_currentIndex];
    final activeColor = currentTab.color;

    return Column(
      children: [
        // Navigation: Wrap with Chips instead of TabBar
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.center, // Center chips
            spacing: 8.0,
            runSpacing: 8.0,
            children: List.generate(widget.tabs.length, (index) {
              final tab = widget.tabs[index];
              final isSelected = index == _currentIndex;
              // Use color from the tab
              final color = tab.color;
              
              return ChoiceChip(
                label: Text(tab.title),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _currentIndex = index);
                  }
                },
                // V6 & V7: Pastel styling & Colored unselected
                selectedColor: color.shade100, // Slightly darker for selected to distinguish
                backgroundColor: color.withOpacity(0.15), // V7.1: Increased saturation (was 0.05)
                labelStyle: TextStyle(
                  color: isSelected ? color.shade900 : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                // V6: Thinner border
                side: BorderSide(
                  color: isSelected ? color.shade300 : Colors.grey.shade300,
                  width: 0.5,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        // V7: Colored divider
        Divider(color: activeColor.shade200, thickness: 1), // V7.1: Increased saturation (was shade100)
        const SizedBox(height: 8),
        
        // Content
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: SelectableText(
                currentTab.text, 
                style: const TextStyle(fontSize: 13, fontFamily: 'Courier', height: 1.2)
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        // Action Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
               await Clipboard.setData(ClipboardData(text: currentTab.text));
               if(!mounted) return;
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Скопировано!")));
            },
            icon: const Icon(Icons.copy, size: 18),
            // V6: Removed "отчет"
            label: Text("Копировать (${currentTab.title})"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: activeColor.shade50,
              foregroundColor: activeColor.shade800,
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
