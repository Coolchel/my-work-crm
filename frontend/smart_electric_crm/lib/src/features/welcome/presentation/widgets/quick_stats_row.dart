import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

        // 1. Предпросчеты (этапы за месяц)
        // Считаем этапы, созданные в текущем месяце, с "предпросчет" в названии
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

        // 2. Текущие объекты (активные этапы за месяц)
        // Считаем ПРОЕКТЫ, у которых в текущем месяце создан этап (НЕ предпросчет)
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
          if (hasNewActiveStage) {
            activeObjectsCount++;
          }
        }

        // 3. Оплачено (Текущий месяц)
        // Суммарное кол-во оплаченных этапов, созданных в текущем месяце
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
                      'Объекты с новыми этапами\n"Предпросчет"\nв тек. месяце',
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
                      selectedStat == 'active_objects'
                          ? null
                          : 'active_objects'),
                  isSelected: selectedStat == 'active_objects',
                  tooltip:
                      'Объекты с новыми этапами\n(кроме "Предпросчет")\nза тек. месяц',
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
                  tooltip: 'Оплаченные этапы\nв тек. месяце',
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
      )),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? color.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.1),
              width: isSelected ? 2 : 1,
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
                      color: isSelected ? Colors.white : color.shade50,
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
                        color: Colors.grey.shade400,
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
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Show dot if no tooltip (already handled above, but here we want dot next to text if space permits?
                      // Actually, let's keep the dot in the top right if no tooltip, OR maybe just remove the dot since we have the icon now.
                      // The previous code had a dot. The user wants a tooltip.
                      // Let's keep the design clean. The dot was a nice touch for "active".
                      // I'll put the dot back if tooltip is null, or maybe always show it if not selected?
                      // Let's just stick to the tooltip icon for now as requested.
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
