import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/presentation/providers/project_providers.dart';
import '../widgets/welcome_header.dart';
import '../widgets/quick_stats_row.dart';
import '../widgets/new_project_card.dart';
import '../widgets/recent_projects_list.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the filter provider
    final selectedStat = ref.watch(dashboardFilterProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const WelcomeHeader(),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: QuickStatsRow(
                  selectedStat: selectedStat,
                  onStatSelected: (stat) {
                    // Update provider state
                    ref.read(dashboardFilterProvider.notifier).state = stat;
                  },
                ),
              ),
            ),
            const SizedBox(height: 0),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: NewProjectCard(),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: RecentProjectsList(),
            ),
            const SizedBox(height: 100), // Bottom padding for navigation bar
          ],
        ),
      ),
    );
  }
}
