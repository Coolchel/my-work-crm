import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../engineering/data/models/shield_model.dart';
import '../../../../engineering/data/models/shield_group_model.dart';
import '../../../../engineering/presentation/providers/engineering_providers.dart';
import '../../../../../shared/presentation/dialogs/confirmation_dialog.dart';
import '../../../../../shared/presentation/widgets/friendly_empty_state.dart';
import '../../providers/project_providers.dart';
import '../../dialogs/engineering/shield_group_dialog.dart';
import '../../../../../core/theme/app_design_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
// import '../../dialogs/engineering/apply_template_dialog.dart'; // Removed

class _PowerGroupHeader extends StatelessWidget {
  final String title;
  final int totalModules;
  final Color accentColor;
  final bool isDark;

  const _PowerGroupHeader({
    required this.title,
    required this.totalModules,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyles = context.appTextStyles;
    final titleStyle = textStyles.bodyStrong.copyWith(
      color: isDark ? scheme.onSurface : const Color(0xFF374151),
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      height: 1.15,
    );
    final counterStyle = textStyles.bodyStrong.copyWith(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: accentColor.withOpacity(0.5),
    );
    final counterText = '$totalModules мод';

    return LayoutBuilder(
      builder: (context, constraints) {
        final counterPainter = TextPainter(
          text: TextSpan(text: counterText, style: counterStyle),
          textDirection: Directionality.of(context),
          maxLines: 1,
        )..layout();

        const markerWidth = 4.0;
        const gapAfterMarker = 8.0;
        const gapBeforeLine = 8.0;
        const gapBeforeCounter = 8.0;

        final maxTitleWidth = (constraints.maxWidth -
                markerWidth -
                gapAfterMarker -
                gapBeforeCounter -
                counterPainter.width)
            .clamp(0.0, double.infinity);

        final titlePainter = TextPainter(
          text: TextSpan(text: title, style: titleStyle),
          textDirection: Directionality.of(context),
          maxLines: 2,
          ellipsis: '…',
        )..layout(maxWidth: maxTitleWidth);

        final lineMetrics = titlePainter.computeLineMetrics();
        final lineCount = lineMetrics.isEmpty ? 1 : lineMetrics.length;
        final markerHeight =
            (titlePainter.preferredLineHeight * lineCount).clamp(14.0, 28.0);
        final dividerTop = titlePainter.preferredLineHeight * 0.55;
        final titleWidth = titlePainter.width;
        final shouldShowDivider =
            maxTitleWidth - titleWidth > gapBeforeLine + 6;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: markerWidth,
              height: markerHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.7),
                    accentColor.withOpacity(0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: gapAfterMarker),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxTitleWidth),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ),
            if (shouldShowDivider) ...[
              const SizedBox(width: gapBeforeLine),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: dividerTop),
                  child: Divider(
                    color: accentColor.withOpacity(0.1),
                    thickness: 1,
                    height: 1,
                  ),
                ),
              ),
            ],
            const SizedBox(width: gapBeforeCounter),
            Text(counterText, style: counterStyle),
          ],
        );
      },
    );
  }
}

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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyles = context.appTextStyles;
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
                  style: textStyles.bodyStrong.copyWith(
                    fontSize: 12.5,
                    color: isDark ? scheme.onSurface : Colors.grey.shade700,
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
        if (groups.isEmpty)
          FriendlyEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Список групп пуст',
            subtitle: 'Добавьте первую группу устройств для этого щита.',
            accentColor: themeColor,
            iconSize: 62,
            padding: const EdgeInsets.symmetric(vertical: 10),
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
                  child: _PowerGroupHeader(
                    title: typeName,
                    totalModules: totalModules,
                    accentColor: _getDeviceTypeColor(type),
                    isDark: isDark,
                  ),
                ),
                // Group Items (ListTile style)
                ...groupItems.map((group) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppDesignTokens.softBorder(context),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppDesignTokens.cardShadow(context),
                              blurRadius: 2,
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
                            overlayColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.hovered)) {
                                return AppDesignTokens.hoverOverlay(context);
                              }
                              if (states.contains(WidgetState.pressed)) {
                                return AppDesignTokens.pressedOverlay(context);
                              }
                              return Colors.transparent;
                            }),
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
                                          style: textStyles.bodyStrong.copyWith(
                                            fontSize: 11,
                                            height: 1.2,
                                            color: isDark
                                                ? scheme.onSurface
                                                : const Color(
                                                    0xFF1F2937), // Reverting to dark grey for text
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          group.zone,
                                          style: textStyles.caption.copyWith(
                                            color: isDark
                                                ? scheme.onSurfaceVariant
                                                : Colors.grey.shade600,
                                            fontSize: 10,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
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
    const calmPalette = <String, Color>{
      'load_switch': Color(0xFF98635D),
      'rcd': Color(0xFF9A7A45),
      'circuit_breaker': Color(0xFF58749B),
      'diff_breaker': Color(0xFF72668F),
      'relay': Color(0xFF537A74),
      'contactor': Color(0xFF8A6A46),
      'other': Color(0xFF617487),
    };
    final resolved = calmPalette[type];
    if (resolved != null) {
      return resolved;
    }
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
