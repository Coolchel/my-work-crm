import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/features/catalog/data/catalog_repository.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/estimate_item_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/stage_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_providers.dart'; // Import for invalidation and repository

class EstimateScreen extends ConsumerStatefulWidget {
  final StageModel stage;
  final String projectId;

  const EstimateScreen({Key? key, required this.stage, required this.projectId})
      : super(key: key);

  @override
  ConsumerState<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends ConsumerState<EstimateScreen> {
  late List<EstimateItemModel> _items;
  late StageModel _stage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _stage = widget.stage;
    _items = List.from(widget.stage.estimateItems);
    // Force refresh on init to ensure data is fresh (even if passed from stale parent)
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final repo = ref.read(projectRepositoryProvider);
      debugPrint("📝 Fetching stage ID: ${widget.stage.id}");
      final updatedStage = await repo.fetchStage(widget.stage.id);
      debugPrint(
          "📝 Loaded notes for stage ${updatedStage.id}: work='${updatedStage.workNotes}', material='${updatedStage.materialNotes}'");
      if (!mounted) return;
      setState(() {
        _stage = updatedStage;
        _items = updatedStage.estimateItems;
        _isLoading = false;
      });

      // Invalidate parent providers so they refetch fresh data when we return
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
                      Tab(text: "Работы"),
                      Tab(text: "Материалы"),
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
                      _EstimateTab(
                        key: ValueKey('works_tab_${_stage.workNotes.hashCode}'),
                        items: _works,
                        onUpdate: _updateItemFromTab,
                        onDelete: _deleteItemFromTab,
                        title: "Работы",
                        note: _stage.workNotes,
                        onSaveNote: (val) => _saveNotes('work', val),
                      ),
                      _EstimateTab(
                        key: ValueKey(
                            'materials_tab_${_stage.materialNotes.hashCode}'),
                        items: _materials,
                        onUpdate: _updateItemFromTab,
                        onDelete: _deleteItemFromTab,
                        title: "Материалы",
                        note: _stage.materialNotes,
                        onSaveNote: (val) => _saveNotes('material', val),
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
    final itemType = index == 0 ? 'work' : 'material';

    showDialog(
        context: context,
        builder: (_) => _AddItemDialog(
              itemType: itemType,
              onAdd: (catalogItem) async {
                // If ID == 0, it's manual. We need to ASK for Name/Unit/Price immediately.
                // Reusing _EditItemDialog is best, but _EditItemDialog takes EstimateItemModel.
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
                      builder: (_) => _EditItemDialog(item: tempItem));

                  if (result is EstimateItemModel) {
                    // Save New Manual Item
                    _saveNewItem(result, null);
                  }
                  return;
                }

                Navigator.pop(context); // Close search dialog

                final quantities = await showDialog<Map<String, double>>(
                    context: context,
                    builder: (_) => _QuantityInputDialog(
                          item: catalogItem,
                          itemType: itemType,
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
                  });
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Добавлено!")));
                  _refresh();
                } catch (e) {
                  if (!mounted) return;
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
        PopupMenuItem(
            child: const Text("Копировать Список МАТЕРИАЛОВ"),
            onTap: () => _copyReport('client', itemType: 'material')),
      ],
    );
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
              title: const Text("Удалить позицию?"),
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
                title: const Text("Применить шаблон"),
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
              title: const Text("Отчеты"),
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
          SnackBar(content: Text("Отчет скопирован!")),
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

class _EstimateTab extends StatefulWidget {
  final List<EstimateItemModel> items;
  final Function(EstimateItemModel) onUpdate;
  final Function(EstimateItemModel) onDelete;
  final String title;

  // Note props
  final String note;
  final Future<void> Function(String) onSaveNote;

  const _EstimateTab(
      {super.key,
      required this.items,
      required this.onUpdate,
      required this.onDelete,
      required this.title,
      required this.note,
      required this.onSaveNote});

  @override
  State<_EstimateTab> createState() => _EstimateTabState();
}

class _EstimateTabState extends State<_EstimateTab> {
  late TextEditingController _noteCtrl;
  Timer? _debounce;
  bool _saving = false;
  String? _lastSavedValue;

  @override
  void initState() {
    super.initState();
    debugPrint("📝 _EstimateTabState.initState: note='${widget.note}'");
    _noteCtrl = TextEditingController(text: widget.note);
    _lastSavedValue = widget.note;
  }

  @override
  void didUpdateWidget(_EstimateTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.note != oldWidget.note) {
      debugPrint(
          "📝 _EstimateTabState.didUpdateWidget: old='${oldWidget.note}', new='${widget.note}'");
      // Parent sent new data - sync if not actively typing
      bool isTyping = _debounce?.isActive ?? false;
      if (!isTyping) {
        _noteCtrl.text = widget.note;
        _lastSavedValue = widget.note;
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    // Save on exit if there are unsaved changes
    if (_noteCtrl.text != _lastSavedValue) {
      widget.onSaveNote(_noteCtrl.text);
    }
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onNoteChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 1), () async {
      setState(() => _saving = true);
      try {
        await widget.onSaveNote(value);
        if (mounted) _lastSavedValue = value;
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double totalUsd = 0;
    double totalByn = 0;
    for (var i in widget.items) {
      if (i.currency == 'USD') {
        totalUsd += (i.clientAmount ?? 0);
      } else {
        totalByn += (i.clientAmount ?? 0);
      }
    }

    return CustomScrollView(
      primary:
          false, // Prevent conflict with NestedScrollView's scroll controller
      slivers: [
        SliverPersistentHeader(
          delegate:
              _EstimateHeaderDelegate(totalUsd: totalUsd, totalByn: totalByn),
          pinned: true,
        ),
        if (widget.items.isEmpty)
          SliverToBoxAdapter(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text("Нет позиций")))),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = widget.items[index];
              return _EstimateListTile(
                item: item,
                onUpdate: widget.onUpdate,
                onDelete: () => widget.onDelete(item),
              );
            },
            childCount: widget.items.length,
          ),
        ),

        // Notes Section at the bottom - now inline
        SliverToBoxAdapter(
            child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Заметки (${widget.title})",
                      style: Theme.of(context).textTheme.titleSmall),
                  if (_saving)
                    const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Icon(Icons.check_circle_outline,
                        size: 16,
                        color: _noteCtrl.text == _lastSavedValue
                            ? Colors.green
                            : Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Дополнительная информация...",
                ),
                onChanged: _onNoteChanged,
              ),
            ],
          ),
        )),

        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }
}

