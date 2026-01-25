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

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.stage.estimateItems);
    // Force refresh on init to ensure data is fresh (even if passed from stale parent)
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final repo = ref.read(projectRepositoryProvider);
      // Invalidate provider to force potential background update if using Riverpod for caching
      // ref.invalidate(stageProvider(widget.stage.id)); // Assuming such provider exists, or manual repo fetch is enough.
      // Since we fetch manually here, we just need to ensure fetchStage gets fresh data (usually it does).

      final updatedStage = await repo.fetchStage(widget.stage.id);
      if (!mounted) return;
      setState(() {
        _items = updatedStage.estimateItems;
      });

      // Invalidate parent providers so they refetch fresh data when we return
      ref.invalidate(projectListProvider);
      ref.invalidate(projectByIdProvider(widget.projectId));
    } catch (e) {
      if (!mounted) return;
      debugPrint("Refresh error: $e");
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
                  title: Text("Смета: ${widget.stage.title}"),
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
            body: TabBarView(
              children: [
                _EstimateTab(
                  items: _works,
                  onUpdate: _updateItemFromTab,
                  onDelete: _deleteItemFromTab,
                  title: "Работы",
                ),
                _EstimateTab(
                  items: _materials,
                  onUpdate: _updateItemFromTab,
                  onDelete: _deleteItemFromTab,
                  title: "Материалы",
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
                final quantities = await showDialog<Map<String, double>>(
                    context: context,
                    builder: (_) => _QuantityInputDialog(
                          item: catalogItem,
                          itemType: itemType,
                        ));

                if (quantities == null) return;

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
                  _refresh(); // Auto-refresh
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Ошибка добавления: $e")));
                }
              },
            ));
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
}

class _EstimateTab extends StatelessWidget {
  final List<EstimateItemModel> items;
  final Function(EstimateItemModel) onUpdate;
  final Function(EstimateItemModel) onDelete;
  final String title;

  const _EstimateTab(
      {required this.items,
      required this.onUpdate,
      required this.onDelete,
      required this.title});

  @override
  Widget build(BuildContext context) {
    double totalUsd = 0;
    double totalByn = 0;
    for (var i in items) {
      if (i.currency == 'USD')
        totalUsd += (i.clientAmount ?? 0);
      else
        totalByn += (i.clientAmount ?? 0);
    }

    if (items.isEmpty) {
      return CustomScrollView(slivers: [
        SliverFillRemaining(
            child: Center(child: Text("Нет позиций в '$title'")))
      ]);
    }

    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          delegate:
              _EstimateHeaderDelegate(totalUsd: totalUsd, totalByn: totalByn),
          pinned: true,
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = items[index];
              return _EstimateListTile(
                item: item,
                onUpdate: onUpdate,
                onDelete: () => onDelete(item),
              );
            },
            childCount: items.length,
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
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

    return ListTile(
      leading: item.itemType == 'work'
          ? const Icon(Icons.build, color: Colors.blue)
          : const Icon(Icons.inventory_2, color: Colors.green),
      title: Text(item.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Главная цифра: Полный итог для клиента
          Text(
              "${item.totalQuantity} ${item.unit} * ${item.pricePerUnit}$currency = ${clientAmount.toStringAsFixed(2)}$currency",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87)),
          // 2. Детализация (если есть доля шефа)
          if (showDetails) ...[
            const SizedBox(height: 2),
            Text(
              "Общий итог: ${clientAmount.toStringAsFixed(2)}$currency | Моя доля: ${myAmount.toStringAsFixed(2)}$currency | Доля шефа: ${employerAmount.toStringAsFixed(2)}$currency",
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ]
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.grey),
        onPressed: onDelete,
      ),
      onTap: () async {
        final result = await showDialog<dynamic>(
            context: context, builder: (_) => _EditItemDialog(item: item));

        if (result == 'delete') {
          // handled by dialog return, but since we have trailing icon now, dialog might not need delete button?
          // Keeping it for consistency or standard behavior.
          onDelete();
        } else if (result is EstimateItemModel) {
          onUpdate(result);
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      visualDensity: VisualDensity.compact,
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
              ))
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

  late TextEditingController _priceCtrl;
  late String _currency;
  bool _showEmployer = false;

  @override
  void initState() {
    super.initState();
    _totalQtyCtrl =
        TextEditingController(text: widget.item.totalQuantity.toString());
    _empQtyCtrl =
        TextEditingController(text: widget.item.employerQuantity.toString());
    _priceCtrl = TextEditingController(
        text: widget.item.pricePerUnit?.toString() ?? '0');
    _currency = widget.item.currency;

    // Show if already has value or user expands it
    if (widget.item.employerQuantity > 0 && widget.item.itemType == 'work') {
      _showEmployer = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Редактирование: ${widget.item.name}"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                            }
                          });
                        },
                        tooltip: "Добавить объем работодателя",
                      )
                    : null,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            if (_showEmployer && widget.item.itemType == 'work') ...[
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
