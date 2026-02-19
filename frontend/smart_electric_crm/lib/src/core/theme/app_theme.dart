import 'package:flutter/material.dart';

import 'app_design_tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
      background: AppDesignTokens.appBackground,
      surface: AppDesignTokens.appSurface,
      surfaceTint: Colors.transparent,
    );

    return _buildTheme(
      scheme: scheme,
      scaffoldBackground: AppDesignTokens.appBackground,
      cardShadow: AppDesignTokens.cardShadowColor,
      navIndicator: Colors.indigo.withOpacity(0.14),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
      background: AppDesignTokens.appBackgroundDark,
      surface: AppDesignTokens.appSurfaceDark,
      surfaceTint: Colors.transparent,
    ).copyWith(
      surfaceContainer: const Color(0xFF1F2126),
      surfaceContainerHigh: const Color(0xFF272A30),
      surfaceContainerHighest: const Color(0xFF2F333B),
      outline: const Color(0xFF5B606B),
      outlineVariant: const Color(0xFF3A3E46),
      onSurfaceVariant: const Color(0xFFB9BDC7),
    );

    return _buildTheme(
      scheme: scheme,
      scaffoldBackground: AppDesignTokens.appBackgroundDark,
      cardShadow: AppDesignTokens.cardShadowColorDark,
      navIndicator: const Color(0xFF30343D),
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme scheme,
    required Color scaffoldBackground,
    required Color cardShadow,
    required Color navIndicator,
  }) {
    final selectedNavColor = scheme.primary;
    final unselectedNavColor = scheme.onSurfaceVariant;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      dividerColor: scheme.outlineVariant,
      navigationBarTheme: NavigationBarThemeData(
        height: AppDesignTokens.navBarHeight,
        backgroundColor: scheme.surface,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusM),
        ),
        indicatorColor: navIndicator,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? selectedNavColor : unselectedNavColor,
            size: AppDesignTokens.navIconSize,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            color: isSelected ? selectedNavColor : unselectedNavColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: AppDesignTokens.elevationSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusM),
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: cardShadow,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusL),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer.withOpacity(0.45),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
