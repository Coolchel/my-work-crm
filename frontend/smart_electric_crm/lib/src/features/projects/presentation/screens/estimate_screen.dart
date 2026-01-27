import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/features/catalog/data/catalog_repository.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/estimate_item_model.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/stage_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_providers.dart'; // Import for invalidation and repository

/// Custom formatter: replaces commas with dots, limits to 2 decimal places, no negatives
class _DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Replace comma with dot
    String text = newValue.text.replaceAll(',', '.');

    // Only allow digits and one dot
    text = text.replaceAll(RegExp(r'[^0-9.]'), '');

    // Ensure only one dot
    final parts = text.split('.');
    if (parts.length > 2) {
      text = '${parts[0]}.${parts.sublist(1).join('')}';
    }

    // Limit to 2 decimal places
    if (parts.length == 2 && parts[1].length > 2) {
      text = '${parts[0]}.${parts[1].substring(0, 2)}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Simple marquee widget for long titles - constrains width and scrolls text
class _MarqueeText extends StatefulWidget {
  final String text;
  final double maxWidth;
  const _MarqueeText({required this.text, this.maxWidth = 250});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> {
  late ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
  }

  void _startScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;

        if (currentScroll >= maxScroll) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(currentScroll + 1.5);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.maxWidth,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            Text(
              widget.text,
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 1,
            ),
            const SizedBox(width: 50), // Gap before restart
          ],
        ),
      ),
    );
  }
}

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
                      _EstimateTab(
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

                final quantities = await showDialog<Map<String, dynamic>>(
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
                    'price_per_unit': quantities['price'],
                    'currency': quantities['currency'],
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
  // Timer? _debounce;
  bool _saving = false;
  String? _lastSavedValue;
  bool _hasUnsavedChanges = false;

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
      // Parent sent new data - sync
      if (widget.note != _lastSavedValue) {
        _noteCtrl.text = widget.note;
        _lastSavedValue = widget.note;
        _hasUnsavedChanges = false;
      }
    }
  }

  @override
  void dispose() {
    // _debounce?.cancel(); // Removed
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() => _saving = true);
    try {
      await widget.onSaveNote(_noteCtrl.text);
      if (mounted) {
        setState(() {
          _lastSavedValue = _noteCtrl.text;
          _hasUnsavedChanges = false;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onNoteChanged(String value) {
    setState(() {
      _hasUnsavedChanges = value != _lastSavedValue;
    });
  }

  // Color theming based on tab type
  bool get _isWorkTab => widget.title == "Работы";
  Color get _primaryColor => _isWorkTab ? Colors.green : Colors.blue;
  Color get _primaryColorLight =>
      _isWorkTab ? Colors.green.shade50 : Colors.blue.shade50;

  @override
  Widget build(BuildContext context) {
    // Calculate all totals
    double totalUsd = 0;
    double totalByn = 0;
    double employerUsd = 0;
    double employerByn = 0;

    for (var i in widget.items) {
      final clientAmount = i.clientAmount ?? 0;
      final employerAmount = i.employerAmount ?? 0;

      if (i.currency == 'USD') {
        totalUsd += clientAmount;
        employerUsd += employerAmount;
      } else {
        totalByn += clientAmount;
        employerByn += employerAmount;
      }
    }

    // Our share = total - employer
    final ourUsd = totalUsd - employerUsd;
    final ourByn = totalByn - employerByn;

    // Group items by category
    final Map<String, List<EstimateItemModel>> groupedItems = {};
    for (var item in widget.items) {
      final category = item.categoryName ?? 'Разное';
      if (!groupedItems.containsKey(category)) {
        groupedItems[category] = [];
      }
      groupedItems[category]!.add(item);
    }

    // Sort categories: specific ones first, 'Разное' last
    final sortedCategories = groupedItems.keys.toList()..sort();
    if (sortedCategories.contains('Разное')) {
      sortedCategories.remove('Разное');
      sortedCategories.add('Разное');
    }

    return CustomScrollView(
      primary: false,
      slivers: [
        // Items list grouped
        if (widget.items.isEmpty)
          const SliverToBoxAdapter(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: Text("Нет позиций",
                          style: TextStyle(color: Colors.grey)))))
        else
          for (var category in sortedCategories) ...[
            SliverToBoxAdapter(
              child: _GroupHeader(title: category, color: _primaryColor),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = groupedItems[category]![index];
                    return _EstimateListTile(
                      item: item,
                      onUpdate: widget.onUpdate,
                      onDelete: () => widget.onDelete(item),
                      primaryColor: _primaryColor,
                    );
                  },
                  childCount: groupedItems[category]!.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
          ],

        // Total Section - Detailed Dashboard
        SliverToBoxAdapter(
          child: _TotalDashboard(
            totalUsd: totalUsd,
            totalByn: totalByn,
            employerUsd: employerUsd,
            employerByn: employerByn,
            ourUsd: ourUsd,
            ourByn: ourByn,
            primaryColor: _primaryColor,
            primaryColorLight: _primaryColorLight,
            isWorkTab: _isWorkTab,
          ),
        ),

        // Notes Section - at the bottom
        SliverToBoxAdapter(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.sticky_note_2_outlined,
                      size: 14, color: _primaryColor.withOpacity(0.8)),
                  const SizedBox(width: 6),
                  Text("Заметки",
                      style: TextStyle(
                          fontSize: 12,
                          color: _primaryColor,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteCtrl,
                minLines: 2,
                maxLines: null,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide:
                        BorderSide(color: _primaryColor.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide:
                        BorderSide(color: _primaryColor.withOpacity(0.5)),
                  ),
                  hintText: "Дополнительная информация...",
                  hintStyle:
                      TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  suffixIcon: _saving
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          onPressed: _hasUnsavedChanges ? _saveNote : null,
                          icon: Icon(
                            _hasUnsavedChanges
                                ? Icons.save_as
                                : Icons.check_circle_outline,
                            color: _primaryColor
                                .withOpacity(_hasUnsavedChanges ? 1.0 : 0.6),
                          ),
                          tooltip: "Сохранить заметку",
                        ),
                ),
                onChanged: _onNoteChanged,
              ),
            ],
          ),
        )),

        // Extra padding at bottom
        const SliverPadding(padding: EdgeInsets.only(bottom: 8)),
      ],
    );
  }
}

