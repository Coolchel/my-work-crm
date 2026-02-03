import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../engineering/data/models/shield_model.dart';
import '../../../../engineering/data/models/shield_group_model.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../../../../shared/presentation/dialogs/confirmation_dialog.dart';
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'УСТРОЙСТВА ЩИТА',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: Color(0xFF374151),
                  ),
                ),
                Text(
                  '${groups.length} позиций спецификации',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showAddGroupDialog(context, ref),
                  icon: Icon(Icons.add_rounded,
                      size: 16, color: Colors.grey.shade600),
                  label: Text('Добавить',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      )),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        if (groups.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text('Список групп пуст',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          )
        else
          ...sortedKeys.map((type) {
            final groupItems = groupedGroups[type]!;
            final totalModules = groupItems.fold<int>(
                0, (sum, item) => sum + (item.modulesCount * item.quantity));
            final typeName = _getDeviceTypeName(type);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Header (Estimate style)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300, // Neutral strip
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        typeName.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF374151), // Neutral dark grey
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Divider(
                            color: Colors.grey.withOpacity(0.08), thickness: 1),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$totalModules mod',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Group Items (ListTile style)
                ...groupItems.map((group) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.15)),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () =>
                                _showAddGroupDialog(context, ref, group: group),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              child: Row(
                                children: [
                                  // Device Icon Badge
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors
                                          .grey.shade50, // Neutral background
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getDeviceIcon(group.deviceType),
                                      size: 14,
                                      color:
                                          Colors.grey.shade400, // Neutral icon
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Device Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          group.device,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                            height: 1.2,
                                            color: const Color(
                                                0xFF1F2937), // Reverting to dark grey for text
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          group.zone,
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
                                      // Quantity badge
                                      if (group.quantity > 1)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: Text(
                                            '${group.quantity} шт.',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4B5563),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 4),
                                      // Close button (Delete)
                                      SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: IconButton(
                                          icon: Icon(Icons.close,
                                              size: 14,
                                              color: Colors.grey.shade300),
                                          padding: EdgeInsets.zero,
                                          onPressed: () async {
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              barrierColor: Colors.transparent,
                                              builder: (context) =>
                                                  ConfirmationDialog(
                                                title: "Удалить группу?",
                                                content:
                                                    "Вы уверены, что хотите удалить эту группу устройств?",
                                                confirmText: "Удалить",
                                                isDestructive: true,
                                                themeColor:
                                                    const Color(0xFF374151),
                                              ),
                                            );

                                            if (confirm != true) return;

                                            await ref
                                                .read(
                                                    engineeringRepositoryProvider)
                                                .deleteShieldGroup(group.id);
                                            ref.invalidate(projectListProvider);
                                            ref.invalidate(
                                                projectByIdProvider(projectId));
                                          },
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
}