class _EstimateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double totalUsd;
  final double totalByn;

  _EstimateHeaderDelegate({required this.totalUsd, required this.totalByn});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        "Итого: ${totalUsd.toStringAsFixed(2)}\$ | ${totalByn.toStringAsFixed(2)} руб",
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  double get maxExtent => 60.0;
  @override
  double get minExtent => 60.0;
  @override
  bool shouldRebuild(_EstimateHeaderDelegate oldDelegate) =>
      oldDelegate.totalUsd != totalUsd || oldDelegate.totalByn != totalByn;
}

class _EstimateListTile extends StatelessWidget {
  final EstimateItemModel item;
  final Function(EstimateItemModel) onUpdate;
  final VoidCallback onDelete;

  const _EstimateListTile(
      {Key? key,
      required this.item,
      required this.onUpdate,
      required this.onDelete})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currency = item.currency == 'USD' ? '\$' : ' руб';

    final clientAmount = item.clientAmount ?? 0;
    final myAmount = item.myAmount ?? 0;
    final employerAmount = item.employerAmount ?? 0;
    final showDetails = employerAmount > 0;

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 2), // Compact margin
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        dense: true, // Key for compactness
        visualDensity: const VisualDensity(
            horizontal: -4, vertical: -4), // Max compactness
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

        // Leading: Icon indicating type (Work/Material)
        leading: Icon(item.itemType == 'work' ? Icons.build : Icons.inventory_2,
            size: 20,
            color: item.itemType == 'work'
                ? Colors.blue.shade700
                : Colors.green.shade700),

        // Title: Name
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        // Subtitle: Calculation stats
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            // Main Row: Qty * Price = Total
            Text(
                "${item.totalQuantity} ${item.unit} x ${item.pricePerUnit}$currency = ${clientAmount.toStringAsFixed(2)}$currency",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87)),
            // Details Row (Employer Share etc)
            if (showDetails)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  // Compact string
                  "Шеф: ${employerAmount.toStringAsFixed(2)}$currency  |  Мои: ${myAmount.toStringAsFixed(2)}$currency",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              )
          ],
        ),

        // Trailing: Delete button (small)
        trailing: SizedBox(
          width: 30,
          height: 30,
          child: IconButton(
            icon:
                const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
            padding: EdgeInsets.zero,
            onPressed: onDelete,
            tooltip: "Удалить",
          ),
        ),

        onTap: () async {
          final result = await showDialog<dynamic>(
              context: context, builder: (_) => _EditItemDialog(item: item));

          if (result == 'delete') {
            onDelete();
          } else if (result is EstimateItemModel) {
            onUpdate(result);
          }
        },
      ),
    );
  }
}

