import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';

import '../../../projects/data/models/project_model.dart';
import '../../../projects/presentation/screens/project_detail_screen.dart';
import '../../../projects/presentation/search/project_search_texts.dart';
import '../../../projects/presentation/widgets/project_search_result_tile.dart';

class SearchResultsOverlay extends ConsumerWidget {
  const SearchResultsOverlay({
    super.key,
    this.maxHeight = 400,
    required this.queryProvider,
    required this.resultsProvider,
    this.inline = false,
    this.matchSearchWidth = false,
  });

  final double maxHeight;
  final StateProvider<String?> queryProvider;
  final FutureProvider<List<ProjectModel>> resultsProvider;
  final bool inline;
  final bool matchSearchWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(queryProvider);
    final projectsAsync = ref.watch(resultsProvider);

    if (searchQuery == null || searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SizedBox(
        height: maxHeight,
        child: projectsAsync.when(
          data: (projects) {
            if (projects.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  matchSearchWidth ? 0 : 16,
                  16,
                  matchSearchWidth ? 0 : 16,
                  120,
                ),
                children: const [
                  FriendlyEmptyState(
                    icon: Icons.search_off_rounded,
                    title: ProjectSearchTexts.emptyTitle,
                    subtitle: ProjectSearchTexts.emptySubtitle,
                    accentColor: Colors.blueGrey,
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: EdgeInsets.fromLTRB(
                matchSearchWidth ? 0 : 16,
                16,
                matchSearchWidth ? 0 : 16,
                120,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: projects.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final project = projects[index];
                return ProjectSearchResultTile(
                  project: project,
                  margin: EdgeInsets.symmetric(
                    horizontal: matchSearchWidth ? 0 : 8,
                    vertical: 2,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectDetailScreen(
                          projectId: project.id.toString(),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              matchSearchWidth ? 0 : 16,
              16,
              matchSearchWidth ? 0 : 16,
              120,
            ),
            children: [
              FriendlyEmptyState(
                icon: Icons.error_outline,
                title: 'Не удалось выполнить поиск',
                subtitle: '$error',
                accentColor: Colors.redAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
