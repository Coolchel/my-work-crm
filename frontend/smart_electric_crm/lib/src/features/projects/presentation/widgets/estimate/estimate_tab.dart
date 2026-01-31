import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  final String remarks;
  final Future<void> Function(String) onSaveRemarks;

  // Markup props
  final double markupPercent;
  final ValueChanged<double>? onMarkupChanged;

  // Show Prices props
  final bool showPrices;
  final ValueChanged<bool>? onShowPricesChanged;
  final bool isDisabled;
  final VoidCallback? onDismissRequest;

  // Automation props
  final String? automationActionLabel;
  final VoidCallback? onAutomationAction;
  final bool isAutomationLoading;

  // Template props
  final VoidCallback? onTemplatesAction;
  final bool isTemplatesLoading;

  const EstimateTab({
    super.key,
    required this.items,
    required this.onUpdate,
    required this.onDelete,
    required this.title,
    required this.note,
    required this.onSaveNote,
    required this.remarks,
    required this.onSaveRemarks,
    this.markupPercent = 0.0,
    this.onMarkupChanged,
    this.showPrices = true,
    this.onShowPricesChanged,
    this.isDisabled = false,
    this.onDismissRequest,
    this.automationActionLabel,
    this.onAutomationAction,
    this.isAutomationLoading = false,
    this.onTemplatesAction,
    this.isTemplatesLoading = false,
  });

  @override
  ConsumerState<EstimateTab> createState() => _EstimateTabState();
}

class _EstimateTabState extends ConsumerState<EstimateTab> {
  late TextEditingController _noteCtrl;
  late TextEditingController _remarksCtrl;
  late TextEditingController _markupCtrl;
  late FocusNode _markupFocus;
  bool _savingNote = false;
  bool _savingRemarks = false;
  String? _lastSavedNote;
  String? _lastSavedRemarks;
  bool _hasUnsavedNote = false;
  bool _hasUnsavedRemarks = false;

  @override
  void initState() {
    super.initState();
    // debugPrint("📝 _EstimateTabState.initState: note='${widget.note}'");
    _noteCtrl = TextEditingController(text: widget.note);

    // Default text logic for Materials
    String initialRemarks = widget.remarks;
    if (!_isWorkTab && initialRemarks.trim().isEmpty) {
      initialRemarks = "Не учтен вводной кабель.";
      _hasUnsavedRemarks = true; // Mark as unsaved so user sees the save button
    }

    _remarksCtrl = TextEditingController(text: initialRemarks);
    _markupCtrl =
        TextEditingController(text: _formatMarkup(widget.markupPercent));
    _markupFocus = FocusNode();
    _markupFocus.addListener(_onMarkupFocusChange);
    _lastSavedNote = widget.note;
    // _lastSavedRemarks should remain as widget.remarks (empty) until saved.
    _lastSavedRemarks = widget.remarks;
  }

