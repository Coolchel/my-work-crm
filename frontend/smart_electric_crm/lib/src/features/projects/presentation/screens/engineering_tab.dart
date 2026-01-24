import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/project_model.dart';
import '../providers/project_providers.dart';
import '../../../engineering/presentation/providers/engineering_providers.dart';
import '../../../engineering/data/models/shield_model.dart';
import '../../../engineering/data/models/shield_group_model.dart';
import '../../../engineering/data/models/led_zone_model.dart';

class EngineeringTab extends ConsumerWidget {
  final ProjectModel project;

  const EngineeringTab({required this.project, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showAddShieldDialog(context, ref, project.id.toString()),
        icon: const Icon(Icons.add),
        label: const Text('Добавить щит'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (project.shields.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Нет щитов. Добавьте первый щит.',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...project.shields.map((shield) => _ShieldCard(
                    shield: shield,
                    projectId: project.id.toString(),
                  )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showAddShieldDialog(
      BuildContext context, WidgetRef ref, String projectId) {
    showDialog(
      context: context,
      builder: (context) => _AddShieldDialog(projectId: projectId),
    );
  }
}

class _ShieldCard extends ConsumerWidget {
  final ShieldModel shield;
  final String projectId;

  const _ShieldCard({required this.shield, required this.projectId});

  Future<void> _deleteShield(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить щит?'),
        content: const Text('Все группы внутри будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(engineeringRepositoryProvider).deleteShield(shield.id);
        ref.invalidate(projectListProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: ExpansionTile(
        initiallyExpanded: false, // Collapsed by default
        title: Row(
          children: [
            Icon(_getIconForType(shield.shieldType),
                color: _getColorForType(shield.shieldType)),
            const SizedBox(width: 8),
            Text(shield.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        subtitle: Text(
          _getTypeName(shield.shieldType),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          // Mounting Toggle
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                const Text('Монтаж:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'internal',
                      label: Text('Внутренний'),
                      icon: Icon(Icons.grid_view, size: 16),
                    ),
                    ButtonSegment(
                      value: 'external',
                      label: Text('Наружный'),
                      icon: Icon(Icons.check_box_outline_blank, size: 16),
                    ),
                  ],
                  selected: {shield.mounting},
                  onSelectionChanged: (Set<String> newSelection) async {
                    final newValue = newSelection.first;
                    try {
                      await ref
                          .read(engineeringRepositoryProvider)
                          .updateShield(shield.id, {'mounting': newValue});
                      ref.invalidate(projectListProvider);
                      // Invalidate specific project provider too just in case
                      ref.invalidate(projectByIdProvider(projectId));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка обновления: $e')));
                      }
                    }
                  },
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: MaterialStateProperty.all(EdgeInsets.zero),
                  ),
                ),
              ],
            ),
          ),

          // Shield Info / Stats
          if (shield.suggestedSize != null)
            Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: _getColorForType(shield.shieldType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          'Рекомендуемый корпус: ${shield.suggestedSize}',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ],
                )),

          // Content based on type
          if (shield.shieldType == 'power')
            _PowerShieldContent(shield: shield, projectId: projectId),
          if (shield.shieldType == 'led')
            _LedShieldContent(shield: shield, projectId: projectId),
          if (shield.shieldType == 'multimedia')
            _MultimediaShieldContent(shield: shield, projectId: projectId),

          const Divider(height: 32),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _deleteShield(context, ref),
                icon: const Icon(Icons.delete, size: 16, color: Colors.grey),
                label: const Text('Удалить щит',
                    style: TextStyle(color: Colors.grey)),
              ),
              // TODO: Edit shield (rename/mounting)
            ],
          )
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'power':
        return Icons.flash_on;
      case 'led':
        return Icons.lightbulb;
      case 'multimedia':
        return Icons.router;
      default:
        return Icons.wb_iridescent;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'power':
        return Colors.teal;
      case 'led':
        return Colors.purple;
      case 'multimedia':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'power':
        return 'Силовой';
      case 'led':
        return 'LED';
      case 'multimedia':
        return 'Слаботочка';
      default:
        return type;
    }
  }
}

