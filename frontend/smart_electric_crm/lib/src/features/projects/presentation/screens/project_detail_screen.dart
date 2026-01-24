import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_providers.dart';
import '../../data/models/project_model.dart';
import 'add_project_screen.dart';
import '../../../engineering/presentation/providers/engineering_providers.dart';
import '../../../engineering/data/models/shield_group_model.dart';
import '../../../engineering/data/models/led_zone_model.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectListAsync = ref.watch(projectListProvider);

    return projectListAsync.when(
      data: (projects) {
        try {
          final project = projects.firstWhere(
            (p) => p.id.toString() == projectId,
          );
          return _ProjectDetailContent(project: project);
        } catch (_) {
          return Scaffold(
            appBar: AppBar(title: const Text('Детали объекта')),
            body: const Center(child: Text('Объект не найден')),
          );
        }
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Детали объекта')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Детали объекта')),
        body: Center(child: Text('Ошибка: $error')),
      ),
    );
  }
}

class _ProjectDetailContent extends ConsumerWidget {
  final ProjectModel project;

  const _ProjectDetailContent({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(project.address),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Этапы"),
              Tab(text: "Щит"),
              Tab(text: "LED"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Редактировать',
              onPressed: () => _editProject(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Удалить',
              onPressed: () => _deleteProject(context, ref),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _StagesTab(project: project),
            _ShieldTab(projectId: project.id.toString()),
            _LedTab(projectId: project.id.toString()),
          ],
        ),
      ),
    );
  }

  void _editProject(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProjectScreen(project: project),
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
          Navigator.pop(context);
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
}

class _StagesTab extends ConsumerWidget {
  final ProjectModel project;

  const _StagesTab({required this.project});

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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      onTap: () {},
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
          Center(
            child: FilledButton.icon(
              onPressed: () => _showAddStageSheet(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Добавить этап'),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  void _showAddStageSheet(BuildContext context, WidgetRef ref) {
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

class _ShieldTab extends ConsumerWidget {
  final String projectId;

  const _ShieldTab({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shieldGroupsAsync = ref.watch(shieldGroupsProvider(projectId));

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: null,
            tooltip: 'Добавить строку',
            onPressed: () => _showEditDialog(context, ref),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: null,
            onPressed: () => _showApplyTemplateDialog(context, ref),
            icon: const Icon(Icons.copy),
            label: const Text('По шаблону'),
          ),
        ],
      ),
      body: shieldGroupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
                child: Text('Нет групп щита. Добавьте или примените шаблон.'));
          }
          return ListView.separated(
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 16),
            itemCount: groups.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final group = groups[index];
              return Dismissible(
                key: ValueKey(group.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Удалить группу?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Удалить',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  ref
                      .read(shieldGroupsProvider(projectId).notifier)
                      .delete(group.id);
                },
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: Icon(Icons.electric_bolt,
                        color: Colors.white, size: 20),
                  ),
                  title: Text(
                    group.device,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(group.zone),
                  onTap: () => _showEditDialog(context, ref, group: group),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                    onPressed: () =>
                        _showEditDialog(context, ref, group: group),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка: $err')),
      ),
    );
  }

  void _showApplyTemplateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _ApplyTemplateDialog(
        projectId: projectId,
        type: 'shield',
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref,
      {ShieldGroupModel? group}) {
    showDialog(
      context: context,
      builder: (context) => _ShieldGroupDialog(
        projectId: projectId,
        group: group,
      ),
    );
  }
}

class _ShieldGroupDialog extends StatefulWidget {
  final String projectId;
  final ShieldGroupModel? group;

  const _ShieldGroupDialog({required this.projectId, this.group});

  @override
  State<_ShieldGroupDialog> createState() => _ShieldGroupDialogState();
}

class _ShieldGroupDialogState extends State<_ShieldGroupDialog> {
  late TextEditingController _deviceController;
  late TextEditingController _zoneController;

  @override
  void initState() {
    super.initState();
    _deviceController = TextEditingController(text: widget.group?.device ?? '');
    _zoneController = TextEditingController(text: widget.group?.zone ?? '');
  }

  @override
  void dispose() {
    _deviceController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.group != null;
    return AlertDialog(
      title: Text(isEdit ? 'Редактировать группу' : 'Добавить группу'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _deviceController,
            decoration:
                const InputDecoration(labelText: 'Устройство (напр. Диф 16А)'),
          ),
          TextField(
            controller: _zoneController,
            decoration: const InputDecoration(labelText: 'Зона (напр. Кухня)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        Consumer(
          builder: (context, ref, child) {
            return ElevatedButton(
              onPressed: () async {
                final device = _deviceController.text;
                final zone = _zoneController.text;
                if (device.isEmpty || zone.isEmpty) return;

                Navigator.pop(context); // Закрываем диалог сразу

                try {
                  if (isEdit) {
                    await ref
                        .read(shieldGroupsProvider(widget.projectId).notifier)
                        .updateShieldGroup(widget.group!.id, device, zone);
                  } else {
                    await ref
                        .read(shieldGroupsProvider(widget.projectId).notifier)
                        .add(device, zone);
                  }
                } catch (e) {
                  // Обработка ошибок, если нужно
                }
              },
              child: const Text('Сохранить'),
            );
          },
        ),
      ],
    );
  }
}

