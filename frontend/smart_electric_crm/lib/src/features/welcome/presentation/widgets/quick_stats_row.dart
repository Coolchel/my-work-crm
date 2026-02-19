import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';

import '../../../projects/presentation/providers/project_providers.dart';

class QuickStatsRow extends ConsumerWidget {
  final Function(String?)? onStatSelected;
  final String? selectedStat;

  const QuickStatsRow({
    super.key,
    this.onStatSelected,
    this.selectedStat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectListProvider);

    return projectsAsync.when(
      data: (projects) {
        final now = DateTime.now();
        final currentMonth = now.month;
        final currentYear = now.year;

        int preCalcCount = 0;
        for (final project in projects) {
          for (final stage in project.stages) {
            if (stage.createdAt != null &&
                stage.createdAt!.year == currentYear &&
                stage.createdAt!.month == currentMonth &&
                stage.title.toLowerCase().contains('предпросчет')) {
              preCalcCount++;
            }
          }
        }

        int activeObjectsCount = 0;
        for (final project in projects) {
          bool hasNewActiveStage = false;
          for (final stage in project.stages) {
            if (stage.createdAt != null &&
                stage.createdAt!.year == currentYear &&
                stage.createdAt!.month == currentMonth &&
                !stage.title.toLowerCase().contains('предпросчет')) {
              hasNewActiveStage = true;
              break;
            }
          }
          if (hasNewActiveStage) activeObjectsCount++;
        }

        int paidCount = 0;
        for (final project in projects) {
          for (final stage in project.stages) {
            if (stage.isPaid &&
                stage.createdAt != null &&
                stage.createdAt!.year == currentYear &&
                stage.createdAt!.month == currentMonth) {
              paidCount++;
            }
          }
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Предпросчеты',
                  value: preCalcCount.toString(),
                  icon: Icons.calculate_outlined,
                  color: Colors.blue,
                  onTap: () => onStatSelected
                      ?.call(selectedStat == 'pre_calc' ? null : 'pre_calc'),
                  isSelected: selectedStat == 'pre_calc',
                  tooltip:
                      'Объекты с новыми этапами\n"Предпросчет"\nв текущем месяце',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Текущие',
                  value: activeObjectsCount.toString(),
                  icon: Icons.engineering,
                  color: Colors.orange,
                  onTap: () => onStatSelected?.call(
                    selectedStat == 'active_objects' ? null : 'active_objects',
                  ),
                  isSelected: selectedStat == 'active_objects',
                  tooltip:
                      'Объекты с новыми этапами\n(кроме "Предпросчет")\nза текущий месяц',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Оплачено',
                  value: paidCount.toString(),
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  onTap: () => onStatSelected
                      ?.call(selectedStat == 'paid' ? null : 'paid'),
                  isSelected: selectedStat == 'paid',
                  tooltip: 'Оплаченные этапы\nв текущем месяце',
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => const Text('Ошибка загрузки'),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final MaterialColor color;
  final VoidCallback? onTap;
  final bool isSelected;
  final String? tooltip;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.isSelected = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);

    final selectedBg = isDark ? color.withOpacity(0.18) : color.shade50;
    final normalBg = AppDesignTokens.cardBackground(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppDesignTokens.pressedOverlay(context);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppDesignTokens.hoverOverlay(context);
          }
          return null;
        }),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : normalBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppDesignTokens.cardShadow(context),
                blurRadius: 9,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(isDark ? 0.8 : 1)
                  : AppDesignTokens.cardBorder(context),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(isDark ? 0.28 : 0.15)
                          : color.withOpacity(isDark ? 0.14 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  if (tooltip != null)
                    Tooltip(
                      message: tooltip!,
                      textAlign: TextAlign.center,
                      child: Icon(
                        Icons.help_outline,
                        size: 18,
                        color: scheme.onSurfaceVariant.withOpacity(0.75),
                      ),
                    ),
                  if (tooltip == null &&
                      int.tryParse(value) != null &&
                      int.parse(value) > 0)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
