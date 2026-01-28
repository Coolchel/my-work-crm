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

  Widget _buildViewModeToggleMinimal(bool showPrices) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildMinimalItem(
            "ПОДРОБНО",
            showPrices,
            () => ref.read(showPricesProvider.notifier).state = true,
          ),
          Container(
            height: 12,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.grey.shade300,
          ),
          _buildMinimalItem(
            "ТОЛЬКО КОЛ-ВО",
            !showPrices,
            () => ref.read(showPricesProvider.notifier).state = false,
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalItem(String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              color: isActive ? Colors.blue.shade800 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: isActive ? 12 : 0,
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeTogglePill(bool showPrices) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleItemPill(
                  "С ценами",
                  showPrices,
                  Icons.payments_outlined,
                  () => ref.read(showPricesProvider.notifier).state = true,
                ),
                _buildToggleItemPill(
                  "Без цен",
                  !showPrices,
                  Icons.visibility_off_outlined,
                  () => ref.read(showPricesProvider.notifier).state = false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItemPill(
      String label, bool isActive, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.blue.shade700 : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Colors.blue.shade900 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeToggleGlass(bool showPrices) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              // Semi-transparent background (Glassmorphic)
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGlassItem(
                  "Цены",
                  showPrices,
                  Icons.receipt_long_outlined,
                  () => ref.read(showPricesProvider.notifier).state = true,
                ),
                _buildGlassItem(
                  "Кол-во",
                  !showPrices,
                  Icons.unarchive_outlined,
                  () => ref.read(showPricesProvider.notifier).state = false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassItem(
      String label, bool isActive, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    Colors.blue.shade400,
                    Colors.blue.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.blue.shade600.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : Colors.blue.shade400,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeToggleSegmented(bool showPrices) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: true,
                label: Text('С ценами', style: TextStyle(fontSize: 11)),
                icon: Icon(Icons.payments_outlined, size: 14),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text('Без цен', style: TextStyle(fontSize: 11)),
                icon: Icon(Icons.visibility_off_outlined, size: 14),
              ),
            ],
            selected: {showPrices},
            onSelectionChanged: (newSelection) {
              ref.read(showPricesProvider.notifier).state = newSelection.first;
            },
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 12),
              ),
              // Theming to match Project/Materials blue
              side: MaterialStateProperty.all(
                BorderSide(color: Colors.blue.shade100),
              ),
              backgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.blue.shade50;
                }
                return Colors.transparent;
              }),
              foregroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.blue.shade900;
                }
                return Colors.blue.shade300;
              }),
            ),
          ),
        ],
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
            child: _buildViewModeToggleSegmented(showPrices),
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
