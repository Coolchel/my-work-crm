import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_navigation.dart';
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
  final ScrollToTopController? scrollController;

  const _DestinationItem({
    required this.screen,
    required this.destination,
    this.scrollController,
  });
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  int _lastNonSettingsIndex = 0;
  bool _temporarySettingsVisible = false;

  @override
  void initState() {
    super.initState();
    AppNavigation.registerHomeTabHandler(_handleExternalHomeRequest);
  }

  @override
  void dispose() {
    AppNavigation.unregisterHomeTabHandler(_handleExternalHomeRequest);
    super.dispose();
  }

  void _handleSettingsBack(AppSettingsState settings) {
    _closeSettingsTab(settings);
  }

  void _handleExternalHomeRequest() {
    if (!mounted) {
      return;
    }
    final settings = ref.read(appSettingsProvider);
    _selectHomeTab(settings, scrollToTop: false);
  }

  bool _isSettingsTabSelected(AppSettingsState settings, int itemCount) {
    if (itemCount == 0) {
      return false;
    }

    final settingsIndex = (!settings.showWelcome || _temporarySettingsVisible)
        ? itemCount - 1
        : -1;
    return settingsIndex != -1 && _currentIndex == settingsIndex;
  }

  bool _canReturnToHome(AppSettingsState settings) {
    return settings.showWelcome && _currentIndex != 0;
  }

  void _handleSectionBack(AppSettingsState settings, int itemCount) {
    if (_canReturnToHome(settings)) {
      _selectHomeTab(settings, scrollToTop: false);
      return;
    }

    if (_isSettingsTabSelected(settings, itemCount)) {
      _handleSettingsBack(settings);
    }
  }

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

  Future<void> _scrollHomeToTop() {
    return AppNavigation.homeScrollController.scrollToTop();
  }

  void _selectHomeTab(
    AppSettingsState settings, {
    required bool scrollToTop,
  }) {
    if (!settings.showWelcome) {
      return;
    }

    setState(() {
      _currentIndex = 0;
      _lastNonSettingsIndex = 0;
      if (_temporarySettingsVisible) {
        _temporarySettingsVisible = false;
      }
    });

    if (!scrollToTop) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scrollHomeToTop();
    });
  }

  void _handleDestinationSelected(
    int index,
    AppSettingsState settings,
    List<_DestinationItem> items,
  ) {
    if (index == _currentIndex) {
      items[index].scrollController?.scrollToTop();
      return;
    }

    if (settings.showWelcome && index == 0) {
      _selectHomeTab(settings, scrollToTop: true);
      return;
    }

    final itemCount = items.length;
    final settingsIndex = (!settings.showWelcome || _temporarySettingsVisible)
        ? itemCount - 1
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
  }

  List<_DestinationItem> _buildDestinations(AppSettingsState settings) {
    final items = <_DestinationItem>[];

    if (settings.showWelcome) {
      items.add(
        _DestinationItem(
          screen: WelcomeScreen(
            onSettingsPressed: () => _openSettingsFromWelcome(settings),
            scrollController: AppNavigation.homeScrollController,
          ),
          destination: const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Главная',
          ),
          scrollController: AppNavigation.homeScrollController,
        ),
      );
    }

    items.add(
      _DestinationItem(
        screen: ProjectListScreen(
          onBackPressed: () => _handleSectionBack(settings, items.length),
        ),
        destination: const NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: 'Объекты',
        ),
        scrollController: AppNavigation.objectsScrollController,
      ),
    );

    items.addAll([
      _DestinationItem(
        screen: FinanceScreen(
          onBackPressed: () => _handleSectionBack(settings, items.length),
        ),
        destination: const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Финансы',
        ),
        scrollController: AppNavigation.financeScrollController,
      ),
      _DestinationItem(
        screen: StatisticsScreen(
          onBackPressed: () => _handleSectionBack(settings, items.length),
        ),
        destination: const NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Статистика',
        ),
        scrollController: AppNavigation.statisticsScrollController,
      ),
    ]);

    if (!settings.showWelcome || _temporarySettingsVisible) {
      items.add(
        _DestinationItem(
          screen: SettingsScreen(
            onBackPressed: () => _handleSectionBack(settings, items.length),
          ),
          destination: const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Настройки',
          ),
          scrollController: AppNavigation.settingsScrollController,
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleSectionBack(settings, items.length);
      },
      child: Scaffold(
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
            onDestinationSelected: (index) =>
                _handleDestinationSelected(index, settings, items),
            destinations: items.map((e) => e.destination).toList(),
          ),
        ),
      ),
    );
  }
}
