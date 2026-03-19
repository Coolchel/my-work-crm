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
    final hasLines = shield.internetLinesCount > 0;
    final summaryBackground =
        isDark ? scheme.surfaceContainerHigh : const Color(0xFFF8FAFC);
    final summaryBorderColor = AppDesignTokens.softBorder(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showEthernetLinesDialog(context, ref),
              icon: Icon(
                hasLines ? Icons.edit_outlined : Icons.add_rounded,
                size: 16,
                color: themeColor.withOpacity(0.7),
              ),
              label: Text(hasLines ? 'Изменить' : 'Добавить',
                  style: textStyles.bodyStrong.copyWith(
                    fontSize: 12.5,
                    color: isDark ? scheme.onSurface : const Color(0xFF616161),
                  )),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppDesignTokens.softBorder(context)),
                backgroundColor:
                    isDark ? scheme.surfaceContainerHigh : scheme.surface,
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
        if (hasLines)
          Container(
            decoration: BoxDecoration(
              color: summaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: summaryBorderColor),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
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
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  themeColor.withOpacity(isDark ? 0.18 : 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.router_rounded,
                              size: 16,
                              color: themeColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ethernet линии',
                                  style: textStyles.bodyStrong.copyWith(
                                    fontSize: 12,
                                    height: 1.2,
                                    color: isDark
                                        ? scheme.onSurface
                                        : const Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Количество линий UTP-5e для этого щита',
                                  style: textStyles.caption.copyWith(
                                    fontSize: 10.5,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 16,
                                color: scheme.onSurfaceVariant,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  barrierColor: Colors.transparent,
                                  builder: (context) =>
                                      const ConfirmationDialog(
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  themeColor.withOpacity(isDark ? 0.18 : 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${shield.internetLinesCount} линий',
                              style: textStyles.captionStrong.copyWith(
                                color: themeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Нажмите, чтобы скорректировать количество.',
                              style: textStyles.caption.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          FriendlyEmptyState(
            icon: Icons.router_outlined,
            title: 'Ethernet линии не добавлены',
            subtitle: 'Добавьте количество линий, чтобы заполнить этот раздел.',
            accentColor: themeColor,
            iconSize: 62,
            padding: const EdgeInsets.symmetric(vertical: 10),
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
