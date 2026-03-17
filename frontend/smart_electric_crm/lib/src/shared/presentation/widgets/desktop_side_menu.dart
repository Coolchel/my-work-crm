import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

class DesktopSideMenuItem {
  const DesktopSideMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selectedIcon,
    this.isSelected = false,
  });

  final String label;
  final Widget icon;
  final Widget? selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;
}

class DesktopSideMenu extends StatelessWidget {
  const DesktopSideMenu({
    required this.items,
    super.key,
    this.width = 224,
    this.compactWidth = 88,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
    this.compact = false,
  });

  final List<DesktopSideMenuItem> items;
  final double width;
  final double compactWidth;
  final EdgeInsetsGeometry padding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHigh
            : scheme.surface.withOpacity(0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(isDark ? 0.5 : 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: compact ? compactWidth : width,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _DesktopSideMenuButton(
                  item: items[i],
                  compact: compact,
                ),
                if (i < items.length - 1) const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopSideMenuButton extends StatefulWidget {
  const _DesktopSideMenuButton({
    required this.item,
    required this.compact,
  });

  final DesktopSideMenuItem item;
  final bool compact;

  @override
  State<_DesktopSideMenuButton> createState() => _DesktopSideMenuButtonState();
}

class _DesktopSideMenuButtonState extends State<_DesktopSideMenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = widget.item.isSelected;
    final backgroundColor = isActive
        ? scheme.primary.withOpacity(isDark ? 0.24 : 0.12)
        : _isHovered
            ? scheme.primary.withOpacity(isDark ? 0.12 : 0.07)
            : Colors.transparent;
    final borderColor = isActive
        ? scheme.primary.withOpacity(isDark ? 0.38 : 0.20)
        : _isHovered
            ? scheme.outlineVariant.withOpacity(isDark ? 0.36 : 0.28)
            : Colors.transparent;
    final foregroundColor = isActive
        ? scheme.primary
        : _isHovered
            ? scheme.onSurface
            : scheme.onSurfaceVariant;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.item.onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 14,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: widget.compact
                ? Tooltip(
                    message: widget.item.label,
                    waitDuration: const Duration(milliseconds: 350),
                    child: Center(
                      child: IconTheme(
                        data: IconThemeData(
                          size: 24,
                          color: foregroundColor,
                        ),
                        child: isActive
                            ? (widget.item.selectedIcon ?? widget.item.icon)
                            : widget.item.icon,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      IconTheme(
                        data: IconThemeData(
                          size: 24,
                          color: foregroundColor,
                        ),
                        child: isActive
                            ? (widget.item.selectedIcon ?? widget.item.icon)
                            : widget.item.icon,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.item.label,
                          style: textStyles.cardTitle.copyWith(
                            color: foregroundColor,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