// Comprehensive dashboard for summary totals
class _TotalDashboard extends StatelessWidget {
  final double totalUsd;
  final double totalByn;
  final double employerUsd;
  final double employerByn;
  final double ourUsd;
  final double ourByn;
  final Color primaryColor;
  final Color primaryColorLight;
  final bool isWorkTab;

  const _TotalDashboard({
    required this.totalUsd,
    required this.totalByn,
    required this.employerUsd,
    required this.employerByn,
    required this.ourUsd,
    required this.ourByn,
    required this.primaryColor,
    required this.primaryColorLight,
    required this.isWorkTab,
  });

  @override
  Widget build(BuildContext context) {
    if (totalUsd == 0 && totalByn == 0) return const SizedBox.shrink();

    final hasEmployer = employerUsd > 0 || employerByn > 0;
    final hasUsd = totalUsd > 0 || employerUsd > 0 || ourUsd > 0;
    final hasByn = totalByn > 0 || employerByn > 0 || ourByn > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      decoration: BoxDecoration(
        color: primaryColorLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          // Header with background
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isWorkTab
                      ? Icons.calculate_outlined
                      : Icons.summarize_outlined,
                  size: 16,
                  color: primaryColor.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                Text(
                  isWorkTab ? 'Итого (работа)' : 'Итого (материал)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor.withOpacity(0.9),
                  ),
                ),
                const Spacer(),
                if (hasUsd) _label('USD (\$)', primaryColor),
                if (hasUsd && hasByn) const SizedBox(width: 15),
                if (hasByn) _label('BYN (р)', Colors.deepPurple),
              ],
            ),
          ),
          // Table Content
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _row('Всего', totalUsd, totalByn, primaryColor, isBold: true),
                if (hasEmployer) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  _row('Контрагент', employerUsd, employerByn, Colors.orange,
                      isBold: true),
                  const SizedBox(height: 6),
                  _row('Наши', ourUsd, ourByn, Colors.green, isBold: true),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, Color color) {
    return SizedBox(
      width: 65,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _row(String label, double usd, double byn, Color color,
      {bool isBold = false}) {
    final hasUsd = totalUsd > 0 || employerUsd > 0 || ourUsd > 0;
    final hasByn = totalByn > 0 || employerByn > 0 || ourByn > 0;

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? color : Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        if (hasUsd) _amount(usd, color, isBold, show: usd > 0),
        if (hasUsd && hasByn) const SizedBox(width: 15),
        if (hasByn)
          _amount(
              byn, label == 'Контрагент' ? color : Colors.deepPurple, isBold,
              show: byn > 0),
      ],
    );
  }

  Widget _amount(double value, Color color, bool isBold, {required bool show}) {
    return SizedBox(
      width: 65,
      child: show
          ? Text(
              value.toStringAsFixed(0),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: isBold ? color : color.withOpacity(0.8),
              ),
            )
          : const Text('—',
              textAlign: TextAlign.right, style: TextStyle(color: Colors.grey)),
    );
  }
}

