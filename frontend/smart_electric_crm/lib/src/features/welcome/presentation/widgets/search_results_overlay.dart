import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';

import '../../../projects/data/models/project_model.dart';
import '../../../projects/presentation/providers/project_providers.dart';
import '../../../projects/presentation/screens/project_detail_screen.dart';

class SearchResultsOverlay extends ConsumerWidget {
  const SearchResultsOverlay({
    super.key,
    this.maxHeight = 400,
  });

  static const int _maxVisibleItems = 4;
  static const double _resultTileExtent = 58;
  static const double _separatorSpacing = 8;
  static const double _listVerticalPadding = 20;

  final double maxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(projectSearchQueryProvider);
    final projectsAsync = ref.watch(projectSearchResultsProvider);

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
                  title: 'Ничего не найдено',
                  subtitle: 'Попробуйте изменить запрос.',
                  accentColor: Colors.blueGrey,
                  iconSize: 62,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                );
              }

              final visibleItems = math.min(projects.length, _maxVisibleItems);
              final visibleSeparators = math.max(visibleItems - 1, 0);
              final desiredListHeight = (visibleItems * _resultTileExtent) +
                  (visibleSeparators * _separatorSpacing) +
                  _listVerticalPadding;
              final constrainedHeight =
                  math.min(desiredListHeight, maxHeight).toDouble();

              return SizedBox(
                height: constrainedHeight,
                child: ListView.separated(
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: projects.length,
                  separatorBuilder: (context, index) => SizedBox(
                    height: _separatorSpacing,
                    child: Center(
                      child: Divider(height: 1, color: scheme.outlineVariant),
                    ),
                  ),
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return _SearchResultItem(
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

class _SearchResultItem extends StatefulWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  const _SearchResultItem({
    required this.project,
    required this.onTap,
  });

  @override
  State<_SearchResultItem> createState() => _SearchResultItemState();
}

class _SearchResultItemState extends State<_SearchResultItem> {
  bool _isHovered = false;

  String _buildMetaLine(ProjectModel project) {
    final client = project.clientInfo.trim();
    final intercom = project.intercomCode.trim();

    if (client.isNotEmpty && intercom.isNotEmpty) {
      return '$client | Домофон: $intercom';
    }
    if (client.isNotEmpty) {
      return client;
    }
    if (intercom.isNotEmpty) {
      return 'Домофон: $intercom';
    }
    return 'Без данных';
  }

  @override
  Widget build(BuildContext context) {
    const hoverAccent = Color(0xFF2B88CF);
    final metaLine = _buildMetaLine(widget.project);
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppDesignTokens.hoverOverlay(context)
              : AppDesignTokens.cardBackground(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? AppDesignTokens.softBorder(context)
                : AppDesignTokens.cardBorder(context),
          ),
          boxShadow: [
            BoxShadow(
              color: AppDesignTokens.cardShadow(context, hovered: _isHovered),
              blurRadius: _isHovered ? 7 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SizedBox(
          height: SearchResultsOverlay._resultTileExtent,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _isHovered
                            ? AppDesignTokens.hoverOverlay(context)
                            : (AppDesignTokens.isDark(context)
                                ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHigh
                                : Colors.indigo.shade50),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.apartment,
                        size: 16,
                        color: Colors.indigo.shade400,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.project.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            metaLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.1,
                              color: onSurfaceVariant.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: _isHovered ? hoverAccent : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
