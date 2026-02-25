import 'package:flutter/material.dart';

class EstimateAppBarActions extends StatelessWidget {
  final bool showPrices;
  final int currentIndex;
  final bool canImportWorksFromPrecalc;
  final bool canImportMaterialsFromPrecalc;
  final bool isImportingFromPrecalc;
  final String stageTitle;
  final bool isApplyingStage3Calculator;
  final VoidCallback onShowPdfActions;
  final VoidCallback onShowTextActions;
  final ValueChanged<String> onMenuSelected;

  const EstimateAppBarActions({
    super.key,
    required this.showPrices,
    required this.currentIndex,
    required this.canImportWorksFromPrecalc,
    required this.canImportMaterialsFromPrecalc,
    required this.isImportingFromPrecalc,
    required this.stageTitle,
    required this.isApplyingStage3Calculator,
    required this.onShowPdfActions,
    required this.onShowTextActions,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.auto_graph_rounded),
          tooltip: 'PDF смета',
          onPressed: onShowPdfActions,
        ),
        IconButton(
          icon: const Icon(Icons.segment_rounded),
          tooltip: 'Текстовые сметы',
          onPressed: onShowTextActions,
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: 'Действия',
          icon: const Icon(Icons.more_vert),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          surfaceTintColor: Theme.of(context).colorScheme.surface,
          onSelected: onMenuSelected,
          itemBuilder: (BuildContext context) {
            final isWork = currentIndex == 0;
            return [
              if (!isWork) ...[
                CheckedPopupMenuItem(
                  value: 'toggle_prices',
                  checked: showPrices,
                  child: const Text('Показывать цены'),
                ),
                const PopupMenuDivider(),
              ],
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(
                      isWork ? Icons.auto_awesome : Icons.download_rounded,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isWork ? 'Рассчитать работы' : 'Импорт из инженерки',
                    ),
                  ],
                ),
              ),
              if ((isWork && canImportWorksFromPrecalc) ||
                  (!isWork && canImportMaterialsFromPrecalc)) ...[
                PopupMenuItem(
                  value: 'import_from_precalc',
                  enabled: !isImportingFromPrecalc,
                  child: Row(
                    children: [
                      Icon(
                        Icons.move_down_rounded,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isImportingFromPrecalc
                            ? 'Перенос...'
                            : 'Перенести из предпросчета',
                      ),
                    ],
                  ),
                ),
              ],
              if (!isWork && stageTitle == 'stage_3') ...[
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'stage3_armature_calculator',
                  enabled: !isApplyingStage3Calculator,
                  child: Row(
                    children: [
                      Icon(
                        Icons.calculate_rounded,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isApplyingStage3Calculator
                            ? 'Обработка...'
                            : 'Калькулятор арматуры',
                      ),
                    ],
                  ),
                ),
              ],
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'apply_template',
                child: Row(
                  children: [
                    Icon(Icons.copy_all_rounded,
                        color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 12),
                    const Text('Применить шаблон...'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'save_template',
                child: Row(
                  children: [
                    Icon(Icons.save_as, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 12),
                    const Text('Сохранить как шаблон...'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever,
                        color: Colors.red.shade300, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Очистить смету...',
                      style: TextStyle(color: Colors.red.shade400),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
