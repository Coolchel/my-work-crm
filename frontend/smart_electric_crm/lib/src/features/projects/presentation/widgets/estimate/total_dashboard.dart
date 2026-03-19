import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/core/utils/app_number_formatter.dart';

/// Comprehensive dashboard for summary totals.
class TotalDashboard extends StatelessWidget {
  final double totalUsd;
  final double totalByn;
  final double employerUsd;
  final double employerByn;
  final double ourUsd;
  final double ourByn;
  final Color primaryColor;
  final Color primaryColorLight;
  final bool isWorkTab;
  final bool isMarkupActive;
  final Widget? footer;
  final String? emptyMessage;

  const TotalDashboard({
    super.key,
    required this.totalUsd,
    required this.totalByn,
    required this.employerUsd,
    required this.employerByn,
    required this.ourUsd,
    required this.ourByn,
    required this.primaryColor,
    required this.primaryColorLight,
    required this.isWorkTab,
    this.isMarkupActive = false,
    this.footer,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final hasAnyTotals = totalUsd > 0 || totalByn > 0;
    final hasEmptyMessage =
        emptyMessage != null && emptyMessage!.trim().isNotEmpty;
    if (!hasAnyTotals && footer == null && !hasEmptyMessage) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);

    final hasEmployer = employerUsd > 0 || employerByn > 0;
    final hasUsd = totalUsd > 0 || employerUsd > 0 || ourUsd > 0;
    final hasByn = totalByn > 0 || employerByn > 0 || ourByn > 0;

    final effectiveBorderColor = isMarkupActive
        ? Colors.teal.withOpacity(isDark ? 0.32 : 0.4)
        : AppDesignTokens.softBorder(context);
    final baseSurface = AppDesignTokens.surface2(context);
    final headerSurface =
        isDark ? baseSurface.withOpacity(0.9) : primaryColor.withOpacity(0.05);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      decoration: BoxDecoration(
        color: isDark ? baseSurface : primaryColorLight.withOpacity(0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: effectiveBorderColor, width: 0.7),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: headerSurface,
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
                  isWorkTab ? 'Итоги по работам' : 'Итоги по материалам',
                  style: context.appTextStyles.bodyStrong.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? scheme.onSurface
                        : primaryColor.withOpacity(0.9),
                  ),
                ),
                const Spacer(),
                if (hasUsd) _label(context, 'USD (\$)', primaryColor),
                if (hasUsd && hasByn) const SizedBox(width: 15),
                if (hasByn) _label(context, 'BYN (р)', Colors.deepPurple),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              children: [
                if (hasAnyTotals) ...[
                  if (hasEmployer) ...[
                    _row(context, 'Наши', ourUsd, ourByn, Colors.green,
                        isBold: true),
                    const SizedBox(height: 6),
                    _row(
                      context,
                      'Контрагент',
                      employerUsd,
                      employerByn,
                      isWorkTab ? Colors.orange : Colors.teal,
                      isBold: true,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Divider(height: 1, thickness: 0.5),
                    ),
                  ],
                  _row(context, 'Всего', totalUsd, totalByn, primaryColor,
                      isBold: true),
                ] else if (hasEmptyMessage) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      emptyMessage!,
                      style: context.appTextStyles.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                if (footer != null) ...[
                  if (hasAnyTotals || hasEmptyMessage)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, thickness: 0.5),
                    ),
                  footer!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text, Color color) {
    return SizedBox(
      width: 65,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: context.appTextStyles.chartLabel.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    double usd,
    double byn,
    Color color, {
    bool isBold = false,
  }) {
    final hasUsd = totalUsd > 0 || employerUsd > 0 || ourUsd > 0;
    final hasByn = totalByn > 0 || employerByn > 0 || ourByn > 0;

    return Row(
      children: [
        Text(
          label,
          style: context.appTextStyles.bodyStrong.copyWith(
            color: isBold ? color : Colors.grey.shade700,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        if (hasUsd) _amount(context, usd, color, isBold, show: usd > 0),
        if (hasUsd && hasByn) const SizedBox(width: 15),
        if (hasByn)
          _amount(
            context,
            byn,
            label == 'Контрагент' ? color : Colors.deepPurple,
            isBold,
            show: byn > 0,
          ),
      ],
    );
  }

  Widget _amount(
    BuildContext context,
    double value,
    Color color,
    bool isBold, {
    required bool show,
  }) {
    final formattedValue = isWorkTab
        ? AppNumberFormatter.integer(value)
        : AppNumberFormatter.decimal(value);
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 70,
      child: show
          ? Text(
              formattedValue,
              textAlign: TextAlign.right,
              style: context.appTextStyles.bodyStrong.copyWith(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: isBold ? color : color.withOpacity(0.8),
              ),
            )
          : Text(
              '—',
              textAlign: TextAlign.right,
              style: context.appTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
    );
  }
}
