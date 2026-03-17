import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_electric_crm/src/core/navigation/app_navigation.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/desktop_web_frame.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';

import '../../../projects/data/models/project_model.dart';
import '../../../projects/presentation/providers/project_providers.dart';

class RecentProjectsList extends ConsumerWidget {
  const RecentProjectsList({super.key});

  bool _isMobileDevice() {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  Widget _buildListHeader(
    BuildContext context,
    String title, {
    VoidCallback? onClear,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;
    final showClear = onClear != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo.withOpacity(0.18),
                      Colors.teal.withOpacity(0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(
                  showClear ? Icons.tune_rounded : Icons.history_rounded,
                  size: 18,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: textStyles.sectionTitle.copyWith(
                    fontSize: 17,
                    color: scheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (showClear)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClear,
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo.withOpacity(0.50),
                    Colors.teal.withOpacity(0.22),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectListProvider);
    final filter = ref.watch(dashboardFilterProvider);

    return projectsAsync.when(
      data: (projects) {
        if (projects.isEmpty) {
          return const SizedBox.shrink();
        }

        List<ProjectModel> filteredProjects = List.from(projects);
        String listTitle = 'Недавние объекты';

        final now = DateTime.now();
        final currentMonth = now.month;
        final currentYear = now.year;

        if (filter != null) {
          switch (filter) {
            case 'pre_calc':
              listTitle = 'Предпросчеты (текущий месяц)';
              filteredProjects = projects.where((p) {
                return p.stages.any((s) =>
                    s.createdAt != null &&
                    s.createdAt!.year == currentYear &&
                    s.createdAt!.month == currentMonth &&
                    s.title.toLowerCase().contains('предпросчет'));
              }).toList();
              break;
            case 'active_objects':
              listTitle = 'Текущие объекты (активные)';
              filteredProjects = projects.where((p) {
                return p.stages.any((s) =>
                    s.createdAt != null &&
                    s.createdAt!.year == currentYear &&
                    s.createdAt!.month == currentMonth &&
                    !s.title.toLowerCase().contains('предпросчет'));
              }).toList();
              break;
            case 'paid':
              listTitle = 'Объекты с оплаченными этапами (текущий месяц)';
              filteredProjects = projects.where((p) {
                return p.stages.any((s) =>
                    s.isPaid &&
                    s.createdAt != null &&
                    s.createdAt!.year == currentYear &&
                    s.createdAt!.month == currentMonth);
              }).toList();
              break;
          }
        }

        filteredProjects.sort((a, b) {
          final dateA = a.updatedAt ?? a.createdAt;
          final dateB = b.updatedAt ?? b.createdAt;
          return dateB.compareTo(dateA);
        });

        final displayProjects = filter == null
            ? filteredProjects.take(5).toList()
            : filteredProjects;

        if (filter != null && displayProjects.isEmpty) {
          void clearFilter() {
            ref.read(dashboardFilterProvider.notifier).state = null;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildListHeader(
                context,
                listTitle,
                onClear: clearFilter,
              ),
              const SizedBox(height: 20),
              const FriendlyEmptyState(
                icon: Icons.filter_alt_off_rounded,
                title: 'Нет проектов по выбранному критерию',
                subtitle: 'Попробуйте другой фильтр или сбросьте текущий.',
                accentColor: Colors.blueGrey,
                iconSize: 58,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildListHeader(
              context,
              listTitle,
              onClear: filter != null
                  ? () =>
                      ref.read(dashboardFilterProvider.notifier).state = null
                  : null,
            ),
            SizedBox(height: _isMobileDevice() ? 6 : 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayProjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _RecentProjectTile(project: displayProjects[index]);
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _RecentProjectTile extends StatefulWidget {
  final ProjectModel project;

  const _RecentProjectTile({required this.project});

  @override
  State<_RecentProjectTile> createState() => _RecentProjectTileState();
}

class _RecentProjectTileState extends State<_RecentProjectTile> {
  bool _isHovered = false;
  static const double _tileMinHeight = 92;
  static const double _dateColumnWidth = 92;
  static const double _contentDateGap = 12;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Сегодня';
    if (diff.inDays == 1) return 'Вчера';
    if (diff.inDays < 7) return '${diff.inDays} дн. назад';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'new_building':
        return Icons.apartment;
      case 'secondary':
        return Icons.home;
      case 'cottage':
        return Icons.villa;
      case 'office':
        return Icons.business;
      default:
        return Icons.category;
    }
  }

  String? _buildClientLine(ProjectModel project) {
    final client = project.clientInfo.trim();
    if (client.isNotEmpty) {
      return client;
    }
    return null;
  }

  String? _buildIntercomLine(ProjectModel project) {
    final intercom = project.intercomCode.trim();
    if (intercom.isNotEmpty) {
      return 'Домофон: $intercom';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final lastActivity = project.updatedAt ?? project.createdAt;
    final isCompactMobileWeb = DesktopWebFrame.isMobileWeb(
      context,
      maxWidth: 480,
    );
    final isAndroidOrIos = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final hideClientLine = isCompactMobileWeb || isAndroidOrIos;
    final clientLine = _buildClientLine(project);
    final intercomLine = _buildIntercomLine(project);
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final textStyles = context.appTextStyles;
    final secondaryInfoStyle = textStyles.captionStrong.copyWith(
      fontSize: 12,
      color: scheme.onSurfaceVariant,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppDesignTokens.cardBackground(
            context,
            hovered: _isHovered,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppDesignTokens.cardBorder(
              context,
              hovered: _isHovered,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppDesignTokens.cardShadow(
                context,
                hovered: _isHovered,
              ),
              blurRadius: _isHovered ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              AppNavigation.openProject(
                context,
                projectId: project.id.toString(),
              );
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: isCompactMobileWeb ? 78 : _tileMinHeight,
              ),
              child: Padding(
                padding: EdgeInsets.all(isCompactMobileWeb ? 10 : 12),
                child: isCompactMobileWeb
                    ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.indigo.withOpacity(0.18)
                                        : Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getIcon(project.objectType),
                                    color: isDark
                                        ? Colors.indigo.shade200
                                        : Colors.indigo,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right:
                                            _dateColumnWidth + _contentDateGap,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              project.address,
                                              style:
                                                  textStyles.cardTitle.copyWith(
                                                fontSize: 14,
                                                color: scheme.onSurface,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (clientLine != null &&
                                                !hideClientLine) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                clientLine,
                                                style: secondaryInfoStyle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            if (intercomLine != null) ...[
                                              const SizedBox(height: 1),
                                              Text(
                                                intercomLine,
                                                style: secondaryInfoStyle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: SizedBox(
                                      width: _dateColumnWidth,
                                      child: Text(
                                        _formatDate(lastActivity),
                                        textAlign: TextAlign.right,
                                        style:
                                            textStyles.captionStrong.copyWith(
                                          fontSize: 11.5,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.indigo.withOpacity(0.18)
                                        : Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getIcon(project.objectType),
                                    color: isDark
                                        ? Colors.indigo.shade200
                                        : Colors.indigo,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right:
                                            _dateColumnWidth + _contentDateGap,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              project.address,
                                              style:
                                                  textStyles.cardTitle.copyWith(
                                                fontSize: 14,
                                                color: scheme.onSurface,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (clientLine != null &&
                                                !hideClientLine) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                clientLine,
                                                style: secondaryInfoStyle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            if (intercomLine != null) ...[
                                              const SizedBox(height: 1),
                                              Text(
                                                intercomLine,
                                                style: secondaryInfoStyle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: SizedBox(
                                      width: _dateColumnWidth,
                                      child: Text(
                                        _formatDate(lastActivity),
                                        textAlign: TextAlign.right,
                                        style:
                                            textStyles.captionStrong.copyWith(
                                          fontSize: 12,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
