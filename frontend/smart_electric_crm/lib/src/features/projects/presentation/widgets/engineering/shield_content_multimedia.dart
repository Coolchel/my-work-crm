import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../engineering/data/models/shield_model.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../../../../shared/presentation/dialogs/confirmation_dialog.dart';
import '../../../../../shared/presentation/widgets/friendly_empty_state.dart';
import '../../dialogs/engineering/ethernet_lines_dialog.dart';
import '../../providers/project_providers.dart';
import '../../../../../core/theme/app_design_tokens.dart';
import '../../../../../core/theme/app_typography.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyles = context.appTextStyles;

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
              label: Text('Добавить',
                  style: textStyles.bodyStrong.copyWith(
                    fontSize: 12,
                    color: isDark ? scheme.onSurface : const Color(0xFF616161),
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
                onTap: () => _showEthernetLinesDialog(context, ref),
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return AppDesignTokens.hoverOverlay(context);
                  }
                  if (states.contains(WidgetState.pressed)) {
                    return AppDesignTokens.pressedOverlay(context);
                  }
                  return Colors.transparent;
                }),
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
                            Text(
                              'Ethernet кабель',
                              style: textStyles.bodyStrong.copyWith(
                                fontSize: 12,
                                height: 1.2,
                                color: isDark
                                    ? scheme.onSurface
                                    : const Color(0xFF1F2937),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Линий: ${shield.internetLinesCount}',
                              style: textStyles.caption.copyWith(
                                fontSize: 10.5,
                                color: isDark
                                    ? scheme.onSurfaceVariant
                                    : Colors.grey.shade600,
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
          const FriendlyEmptyState(
            icon: Icons.router_outlined,
            title: 'Ethernet линии не добавлены',
            subtitle: 'Добавьте количество линий, чтобы заполнить этот раздел.',
            accentColor: Colors.green,
            iconSize: 62,
            padding: EdgeInsets.symmetric(vertical: 10),
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
