import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/project_model.dart';
import '../providers/project_providers.dart';
import '../../../engineering/presentation/providers/engineering_providers.dart';
import '../../../engineering/data/models/shield_group_model.dart';
import '../../../engineering/data/models/led_zone_model.dart';

class EngineeringTab extends ConsumerWidget {
  final ProjectModel project;

  const EngineeringTab({required this.project, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _PowerShieldSection(project: project),
          const SizedBox(height: 16),
          _LedShieldSection(project: project),
          const SizedBox(height: 16),
          _LowCurrentSection(project: project),
          const SizedBox(height: 80), // Bottom padding for scrolling
        ],
      ),
    );
  }
}

class _PowerShieldSection extends ConsumerWidget {
  final ProjectModel project;

  const _PowerShieldSection({required this.project});

  int _calculateRecommendedShield(int modules) {
    const sizes = [1, 2, 4, 6, 8, 12, 18, 24, 36, 48, 60, 72, 96, 108, 144];
    for (final size in sizes) {
      if (modules <= size) return size;
    }
    return modules;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = project.id.toString();
    final shieldGroupsAsync = ref.watch(shieldGroupsProvider(projectId));

    return shieldGroupsAsync.when(
      data: (groups) {
        final totalModules =
            groups.fold(0, (sum, item) => sum + item.modulesCount);
        final recommendedShield = _calculateRecommendedShield(totalModules);

        return Card(
          elevation: 2,
          child: ExpansionTile(
            initiallyExpanded: groups.isNotEmpty,
            shape: const Border(), // Remove default border
            title: const Text('Силовой щит',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$totalModules модулей / Щит: $recommendedShield',
                style: TextStyle(color: Colors.teal.shade700)),
            leading: const Icon(Icons.flash_on, color: Colors.teal),
            childrenPadding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            children: [
              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        _showApplyTemplateDialog(context, projectId),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Шаблон'),
                  ),
                  TextButton.icon(
                    onPressed: () => _showEditDialog(context, projectId),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Добавить'),
                  ),
                ],
              ),
              const Divider(),
              if (groups.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Нет групп. Добавьте или используйте шаблон.',
                      style: TextStyle(color: Colors.grey)),
                )
              else
                _ShieldGroupsList(groups: groups, projectId: projectId),
            ],
          ),
        );
      },
      loading: () => const Card(child: ListTile(title: Text('Загрузка...'))),
      error: (e, _) => Card(child: ListTile(title: Text('Ошибка: $e'))),
    );
  }

  void _showEditDialog(BuildContext context, String projectId) {
    showDialog(
      context: context,
      builder: (context) => _ShieldGroupDialog(projectId: projectId),
    );
  }

  void _showApplyTemplateDialog(BuildContext context, String projectId) {
    showDialog(
      context: context,
      builder: (context) =>
          _ApplyTemplateDialog(projectId: projectId, type: 'shield'),
    );
  }
}

class _ShieldGroupsList extends ConsumerWidget {
  final List<ShieldGroupModel> groups;
  final String projectId;

  const _ShieldGroupsList({required this.groups, required this.projectId});

  Color _getTypeColor(String type) {
    switch (type) {
      case 'diff_breaker':
        return Colors.orange;
      case 'rcd':
        return Colors.deepPurple;
      case 'relay':
        return Colors.blue;
      case 'contactor':
        return Colors.teal;
      case 'load_switch':
        return Colors.black87;
      case 'circuit_breaker':
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = <String, List<ShieldGroupModel>>{};
    for (var item in groups) {
      grouped.putIfAbsent(item.deviceType, () => []).add(item);
    }

    final typeOrder = [
      'circuit_breaker',
      'diff_breaker',
      'rcd',
      'relay',
      'contactor',
      'load_switch',
      'other'
    ];

    final typeNames = {
      'circuit_breaker': 'Автоматы',
      'diff_breaker': 'Диф. автоматы',
      'rcd': 'УЗО',
      'relay': 'Реле и автоматика',
      'contactor': 'Контакторы',
      'load_switch': 'Выключатели нагрузки',
      'other': 'Другое',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final type in typeOrder)
          if (grouped.containsKey(type)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                typeNames[type] ?? type,
                style: TextStyle(
                    color: Colors.blueGrey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
            ...grouped[type]!.map((group) => _ShieldGroupItem(
                group: group,
                projectId: projectId,
                color: _getTypeColor(group.deviceType))),
          ],
      ],
    );
  }
}

class _ShieldGroupItem extends ConsumerWidget {
  final ShieldGroupModel group;
  final String projectId;
  final Color color;

