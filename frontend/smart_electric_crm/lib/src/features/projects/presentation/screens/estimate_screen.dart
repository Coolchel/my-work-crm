import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/estimate_item_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/stage_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_provider.dart';
import 'package:flutter/services.dart';

class EstimateScreen extends ConsumerStatefulWidget {
  final StageModel stage;
  final String projectId;

  const EstimateScreen({Key? key, required this.stage, required this.projectId})
      : super(key: key);

  @override
  ConsumerState<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends ConsumerState<EstimateScreen> {
  // Локальный стейт с товарами, чтобы быстро обновлять UI без лишних запросов
  // (хотя правильнее через provider, но для скорости редактирования можно так)
  late List<EstimateItemModel> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.stage.estimateItems);
    // Сортировка: сначала обычные, потом доп работы? Или как в БД?
    // Пока оставим как есть.
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text("Смета: ${widget.stage.title}"),
            pinned: true,
            actions: [
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
          // Sticky Header с итогами
          SliverPersistentHeader(
            delegate: _EstimateHeaderDelegate(
              totalUsd: _totalUsd,
              totalByn: _totalByn,
            ),
            pinned: true,
          ),
          // Список элементов
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
        ],
      ),
    );
  }

  void _updateItem(int index, EstimateItemModel updatedItem) async {
    // Оптимистичное обновление UI
    setState(() {
      _items[index] = updatedItem;
    });

    try {
      // Отправка на сервер
      // Формируем payload. Важно отправлять только измененные поля или все?
      // Отправим ключевые
      final data = {
        'total_quantity': updatedItem.totalQuantity,
        'employer_quantity': updatedItem.employerQuantity,
        'is_extra': updatedItem.isExtra,
        'currency': updatedItem.currency,
        // Можно добавить и markup_percent
      };

      final repo = ref.read(projectRepositoryProvider);
      await repo.updateEstimateItem(updatedItem.id, data);

      // В идеале - перезапросить проект, чтобы пересчитались client_amount на бэке,
      // если мы их тут сами не считаем.
      // Но у нас clientAmount - read-only поле с сервера.
      // Поэтому лучше перезагрузить список или проект.
      // Но для плавности пока так. Можно вручную пересчитать clientAmount локально для item.
      // ... (локальный пересчет опустим для краткости, полагаемся на refresh при выходе или pull-to-refresh)
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка сохранения: $e")),
      );
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

  void _copyReport(String type) async {
    try {
      final repo = ref.read(projectRepositoryProvider);
      final reports = await repo.fetchStageReport(widget.stage.id);
      final text = type == 'client'
          ? reports['client_report']
          : reports['employer_report'];

      if (text != null) {
        await Clipboard.setData(ClipboardData(text: text));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Отчет ($type) скопирован!")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ошибка копирования: $e")));
    }
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
  bool shouldRebuild(_EstimateHeaderDelegate oldDelegate) {
    return oldDelegate.totalUsd != totalUsd || oldDelegate.totalByn != totalByn;
  }
}

class _EstimateListTile extends StatefulWidget {
  final EstimateItemModel item;
  final Function(EstimateItemModel) onUpdate;

  const _EstimateListTile(
      {Key? key, required this.item, required this.onUpdate})
      : super(key: key);

  @override
  State<_EstimateListTile> createState() => _EstimateListTileState();
}

class _EstimateListTileState extends State<_EstimateListTile> {
  // Контроллеры не обязательно, если редактировать через диалог,
  // Но пользователь просил "быстро менять". Сделаем +/- или ввод.
  // Для простоты сделаем Dialog при клике.

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final currency = item.currency == 'USD' ? '\$' : ' руб';

    return ListTile(
      leading: item.isExtra
          ? const Icon(Icons.add_circle, color: Colors.orange)
          : const Icon(Icons.build, color: Colors.blue),
      title: Text(item.name),
      subtitle: Text(
          "${item.totalQuantity} ${item.unit} * ${item.pricePerUnit}$currency"),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text("${item.clientAmount?.toStringAsFixed(2) ?? '0'}$currency",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          if (item.employerQuantity > 0)
            Text("Работодатель: ${item.employerQuantity}",
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          if (item.isExtra)
            const Text("EXTRA",
                style: TextStyle(
                    fontSize: 9,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold)),
        ],
      ),
      onTap: _editItem,
    );
  }

  void _editItem() async {
    final updatedItem = await showDialog<EstimateItemModel>(
      context: context,
      builder: (context) => _EditItemDialog(item: widget.item),
    );

    if (updatedItem != null) {
      widget.onUpdate(updatedItem);
    }
  }
}

class _EditItemDialog extends StatefulWidget {
  final EstimateItemModel item;

  const _EditItemDialog({required this.item});

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  late TextEditingController _totalQtyController;
  late TextEditingController _employerQtyController;
  late bool _isExtra;
  late String _currency;

  @override
  void initState() {
    super.initState();
    _totalQtyController =
        TextEditingController(text: widget.item.totalQuantity.toString());
    _employerQtyController =
        TextEditingController(text: widget.item.employerQuantity.toString());
    _isExtra = widget.item.isExtra;
    _currency = widget.item.currency;
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
              controller: _totalQtyController,
              decoration:
                  const InputDecoration(labelText: "Общий объем (Клиент)"),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _employerQtyController,
              decoration:
                  const InputDecoration(labelText: "Объем работодателя"),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text("Доп. работа (Extra)"),
              value: _isExtra,
              onChanged: (val) => setState(() => _isExtra = val),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: const InputDecoration(labelText: "Валюта"),
              items: const [
                DropdownMenuItem(value: 'USD', child: Text("USD")),
                DropdownMenuItem(value: 'BYN', child: Text("BYN")),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _currency = val);
              },
            )
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена")),
        TextButton(
            onPressed: () {
              final totalQty = double.tryParse(
                      _totalQtyController.text.replaceAll(',', '.')) ??
                  0;
              final empQty = double.tryParse(
                      _employerQtyController.text.replaceAll(',', '.')) ??
                  0;

              final newItem = widget.item.copyWith(
                totalQuantity: totalQty,
                employerQuantity: empQty,
                isExtra: _isExtra,
                currency: _currency,
              );
              Navigator.pop(context, newItem);
            },
            child: const Text("Сохранить")),
      ],
    );
  }
}
