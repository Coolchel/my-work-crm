import 'package:flutter/material.dart';

/// A styled header for grouping estimate items by category
class GroupHeader extends StatelessWidget {
  final String title;
  final Color color;
  final int? itemCount;

  const GroupHeader({
    super.key,
    required this.title,
    required this.color,
    this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              color: color.withOpacity(0.65),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color.withOpacity(0.9),
            ),
          ),
          if (itemCount != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(
                '$itemCount',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color.withOpacity(0.95),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: color.withOpacity(0.12),
              thickness: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}
