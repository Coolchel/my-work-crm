import 'package:flutter/material.dart';

import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/desktop_web_frame.dart';

class ContentTabStripItem {
  const ContentTabStripItem({
    required this.label,
    required this.icon,
    required this.keyName,
  });

  final String label;
  final IconData icon;
  final String keyName;
}

class ContentTabStrip extends StatelessWidget {
  const ContentTabStrip({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<ContentTabStripItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static double overlayInset(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 720;
    return isCompact ? 68 : 72;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompact = MediaQuery.sizeOf(context).width < 720;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = DesktopWebFrame.centeredContentSidePadding(
          constraints.maxWidth,
          maxWidth: 1380,
          minPadding: 12,
        );

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            8,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                key: const ValueKey('content_tab_strip'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    _TabChipButton(
                      item: items[i],
                      isSelected: i == selectedIndex,
                      isCompact: isCompact,
                      textStyles: textStyles,
                      scheme: scheme,
                      isDark: isDark,
                      onTap: () => onSelected(i),
                    ),
                    if (i < items.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TabChipButton extends StatelessWidget {
  const _TabChipButton({
    required this.item,
    required this.isSelected,
    required this.isCompact,
    required this.textStyles,
    required this.scheme,
    required this.isDark,
    required this.onTap,
  });

  final ContentTabStripItem item;
  final bool isSelected;
  final bool isCompact;
  final AppTextStyles textStyles;
  final ColorScheme scheme;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = isDark
        ? Color.alphaBlend(
            scheme.primary.withOpacity(0.26),
            scheme.surfaceContainerHigh,
          )
        : Color.alphaBlend(
            scheme.primary.withOpacity(0.14),
            scheme.surface,
          );
    final idleColor = isDark ? scheme.surfaceContainerHigh : scheme.surface;
    final foregroundColor = isSelected
        ? scheme.primary
        : (isDark
            ? Colors.white.withOpacity(0.82)
            : scheme.onSurfaceVariant.withOpacity(0.92));

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : idleColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? scheme.primary.withOpacity(isDark ? 0.34 : 0.22)
                  : scheme.outlineVariant.withOpacity(isDark ? 0.28 : 0.20),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 14 : 18,
              vertical: isCompact ? 10 : 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: isCompact ? 18 : 20,
                  color: foregroundColor,
                ),
                const SizedBox(width: 8),
                Text(
                  item.label,
                  key: ValueKey(item.keyName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyles.navLabel.copyWith(
                    fontSize: isCompact ? 13 : 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: foregroundColor,
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
