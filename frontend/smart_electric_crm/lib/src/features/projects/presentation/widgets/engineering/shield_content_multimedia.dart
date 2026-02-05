import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../engineering/data/models/shield_model.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../../../../shared/presentation/dialogs/confirmation_dialog.dart';
import '../../dialogs/engineering/ethernet_lines_dialog.dart';
import '../../providers/project_providers.dart';

class ShieldContentMultimedia extends ConsumerWidget {
  final ShieldModel shield;
  final String projectId;
  final Color themeColor;

  const ShieldContentMultimedia({
    required this.shield,
    required this.projectId,
    required this.themeColor,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Унифицированная кнопка "Добавить" (как в power и LED)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showEthernetLinesDialog(context, ref),
              icon: Icon(Icons.add_rounded,
                  size: 16, color: themeColor.withOpacity(0.7)),
              label: const Text('Добавить',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Color(0xFF616161),
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

        // Отображение линий, если они есть
        if (shield.internetLinesCount > 0)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
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
                onTap: () => _showEthernetLinesDialog(context, ref),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      // Иконка
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.router,
                          size: 14,
                          color: themeColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Текст
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ethernet кабель',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                height: 1.2,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              '× ${shield.internetLinesCount}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Кнопка удаления
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton(
                          icon: Icon(Icons.close,
                              size: 14, color: Colors.grey.shade300),
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              barrierColor: Colors.transparent,
                              builder: (context) => const ConfirmationDialog(
                                title: "Удалить линии?",
                                content:
                                    "Вы уверены, что хотите удалить все Ethernet линии из этого щита?",
                                confirmText: "Удалить",
                                isDestructive: true,
                                themeColor: Color(0xFF374151),
                              ),
                            );

                            if (confirm != true) return;

                            await ref
                                .read(engineeringRepositoryProvider)
                                .updateShield(shield.id, {
                              'internet_lines_count': 0,
                            });
                            ref.invalidate(projectListProvider);
                            ref.invalidate(projectByIdProvider(projectId));
                          },
                          tooltip: "Удалить",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          // Заглушка когда нет линий
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
                Icon(Icons.router, size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text('Ethernet линии не добавлены',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }

  void _showEthernetLinesDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => EthernetLinesDialog(
        projectId: projectId,
        shieldId: shield.id,
        currentLinesCount: shield.internetLinesCount,
        themeColor: themeColor,
      ),
    );
  }
}
