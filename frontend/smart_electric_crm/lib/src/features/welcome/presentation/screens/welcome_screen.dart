import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../projects/presentation/providers/project_providers.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../widgets/new_project_card.dart';
import '../widgets/quick_stats_row.dart';
import '../widgets/recent_projects_list.dart';
import '../widgets/search_results_overlay.dart';
import '../widgets/smart_search_bar.dart';
import '../widgets/welcome_header.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final LayerLink _layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    final selectedStat = ref.watch(dashboardFilterProvider);
    final searchQuery = ref.watch(projectSearchQueryProvider);
    final isSearchActive = searchQuery != null && searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                WelcomeHeader(
                  onSettingsPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        QuickStatsRow(
                          selectedStat: selectedStat,
                          onStatSelected: (stat) {
                            ref.read(dashboardFilterProvider.notifier).state =
                                stat;
                          },
                        ),
                        const SizedBox(height: 24),
                        CompositedTransformTarget(
                          link: _layerLink,
                          child: const SmartSearchBar(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (!isSearchActive)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: NewProjectCard(),
                  ),
                const SizedBox(height: 24),
                if (!isSearchActive)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: RecentProjectsList(),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          if (isSearchActive)
            Positioned.fill(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      ref.read(projectSearchQueryProvider.notifier).state =
                          null;
                      FocusScope.of(context).unfocus();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(color: Colors.transparent),
                  ),
                  CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    offset: const Offset(0, 60),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        child: const SearchResultsOverlay(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
