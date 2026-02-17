import 'package:flutter/material.dart';

class AppDesignTokens {
  const AppDesignTokens._();

  // Base surfaces
  static const Color appBackground = Color(0xFFF7F8FB);
  static const Color appSurface = Colors.white;

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
}
