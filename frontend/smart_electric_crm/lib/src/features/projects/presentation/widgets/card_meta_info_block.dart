import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/desktop_web_frame.dart';

class CardMetaInfoBlock extends StatelessWidget {
  const CardMetaInfoBlock({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
    this.valueMaxLines = 2,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool compact;
  final int valueMaxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final isMobileWeb = kIsWeb &&
        DesktopWebFrame.isMobileWeb(
          context,
          maxWidth: 520,
        );
    final shouldBoostCompactText = compact && (isAndroid || isMobileWeb);
    final iconPadding = compact ? 6.0 : 8.0;
    final iconSize = compact ? 16.0 : 18.0;
    final labelSize = compact ? (shouldBoostCompactText ? 9.5 : 9.0) : 10.0;
    final valueSize = compact ? (shouldBoostCompactText ? 11.5 : 11.0) : 12.0;
    final spacing = compact ? 8.0 : 10.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(iconPadding),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: color,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textStyles.caption.copyWith(
                  fontSize: labelSize,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                maxLines: valueMaxLines,
                overflow: TextOverflow.ellipsis,
                style: textStyles.bodyStrong.copyWith(
                  fontSize: valueSize,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
