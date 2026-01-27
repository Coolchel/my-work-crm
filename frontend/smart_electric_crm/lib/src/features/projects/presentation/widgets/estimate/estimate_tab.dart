import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/providers/project_providers.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/estimate_item_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/utils/decimal_input_formatter.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/estimate/estimate_list_tile.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/estimate/group_header.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/estimate/total_dashboard.dart';

/// Tab widget for displaying estimate items (Materials or Works)
class EstimateTab extends ConsumerStatefulWidget {
  final List<EstimateItemModel> items;
  final Function(EstimateItemModel) onUpdate;
  final Function(EstimateItemModel) onDelete;
  final String title;

  // Note props
  final String note;
  final Future<void> Function(String) onSaveNote;

  // Markup props
  final double markupPercent;
  final ValueChanged<double>? onMarkupChanged;

  const EstimateTab({
    super.key,
    required this.items,
    required this.onUpdate,
    required this.onDelete,
    required this.title,
    required this.note,
    required this.onSaveNote,
    this.markupPercent = 0.0,
    this.onMarkupChanged,
  });

  @override
  ConsumerState<EstimateTab> createState() => _EstimateTabState();
}

class _EstimateTabState extends ConsumerState<EstimateTab> {
  late TextEditingController _noteCtrl;
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
  void didUpdateWidget(EstimateTab oldWidget) {
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

  // Helper to get items with markup applied
  List<EstimateItemModel> get _displayedItems {
    if (!_isWorkTab && widget.markupPercent > 0) {
      return widget.items.map((item) {
        final boostedPrice =
            (item.pricePerUnit ?? 0) * (1 + (widget.markupPercent / 100));
        // Recalculate clientAmount with boosted price
        final newClientAmount = item.totalQuantity * boostedPrice;
        return item.copyWith(
            pricePerUnit: boostedPrice, clientAmount: newClientAmount);
      }).toList();
    }
    return widget.items;
  }

  @override
  void dispose() {
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

  Widget _buildMarkupControl() {
    final hasMarkup = widget.markupPercent > 0;
    // Match TotalDashboard styling when no markup
    final bgColor =
        hasMarkup ? Colors.blue.shade50 : _primaryColorLight.withOpacity(0.5);
    final borderColor =
        hasMarkup ? Colors.orange.shade300 : _primaryColor.withOpacity(0.12);
    final iconColor =
        hasMarkup ? Colors.orange.shade800 : _primaryColor.withOpacity(0.8);
    final textColor =
        hasMarkup ? Colors.orange.shade900 : _primaryColor.withOpacity(0.9);
    final textWeight = hasMarkup ? FontWeight.bold : FontWeight.w500;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: EdgeInsets.zero,
          leading: Icon(Icons.trending_up, color: iconColor, size: 20),
          title: Row(
            children: [
              Text(
                "Наценка: ",
                style: TextStyle(
                    color: textColor, fontWeight: textWeight, fontSize: 14),
              ),
              Text(
                "${widget.markupPercent.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')}%",
                style: TextStyle(
                    color: textColor, fontWeight: textWeight, fontSize: 14),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.orange,
                        inactiveTrackColor: Colors.orange.shade100,
                        thumbColor: Colors.orange.shade800,
                        trackHeight: 4,
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 16),
                      ),
                      child: Slider(
                        value: widget.markupPercent,
                        min: 0,
                        max: 100,
                        divisions: 200,
                        label: "${widget.markupPercent.toStringAsFixed(1)}%",
                        onChanged: widget.onMarkupChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 65,
                    height: 32,
                    child: TextField(
                      controller: TextEditingController(
                          text: widget.markupPercent
                              .toStringAsFixed(2)
                              .replaceAll(RegExp(r'\.?0+$'), ''))
                        ..selection = TextSelection.collapsed(
                            offset: widget.markupPercent
                                .toStringAsFixed(2)
                                .replaceAll(RegExp(r'\.?0+$'), '')
                                .length),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [DecimalInputFormatter()],
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        border: OutlineInputBorder(),
                        suffixText: '%',
                        counterText: '',
                      ),
                      style: const TextStyle(fontSize: 13),
                      onSubmitted: (val) {
                        final parsed =
                            double.tryParse(val.replaceAll(',', '.')) ?? 0;
                        if (widget.onMarkupChanged != null) {
                          widget.onMarkupChanged!(parsed.clamp(0.0, 100.0));
                        }
                      },
                    ),
                  ),
                  if (widget.markupPercent != 0)
                    IconButton(
                      onPressed: () {
                        if (widget.onMarkupChanged != null) {
                          widget.onMarkupChanged!(0.0);
                        }
                      },
                      icon: Icon(Icons.refresh,
                          size: 18, color: Colors.orange.shade800),
                      tooltip: "Сброс",
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Color theming based on tab type
  bool get _isWorkTab => widget.title == "Работы";
  Color get _primaryColor => _isWorkTab ? Colors.green : Colors.blue;
  Color get _primaryColorLight =>
      _isWorkTab ? Colors.green.shade50 : Colors.blue.shade50;

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Displayed Items (Apply Markup if Materials)
    final displayedItems = _displayedItems;

    // 2. Calculate Totals based on DISPLAYED items
    double totalUsd = 0;
    double totalByn = 0;
    double employerUsd = 0;
    double employerByn = 0;

    for (var i in displayedItems) {
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

    // Group items by category (Using displayedItems)
    final Map<String, List<EstimateItemModel>> groupedItems = {};
    for (var item in displayedItems) {
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

    final showPrices = _isWorkTab ? true : ref.watch(showPricesProvider);

    return CustomScrollView(
      primary: false,
      slivers: [
        // Toggle for Hide Prices (Only in Materials tab)
        if (!_isWorkTab)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    showPrices ? "Цены отображаются" : "Цены скрыты",
                    style: TextStyle(
                      fontSize: 12,
                      color: showPrices ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: !showPrices,
                    onChanged: (val) {
                      ref.read(showPricesProvider.notifier).state = !val;
                    },
                    activeColor: Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  const Text("Скрыть цены",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
                ],
              ),
            ),
          ),

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
              child: GroupHeader(title: category, color: _primaryColor),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = groupedItems[category]![index];
                    return EstimateListTile(
                      item: item,
                      onUpdate: widget.onUpdate,
                      onDelete: () => widget.onDelete(item),
                      primaryColor: _primaryColor,
                      isMarkupActive: widget.markupPercent > 0,
                      hidePrices: !showPrices,
                    );
                  },
                  childCount: groupedItems[category]!.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
          ],

        // Total Section - Detailed Dashboard (Hidden if prices hidden)
        if (showPrices)
          SliverToBoxAdapter(
            child: TotalDashboard(
              totalUsd: totalUsd,
              totalByn: totalByn,
              employerUsd: employerUsd,
              employerByn: employerByn,
              ourUsd: ourUsd,
              ourByn: ourByn,
              primaryColor: _primaryColor,
              primaryColorLight: _primaryColorLight,
              isWorkTab: _isWorkTab,
              isMarkupActive: !_isWorkTab && widget.markupPercent > 0,
            ),
          ),

        // Markup Control (Spoiler style) - Hidden if prices hidden
        if (!_isWorkTab && showPrices)
          SliverToBoxAdapter(
            child: _buildMarkupControl(),
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