// --- Content Widgets ---

class _PowerShieldContent extends ConsumerWidget {
  final ShieldModel shield;
  final String projectId;

  const _PowerShieldContent({required this.shield, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = shield.groups;

    // Group items by device type
    final Map<String, List<ShieldGroupModel>> groupedGroups = {};
    for (var group in groups) {
      if (!groupedGroups.containsKey(group.deviceType)) {
        groupedGroups[group.deviceType] = [];
      }
      groupedGroups[group.deviceType]!.add(group);
    }

    // Define custom order for groups
    final List<String> typeOrder = [
      'load_switch', // Вводные всегда первыми
      'relay', // Реле сразу после ввода
      'circuit_breaker',
      'diff_breaker',
      'rcd',
      'contactor',
      'other'
    ];

    // Sort keys based on defined order
    final sortedKeys = groupedGroups.keys.toList()
      ..sort((a, b) {
        int indexA = typeOrder.indexOf(a);
        int indexB = typeOrder.indexOf(b);
        if (indexA == -1) indexA = 999;
        if (indexB == -1) indexB = 999;
        return indexA.compareTo(indexB);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Группы (${groups.length})',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showApplyTemplateDialog(context, ref),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Шаблон'),
                ),
                FilledButton.icon(
                  onPressed: () => _showAddGroupDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Добавить'),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 8),
        if (groups.isEmpty)
          const Text('Нет групп', style: TextStyle(color: Colors.grey))
        else
          ...sortedKeys.map((type) {
            final groupItems = groupedGroups[type]!;
            final totalModules =
                groupItems.fold<int>(0, (sum, item) => sum + item.modulesCount);
            final typeName = _getDeviceTypeName(type);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Text(
                        typeName,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalModules mod',
                          style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
                // Group Items
                ...groupItems.map((group) => Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 4),
                      color: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                        onTap: () =>
                            _showAddGroupDialog(context, ref, group: group),
                        // Leading Icon with Color
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getDeviceColor(group.deviceType)
                                .withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getDeviceIcon(group.deviceType),
                              size: 20,
                              color: _getDeviceColor(group.deviceType)),
                        ),
                        title: Text(group.device,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(group.zone),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete,
                              size: 16, color: Colors.grey),
                          onPressed: () async {
                            await ref
                                .read(engineeringRepositoryProvider)
                                .deleteShieldGroup(group.id);
                            ref.invalidate(projectListProvider);
                          },
                        ),
                      ),
                    )),
                const SizedBox(height: 8),
              ],
            );
          }),
      ],
    );
  }

  void _showAddGroupDialog(BuildContext context, WidgetRef ref,
      {ShieldGroupModel? group}) {
    debugPrint('Opening dialog for group: ${group?.id}');
    showDialog(
      context: context,
      builder: (context) => _ShieldGroupDialog(
          projectId: projectId, shieldId: shield.id, group: group),
    );
  }

  void _showApplyTemplateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _ApplyTemplateDialog(
          projectId: projectId, shieldId: shield.id, type: 'shield'),
    );
  }

  // Helper methods for _PowerShieldContent (local to this file/widget usage)
  String _getDeviceTypeName(String type) {
    final map = {
      'circuit_breaker': 'Автоматические выключатели',
      'diff_breaker': 'Диф. автоматы',
      'rcd': 'УЗО',
      'relay': 'Реле и автоматика',
      'contactor': 'Контакторы',
      'load_switch': 'Рубильники',
      'other': 'Другое',
    };
    return map[type] ?? 'Устройства';
  }

  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'circuit_breaker':
        return Icons.bolt;
      case 'diff_breaker':
        return Icons.shield_outlined;
      case 'rcd':
        return Icons.gpp_maybe_outlined;
      case 'relay':
        return Icons.av_timer;
      case 'contactor':
        return Icons.settings_input_component;
      case 'load_switch':
        return Icons.power_settings_new;
      default:
        return Icons.electrical_services;
    }
  }

  Color _getDeviceColor(String type) {
    switch (type) {
      case 'circuit_breaker':
        return Colors.orange;
      case 'diff_breaker':
        return Colors.blue;
      case 'rcd':
        return Colors.indigo;
      case 'relay':
        return Colors.red;
      case 'contactor':
        return Colors.teal;
      case 'load_switch':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }
}

