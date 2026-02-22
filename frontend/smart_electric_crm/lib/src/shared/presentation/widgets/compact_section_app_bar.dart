import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';

class CompactSectionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final List<Color>? gradientColors;
  final double bottomGap;

  const CompactSectionAppBar({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.leading,
    this.actions,
    this.centerTitle = false,
    this.gradientColors,
    this.bottomGap = _defaultBottomGap,
  });

  static const double _toolbarHeight = 68;
  static const double _defaultBottomGap = 30;
  double get _totalHeight => _toolbarHeight + bottomGap;

  @override
  Size get preferredSize => Size.fromHeight(_totalHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = gradientColors ??
        (isDark
            ? AppDesignTokens.subtleSectionGradientDark
            : AppDesignTokens.subtleSectionGradient);
    final foreground = isDark ? scheme.onSurface : Colors.white;
    final iconBadgeBackground = isDark
        ? scheme.surfaceContainerHighest.withOpacity(0.8)
        : Colors.white.withOpacity(0.16);
    final subtitleColor = isDark
        ? scheme.onSurface.withOpacity(0.72)
        : Colors.white.withOpacity(0.92);

    return AppBar(
      automaticallyImplyLeading: leading == null,
      leading: leading,
      actions: actions,
      toolbarHeight: _totalHeight,
      centerTitle: centerTitle,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppDesignTokens.radiusM),
          bottomRight: Radius.circular(AppDesignTokens.radiusM),
        ),
      ),
      backgroundColor: isDark ? scheme.surface : Colors.transparent,
      foregroundColor: foreground,
      flexibleSpace: isDark
          ? Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppDesignTokens.radiusM),
                      bottomRight: Radius.circular(AppDesignTokens.radiusM),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primary.withOpacity(0.08),
                        scheme.primary.withOpacity(0.03),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppDesignTokens.radiusM),
                      bottomRight: Radius.circular(AppDesignTokens.radiusM),
                    ),
                  ),
                ),
              ],
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppDesignTokens.radiusM),
                  bottomRight: Radius.circular(AppDesignTokens.radiusM),
                ),
              ),
            ),
      iconTheme: IconThemeData(color: foreground),
      actionsIconTheme: IconThemeData(color: foreground),
      titleTextStyle: TextStyle(
        color: foreground,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      title: SizedBox(
        height: _totalHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconBadgeBackground,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      height: 1.1,
                    ),
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                        fontWeight: FontWeight.w400,
                        height: 1.1,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