  const _ShieldGroupItem(
      {required this.group, required this.projectId, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.electric_bolt, color: color, size: 20),
        ),
        title: Text(group.device,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: group.zone.isNotEmpty ? Text(group.zone) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4)),
              child: Text('${group.modulesCount} мод.',
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
              onPressed: () => _showEditDialog(context, group),
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: () => _deleteGroup(context, ref, group),
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, ShieldGroupModel group) {
    showDialog(
      context: context,
      builder: (context) =>
          _ShieldGroupDialog(projectId: projectId, group: group),
    );
  }

  Future<void> _deleteGroup(
      BuildContext context, WidgetRef ref, ShieldGroupModel group) async {
    // Simple confirm
    final confirm = await showDialog<bool>(
        context: context,
        builder: (context) =>
            AlertDialog(title: const Text('Удалить?'), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Отмена')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Удалить')),
            ]));
    if (confirm == true) {
      ref.read(shieldGroupsProvider(projectId).notifier).delete(group.id);
    }
  }
}

class _LedShieldSection extends ConsumerWidget {
  final ProjectModel project;

  const _LedShieldSection({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = project.id.toString();
    final ledZonesAsync = ref.watch(ledZonesProvider(projectId));

    return ledZonesAsync.when(
      data: (zones) {
        final ledShieldSize = project.ledShieldSize ?? 'Н/Д';

        return Card(
          elevation: 2,
          child: ExpansionTile(
            initiallyExpanded: zones.isNotEmpty,
            shape: const Border(),
            title: const Text('LED освещение',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${zones.length} зон / Щит: $ledShieldSize',
                style: TextStyle(color: Colors.purple.shade700)),
            leading: const Icon(Icons.lightbulb, color: Colors.purple),
            childrenPadding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        _showApplyTemplateDialog(context, projectId),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Шаблон'),
                  ),
                  TextButton.icon(
                    onPressed: () => _showEditDialog(context, projectId),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Добавить'),
                  ),
                ],
              ),
              const Divider(),
              if (zones.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Нет LED зон.',
                      style: TextStyle(color: Colors.grey)),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: zones.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final zone = zones[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.purple,
                        child: Icon(Icons.lightbulb_outline,
                            color: Colors.white, size: 16),
                      ),
                      title: Text(zone.transformer,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(zone.zone),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                size: 18, color: Colors.grey),
                            onPressed: () =>
                                _showEditDialog(context, projectId, zone: zone),
                            splashRadius: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                size: 18, color: Colors.red),
                            onPressed: () {
                              ref
                                  .read(ledZonesProvider(projectId).notifier)
                                  .delete(zone.id);
                            },
                            splashRadius: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
      loading: () => const Card(child: ListTile(title: Text('Загрузка...'))),
      error: (e, _) => Card(child: ListTile(title: Text('Ошибка: $e'))),
    );
  }

  void _showEditDialog(BuildContext context, String projectId,
      {LedZoneModel? zone}) {
    showDialog(
      context: context,
      builder: (context) => _LedZoneDialog(projectId: projectId, zone: zone),
    );
  }

  void _showApplyTemplateDialog(BuildContext context, String projectId) {
    showDialog(
      context: context,
      builder: (context) =>
          _ApplyTemplateDialog(projectId: projectId, type: 'led'),
    );
  }
}

class _LowCurrentSection extends ConsumerStatefulWidget {
  final ProjectModel project;

  const _LowCurrentSection({required this.project});

  @override
  ConsumerState<_LowCurrentSection> createState() => _LowCurrentSectionState();
}

class _LowCurrentSectionState extends ConsumerState<_LowCurrentSection> {
  late TextEditingController _internetLinesController;
  late TextEditingController _suggestedShieldController;
  late TextEditingController _multimediaNotesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _internetLinesController = TextEditingController(
        text: widget.project.internetLinesCount.toString());
    _suggestedShieldController =
        TextEditingController(text: widget.project.suggestedInternetShield);
    _multimediaNotesController =
        TextEditingController(text: widget.project.multimediaNotes);
  }

  @override
  void dispose() {
    _internetLinesController.dispose();
    _suggestedShieldController.dispose();
    _multimediaNotesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final internetLines = int.tryParse(_internetLinesController.text) ?? 0;
      await ref.read(projectListProvider.notifier).updateProject(
        widget.project.id.toString(),
        {
          'internet_lines_count': internetLines,
          'suggested_internet_shield': _suggestedShieldController.text,
          'multimedia_notes': _multimediaNotesController.text,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Данные слаботочки сохранены'),
              duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.project.internetLinesCount > 0 ||
        widget.project.multimediaNotes.isNotEmpty;

    return Card(
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: hasData,
        shape: const Border(),
        title: const Text('Слаботочка',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${widget.project.internetLinesCount} интернет-линий',
            style: TextStyle(color: Colors.blue.shade700)),
        leading: const Icon(Icons.router, color: Colors.blue),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          TextField(
            controller: _internetLinesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Количество интернет-линий',
              helperText: 'Витая пара',
              border: UnderlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _suggestedShieldController,
            decoration: const InputDecoration(
              labelText: 'Предполагаемый щиток',
              border: UnderlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _multimediaNotesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Заметки по мультимедиа',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, size: 16),
              label: Text(_isSaving ? '...' : 'Сохранить'),
            ),
          )
        ],
      ),
    );
  }
}