class _LedShieldContent extends ConsumerWidget {
  final ShieldModel shield;
  final String projectId;

  const _LedShieldContent({required this.shield, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = shield.ledZones;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Зоны (${zones.length})',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showApplyTemplateDialog(context, ref),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Шаблон'),
                ),
                FilledButton.icon(
                  onPressed: () => _showAddZoneDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Добавить'),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 8),
        if (zones.isEmpty)
          const Text('Нет зон', style: TextStyle(color: Colors.grey))
        else
          ...zones.map((zone) => ListTile(
                dense: true,
                onTap: () => _showAddZoneDialog(context, ref, zone: zone),
                leading: const Icon(Icons.lightbulb_outline, size: 16),
                title: Text(zone.transformer),
                subtitle: Text(zone.zone),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  onPressed: () async {
                    await ref
                        .read(engineeringRepositoryProvider)
                        .deleteLedZone(zone.id);
                    ref.invalidate(projectListProvider);
                  },
                ),
              )),
      ],
    );
  }

  void _showAddZoneDialog(BuildContext context, WidgetRef ref,
      {LedZoneModel? zone}) {
    showDialog(
      context: context,
      builder: (context) =>
          _LedZoneDialog(projectId: projectId, shieldId: shield.id, zone: zone),
    );
  }

  void _showApplyTemplateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _ApplyTemplateDialog(
          projectId: projectId, shieldId: shield.id, type: 'led'),
    );
  }
}

class _MultimediaShieldContent extends ConsumerStatefulWidget {
  final ShieldModel shield;
  final String projectId;

  const _MultimediaShieldContent(
      {required this.shield, required this.projectId});

  @override
  ConsumerState<_MultimediaShieldContent> createState() =>
      _MultimediaShieldContentState();
}

class _MultimediaShieldContentState
    extends ConsumerState<_MultimediaShieldContent> {
  late TextEditingController _linesController;
  late TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _linesController = TextEditingController(
        text: widget.shield.internetLinesCount.toString());
    _notesController =
        TextEditingController(text: widget.shield.multimediaNotes);
  }

  @override
  void dispose() {
    _linesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final lines = int.tryParse(_linesController.text) ?? 0;
      await ref
          .read(engineeringRepositoryProvider)
          .updateShield(widget.shield.id, {
        'internet_lines_count': lines,
        'multimedia_notes': _notesController.text,
      });
      ref.invalidate(projectListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Сохранено')));
      }
    } catch (e) {
      // Error
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _linesController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Кол-во интернет линий'),
          onEditingComplete: _save,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Заметки'),
          onEditingComplete: _save,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            child: const Text('Сохранить'),
          ),
        )
      ],
    );
  }
}

// --- Dialogs ---

class _AddShieldDialog extends StatefulWidget {
  final String projectId;
  const _AddShieldDialog({required this.projectId});

  @override
  State<_AddShieldDialog> createState() => _AddShieldDialogState();
}

