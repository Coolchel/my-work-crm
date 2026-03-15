import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final class DesktopWebFrame {
  const DesktopWebFrame._();

  static const double shellSidebarBreakpoint = 1180;
  static const double shellSidebarWideBreakpoint = 1450;
  static const double shellSidebarLeftOffset = 16;
  static const double shellSidebarGap = 16;
  static const double shellSidebarWidth = 224;
  static const double shellSidebarCompactWidth = 88;

  static bool isDesktop(BuildContext context, {double minWidth = 1100}) {
    return kIsWeb && MediaQuery.sizeOf(context).width >= minWidth;
  }

  static bool isWide(BuildContext context, {double minWidth = 1360}) {
    return kIsWeb && MediaQuery.sizeOf(context).width >= minWidth;
  }

  static bool isMobileWeb(BuildContext context, {double maxWidth = 700}) {
    return kIsWeb && MediaQuery.sizeOf(context).width < maxWidth;
  }

  static bool hasPersistentShellSidebar(
    BuildContext context, {
    double minWidth = shellSidebarBreakpoint,
  }) {
    return kIsWeb && MediaQuery.sizeOf(context).width >= minWidth;
  }

  static bool hasWideShellSidebar(BuildContext context) {
    return kIsWeb &&
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