class _AddItemDialog extends ConsumerStatefulWidget {
  final Function(CatalogItem) onAdd;
  final String itemType;

  const _AddItemDialog({required this.onAdd, required this.itemType});

  @override
  ConsumerState<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends ConsumerState<_AddItemDialog> {
  final _searchController = TextEditingController();
  List<CatalogItem> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search(query);
    });
  }

  void _search(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _results = []);
      return;
    }
    if (mounted) setState(() => _loading = true);
    try {
      final repo = ref.read(catalogRepositoryProvider);
      final items = await repo.searchItems(query, itemType: widget.itemType);
      if (mounted) setState(() => _results = items);
    } catch (e) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onItemAdded(CatalogItem item) {
    widget.onAdd(item);
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: SizedBox(
            height: 400,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText:
                        "Поиск (${widget.itemType == 'work' ? 'Работы' : 'Материалы'})",
                    suffixIcon: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              Expanded(
                  child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (ctx, i) {
                  final item = _results[i];
                  return ListTile(
                    title: Text(item.name),
                    subtitle:
                        Text("${item.defaultPrice} ${item.defaultCurrency}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _onItemAdded(item),
                    ),
                    onTap: () => _onItemAdded(item),
                  );
                },
              )),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton.icon(
                    onPressed: () {
                      // Manual Add: Create dummy item
                      final dummy = CatalogItem(
                          id: 0, // 0 signals manual
                          name: '',
                          category: 0,
                          unit: 'шт',
                          defaultPrice: 0,
                          defaultCurrency: 'USD',
                          itemType: widget.itemType);
                      widget.onAdd(dummy);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text("Добавить вручную (Свободная позиция)")),
              )
            ])));
  }
}

class _EditItemDialog extends StatefulWidget {
  final EstimateItemModel item;

  const _EditItemDialog({required this.item});

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  late TextEditingController _totalQtyCtrl;
  late TextEditingController _empQtyCtrl;
  late TextEditingController _myQtyCtrl;

  late TextEditingController _priceCtrl;
  late TextEditingController _nameCtrl; // New
  late TextEditingController _unitCtrl; // New

  late String _currency;
  bool _showEmployer = false;

  bool _isUpdating = false; // Prevents infinite loops

