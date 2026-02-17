import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../projects/data/models/project_model.dart';
import '../../../projects/presentation/providers/project_providers.dart';
import '../../../projects/presentation/screens/project_detail_screen.dart';

class RecentProjectsList extends ConsumerWidget {
  const RecentProjectsList({super.key});

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
                // Ищем проекты, где есть этапы за этот месяц, НЕ являющиеся предпросчетами
                return p.stages.any((s) =>
                    s.createdAt != null &&
                    s.createdAt!.year == currentYear &&
                    s.createdAt!.month == currentMonth &&
                    !s.title.toLowerCase().contains('предпросчет'));
              }).toList();
              // ТЗ: "считаеться каждый объект, у которого в текущем месяце был добавлен новый этап, за исключением этапа предпросчет"
              break;
            case 'paid':
              listTitle = 'Объекты с оплаченными этапами (тек. месяц)';
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

        // Sort by updated_at (or created_at) DESC
        filteredProjects.sort((a, b) {
          final dateA = a.updatedAt ?? a.createdAt;
          final dateB = b.updatedAt ?? b.createdAt;
          return dateB.compareTo(dateA);
        });

        // Если фильтр не активен - берем топ 5, иначе показываем все (или больше)
        final displayProjects = filter == null
            ? filteredProjects.take(5).toList()
            : filteredProjects;

        if (filter != null && displayProjects.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Text(
                      listTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => ref
                          .read(dashboardFilterProvider.notifier)
                          .state = null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Center(child: Text("Нет проектов по выбранному критерию")),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    listTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  if (filter != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => ref
                          .read(dashboardFilterProvider.notifier)
                          .state = null,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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

class _RecentProjectTile extends StatelessWidget {
  final ProjectModel project;

  const _RecentProjectTile({required this.project});

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

  @override
  Widget build(BuildContext context) {
    final project = this.project;
    final lastActivity = project.updatedAt ?? project.createdAt;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIcon(project.objectType),
                    color: Colors.indigo,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.address,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (project.clientInfo.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            project.clientInfo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(lastActivity),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
