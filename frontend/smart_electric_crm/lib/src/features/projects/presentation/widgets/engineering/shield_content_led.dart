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

    const themeColor = Colors.red; // Red for LED

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ЗОНЫ УПРАВЛЕНИЯ',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: themeColor,
                  ),
                ),
                Text(
                  '${zones.length} линий в щите',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
            Row(
              children: [
                if (zones.isNotEmpty)
                  IconButton(
                    onPressed: () => _showSaveTemplateDialog(context, ref),
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.all(8),
                    ),
                    icon: const Icon(Icons.save_as_rounded, size: 20),
                    tooltip: "В шаблон",
                  ),
                const SizedBox(width: 4),
                OutlinedButton(
                  onPressed: () => _showApplyTemplateDialog(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo.shade800,
                    side: BorderSide(color: Colors.indigo.shade100),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('ШАБЛОН',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _showAddZoneDialog(context, ref),
                  style: FilledButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('ДОБАВИТЬ',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        if (zones.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 32, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text('Список зон пуст',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          )
        else
          ...zones.map((zone) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => _showAddZoneDialog(context, ref, zone: zone),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            // Icon Badge
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.wb_incandescent_rounded,
                                size: 14,
                                color: Colors.red.shade400,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Zone Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    zone.transformer,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                      height: 1.2,
                                      color: Color(0xFF1F2937),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    zone.zone,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Right side info and actions
                            Row(
                              children: [
                                // Quantity indicator
                                if (zone.quantity > 1)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      '${zone.quantity} шт.',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                // Small Delete button
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        barrierColor: Colors.transparent,
                                        builder: (context) =>
                                            const ConfirmationDialog(
                                          title: "Удалить зону?",
                                          content:
                                              "Вы уверены, что хотите удалить эту LED зону?",
                                          confirmText: "Удалить",
                                          isDestructive: true,
                                          themeColor: Color(0xFF374151),
                                        ),
                                      );

                                      if (confirm != true) return;

                                      await ref
                                          .read(engineeringRepositoryProvider)
                                          .deleteLedZone(zone.id);
                                      ref.invalidate(projectListProvider);
                                      ref.invalidate(
                                          projectByIdProvider(projectId));
                                    },
                                    icon: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.grey.shade300,
                                    ),
                                    tooltip: "Удалить",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
