import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/project_providers.dart';
import '../../data/models/project_model.dart';

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
        onPressed: () {
          // Пока выводим сообщение, как заглушку
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Скоро здесь будет форма создания')),
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
        subtitle: Row(
          children: [
            // Тип объекта
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                project.objectType,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 8),
            // Статус с иконкой
            Icon(Icons.circle, size: 8, color: statusColor),
            const SizedBox(width: 4),
            Text(project.status, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        trailing: Text(dateStr),
        onTap: () {
          // TODO: Навигация в детали
        },
      ),
    );
  }
}
