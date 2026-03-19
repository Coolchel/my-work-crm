import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';

class AppEyebrowLabel extends StatelessWidget {
  const AppEyebrowLabel({
    required this.text,
    super.key,
    this.color,
    this.padding = EdgeInsets.zero,
    this.uppercase = true,
  });

  final String text;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayText = uppercase ? text.toUpperCase() : text;

    return Padding(
      padding: padding,
      child: Text(
        displayText,
        style: context.appTextStyles.captionStrong.copyWith(
          fontSize: 11,
          color: color ?? scheme.onSurfaceVariant.withOpacity(0.72),
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    this.title = '',
    this.eyebrow,
    this.leading,
    this.trailing,
    this.padding = EdgeInsets.zero,
    this.titleStyle,
    this.eyebrowColor,
    this.titleMaxLines = 2,
    this.eyebrowPadding = EdgeInsets.zero,
  });

  final String title;
  final String? eyebrow;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final TextStyle? titleStyle;
  final Color? eyebrowColor;
  final int titleMaxLines;
  final EdgeInsetsGeometry eyebrowPadding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedTitleStyle = context.appTextStyles.sectionTitle
        .copyWith(
          color: scheme.onSurface,
        )
        .merge(titleStyle);

    final headerRow = title.isEmpty
        ? const SizedBox.shrink()
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: titleMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: resolvedTitleStyle,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          );
    return Padding(
      padding: padding,
      child: eyebrow == null || eyebrow!.trim().isEmpty
          ? headerRow
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppEyebrowLabel(
                  text: eyebrow!,
                  color: eyebrowColor,
                  padding: eyebrowPadding,
                ),
                const SizedBox(height: 6),
                headerRow,
              ],
            ),
    );
  }
}
