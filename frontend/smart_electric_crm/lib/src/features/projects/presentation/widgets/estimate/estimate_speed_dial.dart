import 'package:flutter/material.dart';

class EstimateSpeedDial extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onDeleteAll;
  final VoidCallback onShowTemplates;
  final VoidCallback onManualAdd;
  final VoidCallback onSearchAdd;
  final TabController tabController;

  const EstimateSpeedDial({
    required this.isExpanded,
    required this.onToggle,
    required this.onDeleteAll,
    required this.onShowTemplates,
    required this.onManualAdd,
    required this.onSearchAdd,
    required this.tabController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Pastel colors for Main FAB based on active tab
    // We need to listen to tabController in the parent or use AnimatedBuilder here?
    // Since TabController is passed, we can use AnimatedBuilder to listen to it.

    return AnimatedBuilder(
      animation: tabController,
      builder: (context, child) {
        final isWorks = tabController.index == 0;
        final mainFabColor =
            isWorks ? Colors.green.shade200 : Colors.blue.shade200;

        // Contextual soft colors for SpeedDial buttons
        final actionBtnColor =
            isWorks ? Colors.green.shade50 : Colors.blue.shade50;
        final actionBtnTextColor =
            isWorks ? Colors.green.shade800 : Colors.blue.shade800;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isExpanded) ...[
              _buildExtendedFab(
                icon: Icons.delete_forever,
                label: "Очистить",
                color: Colors.red.shade50,
                textColor: Colors.red,
                onTap: onDeleteAll,
              ),
              const SizedBox(height: 8),
              _buildExtendedFab(
                icon: Icons.file_copy_outlined,
                label: "Шаблоны",
                color: actionBtnColor,
                textColor: actionBtnTextColor,
                onTap: onShowTemplates,
              ),
              const SizedBox(height: 8),
              _buildExtendedFab(
                icon: Icons.edit_outlined,
                label: "Вручную",
                color: actionBtnColor,
                textColor: actionBtnTextColor,
                onTap: onManualAdd,
              ),
              const SizedBox(height: 8),
              _buildExtendedFab(
                icon: Icons.search,
                label: "Поиск",
                color: actionBtnColor,
                textColor: actionBtnTextColor,
                onTap: onSearchAdd,
              ),
              const SizedBox(height: 16),
            ],
            FloatingActionButton(
              onPressed: onToggle,
              heroTag: 'main_fab',
              backgroundColor: mainFabColor,
              foregroundColor: Colors.black87,
              elevation: 2,
              child: Icon(isExpanded ? Icons.close : Icons.add),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExtendedFab(
      {required IconData icon,
      required String label,
      required Color color,
      Color? textColor,
      required VoidCallback onTap}) {
    final fgColor = textColor ?? Colors.black87;

    return FloatingActionButton.extended(
      onPressed: onTap,
      heroTag: label,
      backgroundColor: color,
      foregroundColor: fgColor,
      elevation: 2,
      hoverColor: Colors.grey.shade100,
      icon: Icon(icon, size: 18),
      label: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
