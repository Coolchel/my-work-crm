import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../engineering/data/models/shield_model.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../../../engineering/data/models/led_zone_model.dart';
import '../../../../../shared/presentation/dialogs/confirmation_dialog.dart';
import '../../../../../shared/presentation/widgets/friendly_empty_state.dart';
import '../../providers/project_providers.dart';
import '../../dialogs/engineering/led_zone_dialog.dart';
// import '../../dialogs/engineering/apply_template_dialog.dart';

class ShieldContentLed extends ConsumerWidget {
  final ShieldModel shield;
  final String projectId;
  final Color themeColor;

  const ShieldContentLed(
      {required this.shield,
      required this.projectId,
      required this.themeColor,
      super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = shield.ledZones;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showAddZoneDialog(context, ref),
              icon: Icon(Icons.add_rounded,
                  size: 16, color: themeColor.withOpacity(0.7)),
              label: Text('Добавить',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  )),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: themeColor.withOpacity(0.15)),
                backgroundColor: themeColor.withOpacity(0.02),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: const Size(0, 34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (zones.isEmpty)
          const FriendlyEmptyState(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Список зон пуст',
            subtitle: 'Добавьте первую LED-зону для этого щита.',
            accentColor: Colors.purple,
            iconSize: 60,
            padding: EdgeInsets.symmetric(vertical: 10),
          )
        else
          ...zones.map((zone) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: themeColor.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
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
                                color: themeColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.wb_incandescent_rounded,
                                size: 14,
                                color: themeColor.withOpacity(0.6),
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
                                // Quantity badge removed
                                // if (zone.quantity > 1) ...
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
      builder: (context) => LedZoneDialog(
        projectId: projectId,
        shieldId: shield.id,
        zone: zone,
        existingZonesCount: shield.ledZones.length,
        themeColor: themeColor,
      ),
    );
  }
}
