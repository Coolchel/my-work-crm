import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_tokens.dart';

class ShieldTypePresentation {
  const ShieldTypePresentation({
    required this.type,
    required this.label,
    required this.icon,
    required this.accent,
  });

  final String type;
  final String label;
  final IconData icon;
  final Color accent;
}

class ShieldUiPalette {
  const ShieldUiPalette._();

  static const Color _powerAccent = Color(0xFF8A6A42);
  static const Color _ledAccent = Color(0xFF5F6F9D);
  static const Color _multimediaAccent = Color(0xFF4E7A73);
  static const Color _defaultAccent = Color(0xFF5F6B7A);

  static ShieldTypePresentation resolveShield(String type) {
    switch (type) {
      case 'power':
        return const ShieldTypePresentation(
          type: 'power',
          label: 'Силовой',
          icon: Icons.bolt_rounded,
          accent: _powerAccent,
        );
      case 'led':
        return const ShieldTypePresentation(
          type: 'led',
          label: 'LED',
          icon: Icons.lightbulb_rounded,
          accent: _ledAccent,
        );
      case 'multimedia':
        return const ShieldTypePresentation(
          type: 'multimedia',
          label: 'Слаботочный щит',
          icon: Icons.router_rounded,
          accent: _multimediaAccent,
        );
      default:
        return ShieldTypePresentation(
          type: type,
          label: type,
          icon: Icons.wb_iridescent_rounded,
          accent: _defaultAccent,
        );
    }
  }

  static Color resolvePowerDeviceAccent(String type) {
    switch (type) {
      case 'load_switch':
        return const Color(0xFF98635D);
      case 'rcd':
        return const Color(0xFF9A7A45);
      case 'circuit_breaker':
        return const Color(0xFF58749B);
      case 'diff_breaker':
        return const Color(0xFF72668F);
      case 'relay':
        return const Color(0xFF537A74);
      case 'contactor':
        return const Color(0xFF8A6A46);
      default:
        return const Color(0xFF617487);
    }
  }

  static Color blendAccentSurface(
    BuildContext context,
    Color accent, {
    Color? baseColor,
    double lightOpacity = 0.05,
    double darkOpacity = 0.14,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final base = baseColor ??
        (AppDesignTokens.isDark(context)
            ? scheme.surfaceContainer
            : scheme.surface);
    return Color.alphaBlend(
      accent.withOpacity(
        AppDesignTokens.isDark(context) ? darkOpacity : lightOpacity,
      ),
      base,
    );
  }

  static Color blendAccentBorder(
    BuildContext context,
    Color accent, {
    double lightOpacity = 0.15,
    double darkOpacity = 0.28,
  }) {
    return accent.withOpacity(
      AppDesignTokens.isDark(context) ? darkOpacity : lightOpacity,
    );
  }

  static Color neutralFieldBorder(BuildContext context) {
    return AppDesignTokens.softBorder(context);
  }

  static Color primaryActionBackground(BuildContext context, Color accent) {
    final scheme = Theme.of(context).colorScheme;
    return blendAccentSurface(
      context,
      accent,
      baseColor: AppDesignTokens.isDark(context)
          ? scheme.surfaceContainerHigh
          : scheme.surface,
      lightOpacity: 0.12,
      darkOpacity: 0.24,
    );
  }

  static Color primaryActionForeground(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }
}