  @override
  void initState() {
    super.initState();
    _totalQtyCtrl =
        TextEditingController(text: widget.item.totalQuantity.toString());
    _empQtyCtrl =
        TextEditingController(text: widget.item.employerQuantity.toString());
    _myQtyCtrl = TextEditingController(
        text: (widget.item.totalQuantity - widget.item.employerQuantity)
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'\.0+\$'), '')); // Nice format

    _priceCtrl = TextEditingController(
        text: widget.item.pricePerUnit?.toString() ?? '0');

    _nameCtrl = TextEditingController(text: widget.item.name); // New
    _unitCtrl = TextEditingController(text: widget.item.unit); // New

    _currency = widget.item.currency;

    // Show if already has value or user expands it
    if (widget.item.employerQuantity > 0 && widget.item.itemType == 'work') {
      _showEmployer = true;
    }

    if (widget.item.itemType == 'work') {
      _setupListeners();
    }
  }

  void _setupListeners() {
    _totalQtyCtrl.addListener(() {
      if (_isUpdating) return;
      _calculate('total');
    });
    _empQtyCtrl.addListener(() {
      if (_isUpdating) return;
      _calculate('emp');
    });
    _myQtyCtrl.addListener(() {
      if (_isUpdating) return;
      _calculate('my');
    });
  }

  void _calculate(String source) {
    _isUpdating = true;
    try {
      final total =
          double.tryParse(_totalQtyCtrl.text.replaceAll(',', '.')) ?? 0;
      final emp = double.tryParse(_empQtyCtrl.text.replaceAll(',', '.')) ?? 0;
      final my = double.tryParse(_myQtyCtrl.text.replaceAll(',', '.')) ?? 0;

      if (source == 'total') {
        // Edit Total -> My = Total - Emp
        _myQtyCtrl.text =
            (total - emp).toStringAsFixed(2).replaceAll(RegExp(r'\.0+\$'), '');
      } else if (source == 'my') {
        // Edit My -> Total = My + Emp
        _totalQtyCtrl.text =
            (my + emp).toStringAsFixed(2).replaceAll(RegExp(r'\.0+\$'), '');
      } else if (source == 'emp') {
        // Edit Emp -> My = Total - Emp (Split logic)
        // Wait, user requirement 3: "If I change Emp with fixed Total -> My reclaculates"
        // But user requirement 1: "If I change Emp -> Total recalculates"
        // Applying "Split" logic as primary "Calculator" usage for sub-contracting.
        // Assuming "Fixed Total" means "I didn't just type in Total".

        // HOWEVER, to be safe and match the "Sum" expectation if starting from scratch:
        // Let's rely on the fact that usually you set Total first.
        // If I decide to change Emp, I usually mean "My share is less".
        _myQtyCtrl.text =
            (total - emp).toStringAsFixed(2).replaceAll(RegExp(r'\.0+\$'), '');
      }
    } finally {
      _isUpdating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if manual item (id=0 means new manual, or check if we have flag catalogItem=null in real model but model doesn't store it explicitly efficiently yet without query)
    // Actually, if it's a new item (id=0), we DEFINITELY allow editing Name/Unit.
    // If it's existing item, we usually block it IF it's linked to catalog.
    // But our EstimateItemModel doesn't store catalog link explicitly in fields list I saw earlier (it was missing).
    // Assuming for now we allow editing Name/Unit always OR if Id=0.
    // Optimization: Let's allow editing Name/Unit always for flexibility or only if it looks manual.
    // Given the task: "Edit dialog... but with empty fields for Name/Unit".

    final isNewManual = widget.item.id == 0;

    return AlertDialog(
      title: Text(isNewManual
          ? "Новая позиция"
          : "Редактирование: ${widget.item.name}"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isNewManual || widget.item.name.isEmpty) ...[
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Название"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _unitCtrl,
                decoration: const InputDecoration(labelText: "Ед. изм."),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _totalQtyCtrl,
              decoration: InputDecoration(
                labelText: "Общий объем (Клиент)",
                suffixIcon: widget.item.itemType == 'work'
                    ? IconButton(
                        icon: Icon(Icons.person_add_alt,
                            color: _showEmployer
                                ? Theme.of(context).primaryColor
                                : Colors.grey),
                        onPressed: () {
                          setState(() {
                            _showEmployer = !_showEmployer;
                            if (!_showEmployer) {
                              _empQtyCtrl.text = '0';
                              // Trigger recalculation to reset 'My Share' to Total
                              _calculate('emp');
                            } else {
                              // Start with 0 if opening
                              if (_empQtyCtrl.text.isEmpty ||
                                  _empQtyCtrl.text == '0.0') {
                                _empQtyCtrl.text = '0';
                              }
                            }
                          });
                        },
                        tooltip:
                            "Добавить объем работодателя/Показать калькулятор",
                      )
                    : null,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            if (widget.item.itemType == 'work' && _showEmployer) ...[
              const SizedBox(height: 10),
              // Interactive Fields Layout
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _myQtyCtrl,
                      decoration: const InputDecoration(
                          labelText: "Наш объем (Мастер)"),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _empQtyCtrl,
                      decoration: const InputDecoration(
                          labelText: "Объем работодателя"),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
            ] else if (_showEmployer) ...[
              // Material simple view (hidden mainly, but kept structure if needed)
              const SizedBox(height: 10),
              TextField(
                controller: _empQtyCtrl,
                decoration:
                    const InputDecoration(labelText: "Объем работодателя"),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _priceCtrl,
                  decoration: const InputDecoration(labelText: "Цена"),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                  value: _currency,
                  items: const [
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                    DropdownMenuItem(value: 'BYN', child: Text('BYN')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _currency = val);
                  })
            ]),
            const SizedBox(height: 10),
            const SizedBox(height: 10),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Удалить")),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена")),
        FilledButton(
          onPressed: _save,
          child: const Text("Сохранить"),
        ),
      ],
    );
  }

  void _save() {
    final totalFn =
        double.tryParse(_totalQtyCtrl.text.replaceAll(',', '.')) ?? 0;
    final empFn = double.tryParse(_empQtyCtrl.text.replaceAll(',', '.')) ?? 0;

    // VALIDATION
    if (empFn > totalFn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Ошибка: Доля работодателя не может быть больше общего объема!")));
      return;
    }

    final priceFn = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;

    Navigator.pop(
        context,
        widget.item.copyWith(
          totalQuantity: totalFn,
          employerQuantity: empFn,
          pricePerUnit: priceFn,
          currency: _currency,
          name: _nameCtrl.text, // Updated
          unit: _unitCtrl.text, // Updated
        ));
  }
}

