import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/utils/app_number_formatter.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/estimate_item_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/dialogs/estimate/edit_item_dialog.dart';

/// A compact row widget for displaying an estimate item.
class EstimateListTile extends StatefulWidget {
  final EstimateItemModel item;
  final Function(EstimateItemModel) onUpdate;
  final VoidCallback onDelete;
  final Color primaryColor;
  final bool isMarkupActive;
  final bool hidePrices;
  final bool isDisabled;

  const EstimateListTile({
    super.key,
    required this.item,
    required this.onUpdate,
    required this.onDelete,
    required this.primaryColor,
    this.isMarkupActive = false,
    this.hidePrices = false,
    this.isDisabled = false,
  });

  @override
  State<EstimateListTile> createState() => _EstimateListTileState();
}

class _EstimateListTileState extends State<EstimateListTile> {
  bool _isHovered = false;

  IconData get _icon => widget.item.itemType == 'work'
      ? Icons.engineering_outlined
      : Icons.inventory_2_outlined;

  String _formatQuantity(double value) {
    if (widget.item.itemType == 'work') {
      return AppNumberFormatter.integer(value);
    }
    return AppNumberFormatter.decimal(value);
  }

  String _formatMoney(double value) {
    return AppNumberFormatter.decimal(value);
  }

  String _formatCurrencyAmount(double value, bool isUsd) {
    return '${_formatMoney(value)}${isUsd ? '\$' : 'р'}';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = AppDesignTokens.isDark(context);
    final scheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;
    final isUsd = item.currency == 'USD';
    final clientAmount = item.clientAmount ?? 0;
    final employerAmount = item.employerAmount ?? 0;
    final myAmount = item.myAmount ?? 0;
    final hasEmployer = employerAmount > 0;
    const markupAccent = Colors.teal;

    final amountBgColor = widget.primaryColor.withOpacity(isDark ? 0.12 : 0.1);
    final amountTextColor = widget.primaryColor;

    return MouseRegion(
      cursor: widget.isDisabled ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: AppDesignTokens.cardBackground(context, hovered: _isHovered),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? widget.primaryColor.withOpacity(0.2)
                : AppDesignTokens.cardBorder(context),
          ),
          boxShadow: [
            BoxShadow(
              color: AppDesignTokens.cardShadow(context, hovered: _isHovered),
              blurRadius: _isHovered ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isDisabled
                ? null
                : () async {
                    final result = await showDialog<dynamic>(
                      context: context,
                      builder: (_) => EditItemDialog(
                        item: item,
                        hidePrices: widget.hidePrices,
                      ),
                    );

                    if (result == 'delete') {
                      widget.onDelete();
                    } else if (result is EstimateItemModel) {
                      widget.onUpdate(result);
                    }
                  },
            borderRadius: BorderRadius.circular(12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    color: widget.primaryColor.withOpacity(0.65),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: widget.primaryColor.withOpacity(0.11),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(
                              _icon,
                              size: 14,
                              color: widget.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.name,
                                  style: textStyles.bodyStrong.copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                    height: 1.2,
                                  ),
                                  softWrap: true,
                                ),
                                const SizedBox(height: 2),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 5,
                                  runSpacing: 2,
                                  children: [
                                    Text(
                                      '${_formatQuantity(item.totalQuantity)} ${item.unit}',
                                      style: textStyles.captionStrong.copyWith(
                                        fontSize: 10.5,
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (!widget.hidePrices)
                                      Text(
                                        'x ${_formatCurrencyAmount(item.pricePerUnit ?? 0, isUsd)}',
                                        style:
                                            textStyles.captionStrong.copyWith(
                                          fontSize: 10.5,
                                          color: widget.isMarkupActive
                                              ? markupAccent.shade700
                                              : scheme.onSurfaceVariant,
                                          fontWeight: widget.isMarkupActive
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    if (hasEmployer)
                                      _buildMiniBadge(
                                        label:
                                            'Контрагент ${_formatCurrencyAmount(employerAmount, isUsd)}',
                                        background: isDark
                                            ? Colors.orange.withOpacity(0.14)
                                            : Colors.orange.shade50,
                                        foreground: isDark
                                            ? Colors.orange.shade200
                                            : Colors.orange.shade700,
                                        border: isDark
                                            ? Colors.orange.withOpacity(0.30)
                                            : Colors.orange.shade100,
                                      ),
                                    if (hasEmployer)
                                      _buildMiniBadge(
                                        label:
                                            'Наши ${_formatCurrencyAmount(myAmount, isUsd)}',
                                        background: isUsd
                                            ? widget.primaryColor
                                                .withOpacity(0.1)
                                            : Colors.deepPurple.shade50,
                                        foreground: isUsd
                                            ? widget.primaryColor
                                            : Colors.deepPurple.shade600,
                                        border:
                                            AppDesignTokens.softBorder(context),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!widget.hidePrices)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUsd
                                        ? amountBgColor
                                        : Colors.deepPurple.withOpacity(
                                            isDark ? 0.16 : 0.11,
                                          ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: widget.isMarkupActive
                                        ? Border.all(
                                            color:
                                                markupAccent.withOpacity(0.6),
                                            width: 0.8,
                                          )
                                        : Border.all(
                                            color: Colors.transparent,
                                          ),
                                  ),
                                  child: Text(
                                    _formatCurrencyAmount(clientAmount, isUsd),
                                    style: textStyles.captionStrong.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isUsd
                                          ? amountTextColor
                                          : (isDark
                                              ? Colors.deepPurple.shade200
                                              : Colors.deepPurple.shade700),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 2),
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  padding: EdgeInsets.zero,
                                  onPressed: widget.isDisabled
                                      ? null
                                      : widget.onDelete,
                                  tooltip: 'Удалить',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge({
    required String label,
    required Color background,
    required Color foreground,
    Color? border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5),
        border: border == null ? null : Border.all(color: border, width: 0.7),
      ),
      child: Text(
        label,
        style: context.appTextStyles.captionStrong.copyWith(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: foreground,
          height: 1.1,
        ),
      ),
    );
  }
}
