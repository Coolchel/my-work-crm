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
    final scheme = Theme.of(context).colorScheme;
    if (isDark(context)) {
      return hovered ? const Color(0xFF21242A) : scheme.surface;
    }
    return hovered ? const Color(0xFFF6F7FB) : scheme.surface;
  }

  static Color cardBorder(BuildContext context, {bool hovered = false}) {
    final scheme = Theme.of(context).colorScheme;
    if (isDark(context)) {
      return hovered ? const Color(0xFF454A53) : scheme.outlineVariant;
    }
    return hovered ? const Color(0xFFD9DEE8) : const Color(0xFFE7EAF1);
  }

  static Color cardShadow(BuildContext context, {bool hovered = false}) {
    if (isDark(context)) {
      return Colors.black.withOpacity(hovered ? 0.45 : 0.30);
    }
    return Colors.black.withOpacity(hovered ? 0.08 : 0.04);
  }
}
