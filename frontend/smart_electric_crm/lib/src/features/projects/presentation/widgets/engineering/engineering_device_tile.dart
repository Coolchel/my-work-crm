import 'package:flutter/material.dart';

class EngineeringDeviceTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int quantity;
  final Color markerColor;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const EngineeringDeviceTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.quantity,
    required this.markerColor,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 45, // Fixed height for expert mode feel
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
        ),
        child: Row(
          children: [
            // Color Marker
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: markerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      "· $subtitle",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Quantity Badge (if > 1)
            if (quantity > 1)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: markerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'x$quantity',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: markerColor,
                  ),
                ),
              ),

            // Delete Action
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
              onPressed: onDelete,
              constraints: const BoxConstraints(),
              splashRadius: 20,
              padding: const EdgeInsets.all(8),
              tooltip: "Удалить",
            ),
          ],
        ),
      ),
    );
  }
}
