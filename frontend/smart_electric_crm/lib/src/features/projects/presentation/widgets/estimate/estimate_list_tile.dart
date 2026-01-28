import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/features/projects/data/models/estimate_item_model.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/dialogs/estimate/edit_item_dialog.dart';

/// A list tile widget for displaying an estimate item
class EstimateListTile extends StatelessWidget {
  final EstimateItemModel item;
  final Function(EstimateItemModel) onUpdate;
  final VoidCallback onDelete;
  final Color primaryColor;
  final bool isMarkupActive;
  final bool hidePrices;

  const EstimateListTile({
    super.key,
    required this.item,
    required this.onUpdate,
    required this.onDelete,
    required this.primaryColor,
    this.isMarkupActive = false,
    this.hidePrices = false,
  });

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
            context: context,
            builder: (_) => EditItemDialog(item: item, hidePrices: hidePrices));

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

            // Middle: Name + compact info + Контрагент/Наши badges
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
                  // Compact stats row + Контрагент/Наши badges
                  // Compact stats row + Контрагент/Наши badges
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      // Quantity part - always grey
                      Text(
                        '${item.totalQuantity.toStringAsFixed(2).replaceAll(RegExp(r"\.?0+$"), "")} ${item.unit} ',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                      if (!hidePrices) ...[
                        // Price part - orange when markup active
                        Text(
                          '× ${item.pricePerUnit?.toStringAsFixed(2).replaceAll(RegExp(r"\.?0+$"), "") ?? "0"}$currencySymbol',
                          style: TextStyle(
                              fontSize: 11,
                              color: isMarkupActive
                                  ? Colors.deepOrange
                                  : Colors.grey.shade600,
                              fontWeight: isMarkupActive
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                        ),
                      ],
                      if (hasEmployer) ...[
                        // Контрагент mini badge (horizontal)
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
                // Main amount badge - only border is orange when markup is active
                if (!hidePrices)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: amountBgColor,
                      borderRadius: BorderRadius.circular(5),
                      border: isMarkupActive
                          ? Border.all(
                              color: Colors.orange.shade300, width: 0.8)
                          : null,
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
