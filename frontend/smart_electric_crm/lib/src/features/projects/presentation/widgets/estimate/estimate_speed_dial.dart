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
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, child) {
        final scheme = Theme.of(context).colorScheme;
        final isWorks = tabController.index == 0;
        final mainFabColor = isWorks ? Colors.green : Colors.blue.shade200;

        // Contextual soft colors for SpeedDial buttons
        final actionBtnColor = isWorks ? Colors.green : Colors.blue.shade50;
        final actionBtnTextColor =
            isWorks ? Colors.green : Colors.blue.shade800;

        // Hover Colors
        final actionBtnHoverColor =
            isWorks ? Colors.green : Colors.blue.shade100;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isExpanded) ...[
              IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildExtendedFab(
                      icon: Icons.delete_forever,
                      label: "Очистить",
                      color: Colors.red.shade50,
                      hoverColor: Colors.red.shade100,
                      textColor: Colors.red,
                      onTap: onDeleteAll,
                    ),
                    const SizedBox(height: 8),
                    _buildExtendedFab(
                      icon: Icons.file_copy_outlined,
                      label: "Шаблоны",
                      color: actionBtnColor,
                      hoverColor: actionBtnHoverColor,
                      textColor: actionBtnTextColor,
                      onTap: onShowTemplates,
                    ),
                    const SizedBox(height: 8),
                    _buildExtendedFab(
                      icon: Icons.edit_outlined,
                      label: "Вручную",
                      color: actionBtnColor,
                      hoverColor: actionBtnHoverColor,
                      textColor: actionBtnTextColor,
                      onTap: onManualAdd,
                    ),
                    const SizedBox(height: 8),
                    _buildExtendedFab(
                      icon: Icons.search,
                      label: "Поиск",
                      color: actionBtnColor,
                      hoverColor: actionBtnHoverColor,
                      textColor: actionBtnTextColor,
                      onTap: onSearchAdd,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            FloatingActionButton(
              onPressed: onToggle,
              heroTag: 'main_fab',
              backgroundColor: mainFabColor,
              foregroundColor: scheme.onPrimary,
              elevation: 2,
              child: Icon(isExpanded ? Icons.close : Icons.add),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExtendedFab({
    required IconData icon,
    required String label,
    required Color color,
    required Color hoverColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    final fgColor = textColor ?? Colors.black;

    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        alignment: Alignment
            .centerLeft, // Align content to left for better look in menu
        backgroundColor: color,
        foregroundColor: fgColor,
        elevation: 2,
        shadowColor: Colors.black38,
        minimumSize: const Size(0, 42), // Increased height to 42
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        shape: const StadiumBorder(),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(WidgetState.hovered)) {
              return hoverColor;
            }
            if (states.contains(WidgetState.pressed)) {
              return hoverColor.withOpacity(0.8);
            }
            return null;
          },
        ),
      ),
      icon: Icon(icon, size: 20), // Slightly larger icon
      label: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
