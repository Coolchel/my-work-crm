import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../finance/presentation/screens/finance_screen.dart';
import '../../../projects/presentation/screens/project_list_screen.dart';
import '../../../settings/application/app_settings_controller.dart';
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

  List<_DestinationItem> _buildDestinations(AppSettingsState settings) {
    final items = <_DestinationItem>[];

    if (settings.showWelcome) {
      items.add(
        const _DestinationItem(
          screen: WelcomeScreen(),
          destination: NavigationDestination(
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

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final items = _buildDestinations(settings);

    if (_currentIndex >= items.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: items.map((e) => e.screen).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: items.map((e) => e.destination).toList(),
      ),
    );
  }
}
