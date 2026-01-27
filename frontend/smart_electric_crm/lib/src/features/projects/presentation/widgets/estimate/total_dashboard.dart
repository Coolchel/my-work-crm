import 'package:flutter/material.dart';

/// Comprehensive dashboard for summary totals
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