class _LedTab extends ConsumerWidget {
  final String projectId;

  const _LedTab({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledZonesAsync = ref.watch(ledZonesProvider(projectId));

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: null,
            tooltip: 'Добавить строку',
            onPressed: () => _showEditDialog(context, ref),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: null,
            onPressed: () => _showApplyTemplateDialog(context, ref),
            icon: const Icon(Icons.copy),
            label: const Text('По шаблону'),
          ),
        ],
      ),
      body: ledZonesAsync.when(
        data: (zones) {
          if (zones.isEmpty) {
            return const Center(
                child: Text('Нет LED зон. Добавьте или примените шаблон.'));
          }
          return ListView.separated(
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 16),
            itemCount: zones.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final zone = zones[index];
              return Dismissible(
                key: ValueKey(zone.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Удалить зону?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Удалить',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  ref
                      .read(ledZonesProvider(projectId).notifier)
                      .delete(zone.id);
                },
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.lightbulb_outline,
                        color: Colors.white, size: 20),
                  ),
                  title: Text(
                    zone.transformer,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(zone.zone),
                  onTap: () => _showEditDialog(context, ref, zone: zone),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                    onPressed: () => _showEditDialog(context, ref, zone: zone),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка: $err')),
      ),
    );
  }

  void _showApplyTemplateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _ApplyTemplateDialog(
        projectId: projectId,
        type: 'led',
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref,
      {LedZoneModel? zone}) {
    showDialog(
      context: context,
      builder: (context) => _LedZoneDialog(
        projectId: projectId,
        zone: zone,
      ),
    );
  }
}

class _LedZoneDialog extends StatefulWidget {
  final String projectId;
  final LedZoneModel? zone;

  const _LedZoneDialog({required this.projectId, this.zone});

  @override
  State<_LedZoneDialog> createState() => _LedZoneDialogState();
}

class _LedZoneDialogState extends State<_LedZoneDialog> {
  late TextEditingController _transformerController;
  late TextEditingController _zoneController;

  @override
  void initState() {
    super.initState();
    _transformerController =
        TextEditingController(text: widget.zone?.transformer ?? '');
    _zoneController = TextEditingController(text: widget.zone?.zone ?? '');
  }

  @override
  void dispose() {
    _transformerController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.zone != null;
    return AlertDialog(
      title: Text(isEdit ? 'Редактировать зону' : 'Добавить зону'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _transformerController,
            decoration:
                const InputDecoration(labelText: 'Трансформатор (напр. 100Вт)'),
          ),
          TextField(
            controller: _zoneController,
            decoration:
                const InputDecoration(labelText: 'Зона (напр. Потолок)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        Consumer(
          builder: (context, ref, child) {
            return ElevatedButton(
              onPressed: () async {
                final transformer = _transformerController.text;
                final zone = _zoneController.text;
                if (transformer.isEmpty || zone.isEmpty) return;

                Navigator.pop(context);

                try {
                  if (isEdit) {
                    await ref
                        .read(ledZonesProvider(widget.projectId).notifier)
                        .updateLedZone(widget.zone!.id, transformer, zone);
                  } else {
                    await ref
                        .read(ledZonesProvider(widget.projectId).notifier)
                        .add(transformer, zone);
                  }
                } catch (e) {
                  // Error handling
                }
              },
              child: const Text('Сохранить'),
            );
          },
        ),
      ],
    );
  }
}

class _ApplyTemplateDialog extends ConsumerWidget {
  final String projectId;
  final String type; // 'shield' or 'led'

  const _ApplyTemplateDialog({required this.projectId, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = type == 'shield'
        ? ref.watch(shieldTemplatesProvider)
        : ref.watch(ledTemplatesProvider);

    return AlertDialog(
      title: Text(
          type == 'shield' ? 'Выберите шаблон щита' : 'Выберите шаблон LED'),
      content: SizedBox(
        width: double.maxFinite,
        child: templatesAsync.when(
          data: (templates) {
            if (templates.isEmpty) return const Text('Нет доступных шаблонов');
            return ListView.builder(
              shrinkWrap: true,
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index]
                    as dynamic; // Using dynamic to access common fields name/description/id for both models
                return ListTile(
                  title: Text(template.name),
                  subtitle: Text(template.description),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      if (type == 'shield') {
                        await ref
                            .read(shieldGroupsProvider(projectId).notifier)
                            .applyTemplate(template.id);
                      } else {
                        await ref
                            .read(ledZonesProvider(projectId).notifier)
                            .applyTemplate(template.id);
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Шаблон применен')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ошибка: $e')),
                        );
                      }
                    }
                  },
                );
              },
            );
          },
          loading: () => const SizedBox(
              height: 100, child: Center(child: CircularProgressIndicator())),
          error: (err, stack) => Text('Ошибка: $err'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
      ],
    );
  }
}

class _AddStageSheet extends ConsumerStatefulWidget {
  final String projectId;
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

  Map<String, String> get _availableStages {
    final available = Map<String, String>.from(_allStages);
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
        Navigator.pop(context);
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
