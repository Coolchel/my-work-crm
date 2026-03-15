import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';

class AppDialogScrollbar extends StatefulWidget {
  final ScrollController? controller;
  final Widget? child;
  final Widget Function(ScrollController controller)? builder;

  const AppDialogScrollbar({
    super.key,
    this.controller,
    required this.child,
  }) : builder = null;

  const AppDialogScrollbar.builder({
    super.key,
    this.controller,
    required this.builder,
  }) : child = null;

  @override
  State<AppDialogScrollbar> createState() => _AppDialogScrollbarState();
}

class _AppDialogScrollbarState extends State<AppDialogScrollbar> {
  ScrollController? _internalController;

  ScrollController get _effectiveController {
    return widget.controller ?? (_internalController ??= ScrollController());
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _effectiveController;
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final thumbBaseColor = isDark
        ? scheme.onSurface.withOpacity(0.30)
        : scheme.primary.withOpacity(0.28);
    final thumbHoverColor = isDark
        ? scheme.primary.withOpacity(0.58)
        : scheme.primary.withOpacity(0.46);
    final thumbDragColor = isDark
        ? scheme.primary.withOpacity(0.74)
        : scheme.primary.withOpacity(0.60);
    final trackBaseColor = isDark
        ? Colors.white.withOpacity(0.04)
        : scheme.onSurface.withOpacity(0.03);
    final trackActiveColor = isDark
        ? Colors.white.withOpacity(0.08)
        : scheme.primary.withOpacity(0.08);

    return ScrollbarTheme(
      data: ScrollbarThemeData(
        interactive: true,
        radius: const Radius.circular(999),
        minThumbLength: 44,
        crossAxisMargin: 12,
        mainAxisMargin: 12,
        thickness: WidgetStateProperty.resolveWith<double?>((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.dragged)) {
            return 8;
          }
          return 6;
        }),
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.dragged)) {
            return thumbDragColor;
          }
          if (states.contains(WidgetState.hovered)) {
            return thumbHoverColor;
          }
          return thumbBaseColor;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.dragged)) {
            return trackActiveColor;
          }
          return trackBaseColor;
        }),
        trackBorderColor: const WidgetStatePropertyAll(Colors.transparent),
        thumbVisibility: const WidgetStatePropertyAll(true),
        trackVisibility: WidgetStateProperty.resolveWith<bool?>((states) {
          return states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.dragged);
        }),
      ),
      child: Scrollbar(
        controller: controller,
        child: widget.builder?.call(controller) ?? widget.child!,
      ),
    );
  }
}
