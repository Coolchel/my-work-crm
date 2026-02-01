import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../engineering/data/models/shield_model.dart';
import '../../../../engineering/data/models/shield_group_model.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../../../engineering/presentation/providers/template_providers.dart';
import '../../../../engineering/presentation/dialogs/template_selection_dialog.dart';
import '../../../../engineering/data/models/template_models.dart';
import '../../providers/project_providers.dart';
import '../../dialogs/engineering/shield_group_dialog.dart';
// import '../../dialogs/engineering/apply_template_dialog.dart'; // Removed

class ShieldContentPower extends ConsumerWidget {
  final ShieldModel shield;
  final String projectId;

  const ShieldContentPower(
      {required this.shield, required this.projectId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... (same as before until Row with buttons)
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
      'load_switch',
      'relay',
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
                if (groups.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      onPressed: () => _showSaveTemplateDialog(context, ref),
                      icon: const Icon(Icons.save_as,
                          size: 20, color: Colors.blue),
                      tooltip: "Сохранить как шаблон",
                    ),
                  ),
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
            final totalModules = groupItems.fold<int>(
                0, (sum, item) => sum + (item.modulesCount * item.quantity));
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
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(group.device,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                            ),
                            if (group.quantity > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getDeviceColor(group.deviceType)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'x${group.quantity}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getDeviceColor(group.deviceType),
                                  ),
                                ),
                              ),
                          ],
                        ),
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
    showDialog(
      context: context,
      builder: (context) => ShieldGroupDialog(
          projectId: projectId, shieldId: shield.id, group: group),
    );
  }

  void _showApplyTemplateDialog(BuildContext context, WidgetRef ref) async {
    try {
      final templates = await ref.read(powerShieldTemplatesProvider.future);
      // ignore: use_build_context_synchronously
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => TemplateSelectionDialog<PowerShieldTemplate>(
          title: "Шаблоны силового щита",
          templates: templates,
          getName: (t) => t.name,
          getDescription: (t) => t.description,
          onSelected: (t) async {
            await ref
                .read(engineeringRepositoryProvider)
                .applyShieldTemplate(shield.id, t.id);
            ref.invalidate(projectListProvider);
          },
          onDelete: (t) async {
            await ref
                .read(templateRepositoryProvider)
                .deletePowerShieldTemplate(t.id);
            ref.invalidate(powerShieldTemplatesProvider);
          },
          themeColor: Colors.teal,
          onCreate: () => _showSaveTemplateDialog(context, ref),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Ошибка: $e")));
      }
    }
  }

  void _showSaveTemplateDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Сохранить щит как шаблон"),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: "Название шаблона",
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена"),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              try {
                await ref
                    .read(templateRepositoryProvider)
                    .createPowerShieldTemplateFromShield(
                        shield.id, nameCtrl.text);
                ref.invalidate(powerShieldTemplatesProvider);
                // ignore: use_build_context_synchronously
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Шаблон '${nameCtrl.text}' создан")));
                }
              } catch (e) {
                // ignore: use_build_context_synchronously
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Ошибка: $e")));
                }
              }
            },
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );
  }

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
