import 'package:flutter/material.dart';

class AppDesignTokens {
  const AppDesignTokens._();

  // Base surfaces
  static const Color appBackground = Color(0xFFF7F8FB);
  static const Color appSurface = Colors.white;
  static const Color appBackgroundDark = Color(0xFF0E0E10);
  static const Color appSurfaceDark = Color(0xFF17181B);
  static const Color appSurfaceElevatedDark = Color(0xFF1E2024);

  // Shape
  static const double radiusM = 16;
  static const double radiusL = 24;

  // Spacing
  static const double spacingM = 16;
  static const double spacingL = 24;

  // Elevation and shadows
  static const double elevationSoft = 1;
  static const double elevationCard = 2;
  static const Color softShadowColor = Color(0x1A000000);
  static const Color cardShadowColor = Color(0x14000000);
  static const Color softShadowColorDark = Color(0x5A000000);
  static const Color cardShadowColorDark = Color(0x45000000);

  // Navigation
  static const double navBarHeight = 70;
  static const double navIconSize = 22;
  static const EdgeInsets navIndicatorPadding =
      EdgeInsets.symmetric(horizontal: 10, vertical: 8);

  // Shared subtle section gradient (for non-home primary tabs)
  static const List<Color> subtleSectionGradient = <Color>[
    Color(0xFF4558B8),
    Color(0xFF2B88CF),
  ];
  static const List<Color> subtleSectionGradientDark = <Color>[
    Color(0xFF1E2734),
    Color(0xFF202F42),
  ];

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color cardBackground(BuildContext context, {bool hovered = false}) {
    if (isDark(context)) {
      return hovered ? const Color(0xFF21242A) : surface1(context);
    }
    return hovered ? const Color(0xFFEFF3F9) : surface1(context);
  }

  static Color cardBorder(BuildContext context, {bool hovered = false}) {
    if (isDark(context)) {
      // Dark theme: keep border stable across hover states to avoid flicker/jitter.
      return softBorder(context);
    }
    return hovered ? const Color(0xFFCDD6E3) : const Color(0xFFE7EAF1);
  }

  static Color cardShadow(BuildContext context, {bool hovered = false}) {
    if (isDark(context)) {
      return Colors.black.withOpacity(hovered ? 0.45 : 0.30);
    }
    return Colors.black.withOpacity(hovered ? 0.10 : 0.04);
  }

  static Color surface1(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return isDark(context) ? scheme.surface : scheme.surface;
  }

  static Color surface2(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return isDark(context)
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainer.withOpacity(0.55);
  }

  static Color surface3(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return isDark(context)
        ? scheme.surfaceContainerHighest
        : scheme.surfaceContainerHigh.withOpacity(0.65);
  }

  static Color softBorder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return isDark(context)
        ? Colors.white.withOpacity(0.12)
        : scheme.outlineVariant.withOpacity(0.85);
  }

  static Color hoverOverlay(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.primary.withOpacity(isDark(context) ? 0.10 : 0.06);
  }

  static Color pressedOverlay(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.primary.withOpacity(isDark(context) ? 0.14 : 0.10);
  }
}