class _AddShieldDialogState extends State<_AddShieldDialog> {
  final _nameController = TextEditingController();
  String _type = 'power';
  String _mounting = 'internal';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить щит'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Название щита'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            items: const [
              DropdownMenuItem(value: 'power', child: Text('Силовой')),
              DropdownMenuItem(value: 'led', child: Text('LED')),
              DropdownMenuItem(value: 'multimedia', child: Text('Слаботочка')),
            ],
            onChanged: (v) => setState(() => _type = v!),
            decoration: const InputDecoration(labelText: 'Тип'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _mounting,
            items: const [
              DropdownMenuItem(value: 'internal', child: Text('Внутренний')),
              DropdownMenuItem(value: 'external', child: Text('Наружный')),
            ],
            onChanged: (v) => setState(() => _mounting = v!),
            decoration: const InputDecoration(labelText: 'Монтаж'),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Consumer(builder: (context, ref, _) {
                return FilledButton(
                  onPressed: () async {
                    if (_nameController.text.isEmpty) return;
                    try {
                      await ref
                          .read(engineeringRepositoryProvider)
                          .addShield(widget.projectId, {
                        'name': _nameController.text,
                        'shield_type': _type,
                        'mounting': _mounting,
                      });
                      ref.invalidate(projectListProvider);
                      ref.invalidate(projectByIdProvider(widget.projectId));
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      // Error
                    }
                  },
                  child: const Text('Создать'),
                );
              }),
            ),
          ],
        )
      ],
    );
  }
}

class _ShieldGroupDialog extends StatefulWidget {
  final String projectId;
  final int shieldId;
  final ShieldGroupModel? group;

  const _ShieldGroupDialog(
      {required this.projectId, required this.shieldId, this.group});

  @override
  State<_ShieldGroupDialog> createState() => _ShieldGroupDialogState();
}

class _ShieldGroupDialogState extends State<_ShieldGroupDialog> {
  late TextEditingController _zoneController;
  late TextEditingController _ratingController;
  late TextEditingController _polesController;
  String _selectedDeviceType = 'circuit_breaker';
  bool _isSaving = false;

  final Map<String, String> _deviceTypes = {
    'circuit_breaker': 'Автомат',
    'diff_breaker': 'Диф.автомат',
    'rcd': 'УЗО',
    'relay': 'Реле напряжения',
    'contactor': 'Контактор',
    'load_switch': 'Выключатель нагрузки',
    'other': 'Другое',
  };

  @override
  void initState() {
    super.initState();
    debugPrint('ShieldGroupDialog: initState');
    try {
      _zoneController = TextEditingController(text: widget.group?.zone ?? '');
      _ratingController =
          TextEditingController(text: widget.group?.rating ?? '16A');
      _polesController =
          TextEditingController(text: widget.group?.poles ?? '1P');
      if (widget.group != null) {
        debugPrint('Editing group: ${widget.group!.id}');
        _selectedDeviceType = widget.group!.deviceType;
      }

      // Add listeners for smart normalization
      _ratingController.addListener(_normalizeRating);
      _polesController.addListener(_normalizePoles);
    } catch (e, stack) {
      debugPrint('Error in ShieldGroupDialog initState: $e\n$stack');
    }
  }

