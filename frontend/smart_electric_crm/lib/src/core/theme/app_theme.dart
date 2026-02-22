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
      outline: const Color(0x24FFFFFF),
      outlineVariant: const Color(0x1FFFFFFF),
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
    final isDark = scheme.brightness == Brightness.dark;
    final bodyColor =
        isDark ? scheme.onSurface.withOpacity(0.76) : scheme.onSurface;
    final secondaryColor =
        isDark ? scheme.onSurface.withOpacity(0.62) : scheme.onSurfaceVariant;
    final hoverOverlayColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.045);
    final highlightOverlayColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.035);

    final textTheme = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
    ).textTheme.copyWith(
          headlineSmall: TextStyle(
            color:
                isDark ? scheme.onSurface.withOpacity(0.92) : scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            color:
                isDark ? scheme.onSurface.withOpacity(0.90) : scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color:
                isDark ? scheme.onSurface.withOpacity(0.88) : scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: bodyColor),
          bodyMedium: TextStyle(color: bodyColor),
          bodySmall: TextStyle(color: secondaryColor),
          labelLarge: TextStyle(
            color:
                isDark ? scheme.onSurface.withOpacity(0.88) : scheme.onSurface,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scaffoldBackground,
      dividerColor: scheme.outlineVariant,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
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
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
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
        backgroundColor: isDark ? scheme.surfaceContainerHigh : scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusL),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            isDark ? scheme.surfaceContainerHigh : scheme.surface,
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          side: WidgetStatePropertyAll(
            BorderSide(
                color: scheme.outlineVariant.withOpacity(isDark ? 0.55 : 0.85)),
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: isDark
              ? scheme.surfaceContainerHigh
              : scheme.surfaceContainer.withOpacity(0.45),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: scheme.outlineVariant.withOpacity(isDark ? 0.55 : 0.85)),
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            isDark ? scheme.surfaceContainerHigh : scheme.surface,
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withOpacity(isDark ? 0.55 : 0.85),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainer.withOpacity(0.45),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withOpacity(isDark ? 0.55 : 0.85),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withOpacity(isDark ? 0.55 : 0.85),
          ),
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
      splashColor: highlightOverlayColor,
      highlightColor: highlightOverlayColor,
      hoverColor: hoverOverlayColor,
    );
  }
}
