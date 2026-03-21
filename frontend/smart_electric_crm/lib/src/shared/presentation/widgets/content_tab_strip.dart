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

class ContentTabStripSpacing {
  const ContentTabStripSpacing({
    required this.topPadding,
    required this.bottomPadding,
    required this.contentGap,
    required this.itemHeight,
  });

  final double topPadding;
  final double bottomPadding;
  final double contentGap;
  final double itemHeight;

  double get overlayHeight => topPadding + itemHeight + bottomPadding;
  double get contentInset => overlayHeight + contentGap;
  double get lowerGap => bottomPadding + contentGap;
  double get outerGap => topPadding;
}

class ContentTabStrip extends StatelessWidget {
  const ContentTabStrip({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.topPadding = 12,
    this.bottomPadding = 8,
    this.sidePadding,
    this.itemWidth,
    this.trailing,
    this.trailingGap = 12,
    this.trailingReservedWidth,
    super.key,
  });

  final List<ContentTabStripItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double topPadding;
  final double bottomPadding;
  final double? sidePadding;
  final double? itemWidth;
  final Widget? trailing;
  final double trailingGap;
  final double? trailingReservedWidth;

  static double overlayInset(BuildContext context) {
    return balancedSpacing(context).overlayHeight;
  }

  static ContentTabStripSpacing balancedSpacing(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    if (viewportWidth < 720) {
      return const ContentTabStripSpacing(
        topPadding: 16,
        bottomPadding: 6,
        contentGap: 10,
        itemHeight: 38,
      );
    }
    if (DesktopWebFrame.isDesktop(context, minWidth: 1180)) {
      return const ContentTabStripSpacing(
        topPadding: 20,
        bottomPadding: 8,
        contentGap: 12,
        itemHeight: 44,
      );
    }
    return const ContentTabStripSpacing(
      topPadding: 18,
      bottomPadding: 8,
      contentGap: 10,
      itemHeight: 44,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompact = MediaQuery.sizeOf(context).width < 720;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding =
            DesktopWebFrame.centeredContentHorizontalPadding(
          context,
          constraints.maxWidth,
        );

        return Padding(
          padding: EdgeInsets.fromLTRB(
            sidePadding ?? horizontalPadding,
            topPadding,
            sidePadding ?? horizontalPadding,
            bottomPadding,
          ),
          child: trailing == null
              ? Align(
                  alignment: Alignment.topCenter,
                  child: _buildTabsRow(
                    isCompact: isCompact,
                    textStyles: textStyles,
                    scheme: scheme,
                    isDark: isDark,
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: (trailingReservedWidth ?? 0) + trailingGap,
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: _buildTabsRow(
                          isCompact: isCompact,
                          textStyles: textStyles,
                          scheme: scheme,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    SizedBox(width: trailingGap),
                    SizedBox(
                      width: trailingReservedWidth,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: trailing!,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildTabsRow({
    required bool isCompact,
    required AppTextStyles textStyles,
    required ColorScheme scheme,
    required bool isDark,
  }) {
    return SingleChildScrollView(
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
              width: itemWidth,
              textStyles: textStyles,
              scheme: scheme,
              isDark: isDark,
              onTap: () => onSelected(i),
            ),
            if (i < items.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _TabChipButton extends StatelessWidget {
  const _TabChipButton({
    required this.item,
    required this.isSelected,
    required this.isCompact,
    required this.width,
    required this.textStyles,
    required this.scheme,
    required this.isDark,
    required this.onTap,
  });

  final ContentTabStripItem item;
  final bool isSelected;
  final bool isCompact;
  final double? width;
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
          child: SizedBox(
            width: width,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 14 : 18,
                vertical: isCompact ? 10 : 12,
              ),
              child: Row(
                mainAxisSize:
                    width == null ? MainAxisSize.min : MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: isCompact ? 18 : 20,
                    color: foregroundColor,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item.label,
                      key: ValueKey(item.keyName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: textStyles.navLabel.copyWith(
                        fontSize: isCompact ? 13 : 14,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: foregroundColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