class _QuantityInputDialog extends StatefulWidget {
  final CatalogItem item;
  final String itemType;
  const _QuantityInputDialog({required this.item, required this.itemType});

  @override
  State<_QuantityInputDialog> createState() => _QuantityInputDialogState();
}

class _QuantityInputDialogState extends State<_QuantityInputDialog> {
  late TextEditingController _totalCtrl;
  late TextEditingController _empCtrl;
  bool _showEmployer = false;

  @override
  void initState() {
    super.initState();
    _totalCtrl = TextEditingController(text: '1');
    _empCtrl = TextEditingController(text: '0');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Добавление: ${widget.item.name}"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
            controller: _totalCtrl,
            decoration: InputDecoration(
              labelText: "Общее кол-во",
              suffixIcon: widget.itemType == 'work'
                  ? IconButton(
                      icon: Icon(Icons.person_add_alt,
                          color: _showEmployer
                              ? Theme.of(context).primaryColor
                              : Colors.grey),
                      onPressed: () {
                        setState(() {
                          _showEmployer = !_showEmployer;
                          if (!_showEmployer) _empCtrl.text = '0';
                        });
                      },
                      tooltip: "Добавить объем работодателя",
                    )
                  : null,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        if (_showEmployer && widget.itemType == 'work')
          TextField(
              controller: _empCtrl,
              decoration:
                  const InputDecoration(labelText: "Кол-во работодателя"),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true)),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена")),
        FilledButton(
            onPressed: () {
              final t =
                  double.tryParse(_totalCtrl.text.replaceAll(',', '.')) ?? 0;
              final e =
                  double.tryParse(_empCtrl.text.replaceAll(',', '.')) ?? 0;

              if (e > t) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text("Ошибка: Доля работодателя > Общего объема")));
                return;
              }

              Navigator.pop(context, {'total': t, 'employer': e});
            },
            child: const Text("Добавить"))
      ],
    );
  }
}
