import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_navigation.dart';
import '../../../settings/application/app_settings_controller.dart';
import '../../../../shared/presentation/widgets/desktop_web_frame.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _DestinationItem {
  const _DestinationItem({
    required this.branchIndex,
    required this.destination,
    this.scrollController,
  });

  final int branchIndex;
  final NavigationDestination destination;
  final ScrollToTopController? scrollController;
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const int _homeBranchIndex = 0;
  static const int _projectsBranchIndex = 1;
  static const int _financeBranchIndex = 2;
  static const int _statisticsBranchIndex = 3;
  static const int _settingsBranchIndex = 4;
  static const double _defaultDesktopMenuTop = 132;
  static const double _welcomeDesktopMenuTop = 220;

  @override
  void initState() {
    super.initState();
    _syncLastNonSettingsBranch();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncLastNonSettingsBranch();
  }

  void _syncLastNonSettingsBranch() {
    final currentSection =
        _sectionForBranch(widget.navigationShell.currentIndex);
    AppNavigation.setLastNonSettingsSection(currentSection);
  }

  AppShellSection _sectionForBranch(int branchIndex) {
    return switch (branchIndex) {
      _homeBranchIndex => AppShellSection.home,
      _projectsBranchIndex => AppShellSection.projects,
      _financeBranchIndex => AppShellSection.finance,
      _statisticsBranchIndex => AppShellSection.statistics,
      _settingsBranchIndex => AppShellSection.settings,
      _ => AppShellSection.projects,
    };
  }

  bool _isSettingsBranchSelected() {
    return widget.navigationShell.currentIndex == _settingsBranchIndex;
  }

  bool _isHomeBranchSelected(AppSettingsState settings) {
    return settings.showWelcome &&
        widget.navigationShell.currentIndex == _homeBranchIndex;
  }

  List<_DestinationItem> _buildDestinations(AppSettingsState settings) {
    final items = <_DestinationItem>[];

    if (settings.showWelcome) {
      items.add(
        _DestinationItem(
          branchIndex: _homeBranchIndex,
          destination: const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Главная',
          ),
          scrollController: AppNavigation.homeScrollController,
        ),
      );
    }

    items.addAll([
      _DestinationItem(
        branchIndex: _projectsBranchIndex,
        destination: const NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: 'Объекты',
        ),
        scrollController: AppNavigation.objectsScrollController,
      ),
      _DestinationItem(
        branchIndex: _financeBranchIndex,
        destination: const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Финансы',
        ),
        scrollController: AppNavigation.financeScrollController,
      ),
      _DestinationItem(
        branchIndex: _statisticsBranchIndex,
        destination: const NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Статистика',
        ),
        scrollController: AppNavigation.statisticsScrollController,
      ),
    ]);

    if (!settings.showWelcome || _isSettingsBranchSelected()) {
      items.add(
        _DestinationItem(
          branchIndex: _settingsBranchIndex,
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

  int _selectedVisibleIndex(List<_DestinationItem> items) {
    final currentBranch = widget.navigationShell.currentIndex;
    final match = items.indexWhere((item) => item.branchIndex == currentBranch);
    return match == -1 ? 0 : match;
  }

  void _goToBranch(int branchIndex) {
    widget.navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == widget.navigationShell.currentIndex,
    );
    _syncLastNonSettingsBranch();
  }

  void _handleDestinationSelected(
    int index,
    AppSettingsState settings,
    List<_DestinationItem> items,
  ) {
    final item = items[index];
    if (item.branchIndex == widget.navigationShell.currentIndex) {
      item.scrollController?.scrollToTop();
      return;
    }

    if (item.branchIndex == _homeBranchIndex && settings.showWelcome) {
      AppNavigation.goHome(scrollToTop: true);
      return;
    }

    _goToBranch(item.branchIndex);
  }

  void _handleNativeBack(AppSettingsState settings) {
    final currentBranch = widget.navigationShell.currentIndex;
    if (currentBranch == _settingsBranchIndex) {
      context.go(
        AppNavigation.locationForShellSection(
          AppNavigation.lastNonSettingsSection == AppShellSection.home &&
                  !settings.showWelcome
              ? AppShellSection.projects
              : AppNavigation.lastNonSettingsSection,
        ),
      );
      return;
    }

    if (settings.showWelcome && currentBranch != _homeBranchIndex) {
      AppNavigation.goHome(scrollToTop: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _buildDestinations(settings);
    final selectedIndex = _selectedVisibleIndex(items);
    final isDesktopWeb = DesktopWebFrame.isDesktop(context, minWidth: 1180);
    final desktopMenuTop = _isHomeBranchSelected(settings)
        ? _welcomeDesktopMenuTop
        : _defaultDesktopMenuTop;

    final scaffold = Scaffold(
      body: isDesktopWeb
          ? Stack(
              children: [
                widget.navigationShell,
                Positioned(
                  left: 16,
                  top: desktopMenuTop,
                  bottom: 16,
                  child: SafeArea(
                    top: false,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.surfaceContainerHigh
                            : scheme.surface.withOpacity(0.98),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: scheme.outlineVariant
                              .withOpacity(isDark ? 0.5 : 0.35),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(isDark ? 0.22 : 0.05),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: 224,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 14,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < items.length; i++) ...[
                                _DesktopNavigationButton(
                                  label: items[i].destination.label,
                                  icon: items[i].destination.icon,
                                  selectedIcon:
                                      items[i].destination.selectedIcon,
                                  isSelected: i == selectedIndex,
                                  onTap: () => _handleDestinationSelected(
                                    i,
                                    settings,
                                    items,
                                  ),
                                ),
                                if (i < items.length - 1)
                                  const SizedBox(height: 6),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : widget.navigationShell,
      bottomNavigationBar: isDesktopWeb
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: isDark
                    ? scheme.surfaceContainerHigh
                    : scheme.surface.withOpacity(0.98),
                border: Border(
                  top: BorderSide(
                    color:
                        scheme.outlineVariant.withOpacity(isDark ? 0.55 : 0.4),
                    width: 0.8,
                  ),
                ),
              ),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) =>
                    _handleDestinationSelected(index, settings, items),
                destinations: items.map((item) => item.destination).toList(),
              ),
            ),
    );

    if (kIsWeb) {
      return scaffold;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleNativeBack(settings);
      },
      child: scaffold,
    );
  }
}

class _DesktopNavigationButton extends StatefulWidget {
  const _DesktopNavigationButton({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final Widget? selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_DesktopNavigationButton> createState() =>
      _DesktopNavigationButtonState();
}

class _DesktopNavigationButtonState extends State<_DesktopNavigationButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = widget.isSelected;
    final backgroundColor = isActive
        ? scheme.primary.withOpacity(isDark ? 0.24 : 0.12)
        : _isHovered
            ? scheme.primary.withOpacity(isDark ? 0.12 : 0.07)
            : Colors.transparent;
    final borderColor = isActive
        ? scheme.primary.withOpacity(isDark ? 0.38 : 0.20)
        : _isHovered
            ? scheme.outlineVariant.withOpacity(isDark ? 0.36 : 0.28)
            : Colors.transparent;
    final foregroundColor = isActive
        ? scheme.primary
        : _isHovered
            ? scheme.onSurface
            : scheme.onSurfaceVariant;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                IconTheme(
                  data: IconThemeData(
                    size: 24,
                    color: foregroundColor,
                  ),
                  child: widget.isSelected
                      ? (widget.selectedIcon ?? widget.icon)
                      : widget.icon,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: foregroundColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
