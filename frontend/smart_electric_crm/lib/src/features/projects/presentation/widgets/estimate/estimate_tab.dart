import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/estimate_item_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/dialogs/estimate/estimate_actions_dialog.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/utils/decimal_input_formatter.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/estimate/estimate_list_tile.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/estimate/group_header.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/widgets/estimate/total_dashboard.dart';
import 'package:smart_electric_crm/src/core/navigation/app_navigation.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/app_section_header.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/desktop_web_frame.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/inline_save_button.dart';

/// Tab widget for displaying estimate items (Materials or Works)
class EstimateTab extends ConsumerStatefulWidget {
  final List<EstimateItemModel> items;
  final Function(EstimateItemModel) onUpdate;
  final Function(EstimateItemModel) onDelete;
  final String title;
  final ScrollController scrollController;
  final double topContentInset;

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
    this.topContentInset = 0,
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
  bool _savingNote = false;
  bool _savingRemarks = false;
  bool _savingNotesAction = false;
  String? _lastSavedNote;
  String? _lastSavedRemarks;
  bool _hasNotesChanges = false;
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
        _hasNotesChanges = false;
      }
    }
    if (widget.remarks != oldWidget.remarks) {
      if (widget.remarks != _lastSavedRemarks) {
        _remarksCtrl.text = widget.remarks;
        _lastSavedRemarks = widget.remarks;
        _hasNotesChanges = false;
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
        });
      }
    } finally {
      if (mounted) setState(() => _savingRemarks = false);
    }
  }

  Future<void> _savePendingNotes() async {
    if (_savingNotesAction || widget.isDisabled) {
      return;
    }

    final shouldSaveRemarks = _remarksCtrl.text != _lastSavedRemarks;
    final shouldSaveNote = _noteCtrl.text != _lastSavedNote;
    if (!shouldSaveRemarks && !shouldSaveNote) {
      if (mounted && _hasNotesChanges) {
        setState(() => _hasNotesChanges = false);
      }
      return;
    }

    var completedSuccessfully = false;
    setState(() => _savingNotesAction = true);
    try {
      if (shouldSaveRemarks) {
        await _saveRemarks();
      }
      if (shouldSaveNote) {
        await _saveNote();
      }
      completedSuccessfully = true;
    } finally {
      if (mounted) {
        setState(() {
          _savingNotesAction = false;
          if (completedSuccessfully) {
            _hasNotesChanges = false;
          }
        });
      }
    }
  }

  void _onNoteChanged(String value) {
    if (_hasNotesChanges) {
      return;
    }
    setState(() {
      _hasNotesChanges = true;
    });
  }

  void _onRemarksChanged(String value) {
    if (_hasNotesChanges) {
      return;
    }
    setState(() {
      _hasNotesChanges = true;
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

  Widget? _buildSaveButton({
    required bool hasUnsaved,
    required bool saving,
    required VoidCallback onSave,
    required String label,
    String? savingLabel,
  }) {
    if (!hasUnsaved && !saving) return null;

    return InlineSaveButton(
      accentColor: _primaryColor,
      label: label,
      savingLabel: savingLabel,
      saving: saving,
      compact: true,
      enabled: !widget.isDisabled,
      onPressed: widget.isDisabled || saving ? null : onSave,
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
    final textStyles = context.appTextStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textStyles.fieldLabel.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: null,
          minLines: 1,
          keyboardType: TextInputType.multiline,
          textAlignVertical: TextAlignVertical.top,
          style: textStyles.input.copyWith(color: scheme.onSurface),
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
    final textStyles = context.appTextStyles;
    final borderColor = hasMarkup
        ? markupAccent.withOpacity(isDark ? 0.36 : 0.55)
        : AppDesignTokens.softBorder(context);
    final iconColor = hasMarkup
        ? (isDark ? markupAccent.shade300 : markupAccent.shade700)
        : _primaryColor.withOpacity(0.8);
    final valueBgColor = hasMarkup
        ? markupAccent.withOpacity(isDark ? 0.18 : 0.12)
        : (isDark
            ? scheme.surfaceContainerHighest.withOpacity(0.7)
            : _primaryColor.withOpacity(0.08));
    final valueTextColor = hasMarkup
        ? (isDark ? markupAccent.shade200 : markupAccent.shade800)
        : scheme.onSurfaceVariant;
    final titleColor = hasMarkup ? scheme.onSurface : scheme.onSurfaceVariant;
    final subtitleColor = hasMarkup
        ? (isDark ? markupAccent.shade200 : markupAccent.shade700)
        : scheme.onSurfaceVariant;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.isDisabled ? null : _showMarkupEditor,
        child: Ink(
          decoration: BoxDecoration(
            color: hasMarkup
                ? (isDark
                    ? AppDesignTokens.surface2(context).withOpacity(0.66)
                    : markupAccent.withOpacity(0.055))
                : (isDark
                    ? scheme.surfaceContainerLow.withOpacity(0.8)
                    : scheme.surfaceContainerLowest),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.trending_up, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Наценка',
                        style: textStyles.bodyStrong.copyWith(
                          color: titleColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasMarkup
                            ? 'Учитывается в итоге материалов'
                            : 'Параметр расчета материалов',
                        style: textStyles.caption.copyWith(
                          color: subtitleColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: valueBgColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: borderColor.withOpacity(0.65)),
                  ),
                  child: Text(
                    '${_formatMarkup(widget.markupPercent)}%',
                    style: textStyles.captionStrong.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: valueTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMarkupEditor() async {
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => _MarkupEditorDialog(
        initialValue: widget.markupPercent,
        onMarkupChanged: widget.onMarkupChanged,
        formatMarkup: _formatMarkup,
      ),
    );
    if (result != null &&
        widget.onMarkupChanged != null &&
        (result - widget.markupPercent).abs() > 0.01) {
      widget.onMarkupChanged!(result);
    }
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
              style: context.appTextStyles.button.copyWith(
                color: _primaryColor,
                fontSize: 13,
              ),
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
              style: context.appTextStyles.button.copyWith(
                color: _primaryColor,
                fontSize: 13,
              ),
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

  Widget _buildSectionHeader(
    String title, {
    required double horizontalPadding,
    double? horizontalEndPadding,
    double topPadding = 0,
    double bottomPadding = 8,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;
    return AppSectionHeader(
      title: title,
      padding: EdgeInsetsDirectional.fromSTEB(
        horizontalPadding,
        topPadding,
        horizontalEndPadding ?? horizontalPadding,
        bottomPadding,
      ),
      titleStyle: textStyles.sectionTitle.copyWith(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        height: 1.18,
        letterSpacing: -0.15,
        color: scheme.onSurface,
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
    final notesSaveButton = _buildSaveButton(
      hasUnsaved: _hasNotesChanges,
      saving: _savingNotesAction || _savingRemarks || _savingNote,
      onSave: _savePendingNotes,
      label: 'Сохранить',
      savingLabel: 'Сохранение...',
    );
    final hasNotesSaveButton = notesSaveButton != null;

    return GestureDetector(
      onTap: widget.isDisabled ? widget.onDismissRequest : null,
      behavior: HitTestBehavior.translucent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scrollbarEndInset =
              DesktopWebFrame.scrollableContentEndInset(context);
          final useOverlayPrimaryAction =
              DesktopWebFrame.usesOverlayPrimaryAction(context);
          final bottomPadding = DesktopWebFrame.scrollableContentBottomPadding(
            context,
            hasOverlayAction: useOverlayPrimaryAction,
          );
          final effectiveBottomPadding = useOverlayPrimaryAction
              ? (bottomPadding - 12).clamp(0.0, double.infinity).toDouble()
              : bottomPadding;
          final horizontalPadding =
              DesktopWebFrame.centeredContentHorizontalPadding(
            context,
            constraints.maxWidth,
            trailingInset: scrollbarEndInset,
          );
          final horizontalEndPadding = horizontalPadding + scrollbarEndInset;
          final cardInset = horizontalPadding - 12;
          final cardEndInset = cardInset + scrollbarEndInset;

          return CustomScrollView(
            controller: widget.scrollController,
            primary: false,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: widget.topContentInset),
              ),

              if (!widget.hideTopActions)
                SliverToBoxAdapter(child: _buildActionButtons()),

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
                      padding: EdgeInsetsDirectional.only(
                        start: horizontalPadding,
                        end: horizontalEndPadding,
                      ),
                      child: GroupHeader(
                        title: category,
                        color: _primaryColor,
                        itemCount: groupedItems[category]?.length,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      horizontalPadding,
                      0,
                      horizontalEndPadding,
                      0,
                    ),
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
              if (showPrices)
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
              if (showPrices)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: cardInset,
                      end: cardEndInset,
                    ),
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
                      emptyMessage:
                          !_isWorkTab && totalUsd == 0 && totalByn == 0
                              ? 'Итоги появятся после добавления материалов.'
                              : null,
                      footer: !_isWorkTab
                          ? AbsorbPointer(
                              absorbing: widget.isDisabled,
                              child: _buildMarkupControl(),
                            )
                          : null,
                    ),
                  ),
                ),
              // Notes & Remarks Section - at the bottom
              // Notes & Remarks Section - at the bottom
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  'Заметки',
                  horizontalPadding: horizontalPadding,
                  horizontalEndPadding: horizontalEndPadding,
                  topPadding: showPrices ? 10 : 12,
                  bottomPadding: 8,
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsetsDirectional.fromSTEB(
                    horizontalPadding,
                    4,
                    horizontalEndPadding,
                    12,
                  ),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    hasNotesSaveButton ? 16 : 20,
                  ),
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
                      const SizedBox(height: 12),
                      _buildInputField(
                        label: "Заметки (для себя)",
                        controller: _noteCtrl,
                        onChanged: _onNoteChanged,
                        suffix: _buildSuffix(isSaving: _savingNote),
                      ),
                      InlineSaveActionsRow(
                        topPadding: 16,
                        actions: [
                          if (notesSaveButton != null) notesSaveButton,
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: effectiveBottomPadding),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MarkupEditorDialog extends StatefulWidget {
  const _MarkupEditorDialog({
    required this.initialValue,
    required this.onMarkupChanged,
    required this.formatMarkup,
  });

  final double initialValue;
  final ValueChanged<double>? onMarkupChanged;
  final String Function(double value) formatMarkup;

  @override
  State<_MarkupEditorDialog> createState() => _MarkupEditorDialogState();
}

class _MarkupEditorDialogState extends State<_MarkupEditorDialog>
    with EstimateDialogHelpers {
  static const _markupAccent = Colors.teal;
  Timer? _syncDebounce;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late double _draftValue;

  @override
  void initState() {
    super.initState();
    _draftValue = widget.initialValue.clamp(0.0, 100.0);
    _controller = TextEditingController(text: widget.formatMarkup(_draftValue));
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _flushPendingSync();
    _syncDebounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncMarkup(double value, {required bool immediate}) {
    final roundedValue =
        double.parse(value.clamp(0.0, 100.0).toStringAsFixed(2));
    if (immediate) {
      _syncDebounce?.cancel();
      widget.onMarkupChanged?.call(roundedValue);
      return;
    }

    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 70), () {
      widget.onMarkupChanged?.call(roundedValue);
    });
  }

  void _flushPendingSync() {
    if (_syncDebounce?.isActive ?? false) {
      _syncDebounce?.cancel();
      widget.onMarkupChanged?.call(
        double.parse(_draftValue.clamp(0.0, 100.0).toStringAsFixed(2)),
      );
    }
  }

  void _setDraftValue(double value, {bool immediateSync = false}) {
    final roundedValue =
        double.parse(value.clamp(0.0, 100.0).toStringAsFixed(2));
    final formatted = widget.formatMarkup(roundedValue);

    if (mounted) {
      setState(() {
        _draftValue = roundedValue;
      });
    }

    if (_controller.text != formatted) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    _syncMarkup(roundedValue, immediate: immediateSync);
  }

  void _commitTextValue() {
    final rawValue = _controller.text.trim();
    final parsed = double.tryParse(rawValue.replaceAll(',', '.'));
    final nextValue = parsed ?? _draftValue;
    _setDraftValue(nextValue, immediateSync: true);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final textStyles = context.appTextStyles;
    final hasMarkup = _draftValue > 0;
    final borderColor = _markupAccent.withOpacity(isDark ? 0.36 : 0.24);

    return buildPremiumContainer(
      context: context,
      themeColor: _markupAccent,
      maxWidth: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildPremiumHeader(
            context: context,
            title: 'Наценка материалов',
            icon: Icons.trending_up_rounded,
            themeColor: _markupAccent,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.surfaceContainerLow
                            : _markupAccent.withOpacity(0.045),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: hasMarkup
                                      ? _markupAccent.withOpacity(
                                          isDark ? 0.18 : 0.12,
                                        )
                                      : scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${widget.formatMarkup(_draftValue)}%',
                                  style: textStyles.bodyStrong.copyWith(
                                    fontSize: 13,
                                    color: hasMarkup
                                        ? (isDark
                                            ? _markupAccent.shade200
                                            : _markupAccent.shade800)
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _markupAccent,
                              inactiveTrackColor:
                                  _markupAccent.withOpacity(0.18),
                              thumbColor: _markupAccent.shade700,
                              trackHeight: 4,
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16,
                              ),
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 7,
                              ),
                            ),
                            child: Slider(
                              value: _draftValue,
                              min: 0,
                              max: 100,
                              divisions: 200,
                              label: '${_draftValue.toStringAsFixed(1)}%',
                              onChanged: _setDraftValue,
                              onChangeEnd: (value) =>
                                  _syncMarkup(value, immediate: true),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [DecimalInputFormatter()],
                            textInputAction: TextInputAction.done,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: isDark
                                  ? scheme.surfaceContainerHigh
                                  : scheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              labelText: 'Процент',
                              suffixText: '%',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: borderColor.withOpacity(0.9),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _markupAccent.shade700,
                                  width: 1.4,
                                ),
                              ),
                            ),
                            style: textStyles.bodyStrong.copyWith(
                              fontSize: 14,
                              color: scheme.onSurface,
                            ),
                            onTap: () {
                              _controller.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _controller.text.length,
                              );
                            },
                            onChanged: (value) {
                              final normalized = value.replaceAll(',', '.');
                              if (normalized.isEmpty ||
                                  normalized == '.' ||
                                  normalized.endsWith('.')) {
                                return;
                              }
                              final parsed = double.tryParse(normalized);
                              if (parsed == null) {
                                return;
                              }
                              final roundedValue = double.parse(
                                parsed.clamp(0.0, 100.0).toStringAsFixed(2),
                              );
                              setState(() {
                                _draftValue = roundedValue;
                              });
                              _syncMarkup(roundedValue, immediate: false);
                            },
                            onSubmitted: (_) => _commitTextValue(),
                            onEditingComplete: _commitTextValue,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        'Наценка влияет на итог по материалам и обновляется сразу.',
                        style: textStyles.caption.copyWith(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        const Spacer(),
                        FilledButton.tonal(
                          onPressed: hasMarkup
                              ? () => _setDraftValue(0, immediateSync: true)
                              : null,
                          child: const Text('Сброс'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: () {
                            _commitTextValue();
                            Navigator.of(context).pop(_draftValue);
                          },
                          child: const Text('Готово'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
