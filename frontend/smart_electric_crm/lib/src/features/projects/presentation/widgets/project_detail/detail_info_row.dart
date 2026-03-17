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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;
    final valueStyle = textStyles.bodyStrong.copyWith(
      fontSize: 14,
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
                label,
                style: textStyles.captionStrong.copyWith(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              selectable
                  ? SelectionArea(
                      child: Text(
                        value,
                        style: valueStyle,
                      ),
                    )
                  : Text(
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