  void _normalizeRating() {
    String text = _ratingController.text;
    String newText = text.replaceAll(RegExp(r'а|a', caseSensitive: false), 'A');
    if (text != newText) {
      _ratingController.value = _ratingController.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  void _normalizePoles() {
    String text = _polesController.text;
    String newText = text.replaceAll(RegExp(r'п|p', caseSensitive: false), 'P');
    if (text != newText) {
      _polesController.value = _polesController.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
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
              items: _deviceTypes.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedDeviceType = v!),
              decoration: const InputDecoration(
                labelText: 'Тип устройства',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ratingController,
                    decoration: InputDecoration(
                      labelText: 'Номинал',
                      border: const OutlineInputBorder(),
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (String value) {
                          _ratingController.text = value;
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            '6A',
                            '10A',
                            '16A',
                            '20A',
                            '25A',
                            '32A',
                            '40A',
                            '50A',
                            '63A',
                            '80A'
                          ].map((String choice) {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Text(choice),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _polesController,
                    decoration: InputDecoration(
                      labelText: 'Полюса',
                      border: const OutlineInputBorder(),
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (String value) {
                          _polesController.text = value;
                        },
                        itemBuilder: (BuildContext context) {
                          return ['1P', '2P', '3P', '4P'].map((String choice) {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Text(choice),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _zoneController,
              decoration: const InputDecoration(
                labelText: 'Зона / Потребитель',
                hintText: 'Например: Кухня',
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Consumer(builder: (context, ref, _) {
                return FilledButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          setState(() => _isSaving = true);
                          try {
                            final data = {
                              'device_type': _selectedDeviceType,
                              'rating': _ratingController.text,
                              'poles': _polesController.text,
                              'zone': _zoneController.text,
                            };
                            if (isEdit) {
                              await ref
                                  .read(engineeringRepositoryProvider)
                                  .updateShieldGroup(widget.group!.id, data);
                            } else {
                              await ref
                                  .read(engineeringRepositoryProvider)
                                  .addShieldGroup(widget.shieldId, data);
                            }
                            ref.invalidate(projectListProvider);
                            ref.invalidate(
                                projectByIdProvider(widget.projectId));
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ошибка: $e')));
                            }
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Сохранить'),
                );
              }),
            ),
          ],
        )
      ],
    );
  }
}

class _LedZoneDialog extends StatefulWidget {
  final String projectId;
  final int shieldId;
  final LedZoneModel? zone;

  const _LedZoneDialog(
      {required this.projectId, required this.shieldId, this.zone});

  @override
  State<_LedZoneDialog> createState() => _LedZoneDialogState();
}

class _LedZoneDialogState extends State<_LedZoneDialog> {
  late TextEditingController _transformerController;
  late TextEditingController _zoneController;
  bool _isSaving = false;

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
      title: Text(isEdit ? 'Редактировать LED зону' : 'Добавить LED зону'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _transformerController,
              decoration: const InputDecoration(
                labelText: 'Трансформатор / Блок питания',
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _zoneController,
              decoration: const InputDecoration(
                labelText: 'Зона подсветки / Лента',
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Consumer(builder: (context, ref, _) {
                return FilledButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          setState(() => _isSaving = true);
                          try {
                            final data = {
                              'transformer': _transformerController.text,
                              'zone': _zoneController.text,
                            };
                            if (isEdit) {
                              await ref
                                  .read(engineeringRepositoryProvider)
                                  .updateLedZone(widget.zone!.id, data);
                            } else {
                              await ref
                                  .read(engineeringRepositoryProvider)
                                  .addLedZone(widget.shieldId, data);
                            }
                            ref.invalidate(projectListProvider);
                            ref.invalidate(
                                projectByIdProvider(widget.projectId));
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ошибка: $e')));
                            }
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Сохранить'),
                );
              }),
            ),
          ],
        )
      ],
    );
  }
}

class _ApplyTemplateDialog extends ConsumerWidget {
  final String projectId;
  final int shieldId;
  final String type;

  const _ApplyTemplateDialog(
      {required this.projectId, required this.shieldId, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = type == 'shield'
        ? ref.watch(shieldTemplatesProvider)
        : ref.watch(ledTemplatesProvider);

    return AlertDialog(
      title: const Text('Применить шаблон'),
      content: templatesAsync.when(
        data: (templates) => SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: templates.length,
              itemBuilder: (context, index) {
                // Dynamic cast hack for brevity
                final t = templates[index] as dynamic;
                return ListTile(
                  title: Text(t.name),
                  subtitle: Text(t.description),
                  onTap: () async {
                    Navigator.pop(context);
                    if (type == 'shield') {
                      await ref
                          .read(engineeringRepositoryProvider)
                          .applyShieldTemplate(shieldId, t.id);
                    } else {
                      await ref
                          .read(engineeringRepositoryProvider)
                          .applyLedTemplate(shieldId, t.id);
                    }
                    ref.invalidate(projectListProvider);
                  },
                );
              },
            )),
        loading: () => const SizedBox(
            height: 100, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Text('Error: $e'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена')),
      ],
    );
  }
}
