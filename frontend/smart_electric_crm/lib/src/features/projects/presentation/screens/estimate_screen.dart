import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/features/catalog/data/catalog_repository.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/estimate_item_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/estimate_template_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/stage_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_provider.dart';

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
  }

  // Расчет итогов для Sticky Header
  double get _totalUsd => _items
      .where((i) => i.currency == 'USD')
      .fold(0.0, (sum, i) => sum + (i.clientAmount ?? 0));

  double get _totalByn => _items
      .where((i) => i.currency == 'BYN')
      .fold(0.0, (sum, i) => sum + (i.clientAmount ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text("Смета: ${widget.stage.title}"),
            pinned: true,
            actions: [
              IconButton(
                  onPressed: _showTemplatesDialog,
                  icon: const Icon(Icons.file_copy_outlined),
                  tooltip: "Шаблоны"),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'client') _copyReport('client');
                  if (value == 'employer') _copyReport('employer');
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'client',
                      child: Text("Скопировать отчет клиента")),
                  const PopupMenuItem(
                      value: 'employer',
                      child: Text("Скопировать отчет работодателя")),
                ],
                icon: const Icon(Icons.copy),
              ),
              IconButton(
                  onPressed: _showReport, icon: const Icon(Icons.description)),
            ],
          ),
          SliverPersistentHeader(
            delegate: _EstimateHeaderDelegate(
              totalUsd: _totalUsd,
              totalByn: _totalByn,
            ),
            pinned: true,
          ),
          if (_items.isEmpty)
            const SliverFillRemaining(
                child: Center(child: Text("Смета пуста"))),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _items[index];
                return _EstimateListTile(
                  item: item,
                  onUpdate: (updatedItem) => _updateItem(index, updatedItem),
                );
              },
              childCount: _items.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  // --- Logic ---

  Future<void> _refresh() async {
    // В реальном приложении лучше использовать stream provider,
    // но здесь мы просто обновим список при возврате на экран проекта.
    // Пока оставим так.
  }

  void _updateItem(int index, EstimateItemModel updatedItem) async {
    setState(() => _items[index] = updatedItem);
    try {
      final data = {
        'total_quantity': updatedItem.totalQuantity,
        'employer_quantity': updatedItem.employerQuantity,
        'is_extra': updatedItem.isExtra,
        'currency': updatedItem.currency,
        'price_per_unit': updatedItem.pricePerUnit,
      };
      final repo = ref.read(projectRepositoryProvider);
      await repo.updateEstimateItem(updatedItem.id, data);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка сохранения: $e")));
    }
  }

  void _showAddItemDialog() {
    showDialog(
        context: context,
        builder: (_) => _AddItemDialog(onAdd: (catalogItem) async {
              try {
                final repo = ref.read(projectRepositoryProvider);
                await repo.addEstimateItem({
                  'stage': widget.stage.id,
                  'catalog_item': catalogItem.id,
                  'total_quantity': 1, // Default
                  // Backend should handle defaults for price/name if sending catalog_item only?
                  // Or we send them explicitly. Let's rely on backend signal or send basic defaults.
                  // Based on backend imports, catalog_item triggers defaults unless overridden.
                });
                if (!mounted) return;
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Добавлено! Обновите экран.")));
                // TODO: Add to _items locally or refresh?
                // For now ask user to refresh or implement refresh logic
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Ошибка добавления: $e")));
              }
            }));
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Шаблон применен! Обновите экран.")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка применения: $e")));
    }
  }

  void _showReport() async {
    // (Same as before)
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

  void _copyReport(String type) async {
    // (Same as before)
    try {
      final repo = ref.read(projectRepositoryProvider);
      final reports = await repo.fetchStageReport(widget.stage.id);
      final text = type == 'client'
          ? reports['client_report']
          : reports['employer_report'];
      if (text != null) {
        await Clipboard.setData(ClipboardData(text: text));
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Отчет ($type) скопирован!")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка копирования: $e")));
    }
  }
}

// --- Delegates & Widgets ---

