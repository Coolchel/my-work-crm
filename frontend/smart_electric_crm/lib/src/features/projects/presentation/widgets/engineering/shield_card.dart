import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../engineering/data/models/shield_model.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../providers/project_providers.dart';
import '../../dialogs/engineering/edit_shield_dialog.dart';
import 'shield_content_power.dart';
import 'shield_content_led.dart';
import '../../../../engineering/presentation/dialogs/template_selection_dialog.dart';
import '../../../../engineering/presentation/providers/template_providers.dart';
import '../../../../engineering/data/models/template_models.dart';

class ShieldCard extends ConsumerWidget {
  final ShieldModel shield;
  final String projectId;

  const ShieldCard({required this.shield, required this.projectId, super.key});

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
        ref.invalidate(projectByIdProvider(projectId));
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
            ShieldContentPower(shield: shield, projectId: projectId),
          if (shield.shieldType == 'led')
            ShieldContentLed(shield: shield, projectId: projectId),

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
              TextButton.icon(
                onPressed: () => _showEditShieldDialog(context, ref, shield),
                icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                label: const Text('Изменить',
                    style: TextStyle(color: Colors.blue)),
              ),
              if (shield.shieldType == 'power' || shield.shieldType == 'led')
                IconButton(
                  onPressed: () => _showTemplateDialog(context, ref, shield),
                  icon: const Icon(Icons.copy_all, color: Colors.indigo),
                  tooltip: "Применить шаблон",
                ),
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

  void _showEditShieldDialog(
      BuildContext context, WidgetRef ref, ShieldModel shield) {
    showDialog(
      context: context,
      builder: (context) =>
          EditShieldDialog(shield: shield, projectId: projectId),
    );
  }

  void _showTemplateDialog(
      BuildContext context, WidgetRef ref, ShieldModel shield) async {
    try {
      final isPower = shield.shieldType == 'power';
      final templates = isPower
          ? await ref.read(powerShieldTemplatesProvider.future)
          : await ref.read(ledShieldTemplatesProvider.future);

      if (!context.mounted) return;

      // Handle generic type safely
      void showSelect<T>(List<T> items) {
        showDialog(
          context: context,
          builder: (ctx) => TemplateSelectionDialog<T>(
            title: isPower ? "Выберите силовой шаблон" : "Выберите LED шаблон",
            templates: items,
            getName: (t) => (t as dynamic).name,
            getDescription: (t) => (t as dynamic).description ?? '',
            onSelected: (t) =>
                _applyTemplate(context, ref, shield, (t as dynamic).id),
            themeColor: isPower ? Colors.teal : Colors.purple,
          ),
        );
      }

      if (isPower) {
        showSelect<PowerShieldTemplate>(templates as List<PowerShieldTemplate>);
      } else {
        showSelect<LedShieldTemplate>(templates as List<LedShieldTemplate>);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ошибка загрузки шаблонов: $e")));
      }
    }
  }

  Future<void> _applyTemplate(BuildContext context, WidgetRef ref,
      ShieldModel shield, int templateId) async {
    try {
      if (shield.shieldType == 'power') {
        await ref
            .read(templateRepositoryProvider)
            .applyPowerShieldTemplate(shield.id, templateId);
      } else {
        await ref
            .read(templateRepositoryProvider)
            .applyLedShieldTemplate(shield.id, templateId);
      }

      ref.invalidate(projectListProvider);
      ref.invalidate(projectByIdProvider(projectId));

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Шаблон применен!")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Ошибка применения: $e")));
      }
    }
  }
}
