import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../engineering/data/models/shield_model.dart';
import '../../../../engineering/data/models/shield_group_model.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../../../../shared/presentation/dialogs/confirmation_dialog.dart';
import '../../../../../shared/presentation/widgets/friendly_empty_state.dart';
import '../../providers/project_providers.dart';
import '../../dialogs/engineering/shield_group_dialog.dart';
// import '../../dialogs/engineering/apply_template_dialog.dart'; // Removed

class ShieldContentPower extends ConsumerWidget {
  final ShieldModel shield;
  final String projectId;
  final Color themeColor;

  const ShieldContentPower(
      {required this.shield,
      required this.projectId,
      required this.themeColor,
      super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... (same as before until Row with buttons)
    final groups = shield.groups;

    // Group items by device type, preserving insertion order
    final Map<String, List<ShieldGroupModel>> groupedGroups = {};
    final List<String> keyOrder = []; // Порядок первого появления типа

    for (var group in groups) {
      if (!groupedGroups.containsKey(group.deviceType)) {
        groupedGroups[group.deviceType] = [];
        keyOrder.add(group.deviceType); // Запоминаем порядок
      }
      groupedGroups[group.deviceType]!.add(group);
    }

    // Используем порядок добавления
    final sortedKeys = keyOrder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showAddGroupDialog(context, ref),
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
        if (groups.isEmpty)
          const FriendlyEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Список групп пуст',
            subtitle: 'Добавьте первую группу устройств для этого щита.',
            accentColor: Colors.blueGrey,
            iconSize: 62,
            padding: EdgeInsets.symmetric(vertical: 10),
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
                          gradient: LinearGradient(
                            colors: [
                              _getDeviceTypeColor(type).withOpacity(0.7),
                              _getDeviceTypeColor(type).withOpacity(0.3),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        typeName.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Divider(
                            color: themeColor.withOpacity(0.1), thickness: 1),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$totalModules мод',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: themeColor.withOpacity(0.5),
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
                              Border.all(color: themeColor.withOpacity(0.08)),
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
                                      color:
                                          _getDeviceTypeColor(group.deviceType)
                                              .withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getDeviceIcon(group.deviceType),
                                      size: 14,
                                      color:
                                          _getDeviceTypeColor(group.deviceType)
                                              .withOpacity(0.7),
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
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                            height: 1.2,
                                            color: Color(
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
                                      // Quantity badge removed
                                      // if (group.quantity > 1) ...
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
                                                  const ConfirmationDialog(
                                                title: "Удалить группу?",
                                                content:
                                                    "Вы уверены, что хотите удалить эту группу устройств?",
                                                confirmText: "Удалить",
                                                isDestructive: true,
                                                themeColor: Color(0xFF374151),
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
          projectId: projectId,
          shieldId: shield.id,
          group: group,
          themeColor: themeColor),
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

  // Определяет цвет иконки на основе типа устройства (семантическое кодирование)
  Color _getDeviceTypeColor(String type) {
    switch (type) {
      case 'load_switch':
        return Colors.red.shade600; // Рубильники - критичное устройство
      case 'rcd':
        return Colors.amber.shade700; // УЗО - предупреждение, защита от утечки
      case 'circuit_breaker':
        return Colors.blue.shade600; // Автоматы - основная защита, стабильность
      case 'diff_breaker':
        return Colors.purple.shade600; // Диф. автоматы - премиум защита
      case 'relay':
        return Colors.teal.shade600; // Реле - автоматизация, технологии
      case 'contactor':
        return Colors.orange.shade700; // Контакторы - силовая коммутация
      default:
        return Colors.blueGrey.shade600; // Другое - нейтральность
    }
  }
}