class _EstimateListTile extends StatelessWidget {
  final EstimateItemModel item;
  final Function(EstimateItemModel) onUpdate;
  final VoidCallback onDelete;
  final Color primaryColor;

  const _EstimateListTile(
      {Key? key,
      required this.item,
      required this.onUpdate,
      required this.onDelete,
      required this.primaryColor})
      : super(key: key);

  IconData get _icon =>
      item.itemType == 'work' ? Icons.engineering : Icons.inventory_2_outlined;

  @override
  Widget build(BuildContext context) {
    final isUsd = item.currency == 'USD';
    final currencySymbol = isUsd ? '\$' : 'р';
    final clientAmount = item.clientAmount ?? 0;
    final employerAmount = item.employerAmount ?? 0;
    final myAmount = item.myAmount ?? 0;
    final hasEmployer = employerAmount > 0;

    // Amount badge colors based on currency
    Color amountBgColor;
    Color amountTextColor;
    if (isUsd) {
      amountBgColor = primaryColor.withOpacity(0.1);
      amountTextColor = primaryColor;
    } else {
      // BYN - purple theme
      amountBgColor = Colors.deepPurple.shade50;
      amountTextColor = Colors.deepPurple.shade600;
    }

    return InkWell(
      onTap: () async {
        final result = await showDialog<dynamic>(
            context: context, builder: (_) => _EditItemDialog(item: item));

        if (result == 'delete') {
          onDelete();
        } else if (result is EstimateItemModel) {
          onUpdate(result);
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            // Leading: Colored circular icon (uses primaryColor)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, size: 16, color: primaryColor),
            ),
            const SizedBox(width: 10),

            // Middle: Name + compact info + Шеф/Наши badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  Text(
                    item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13, height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Compact stats row + Шеф/Наши badges
                  Row(
                    children: [
                      Text(
                        '${item.totalQuantity.toStringAsFixed(2).replaceAll(RegExp(r"\.?0+$"), "")} ${item.unit} × ${item.pricePerUnit?.toStringAsFixed(2).replaceAll(RegExp(r"\.?0+$"), "") ?? "0"}$currencySymbol',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                      if (hasEmployer) ...[
                        const SizedBox(width: 6),
                        // Шеф mini badge (horizontal)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Контрагент ${employerAmount.toStringAsFixed(2).replaceAll(RegExp(r"\.?0+$"), "")}$currencySymbol',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange.shade600),
                          ),
                        ),
                        const SizedBox(width: 3),
                        // Наши mini badge (horizontal) - purple when BYN
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: isUsd
                                ? primaryColor.withOpacity(0.1)
                                : Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Наши ${myAmount.toStringAsFixed(2).replaceAll(RegExp(r"\.?0+$"), "")}$currencySymbol',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: isUsd
                                    ? primaryColor
                                    : Colors.deepPurple.shade500),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Trailing: Main amount + delete
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main amount badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: amountBgColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '${clientAmount.toStringAsFixed(2).replaceAll(RegExp(r"\.?0+$"), "")}$currencySymbol',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: amountTextColor),
                  ),
                ),
                const SizedBox(width: 4),
                // Delete button
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    icon: Icon(Icons.close,
                        size: 14, color: Colors.grey.shade400),
                    padding: EdgeInsets.zero,
                    onPressed: onDelete,
                    tooltip: "Удалить",
                  ),
                ),
              ],
            ),
          ],
        ),
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

    String formatNum(double val) {
      if (val == val.toInt()) return val.toInt().toString();
      final str = val.toStringAsFixed(2);
      if (str.endsWith('.00')) return str.substring(0, str.length - 3);
      if (str.endsWith('0')) return str.substring(0, str.length - 1);
      return str;
    }

    _totalQtyCtrl =
        TextEditingController(text: formatNum(widget.item.totalQuantity));
    _empQtyCtrl =
        TextEditingController(text: formatNum(widget.item.employerQuantity));
    _myQtyCtrl = TextEditingController(
        text: formatNum(
            widget.item.totalQuantity - widget.item.employerQuantity));

    _priceCtrl =
        TextEditingController(text: formatNum(widget.item.pricePerUnit ?? 0));

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

      String formatNum(double val) {
        if (val < 0) val = 0; // No negative values
        if (val == val.toInt()) return val.toInt().toString();
        final str = val.toStringAsFixed(2);
        if (str.endsWith('.00')) return str.substring(0, str.length - 3);
        if (str.endsWith('0')) return str.substring(0, str.length - 1);
        return str;
      }

      if (source == 'total') {
        _myQtyCtrl.text = formatNum(total - emp);
      } else if (source == 'my') {
        _totalQtyCtrl.text = formatNum(my + emp);
      } else if (source == 'emp') {
        _myQtyCtrl.text = formatNum(total - emp);
      }
    } finally {
      _isUpdating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNewManual = widget.item.id == 0;
    final isWork = widget.item.itemType == 'work';
    final themeColor = isWork ? Colors.green : Colors.blue;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme:
            Theme.of(context).colorScheme.copyWith(primary: themeColor),
      ),
      child: AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        title: isNewManual
            ? const Center(child: Text("Новая позиция"))
            : Center(
                child: widget.item.name.length > 25
                    ? _MarqueeText(text: widget.item.name)
                    : Text(widget.item.name),
              ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isNewManual || widget.item.name.isEmpty) ...[
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: "Название",
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    hintText: isWork ? "Штроба" : "Кабель",
                  ),
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
                  labelText: "Общий объем",
                  suffixIcon: isWork
                      ? IconButton(
                          icon: Icon(Icons.person_add_alt,
                              color: _showEmployer ? themeColor : Colors.grey),
                          onPressed: () {
                            setState(() {
                              _showEmployer = !_showEmployer;
                              if (!_showEmployer) {
                                _empQtyCtrl.text = '0';
                                _calculate('emp');
                              } else {
                                if (_empQtyCtrl.text.isEmpty ||
                                    _empQtyCtrl.text == '0.0') {
                                  _empQtyCtrl.text = '0';
                                }
                              }
                            });
                          },
                          tooltip: "Показать калькулятор",
                        )
                      : null,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_DecimalInputFormatter()],
              ),
              if (widget.item.itemType == 'work' && _showEmployer) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _myQtyCtrl,
                        decoration: const InputDecoration(labelText: "Мы"),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [_DecimalInputFormatter()],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _empQtyCtrl,
                        decoration:
                            const InputDecoration(labelText: "Контрагент"),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [_DecimalInputFormatter()],
                      ),
                    ),
                  ],
                ),
              ] else if (_showEmployer) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _empQtyCtrl,
                  decoration: const InputDecoration(labelText: "Контрагент"),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [_DecimalInputFormatter()],
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
                    inputFormatters: [_DecimalInputFormatter()],
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'USD', label: Text('USD')),
                  ButtonSegment(value: 'BYN', label: Text('BYN')),
                ],
                selected: {_currency},
                onSelectionChanged: (val) =>
                    setState(() => _currency = val.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return themeColor.withOpacity(0.15);
                    }
                    return null;
                  }),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
              child: const Text("Отмена")),
          if (!isNewManual)
            TextButton(
                onPressed: () => Navigator.pop(context, 'delete'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("Удалить")),
          FilledButton(
            onPressed: _save,
            child: Text(isNewManual ? "Добавить" : "Изменить"),
          ),
        ],
      ),
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
              "Ошибка: Доля контрагента не может быть больше общего объема!")));
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
  late TextEditingController _myCtrl;
  late TextEditingController _priceCtrl;
  late String _currency;
  bool _showEmployer = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _totalCtrl = TextEditingController(text: '1');
    _empCtrl = TextEditingController(text: '0');
    _myCtrl = TextEditingController(text: '1');
    _priceCtrl = TextEditingController(
        text: widget.item.defaultPrice
                ?.toStringAsFixed(2)
                .replaceAll(RegExp(r'\.?0+$'), '') ??
            '0');
    _currency = 'USD';

    if (widget.itemType == 'work') {
      _setupListeners();
    }
  }

  void _setupListeners() {
    _totalCtrl.addListener(() {
      if (_isUpdating) return;
      _calculate('total');
    });
    _myCtrl.addListener(() {
      if (_isUpdating) return;
      _calculate('my');
    });
    _empCtrl.addListener(() {
      if (_isUpdating) return;
      _calculate('emp');
    });
  }

  void _calculate(String source) {
    if (_isUpdating) return;
    _isUpdating = true;
    try {
      final total = double.tryParse(_totalCtrl.text.replaceAll(',', '.')) ?? 0;
      final my = double.tryParse(_myCtrl.text.replaceAll(',', '.')) ?? 0;
      final emp = double.tryParse(_empCtrl.text.replaceAll(',', '.')) ?? 0;

      String formatNum(double val) {
        if (val < 0) val = 0;
        if (val == val.toInt()) return val.toInt().toString();
        final str = val.toStringAsFixed(2);
        if (str.endsWith('.00')) return str.substring(0, str.length - 3);
        if (str.endsWith('0')) return str.substring(0, str.length - 1);
        return str;
      }

      if (source == 'total') {
        _myCtrl.text = formatNum(total - emp);
      } else if (source == 'my') {
        _totalCtrl.text = formatNum(my + emp);
      } else if (source == 'emp') {
        _myCtrl.text = formatNum(total - emp);
      }
    } finally {
      _isUpdating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWork = widget.itemType == 'work';
    final themeColor = isWork ? Colors.green : Colors.blue;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme:
            Theme.of(context).colorScheme.copyWith(primary: themeColor),
      ),
      child: AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
          child: widget.item.name.length > 25
              ? _MarqueeText(text: widget.item.name)
              : Text(widget.item.name),
        ),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: _totalCtrl,
                decoration: InputDecoration(
                  labelText: "Общий объем",
                  suffixIcon: isWork
                      ? IconButton(
                          icon: Icon(Icons.person_add_alt,
                              color: _showEmployer ? themeColor : Colors.grey),
                          onPressed: () {
                            setState(() {
                              _showEmployer = !_showEmployer;
                              if (!_showEmployer) {
                                _empCtrl.text = '0';
                                _calculate('emp');
                              }
                            });
                          },
                          tooltip: "Показать калькулятор",
                        )
                      : null,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_DecimalInputFormatter()]),
            if (_showEmployer && isWork) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _myCtrl,
                      decoration: const InputDecoration(labelText: "Мы"),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [_DecimalInputFormatter()],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _empCtrl,
                      decoration:
                          const InputDecoration(labelText: "Контрагент"),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [_DecimalInputFormatter()],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            TextField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: "Цена"),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_DecimalInputFormatter()]),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'USD', label: Text('USD')),
                ButtonSegment(value: 'BYN', label: Text('BYN')),
              ],
              selected: {_currency},
              onSelectionChanged: (val) =>
                  setState(() => _currency = val.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return themeColor.withOpacity(0.15);
                  }
                  return null;
                }),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
              child: const Text("Отмена")),
          FilledButton(
              onPressed: () {
                final t =
                    double.tryParse(_totalCtrl.text.replaceAll(',', '.')) ?? 0;
                final e =
                    double.tryParse(_empCtrl.text.replaceAll(',', '.')) ?? 0;
                final p =
                    double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;

                if (e > t) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text("Ошибка: Доля контрагента > Общего объема")));
                  return;
                }

                Navigator.pop(context, {
                  'total': t,
                  'employer': e,
                  'price': p,
                  'currency': _currency,
                });
              },
              child: const Text("Добавить"))
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _GroupHeader({
    Key? key,
    required this.title,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: color.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: color.withOpacity(0.1),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}
