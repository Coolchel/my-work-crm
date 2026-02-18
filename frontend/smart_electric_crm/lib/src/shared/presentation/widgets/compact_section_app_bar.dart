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

  @override
  Size get preferredSize => Size.fromHeight(_toolbarHeight + bottomGap);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = gradientColors ??
        (isDark
            ? AppDesignTokens.subtleSectionGradientDark
            : AppDesignTokens.subtleSectionGradient);
    final foreground = Colors.white;
    final iconBadgeBackground = Colors.white.withOpacity(isDark ? 0.2 : 0.16);
    final subtitleColor = Colors.white.withOpacity(isDark ? 0.95 : 0.92);

    return AppBar(
      automaticallyImplyLeading: leading == null,
      leading: leading,
      actions: actions,
      toolbarHeight: _toolbarHeight,
      centerTitle: centerTitle,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: foreground,
      flexibleSpace: Container(
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
      title: Row(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
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
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(bottomGap),
        child: SizedBox(height: bottomGap),
      ),
    );
  }
}
