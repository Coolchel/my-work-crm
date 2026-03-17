import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';

class DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool selectable;

  const DetailInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.selectable = false,
  });

  String _normalizeLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return raw;
    }

    final isAllCaps =
        trimmed == trimmed.toUpperCase() && trimmed != trimmed.toLowerCase();
    if (!isAllCaps) {
      return raw;
    }

    final lower = trimmed.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;
    final normalizedLabel = _normalizeLabel(label);

    final labelStyle = textStyles.bodyStrong.copyWith(
      fontSize: 12,
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    );
    final valueStyle = textStyles.body.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: scheme.onSurface,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                normalizedLabel,
                style: labelStyle,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: valueStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