// Dialogs

class _ShieldGroupDialog extends StatefulWidget {
  final String projectId;
  final ShieldGroupModel? group;

  const _ShieldGroupDialog({required this.projectId, this.group});

  @override
  State<_ShieldGroupDialog> createState() => _ShieldGroupDialogState();
}

class _ShieldGroupDialogState extends State<_ShieldGroupDialog> {
  late TextEditingController _zoneController;
  late TextEditingController _ratingController;
  late TextEditingController _polesController;

  String _selectedDeviceType = 'circuit_breaker';

  final Map<String, String> _deviceTypes = {
    'circuit_breaker': 'Автомат',
    'diff_breaker': 'Диф.автомат',
    'rcd': 'УЗО',
    'relay': 'Реле напряжения',
    'contactor': 'Контактор',
    'load_switch': 'Выключатель нагрузки',
    'other': 'Другое',
  };

  final List<String> _ratings = [
    '6A',
    '10A',
    '16A',
    '20A',
    '25A',
    '32A',
    '40A',
    '50A',
    '63A',
    '80A',
    '100A'
  ];
  final List<String> _poles = ['1P', '2P', '3P', '4P'];

  @override
  void initState() {
    super.initState();
    _zoneController = TextEditingController(text: widget.group?.zone ?? '');
    _ratingController =
        TextEditingController(text: widget.group?.rating ?? '16A');
    _polesController = TextEditingController(text: widget.group?.poles ?? '1P');

    if (widget.group != null) {
      _selectedDeviceType = widget.group!.deviceType;
    }
  }

  @override
  void dispose() {
    _zoneController.dispose();
    _ratingController.dispose();
    _polesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.group != null;
    return AlertDialog(
      title: Text(isEdit ? 'Редактировать группу' : 'Добавить группу'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _deviceTypes.containsKey(_selectedDeviceType)
                  ? _selectedDeviceType
                  : 'circuit_breaker',
              decoration: const InputDecoration(labelText: 'Тип устройства'),
              items: _deviceTypes.entries.map((e) {
                return DropdownMenuItem(value: e.key, child: Text(e.value));
              }).toList(),
              onChanged: (val) => setState(() => _selectedDeviceType = val!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ratingController,
                    decoration: InputDecoration(
                      labelText: 'Номинал',
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (v) => _ratingController.text = v,
                        itemBuilder: (c) => _ratings
                            .map((e) => PopupMenuItem(value: e, child: Text(e)))
                            .toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _polesController,
                    decoration: InputDecoration(
                      labelText: 'Полюса',
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (v) => _polesController.text = v,
                        itemBuilder: (c) => _poles
                            .map((e) => PopupMenuItem(value: e, child: Text(e)))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _zoneController,
              decoration:
                  const InputDecoration(labelText: 'Зона / Потребитель'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена')),
        Consumer(
          builder: (context, ref, child) {
            return FilledButton(
              onPressed: () async {
                final zone = _zoneController.text;
                Navigator.pop(context);
                try {
                  final notifier =
                      ref.read(shieldGroupsProvider(widget.projectId).notifier);
                  if (isEdit) {
                    await notifier.updateShieldGroup(
                        widget.group!.id,
                        _selectedDeviceType,
                        _ratingController.text,
                        _polesController.text,
                        zone);
                  } else {
                    await notifier.add(_selectedDeviceType,
                        _ratingController.text, _polesController.text, zone);
                  }
                } catch (e) {
                  // ignore
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
            child: const Text('Отмена')),
        Consumer(
          builder: (context, ref, child) {
            return FilledButton(
              onPressed: () async {
                if (_transformerController.text.isEmpty) return;
                Navigator.pop(context);
                try {
                  final notifier =
                      ref.read(ledZonesProvider(widget.projectId).notifier);
                  if (isEdit) {
                    await notifier.updateLedZone(widget.zone!.id,
                        _transformerController.text, _zoneController.text);
                  } else {
                    await notifier.add(
                        _transformerController.text, _zoneController.text);
                  }
                } catch (e) {
                  // ignore
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
                final template = templates[index] as dynamic;
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
                            const SnackBar(content: Text('Шаблон применен')));
                      }
                    } catch (e) {
                      // ignore
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
            child: const Text('Отмена')),
      ],
    );
  }
}
