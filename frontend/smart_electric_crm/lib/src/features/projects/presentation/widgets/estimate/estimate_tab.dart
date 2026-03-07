import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/estimate_item_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/utils/decimal_input_formatter.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/estimate/estimate_list_tile.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/estimate/group_header.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/estimate/total_dashboard.dart';
import 'package:smart_electric_crm/src/core/navigation/app_navigation.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';

/// Tab widget for displaying estimate items (Materials or Works)
class EstimateTab extends ConsumerStatefulWidget {
  final List<EstimateItemModel> items;
  final Function(EstimateItemModel) onUpdate;
  final Function(EstimateItemModel) onDelete;
  final String title;
  final ScrollController scrollController;

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
  final VoidCallback? onSaveAsTemplate;
  final bool hideTopActions;

  const EstimateTab({
    super.key,
    required this.items,
    required this.onUpdate,
    required this.onDelete,
    required this.title,
    required this.scrollController,
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
    this.onSaveAsTemplate,
    this.hideTopActions = false,
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
  Object? _scrollAttachment;

  static const _defaultMaterialsRemarks = "Не учтен вводной кабель.";

  @override
  void initState() {
    super.initState();
    _scrollAttachment = (_isWorkTab
            ? AppNavigation.worksScrollController
            : AppNavigation.materialsScrollController)
        .attach(_scrollToTop);
    _noteCtrl = TextEditingController(text: widget.note);

    // Default text logic for Materials
    String initialRemarks = widget.remarks;
    if (!_isWorkTab && initialRemarks.trim().isEmpty) {
      initialRemarks = _defaultMaterialsRemarks;
      // Do NOT set _hasUnsavedRemarks = true here anymore.
      // Button will only appear if user changes this default text.
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
    if (oldWidget.title != widget.title) {
      final scrollAttachment = _scrollAttachment;
      if (scrollAttachment != null) {
        final oldController = oldWidget.title == "Работы"
            ? AppNavigation.worksScrollController
            : AppNavigation.materialsScrollController;
        oldController.detach(scrollAttachment);
      }
      _scrollAttachment = (_isWorkTab
              ? AppNavigation.worksScrollController
              : AppNavigation.materialsScrollController)
          .attach(_scrollToTop);
    }
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
    final scrollAttachment = _scrollAttachment;
    if (scrollAttachment != null) {
      final controller = _isWorkTab
          ? AppNavigation.worksScrollController
          : AppNavigation.materialsScrollController;
      controller.detach(scrollAttachment);
    }
    _noteCtrl.dispose();
    _remarksCtrl.dispose();
    _markupCtrl.dispose();
    _markupFocus.dispose();
    super.dispose();
  }

  Future<void> _scrollToTop({bool animated = true}) async {
    if (!widget.scrollController.hasClients) {
      return;
    }
    if (animated) {
      await widget.scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    widget.scrollController.jumpTo(0);
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
      // If it's Materials and was initially empty, and now it's the default text,
      // we consider it "unsaved" but we want to HIDE the button per user request.
      final isDefaultSpecialCase = !_isWorkTab &&
          widget.remarks.trim().isEmpty &&
          value == _defaultMaterialsRemarks;

      if (isDefaultSpecialCase) {
        _hasUnsavedRemarks = false;
      } else {
        _hasUnsavedRemarks = value != _lastSavedRemarks;
      }
    });
  }

// Methods _buildNoteSuffix and _buildRemarksSuffix are replaced by _buildSaveButton logic below.

  Widget? _buildSuffix({
    bool isSaving = false,
  }) {
    if (isSaving) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return null;
  }

  Widget _buildSaveButton({
    required bool hasUnsaved,
    required bool saving,
    required VoidCallback onSave,
  }) {
    if (!hasUnsaved && !saving) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          onPressed: widget.isDisabled || saving ? null : onSave,
          icon: saving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save, size: 14),
          label: Text(saving ? 'Сохранение...' : 'Сохранить'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryColor,
            side: BorderSide(color: _primaryColor),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
                if (states.contains(WidgetState.hovered)) {
                  return _primaryColor.withOpacity(0.08);
                }
                return null;
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    Widget? suffix,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: null,
          minLines: 2,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(fontSize: 14),
          onChanged: onChanged,
          readOnly: widget.isDisabled,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            fillColor: isDark
                ? scheme.surfaceContainer.withOpacity(0.7)
                : scheme.surfaceContainer.withOpacity(0.4),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: AppDesignTokens.softBorder(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: AppDesignTokens.softBorder(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _primaryColor, width: 1),
            ),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }

  Widget _buildMarkupControl() {
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final hasMarkup = widget.markupPercent > 0;
    const markupAccent = Colors.teal;

    final headerColor = hasMarkup
        ? (isDark
            ? AppDesignTokens.surface2(context).withOpacity(0.96)
            : markupAccent.withOpacity(0.11))
        : (isDark
            ? AppDesignTokens.surface2(context).withOpacity(0.92)
            : _primaryColorLight.withOpacity(0.45));
    final bodyColor = hasMarkup
        ? (isDark
            ? AppDesignTokens.surface2(context).withOpacity(0.84)
            : markupAccent.withOpacity(0.06))
        : Colors.transparent;

    final borderColor = hasMarkup
        ? markupAccent.withOpacity(isDark ? 0.36 : 0.55)
        : AppDesignTokens.softBorder(context);
    final iconColor = hasMarkup
        ? (isDark ? markupAccent.shade300 : markupAccent.shade700)
        : _primaryColor.withOpacity(0.8);
    final textColor = hasMarkup
        ? (isDark ? scheme.onSurface : markupAccent.shade800)
        : (isDark ? scheme.onSurface : _primaryColor.withOpacity(0.9));
    final textWeight = hasMarkup ? FontWeight.bold : FontWeight.w500;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                        activeTrackColor: markupAccent,
                        inactiveTrackColor: markupAccent.withOpacity(0.2),
                        thumbColor: markupAccent.shade700,
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
                            fillColor: AppDesignTokens.isDark(context)
                                ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHigh
                                : Colors.white.withOpacity(0.9),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            suffixText: '%',
                            suffixStyle: TextStyle(
                              fontSize: 12,
                              color: hasMarkup
                                  ? (isDark
                                      ? markupAccent.shade300
                                      : markupAccent.shade700)
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
                                ? (isDark
                                    ? scheme.onSurface
                                    : markupAccent.shade800)
                                : (isDark
                                    ? scheme.onSurface
                                    : Colors.blue.shade900),
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
                                  ? markupAccent.shade700
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

    // Save as Template Button
    if (widget.onSaveAsTemplate != null) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: 8));
      }
      buttons.add(
        Tooltip(
          message: "Сохранить как шаблон",
          child: SizedBox(
            // Not expanded, just an icon button or small button
            width: 48,
            child: OutlinedButton(
              onPressed: widget.isDisabled ? null : widget.onSaveAsTemplate,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: _primaryColor.withOpacity(0.3)),
                visualDensity: VisualDensity.compact,
              ),
              child: Icon(Icons.save_as, size: 20, color: _primaryColor),
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(children: buttons),
    );
  }

  Widget _buildItemsCaption(int itemCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          Icon(
            _isWorkTab ? Icons.handyman_outlined : Icons.inventory_2_outlined,
            size: 14,
            color: _primaryColor.withOpacity(0.85),
          ),
          const SizedBox(width: 6),
          Text(
            _isWorkTab ? 'Позиции работ' : 'Позиции материалов',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _primaryColor.withOpacity(0.18)),
            ),
            child: Text(
              '$itemCount',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: _primaryColor,
              ),
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
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
        controller: widget.scrollController,
        primary: false,
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          if (!widget.hideTopActions)
            SliverToBoxAdapter(child: _buildActionButtons()),
          SliverToBoxAdapter(child: _buildItemsCaption(widget.items.length)),

          if (widget.items.isEmpty)
            const SliverToBoxAdapter(
              child: FriendlyEmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Нет позиций',
                subtitle:
                    'Добавьте первую позицию вручную или через автоматизацию.',
                accentColor: Colors.blueGrey,
                iconSize: 66,
                padding: EdgeInsets.all(8),
              ),
            )
          else
            for (var category in sortedCategories) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GroupHeader(
                    title: category,
                    color: _primaryColor,
                    itemCount: groupedItems[category]?.length,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
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
              const SliverToBoxAdapter(child: SizedBox(height: 2)),
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
          // Notes & Remarks Section - at the bottom
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppDesignTokens.softBorder(context),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.24)
                        : Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputField(
                    label: "Примечания (для сметы)",
                    controller: _remarksCtrl,
                    onChanged: _onRemarksChanged,
                    suffix: _buildSuffix(isSaving: _savingRemarks),
                  ),
                  _buildSaveButton(
                    hasUnsaved: _hasUnsavedRemarks,
                    saving: _savingRemarks,
                    onSave: _saveRemarks,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    label: "Заметки (для себя)",
                    controller: _noteCtrl,
                    onChanged: _onNoteChanged,
                    suffix: _buildSuffix(isSaving: _savingNote),
                  ),
                  _buildSaveButton(
                    hasUnsaved: _hasUnsavedNote,
                    saving: _savingNote,
                    onSave: _saveNote,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Padding for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
