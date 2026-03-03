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

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final spacing = isMobile ? 8.0 : 12.0;

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
                      onTap: () => onStatSelected?.call(
                          selectedStat == 'pre_calc' ? null : 'pre_calc'),
                      isSelected: selectedStat == 'pre_calc',
                      compact: isMobile,
                      tooltip:
                          'Объекты с новыми этапами\n"Предпросчет"\nв текущем месяце',
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _StatCard(
                      title: 'Текущие',
                      value: activeObjectsCount.toString(),
                      icon: Icons.engineering,
                      color: Colors.orange,
                      onTap: () => onStatSelected?.call(
                        selectedStat == 'active_objects'
                            ? null
                            : 'active_objects',
                      ),
                      isSelected: selectedStat == 'active_objects',
                      compact: isMobile,
                      tooltip:
                          'Объекты с новыми этапами\n(кроме "Предпросчет")\nза текущий месяц',
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _StatCard(
                      title: 'Оплачено',
                      value: paidCount.toString(),
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      onTap: () => onStatSelected
                          ?.call(selectedStat == 'paid' ? null : 'paid'),
                      isSelected: selectedStat == 'paid',
                      compact: isMobile,
                      tooltip: 'Оплаченные этапы\nв текущем месяце',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}

class _StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final MaterialColor color;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool compact;
  final String? tooltip;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.isSelected = false,
    this.compact = false,
    this.tooltip,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final effectiveHover = _isHovered;
    final compact = widget.compact;
    final baseGradient = isDark
        ? const [Color(0xFF171A21), Color(0xFF151920)]
        : const [Color(0xFFF7F9FF), Color(0xFFF1F5FF)];
    final selectedGradient = isDark
        ? const [Color(0xFF232831), Color(0xFF1C2028)]
        : const [Color(0xFFFFFFFF), Color(0xFFF6F8FC)];
    final selectedBorderColor = isDark
        ? Colors.white.withOpacity(0.42)
        : scheme.onSurface.withOpacity(0.20);
    final selectedShadowColor = isDark
        ? Colors.white.withOpacity(0.14)
        : Colors.black.withOpacity(0.07);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isSelected ? selectedGradient : baseGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (widget.isSelected)
              BoxShadow(
                color: selectedShadowColor,
                blurRadius: isDark ? 18 : 14,
                spreadRadius: isDark ? 0.4 : 0,
                offset: const Offset(0, 0),
              ),
            BoxShadow(
              color:
                  AppDesignTokens.cardShadow(context, hovered: effectiveHover),
              blurRadius: effectiveHover ? 15 : 11,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: widget.isSelected
                ? selectedBorderColor
                : AppDesignTokens.cardBorder(
                    context,
                    hovered: effectiveHover,
                  ),
            width: widget.isSelected ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
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
            child: Padding(
              padding: EdgeInsets.all(compact ? 10 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(compact ? 8 : 10),
                        decoration: BoxDecoration(
                          color: widget.isSelected
                              ? (isDark
                                  ? Colors.white.withOpacity(0.13)
                                  : Colors.black.withOpacity(0.06))
                              : widget.color.withOpacity(isDark ? 0.14 : 0.1),
                          borderRadius:
                              BorderRadius.circular(compact ? 10 : 12),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.color,
                          size: compact ? 18 : 22,
                        ),
                      ),
                      if (widget.tooltip != null)
                        Tooltip(
                          message: widget.tooltip!,
                          textAlign: TextAlign.center,
                          child: Padding(
                            padding: EdgeInsets.only(top: compact ? 2 : 1),
                            child: Text(
                              '?',
                              style: TextStyle(
                                fontSize: compact ? 14 : 15,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurfaceVariant.withOpacity(
                                  isDark ? 0.46 : 0.52,
                                ),
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      if (widget.tooltip == null &&
                          int.tryParse(widget.value) != null &&
                          int.parse(widget.value) > 0)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.color,
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
                        widget.value,
                        style: TextStyle(
                          fontSize: compact ? 21 : 24,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: compact ? 11 : 12,
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
        ),
      ),
    );
  }
}
