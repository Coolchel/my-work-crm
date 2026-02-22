import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../finance/presentation/screens/finance_screen.dart';
import '../../../projects/presentation/screens/project_list_screen.dart';
import '../../../settings/application/app_settings_controller.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../statistics/presentation/screens/statistics_screen.dart';
import '../../../welcome/presentation/screens/welcome_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _DestinationItem {
  final Widget screen;
  final NavigationDestination destination;

  const _DestinationItem({required this.screen, required this.destination});
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  int _lastNonSettingsIndex = 0;
  bool _temporarySettingsVisible = false;

  void _openSettingsFromWelcome(AppSettingsState settings) {
    setState(() {
      _lastNonSettingsIndex = _currentIndex;
      _temporarySettingsVisible = settings.showWelcome;
      final items = _buildDestinations(settings);
      _currentIndex = items.length - 1;
    });
  }

  void _closeSettingsTab(AppSettingsState settings) {
    setState(() {
      if (settings.showWelcome && _temporarySettingsVisible) {
        _temporarySettingsVisible = false;
      }
      final items = _buildDestinations(settings);
      _currentIndex = _lastNonSettingsIndex.clamp(0, items.length - 1);
    });
  }

  List<_DestinationItem> _buildDestinations(AppSettingsState settings) {
    final items = <_DestinationItem>[];

    if (settings.showWelcome) {
      items.add(
        _DestinationItem(
          screen: WelcomeScreen(
            onSettingsPressed: () => _openSettingsFromWelcome(settings),
          ),
          destination: const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Главная',
          ),
        ),
      );
    }

    items.add(
      const _DestinationItem(
        screen: ProjectListScreen(),
        destination: NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: 'Объекты',
        ),
      ),
    );

    items.addAll(
      const [
        _DestinationItem(
          screen: FinanceScreen(),
          destination: NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Финансы',
          ),
        ),
        _DestinationItem(
          screen: StatisticsScreen(),
          destination: NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Статистика',
          ),
        ),
      ],
    );

    if (!settings.showWelcome || _temporarySettingsVisible) {
      items.add(
        _DestinationItem(
          screen: SettingsScreen(
            onBackPressed: () => _closeSettingsTab(settings),
          ),
          destination: const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final items = _buildDestinations(settings);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_currentIndex >= items.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: items.map((e) => e.screen).toList(),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark
              ? scheme.surfaceContainerHigh
              : scheme.surface.withOpacity(0.98),
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withOpacity(isDark ? 0.55 : 0.4),
              width: 0.8,
            ),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            final settingsIndex =
                (!settings.showWelcome || _temporarySettingsVisible)
                    ? items.length - 1
                    : -1;

            setState(() {
              _currentIndex = index;
              if (index != settingsIndex) {
                _lastNonSettingsIndex = index;
                if (settings.showWelcome && _temporarySettingsVisible) {
                  _temporarySettingsVisible = false;
                }
              }
            });
          },
          destinations: items.map((e) => e.destination).toList(),
        ),
      ),
    );
  }
}
