import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';

import '../../../projects/data/models/project_model.dart';
import '../../../projects/presentation/search/project_search_texts.dart';
import '../../../projects/presentation/screens/project_detail_screen.dart';
import '../../../projects/presentation/widgets/project_search_result_tile.dart';

class SearchResultsOverlay extends ConsumerWidget {
  const SearchResultsOverlay({
    super.key,
    this.maxHeight = 400,
    required this.queryProvider,
    required this.resultsProvider,
  });

  static const int _maxVisibleItemsCap = 12;
  static const double _resultTileExtent = 58;
  static const double _separatorSpacing = 8;
  static const double _viewportEdgeInset = 10;
  static const double _itemOuterVerticalMargin = 2;
  static const double _listVerticalPadding = _viewportEdgeInset * 2;

  final double maxHeight;
  final StateProvider<String?> queryProvider;
  final FutureProvider<List<ProjectModel>> resultsProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(queryProvider);
    final projectsAsync = ref.watch(resultsProvider);

    if (searchQuery == null || searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppDesignTokens.softBorder(context)),
          boxShadow: [
            BoxShadow(
              color: AppDesignTokens.cardShadow(context),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: projectsAsync.when(
            data: (projects) {
              final scheme = Theme.of(context).colorScheme;

              if (projects.isEmpty) {
                return const FriendlyEmptyState(
                  icon: Icons.search_off_rounded,
                  title: ProjectSearchTexts.emptyTitle,
                  subtitle: ProjectSearchTexts.emptySubtitle,
                  accentColor: Colors.blueGrey,
                  iconSize: 62,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                );
              }

              const approximateItemHeight = _resultTileExtent +
                  (_itemOuterVerticalMargin * 2) +
                  _separatorSpacing;
              final calculatedVisibleItems =
                  ((maxHeight - _listVerticalPadding) / approximateItemHeight)
                      .floor()
                      .clamp(1, _maxVisibleItemsCap);
              final visibleItems =
                  math.min(projects.length, calculatedVisibleItems);
              final visibleSeparators = math.max(visibleItems - 1, 0);
              final desiredListHeight = (visibleItems * _resultTileExtent) +
                  (visibleItems * (_itemOuterVerticalMargin * 2)) +
                  (visibleSeparators * _separatorSpacing) +
                  _listVerticalPadding;
              final constrainedHeight =
                  math.min(desiredListHeight, maxHeight).toDouble();

              return SizedBox(
                height: constrainedHeight,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: _viewportEdgeInset),
                  child: ListView.separated(
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.zero,
                    itemCount: projects.length,
                    separatorBuilder: (context, index) => SizedBox(
                      height: _separatorSpacing,
                      child: Center(
                        child: Divider(height: 1, color: scheme.outlineVariant),
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return ProjectSearchResultTile(
                        project: project,
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
                  ),
                ),
              );
            },
            loading: () => const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Ошибка: $err',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
