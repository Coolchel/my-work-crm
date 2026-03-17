import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';

class SectionAppBarCollapseController extends ChangeNotifier {
  SectionAppBarCollapseController({
    this.collapseDistance = CompactSectionAppBar.defaultCollapseDistance,
  });

  final double collapseDistance;

  ScrollController? _scrollController;
  double _progress = 0;

  double get progress => _progress;
  bool get isCollapsed => _progress >= 0.99;

  void bind(ScrollController? controller) {
    if (identical(_scrollController, controller)) {
      _syncFromScroll();
      return;
    }

    _scrollController?.removeListener(_handleScroll);
    _scrollController = controller;
    _scrollController?.addListener(_handleScroll);
    _syncFromScroll(notify: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromScroll());
  }

  void reset() {
    _setProgress(0);
  }

  void _handleScroll() {
    _syncFromScroll();
  }

  void _syncFromScroll({bool notify = true}) {
    final controller = _scrollController;
    if (controller == null || !controller.hasClients) {
      _setProgress(0, notify: notify);
      return;
    }

    final offset = controller.offset.clamp(0.0, collapseDistance);
    final nextProgress = collapseDistance <= 0
        ? 1.0
        : (offset / collapseDistance).clamp(0.0, 1.0);
    _setProgress(nextProgress, notify: notify);
  }

  void _setProgress(double nextProgress, {bool notify = true}) {
    if ((_progress - nextProgress).abs() < 0.001) {
      return;
    }
    _progress = nextProgress;
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_handleScroll);
    super.dispose();
  }
}

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
  final double collapsedBottomGap;
  final double collapseProgress;
  final double collapsedToolbarHeight;

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
    this.collapsedBottomGap = _collapsedBottomGap,
    this.collapseProgress = 0,
    this.collapsedToolbarHeight = _collapsedToolbarHeight,
  });

  static const double expandedToolbarHeight = 68;
  static const double defaultCollapseDistance = 72;
  static const double _collapsedToolbarHeight = 54;
  static const double _defaultBottomGap = 30;
  static const double _collapsedBottomGap = 0;

  static bool shouldUseCollapsibleLayout(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isNarrowViewport = size.width < 700 || size.shortestSide < 700;
    if (kIsWeb) {
      return isNarrowViewport;
    }
    return defaultTargetPlatform == TargetPlatform.android && isNarrowViewport;
  }

  static double resolveCollapseProgress(
    BuildContext context,
    double progress,
  ) {
    if (!shouldUseCollapsibleLayout(context)) {
      return 0;
    }
    return progress.clamp(0.0, 1.0);
  }

  double get _clampedCollapseProgress => collapseProgress.clamp(0.0, 1.0);
  double get _toolbarHeight => lerpDouble(
      expandedToolbarHeight, collapsedToolbarHeight, _clampedCollapseProgress)!;
  double get _effectiveBottomGap =>
      lerpDouble(bottomGap, collapsedBottomGap, _clampedCollapseProgress)!;
  double get _totalHeight => _toolbarHeight + _effectiveBottomGap;

  @override
  Size get preferredSize => Size.fromHeight(_totalHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textStyles = context.appTextStyles;
    final isDark = theme.brightness == Brightness.dark;
    final colors = gradientColors ??
        (isDark
            ? AppDesignTokens.subtleSectionGradientDark
            : AppDesignTokens.subtleSectionGradient);
    final foreground = isDark ? scheme.onSurface : Colors.white;
    final progress = _clampedCollapseProgress;
    final iconBadgeBackground = isDark
        ? scheme.surfaceContainerHighest.withOpacity(0.8)
        : Colors.white.withOpacity(0.16);
    final subtitleColor = isDark
        ? scheme.onSurface.withOpacity(0.72)
        : Colors.white.withOpacity(0.92);
    final badgeSize = lerpDouble(28, 20, progress)!;
    final badgeRadius = lerpDouble(9, 6, progress)!;
    final badgeIconSize = lerpDouble(17, 14, progress)!;
    final titleGap = lerpDouble(10, 6, progress)!;
    final subtitleOpacity =
        (1 - Curves.easeOut.transform((progress * 1.2).clamp(0.0, 1.0)))
            .clamp(0.0, 1.0);
    final titleSpacing = lerpDouble(2, 0, progress)!;
    final bottomRadius = lerpDouble(AppDesignTokens.radiusM, 10, progress)!;
    final titleTextStyle = (TextStyle.lerp(
              textStyles.pageTitle,
              textStyles.sectionTitle,
              progress,
            ) ??
            textStyles.pageTitle)
        .copyWith(color: foreground);
    final subtitleTextStyle = textStyles.secondaryBody.copyWith(
      color: subtitleColor,
    );

    return AppBar(
      automaticallyImplyLeading: leading == null,
      leading: leading,
      actions: actions,
      toolbarHeight: _totalHeight,
      centerTitle: centerTitle,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(bottomRadius),
          bottomRight: Radius.circular(bottomRadius),
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
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(bottomRadius),
                      bottomRight: Radius.circular(bottomRadius),
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
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(bottomRadius),
                      bottomRight: Radius.circular(bottomRadius),
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
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(bottomRadius),
                  bottomRight: Radius.circular(bottomRadius),
                ),
              ),
            ),
      iconTheme: IconThemeData(color: foreground),
      actionsIconTheme: IconThemeData(color: foreground),
      titleTextStyle: titleTextStyle,
      title: SizedBox(
        height: _totalHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: iconBadgeBackground,
                borderRadius: BorderRadius.circular(badgeRadius),
              ),
              child: Icon(icon, size: badgeIconSize),
            ),
            SizedBox(width: titleGap),
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
                    style: titleTextStyle,
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty)
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        heightFactor: subtitleOpacity,
                        child: Opacity(
                          opacity: subtitleOpacity,
                          child: Padding(
                            padding: EdgeInsets.only(top: titleSpacing),
                            child: Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: subtitleTextStyle,
                            ),
                          ),
                        ),
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
