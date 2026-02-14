import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsState {
  final ThemeMode themeMode;
  final bool showCatalog;
  final bool showWelcome;
  final bool isLoaded;

  const AppSettingsState({
    required this.themeMode,
    required this.showCatalog,
    required this.showWelcome,
    required this.isLoaded,
  });

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    bool? showCatalog,
    bool? showWelcome,
    bool? isLoaded,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      showCatalog: showCatalog ?? this.showCatalog,
      showWelcome: showWelcome ?? this.showWelcome,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  static const _themeKey = 'app_theme_mode';
  static const _showCatalogKey = 'show_catalog_menu';
  static const _showWelcomeKey = 'show_welcome_screen';

  AppSettingsNotifier()
      : super(const AppSettingsState(
          themeMode: ThemeMode.system,
          showCatalog: true,
          showWelcome: true,
          isLoaded: false,
        )) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;

    state = state.copyWith(
      themeMode: ThemeMode.values[themeIndex],
      showCatalog: prefs.getBool(_showCatalogKey) ?? true,
      showWelcome: prefs.getBool(_showWelcomeKey) ?? true,
      isLoaded: true,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> setShowCatalog(bool value) async {
    state = state.copyWith(showCatalog: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showCatalogKey, value);
  }

  Future<void> setShowWelcome(bool value) async {
    state = state.copyWith(showWelcome: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showWelcomeKey, value);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>(
  (ref) => AppSettingsNotifier(),
);
