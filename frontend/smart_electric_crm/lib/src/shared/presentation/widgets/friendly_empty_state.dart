import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

class FriendlyEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accentColor;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final Widget? action;

  const FriendlyEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accentColor = Colors.indigo,
    this.iconSize = 82,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textStyles = context.appTextStyles;
    final titleStyle = textStyles.sectionTitle.copyWith(
      color: scheme.onSurface,
    );
    final subtitleStyle = textStyles.body.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.35,
    );

    return Center(
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: accentColor.withOpacity(
                  theme.brightness == Brightness.dark ? 0.48 : 0.28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: titleStyle,
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: subtitleStyle,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 12),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
