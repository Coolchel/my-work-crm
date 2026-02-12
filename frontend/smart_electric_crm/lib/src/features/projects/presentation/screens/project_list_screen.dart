import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/project_providers.dart';
import '../../data/models/project_model.dart';
import 'project_detail_screen.dart';
import 'add_project_screen.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectListAsync = ref.watch(projectListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои Объекты'),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProjectScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Инвалидируем провайдер для перезагрузки списка
          return ref.refresh(projectListProvider.future);
        },
        child: projectListAsync.when(
          data: (projects) {
            if (projects.isEmpty) {
              return const Center(child: Text('Нет проектов'));
            }
            return ListView.builder(
              itemCount: projects.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final project = projects[index];
                return _ProjectCard(project: project);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Ошибка загрузки: $error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(projectListProvider),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    // Форматирование даты
    final dateStr = DateFormat('dd.MM.yy').format(project.createdAt);

    // Определяем цвет иконки статуса (простая логика для примера)
    Color statusColor = Colors.grey;
    if (project.status == 'new') statusColor = Colors.blue;
    if (project.status == 'completed') statusColor = Colors.green;
    if (project.status == 'calculating') statusColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          project.address,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              // Тип объекта
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getObjectTypeDisplay(project.objectType),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 8),
              // Статус с иконкой
              Icon(Icons.circle, size: 8, color: statusColor),
              const SizedBox(width: 4),
              Text(_getProjectStatusDisplay(project.status),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(dateStr),
            const SizedBox(width: 8),
            Consumer(
              builder: (context, ref, child) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddProjectScreen(project: project),
                        ),
                      );
                    } else if (value == 'delete') {
                      _deleteProject(context, ref);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Редактировать'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Удалить', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProjectDetailScreen(projectId: project.id.toString()),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteProject(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление проекта'),
        content: const Text('Вы уверены, что хотите удалить этот проект?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(projectListProvider.notifier)
            .deleteProject(project.id.toString());

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Проект удален')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось удалить: $e')),
          );
        }
      }
    }
  }

  // Маппинг для типов объектов
  String _getObjectTypeDisplay(String type) {
    const map = {
      'new_building': 'Новостройка',
      'secondary': 'Вторичка',
      'cottage': 'Коттедж',
      'office': 'Офис',
      'other': 'Другое',
    };
    return map[type] ?? type;
  }

  // Маппинг для статусов проекта
  String _getProjectStatusDisplay(String status) {
    const map = {
      'new': 'Новый',
      'calculating': 'Предпросчет',
      'stage1_done': 'Этап 1 готов',
      'stage2_done': 'Этап 2 готов',
      'stage3_done': 'Этап 3 готов',
      'completed': 'Завершен',
    };
    return map[status] ?? status;
  }
}