  @override
  void didUpdateWidget(EstimateTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.note != oldWidget.note) {
      if (widget.note != _lastSavedNote) {
        _noteCtrl.text = widget.note;
        _lastSavedNote = widget.note;
        _hasUnsavedNote = false;
      }
    }
    if (widget.remarks != oldWidget.remarks) {
      if (widget.remarks != _lastSavedRemarks) {
        _remarksCtrl.text = widget.remarks;
        _lastSavedRemarks = widget.remarks;
        _hasUnsavedRemarks = false;
      }
    }
    if (widget.markupPercent != oldWidget.markupPercent) {
      // Sync only if not focused to avoid fighting user input
      if (!_markupFocus.hasFocus) {
        final newText = _formatMarkup(widget.markupPercent);
        if (_markupCtrl.text != newText && newText != "0" && newText != "0.0") {
          _markupCtrl.text = newText;
        }
      }
    }
  }

  void _onMarkupFocusChange() {
    if (!_markupFocus.hasFocus) {
      // Create a submission when focus is lost
      _submitMarkup(_markupCtrl.text);
    }
  }

  void _submitMarkup(String val) {
    if (val.isEmpty) return;
    final parsed = double.tryParse(val.replaceAll(',', '.')) ?? 0;
    if (widget.onMarkupChanged != null) {
      // Prevent redundant updates if value works out to same
      if ((parsed - widget.markupPercent).abs() > 0.01) {
        final rounded = double.parse(parsed.toStringAsFixed(2));
        widget.onMarkupChanged!(rounded.clamp(0.0, 100.0));
      }
    }
  }

  String _formatMarkup(double val) {
    return val.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
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
    _remarksCtrl.dispose();
    _markupCtrl.dispose();
    _markupFocus.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() => _savingNote = true);
    try {
      await widget.onSaveNote(_noteCtrl.text);
      if (mounted) {
        setState(() {
          _lastSavedNote = _noteCtrl.text;
          _hasUnsavedNote = false;
        });
      }
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  Future<void> _saveRemarks() async {
    setState(() => _savingRemarks = true);
    try {
      await widget.onSaveRemarks(_remarksCtrl.text);
      if (mounted) {
        setState(() {
          _lastSavedRemarks = _remarksCtrl.text;
          _hasUnsavedRemarks = false;
        });
      }
    } finally {
      if (mounted) setState(() => _savingRemarks = false);
    }
  }

  void _onNoteChanged(String value) {
    setState(() {
      _hasUnsavedNote = value != _lastSavedNote;
    });
  }

  void _onRemarksChanged(String value) {
    setState(() {
      _hasUnsavedRemarks = value != _lastSavedRemarks;
    });
  }

  Widget? _buildNoteSuffix() {
    return _buildSuffix(
      saving: _savingNote,
      hasUnsaved: _hasUnsavedNote,
      onSave: widget.isDisabled ? null : _saveNote,
    );
  }

  Widget? _buildRemarksSuffix() {
    return _buildSuffix(
      saving: _savingRemarks,
      hasUnsaved: _hasUnsavedRemarks,
      onSave: widget.isDisabled ? null : _saveRemarks,
    );
  }

  Widget? _buildSuffix({
    required bool saving,
    required bool hasUnsaved,
    required VoidCallback? onSave,
  }) {
    if (saving) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (hasUnsaved) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: SizedBox(
          width: 24,
          height: 24,
          child: IconButton(
            onPressed: onSave,
            icon: Icon(Icons.save, color: _primaryColor, size: 20),
            padding: EdgeInsets.zero,
            tooltip: "Сохранить",
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ),
        ),
      );
    }
    return Icon(Icons.check_circle,
        color: _primaryColor.withOpacity(0.5), size: 18);
  }

  Widget _buildMarkupControl() {
    final hasMarkup = widget.markupPercent > 0;

    // Header Color: Very soft, almost white blue
    final headerColor = hasMarkup
        ? Colors.blue.shade50.withOpacity(0.3)
        : _primaryColorLight.withOpacity(0.5);

    // Body Color: Even paler blue
    final bodyColor =
        hasMarkup ? Colors.blue.shade50.withOpacity(0.15) : Colors.transparent;

    final borderColor =
        hasMarkup ? Colors.orange.shade300 : _primaryColor.withOpacity(0.12);
    final iconColor =
        hasMarkup ? Colors.orange.shade800 : _primaryColor.withOpacity(0.8);
    final textColor =
        hasMarkup ? Colors.orange.shade900 : _primaryColor.withOpacity(0.9);
    final textWeight = hasMarkup ? FontWeight.bold : FontWeight.w500;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          backgroundColor: headerColor,
          collapsedBackgroundColor: headerColor,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
                "${_formatMarkup(widget.markupPercent)}%",
                style: TextStyle(
                    color: textColor, fontWeight: textWeight, fontSize: 14),
              ),
            ],
          ),
          children: [
            Container(
              color: bodyColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.orange,
                        inactiveTrackColor: Colors.orange.shade100,
                        thumbColor: Colors.orange.shade800,
                        trackHeight: 4,
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 18),
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 7),
                      ),
                      child: Slider(
                        value: widget.markupPercent,
                        min: 0,
                        max: 100,
                        divisions: 200,
                        label: "${widget.markupPercent.toStringAsFixed(1)}%",
                        onChanged: (val) {
                          // Round to 2 decimal places to avoid "max 5 digits" backend error
                          final roundedVal =
                              double.parse(val.toStringAsFixed(2));
                          if (widget.onMarkupChanged != null) {
                            widget.onMarkupChanged!(roundedVal);
                          }
                          _markupCtrl.text = _formatMarkup(roundedVal);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Vertical arrangement for Input and Reset
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 65,
                        height:
                            38, // Slightly more compact for vertical stacking
                        child: TextField(
                          controller: _markupCtrl,
                          focusNode: _markupFocus,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [DecimalInputFormatter()],
                          textInputAction: TextInputAction.done,
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            suffixText: '%',
                            suffixStyle: TextStyle(
                              fontSize: 12,
                              color: hasMarkup
                                  ? Colors.orange.shade700
                                  : Colors.blue.shade300,
                              fontWeight: FontWeight.bold,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: borderColor.withOpacity(0.5)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: borderColor.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: borderColor, width: 1.5),
                            ),
                            counterText: '',
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: hasMarkup
                                ? Colors.orange.shade900
                                : Colors.blue.shade900,
                          ),
                          onTap: () {
                            _markupCtrl.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _markupCtrl.text.length);
                          },
                          onSubmitted: (val) {
                            _submitMarkup(val);
                            _markupFocus.unfocus();
                          },
                          onEditingComplete: () {
                            _submitMarkup(_markupCtrl.text);
                            _markupFocus.unfocus();
                          },
                        ),
                      ),
                      const SizedBox(height: 0),
                      // Reset button below input
                      SizedBox(
                        height: 26, // Slightly more compact
                        width: 26,
                        child: IconButton(
                          onPressed: widget.markupPercent > 0
                              ? () {
                                  if (widget.onMarkupChanged != null) {
                                    widget.onMarkupChanged!(0.0);
                                  }
                                  _markupCtrl.text = "0";
                                }
                              : null,
                          icon: Icon(Icons.refresh,
                              size:
                                  18, // Increased icon size for better visibility
                              color: widget.markupPercent > 0
                                  ? Colors.orange.shade800
                                  : Colors.grey.withOpacity(0.3)),
                          tooltip: "Сброс",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final buttons = <Widget>[];

    // Automation Button
    if (widget.onAutomationAction != null) {
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.isDisabled || widget.isAutomationLoading
                ? null
                : widget.onAutomationAction,
            icon: widget.isAutomationLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.auto_awesome, size: 18, color: _primaryColor),
            label: Text(
              widget.isAutomationLoading
                  ? "Загрузка..."
                  : (widget.automationActionLabel ?? "Автоматизация"),
              style: TextStyle(color: _primaryColor, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _primaryColor.withOpacity(0.3)),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      );
    }

    // Templates Button
    if (widget.onTemplatesAction != null) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: 8));
      }
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.isDisabled || widget.isTemplatesLoading
                ? null
                : widget.onTemplatesAction,
            icon: widget.isTemplatesLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.copy_all, size: 18, color: _primaryColor),
            label: Text(
              widget.isTemplatesLoading ? "Загрузка..." : "Шаблоны",
              style: TextStyle(color: _primaryColor, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _primaryColor.withOpacity(0.3)),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: buttons),
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
              if (widget.onShowPricesChanged != null) {
                widget.onShowPricesChanged!(newSelection.first);
              }
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

    // Use passed prop instead of provider
    final showPrices = _isWorkTab ? true : widget.showPrices;

    return GestureDetector(
      onTap: widget.isDisabled ? widget.onDismissRequest : null,
      behavior: HitTestBehavior.translucent,
      child: CustomScrollView(
        primary: false,
        slivers: [
          // Toggle for Hide Prices (Only in Materials tab)
          if (!_isWorkTab)
            SliverToBoxAdapter(
              child: AbsorbPointer(
                absorbing: widget.isDisabled,
                child: _buildViewModeToggleSegmented(showPrices),
              ),
            ),

          SliverToBoxAdapter(child: _buildActionButtons()),

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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GroupHeader(title: category, color: _primaryColor),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = groupedItems[category]![index];
                      return EstimateListTile(
                        item: item,
                        onUpdate: widget.onUpdate,
                        onDelete: () => widget.onDelete(item),
                        primaryColor: _primaryColor,
                        isMarkupActive: (widget.markupPercent > 0) == true,
                        hidePrices: (!showPrices) == true,
                        isDisabled: widget.isDisabled == true,
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
              child: AbsorbPointer(
                absorbing: widget.isDisabled,
                child: _buildMarkupControl(),
              ),
            ),

          // Notes & Remarks Section - at the bottom
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Remarks (For Report) - Now Top
                Row(
                  children: [
                    Icon(Icons.description_outlined,
                        size: 14, color: _primaryColor.withOpacity(0.8)),
                    const SizedBox(width: 6),
                    Text(
                      "Примечания (для сметы)",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor.withOpacity(0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _remarksCtrl,
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontSize: 13),
                  onChanged: _onRemarksChanged,
                  readOnly: widget.isDisabled,
                  decoration: InputDecoration(
                    hintText: "Добавить примечание...",
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
                    filled: true,
                    fillColor: _primaryColorLight,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.5), width: 1.5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: _primaryColor.withOpacity(0.12),
                            width: 0.8)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: _primaryColor, width: 1.0)),
                    suffixIcon: _buildRemarksSuffix(),
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Notes (Internal) - Now Bottom
                Row(
                  children: [
                    Icon(Icons.sticky_note_2_outlined,
                        size: 14, color: _primaryColor.withOpacity(0.8)),
                    const SizedBox(width: 6),
                    Text(
                      "Заметки (для себя)",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor.withOpacity(0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteCtrl,
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontSize: 13),
                  onChanged: _onNoteChanged,
                  readOnly: widget.isDisabled,
                  decoration: InputDecoration(
                    hintText: "Добавить заметку...",
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
                    filled: true,
                    // Match TotalDashboard background (primary shade50)
                    fillColor: _primaryColorLight,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    // Glassmorphic border (Offline state)
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.5), width: 1.5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        // Soft border matching Total
                        borderSide: BorderSide(
                            color: _primaryColor.withOpacity(0.12),
                            width: 0.8)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: _primaryColor, width: 1.0)),
                    suffixIcon: _buildNoteSuffix(),
                  ),
                ),
              ],
            ),
          )),

          // Bottom Padding for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
