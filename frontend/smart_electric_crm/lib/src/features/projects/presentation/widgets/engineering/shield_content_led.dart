import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../engineering/data/models/shield_model.dart';
import '../../../../engineering/data/models/led_zone_model.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../../../engineering/presentation/providers/template_providers.dart';
import '../../../../engineering/presentation/dialogs/template_selection_dialog.dart';
import '../../../../../shared/presentation/dialogs/text_input_dialog.dart';
import '../../../../../shared/presentation/dialogs/confirmation_dialog.dart';
import '../../../../engineering/data/models/template_models.dart';
import '../../providers/project_providers.dart';
import '../../dialogs/engineering/led_zone_dialog.dart';
// import '../../dialogs/engineering/apply_template_dialog.dart';

class ShieldContentLed extends ConsumerWidget {
  final ShieldModel shield;
  final String projectId;

  const ShieldContentLed(
      {required this.shield, required this.projectId, super.key});

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
                if (zones.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      onPressed: () => _showSaveTemplateDialog(context, ref),
                      icon: const Icon(Icons.save_as,
                          size: 20, color: Colors.purple),
                      tooltip: "Сохранить как шаблон",
                    ),
                  ),
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
          ...zones.map((zone) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 4),
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                onTap: () => _showAddZoneDialog(context, ref, zone: zone),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lightbulb,
                      size: 20, color: Colors.purple),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(zone.transformer,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    if (zone.quantity > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'x${zone.quantity}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(zone.zone),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, size: 16, color: Colors.grey),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      barrierColor: Colors.transparent,
                      builder: (context) => const ConfirmationDialog(
                        title: "Удалить зону?",
                        content: "Вы уверены, что хотите удалить эту LED зону?",
                        confirmText: "Удалить",
                        isDestructive: true,
                        themeColor: Colors.purple,
                      ),
                    );

                    if (confirm != true) return;

                    await ref
                        .read(engineeringRepositoryProvider)
                        .deleteLedZone(zone.id);
                    ref.invalidate(projectListProvider);
                  },
                ),
              ))),
      ],
    );
  }

  void _showAddZoneDialog(BuildContext context, WidgetRef ref,
      {LedZoneModel? zone}) {
    showDialog(
      context: context,
      builder: (context) =>
          LedZoneDialog(projectId: projectId, shieldId: shield.id, zone: zone),
    );
  }

  void _showApplyTemplateDialog(BuildContext context, WidgetRef ref) async {
    try {
      final templates = await ref.read(ledShieldTemplatesProvider.future);
      // ignore: use_build_context_synchronously
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => TemplateSelectionDialog<LedShieldTemplate>(
          title: "Шаблоны LED щита",
          templates: templates,
          getName: (t) => t.name,
          getDescription: (t) => t.description,
          onSelected: (t) async {
            await ref
                .read(engineeringRepositoryProvider)
                .applyLedTemplate(shield.id, t.id);
            ref.invalidate(projectListProvider);
          },
          onDelete: (t) async {
            await ref
                .read(templateRepositoryProvider)
                .deleteLedShieldTemplate(t.id);
            ref.invalidate(ledShieldTemplatesProvider);
          },
          themeColor: Colors.purple,
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

  void _showSaveTemplateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<dynamic>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => const TextInputDialog(
        title: "Сохранить LED щит как шаблон",
        labelText: "Название шаблона",
        descriptionLabelText: "Описание (опционально)",
        themeColor: Colors.purple,
      ),
    );

    if (result == null) return;

    final name = result is Map ? result['text'] : result;
    final description = result is Map ? result['description'] : '';

    if (name == null || name.isEmpty) return;

    try {
      await ref
          .read(templateRepositoryProvider)
          .createLedShieldTemplateFromShield(shield.id, name,
              description: description);
      ref.invalidate(ledShieldTemplatesProvider);
      // ignore: use_build_context_synchronously
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Шаблон '$name' создан")));
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Ошибка: $e")));
      }
    }
  }
}
