import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_providers.dart';
import '../../data/models/project_model.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectListAsync = ref.watch(projectListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали проекта'),
      ),
      body: projectListAsync.when(
        data: (projects) {
          // Ищем проект в списке по ID
          final project = projects.firstWhere(
            (p) => p.id.toString() == projectId,
            orElse: () => throw Exception('Проект не найден'),
          );
          return _ProjectDetailContent(project: project);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка: $error')),
      ),
    );
  }
}

class _ProjectDetailContent extends ConsumerWidget {
  final ProjectModel project;

  const _ProjectDetailContent({required this.project});

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
      'precalculation': 'Предпросчет',
      'stage1_done': 'Этап 1 готов',
      'stage2_done': 'Этап 2 готов',
      'stage3_done': 'Этап 3 готов',
      'completed': 'Завершен',
    };
    return map[status] ?? status;
  }

  // Маппинг для названий этапов
  String _getStageTitleDisplay(String title) {
    const map = {
      'precalc': 'Предпросчет',
      'stage_1': 'Этап 1 (Черновой)',
      'stage_1_2': 'Этап 1+2 (Черновой)',
      'stage_2': 'Этап 2 (Черновой)',
      'stage_3': 'Этап 3 (Чистовой)',
      'extra': 'Доп. работы',
      'other': 'Другое',
    };
    return map[title] ?? title;
  }

  // Маппинг для статусов этапов
  String _getStageStatusDisplay(String status) {
    const map = {
      'plan': 'План',
      'in_progress': 'В процессе',
      'completed': 'Завершен',
    };
    return map[status] ?? status;
  }

  Color _getStageStatusColor(String status) {
    switch (status) {
      case 'plan':
        return Colors.grey;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref,
      String stageId, String currentStatus, Offset globalPosition) async {
    final newStatus = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      items: const [
        PopupMenuItem(value: 'plan', child: Text('План')),
        PopupMenuItem(value: 'in_progress', child: Text('В процессе')),
        PopupMenuItem(value: 'completed', child: Text('Завершен')),
      ],
    );

    if (newStatus != null && newStatus != currentStatus) {
      await ref
          .read(projectListProvider.notifier)
          .updateStageStatus(stageId, newStatus);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Карточка с основной информацией
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.address,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                      label: 'Тип:',
                      value: _getObjectTypeDisplay(project.objectType)),
                  _InfoRow(
                      label: 'Статус:',
                      value: _getProjectStatusDisplay(project.status)),
                  if (project.clientInfo.isNotEmpty)
                    _InfoRow(label: 'Клиент:', value: project.clientInfo),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Этапы работ',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          // Список этапов
          if (project.stages.isEmpty) const Text('Этапы еще не созданы'),

          ...project.stages.map((stage) {
            final statusColor = _getStageStatusColor(stage.status);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(_getStageTitleDisplay(stage.title)),
                subtitle: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: InkWell(
                      onTapDown: (details) => _updateStatus(
                          context,
                          ref,
                          stage.id.toString(),
                          stage.status,
                          details.globalPosition),
                      onTap: () {}, // Необходим для эффекта нажатия
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStageStatusDisplay(stage.status),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
                trailing: stage.isPaid
                    ? const Icon(Icons.monetization_on, color: Colors.green)
                    : const Icon(Icons.money_off, color: Colors.grey),
              ),
            );
          }),

          const SizedBox(height: 16),
          // Кнопка добавления этапа
          Center(
            child: FilledButton.icon(
              onPressed: () => _showAddStageSheet(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Добавить этап'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStageSheet(BuildContext context, WidgetRef ref) {
    // Собираем ключи уже существующих этапов
    final existingKeys = project.stages.map((s) => s.title).toList();

    showModalBottomSheet(
      context: context,
      builder: (context) => _AddStageSheet(
        projectId: project.id.toString(),
        existingStageKeys: existingKeys,
      ),
    );
  }
}

class _AddStageSheet extends ConsumerStatefulWidget {
  final String projectId;
  // Передаем существующие этапы, чтобы исключить их из выбора
  final List<String> existingStageKeys;

  const _AddStageSheet({
    required this.projectId,
    required this.existingStageKeys,
  });

  @override
  ConsumerState<_AddStageSheet> createState() => _AddStageSheetState();
}

class _AddStageSheetState extends ConsumerState<_AddStageSheet> {
  bool _isLoading = false;

  final Map<String, String> _allStages = {
    'precalc': 'Предпросчет',
    'stage_1': 'Этап 1 (Черновой)',
    'stage_1_2': 'Этап 1+2 (Черновой)',
    'stage_2': 'Этап 2 (Черновой)',
    'stage_3': 'Этап 3 (Чистовой)',
    'extra': 'Доп. работы',
    'other': 'Другое',
  };

  // Получаем только те этапы, которых нет в проекте (кроме 'extra' и 'other', их может быть много)
  Map<String, String> get _availableStages {
    final available = Map<String, String>.from(_allStages);
    // Удаляем из списка уже существующие этапы, кроме 'extra' и 'other'
    for (final key in widget.existingStageKeys) {
      if (key != 'extra' && key != 'other') {
        available.remove(key);
      }
    }
    return available;
  }

  Future<void> _addStage(String stageKey) async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(projectListProvider.notifier)
          .addStage(widget.projectId, stageKey);
      if (mounted) {
        Navigator.pop(context); // Закрываем шторку
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Этап успешно добавлен')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stages = _availableStages;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выберите этап',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (stages.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Все основные этапы уже добавлены'),
            )
          else
            ...stages.entries.map((entry) => ListTile(
                  title: Text(entry.value),
                  onTap: () => _addStage(entry.key),
                  leading: const Icon(Icons.add_circle_outline),
                )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