class _EstimateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double totalUsd;
  final double totalByn;

  _EstimateHeaderDelegate({required this.totalUsd, required this.totalByn});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      padding: const EdgeInsets.all(16),
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

  const _EstimateListTile(
      {Key? key, required this.item, required this.onUpdate})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currency = item.currency == 'USD' ? '\$' : ' руб';

    return ListTile(
      leading: item.isExtra
          ? const Icon(Icons.add_circle, color: Colors.orange)
          : const Icon(Icons.build, color: Colors.blue),
      title: Text(item.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              "${item.totalQuantity} ${item.unit} * ${item.pricePerUnit}$currency = ${(item.clientAmount ?? 0).toStringAsFixed(2)}$currency"),
          if (item.employerQuantity > 0)
            Text(
                "Работодатель: ${item.employerQuantity} ${item.unit} (${(item.employerAmount ?? 0).toStringAsFixed(2)}$currency)",
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: item.isExtra
          ? const Text("EXTRA",
              style:
                  TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))
          : null,
      onTap: () async {
        final updated = await showModalBottomSheet<EstimateItemModel>(
            context: context,
            isScrollControlled: true,
            builder: (_) => _EditItemSheet(item: item));
        if (updated != null) onUpdate(updated);
      },
    );
  }
}

class _AddItemDialog extends ConsumerStatefulWidget {
  final Function(CatalogItem) onAdd;
  const _AddItemDialog({required this.onAdd});

  @override
  ConsumerState<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends ConsumerState<_AddItemDialog> {
  final _searchController = TextEditingController();
  List<CatalogItem> _results = [];
  bool _loading = false;

  void _search(String query) async {
    if (query.isEmpty) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(catalogRepositoryProvider);
      final items = await repo.searchItems(query);
      setState(() => _results = items);
    } catch (e) {
      // ignore error
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                  decoration: InputDecoration(
                    labelText: "Поиск (напр. кабель)",
                    suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _search(_searchController.text)),
                  ),
                  onSubmitted: _search,
                ),
              ),
              Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (ctx, i) {
                            final item = _results[i];
                            return ListTile(
                              title: Text(item.name),
                              subtitle: Text(
                                  "${item.defaultPrice} ${item.defaultCurrency}"),
                              trailing: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => widget.onAdd(item),
                              ),
                            );
                          },
                        ))
            ])));
  }
}

class _EditItemSheet extends StatefulWidget {
  final EstimateItemModel item;
  const _EditItemSheet({required this.item});

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  late TextEditingController _totalQtyCtrl;
  late TextEditingController _empQtyCtrl;
  late TextEditingController _priceCtrl;
  late bool _isExtra;
  late String _currency;

  @override
  void initState() {
    super.initState();
    _totalQtyCtrl =
        TextEditingController(text: widget.item.totalQuantity.toString());
    _empQtyCtrl =
        TextEditingController(text: widget.item.employerQuantity.toString());
    _priceCtrl = TextEditingController(
        text: widget.item.pricePerUnit?.toString() ?? '0');
    _isExtra = widget.item.isExtra;
    _currency = widget.item.currency;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Редактирование: ${widget.item.name}",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _totalQtyCtrl,
              decoration: const InputDecoration(labelText: "Общий объем"),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _empQtyCtrl,
              decoration:
                  const InputDecoration(labelText: "Объем работодателя"),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            _priceRow(),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text("Доп. работа (Extra)"),
              value: _isExtra,
              onChanged: (val) => setState(() => _isExtra = val),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: const Text("Сохранить"),
            ),
            const SizedBox(height: 16),
          ],
        ));
  }

  Widget _priceRow() {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _priceCtrl,
          decoration: const InputDecoration(labelText: "Цена за ед."),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ),
      const SizedBox(width: 16),
      DropdownButton<String>(
          value: _currency,
          items: const [
            DropdownMenuItem(value: 'USD', child: Text('USD')),
            DropdownMenuItem(value: 'BYN', child: Text('BYN')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _currency = val);
          })
    ]);
  }

  void _save() {
    final totalFn =
        double.tryParse(_totalQtyCtrl.text.replaceAll(',', '.')) ?? 0;
    final empFn = double.tryParse(_empQtyCtrl.text.replaceAll(',', '.')) ?? 0;
    final priceFn = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;

    Navigator.pop(
        context,
        widget.item.copyWith(
          totalQuantity: totalFn,
          employerQuantity: empFn,
          pricePerUnit: priceFn,
          isExtra: _isExtra,
          currency: _currency,
        ));
  }
}
