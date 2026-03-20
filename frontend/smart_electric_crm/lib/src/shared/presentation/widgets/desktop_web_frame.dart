import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final class DesktopWebFrame {
  const DesktopWebFrame._();

  static const double mobileContentHorizontalPadding = 12;
  static const double shellSidebarBreakpoint = 1180;
  static const double shellSidebarWideBreakpoint = 1450;
  static const double shellSidebarLeftOffset = 16;
  static const double shellSidebarGap = 16;
  static const double shellSidebarWidth = 224;
  static const double shellSidebarCompactWidth = 88;

  static bool _isDesktopSurface() {
    if (kIsWeb) {
      return true;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.windows => true,
      _ => false,
    };
  }

  static bool isDesktop(BuildContext context, {double minWidth = 1100}) {
    return _isDesktopSurface() && MediaQuery.sizeOf(context).width >= minWidth;
  }

  static bool isWide(BuildContext context, {double minWidth = 1360}) {
    return _isDesktopSurface() && MediaQuery.sizeOf(context).width >= minWidth;
  }

  static bool isMobileWeb(BuildContext context, {double maxWidth = 700}) {
    return kIsWeb && MediaQuery.sizeOf(context).width < maxWidth;
  }

  static bool usesMobileContentPadding(
    BuildContext context, {
    double maxWidth = 700,
  }) {
    return isMobileWeb(context, maxWidth: maxWidth) ||
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);
  }

  static bool hasPersistentShellSidebar(
    BuildContext context, {
    double minWidth = shellSidebarBreakpoint,
  }) {
    final scope = _DesktopShellScope.maybeOf(context);
    if (scope != null) {
      return scope.hasSidebar;
    }
    return supportsPersistentShellSidebar(context, minWidth: minWidth);
  }

  static bool hasWideShellSidebar(BuildContext context) {
    final scope = _DesktopShellScope.maybeOf(context);
    if (scope != null) {
      return scope.isWideSidebar;
    }
    return supportsWideShellSidebar(context);
  }

  static bool supportsPersistentShellSidebar(
    BuildContext context, {
    double minWidth = shellSidebarBreakpoint,
  }) {
    return _isDesktopSurface() && MediaQuery.sizeOf(context).width >= minWidth;
  }

  static bool supportsWideShellSidebar(BuildContext context) {
    return _isDesktopSurface() &&
        MediaQuery.sizeOf(context).width >= shellSidebarWideBreakpoint;
  }

  static double persistentShellSidebarWidth(BuildContext context) {
    if (!hasPersistentShellSidebar(context)) {
      return 0;
    }
    return hasWideShellSidebar(context)
        ? shellSidebarWidth
        : shellSidebarCompactWidth;
  }

  static double persistentShellContentInset(BuildContext context) {
    if (!hasPersistentShellSidebar(context)) {
      return 0;
    }
    return shellSidebarLeftOffset +
        persistentShellSidebarWidth(context) +
        shellSidebarGap;
  }

  static double centeredContentSidePadding(
    double availableWidth, {
    required double maxWidth,
    double minPadding = 16,
  }) {
    final extraWidth = availableWidth - maxWidth;
    if (extraWidth <= 0) {
      return minPadding;
    }
    return minPadding + (extraWidth / 2);
  }

  static EdgeInsets pagePadding(
    BuildContext context, {
    double mobileHorizontal = 16,
    double desktopHorizontal = 28,
    double mobileVertical = 16,
    double desktopVertical = 24,
  }) {
    final isDesktopWeb = isDesktop(context);
    return EdgeInsets.symmetric(
      horizontal: isDesktopWeb ? desktopHorizontal : mobileHorizontal,
      vertical: isDesktopWeb ? desktopVertical : mobileVertical,
    );
  }

  static double contentHorizontalPadding(
    BuildContext context, {
    double mobile = mobileContentHorizontalPadding,
    double desktop = 16,
    double maxWidth = 700,
  }) {
    return usesMobileContentPadding(context, maxWidth: maxWidth)
        ? mobile
        : desktop;
  }
}

class DesktopShellScope extends InheritedWidget {
  const DesktopShellScope({
    required this.hasSidebar,
    required this.isWideSidebar,
    required super.child,
    super.key,
  });

  final bool hasSidebar;
  final bool isWideSidebar;

  static DesktopShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DesktopShellScope>();
  }

  @override
  bool updateShouldNotify(covariant DesktopShellScope oldWidget) {
    return hasSidebar != oldWidget.hasSidebar ||
        isWideSidebar != oldWidget.isWideSidebar;
  }
}

class DesktopWebPageFrame extends StatelessWidget {
  const DesktopWebPageFrame({
    required this.child,
    super.key,
    this.maxWidth = 1320,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );

    final paddedContent =
        padding == null ? content : Padding(padding: padding!, child: content);

    if (!DesktopWebFrame.isDesktop(context)) {
      return paddedContent;
    }

    return Align(
      alignment: alignment,
      child: paddedContent,
    );
  }
}

typedef _DesktopShellScope = DesktopShellScope;
