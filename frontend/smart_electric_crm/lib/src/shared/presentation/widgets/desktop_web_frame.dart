import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final class DesktopWebFrame {
  const DesktopWebFrame._();

  static bool isDesktop(BuildContext context, {double minWidth = 1100}) {
    return kIsWeb && MediaQuery.sizeOf(context).width >= minWidth;
  }

  static bool isWide(BuildContext context, {double minWidth = 1360}) {
    return kIsWeb && MediaQuery.sizeOf(context).width >= minWidth;
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
