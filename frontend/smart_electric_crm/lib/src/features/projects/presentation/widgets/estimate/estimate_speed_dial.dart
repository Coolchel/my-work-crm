import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';

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
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, child) {
        final scheme = Theme.of(context).colorScheme;
        final isDark = AppDesignTokens.isDark(context);
        final isWorks = tabController.index == 0;
        final mainFabColor = isWorks
            ? (isDark ? const Color(0xFF2A5139) : Colors.green)
            : (isDark ? const Color(0xFF2A4468) : Colors.blue.shade300);

        final actionBtnColor = isWorks
            ? (isDark ? const Color(0xFF1F3A2A) : Colors.green.shade50)
            : (isDark ? const Color(0xFF1F2E46) : Colors.blue.shade50);
        final actionBtnTextColor = isWorks
            ? (isDark ? const Color(0xFF8EE0AF) : Colors.green.shade800)
            : (isDark ? const Color(0xFF8FBFFF) : Colors.blue.shade800);
        final actionBtnHoverColor = isWorks
            ? (isDark ? const Color(0xFF2A5139) : Colors.green.shade100)
            : (isDark ? const Color(0xFF2A4468) : Colors.blue.shade100);

        final deleteBtnColor =
            isDark ? const Color(0xFF4A2525) : Colors.red.shade50;
        final deleteBtnTextColor =
            isDark ? const Color(0xFFFFB4B4) : Colors.red.shade700;
        final deleteBtnHoverColor =
            isDark ? const Color(0xFF6A3131) : Colors.red.shade100;

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
                      context: context,
                      icon: Icons.delete_forever,
                      label: 'Очистить',
                      color: deleteBtnColor,
                      hoverColor: deleteBtnHoverColor,
                      textColor: deleteBtnTextColor,
                      onTap: onDeleteAll,
                    ),
                    const SizedBox(height: 8),
                    _buildExtendedFab(
                      context: context,
                      icon: Icons.file_copy_outlined,
                      label: 'Шаблоны',
                      color: actionBtnColor,
                      hoverColor: actionBtnHoverColor,
                      textColor: actionBtnTextColor,
                      onTap: onShowTemplates,
                    ),
                    const SizedBox(height: 8),
                    _buildExtendedFab(
                      context: context,
                      icon: Icons.edit_outlined,
                      label: 'Вручную',
                      color: actionBtnColor,
                      hoverColor: actionBtnHoverColor,
                      textColor: actionBtnTextColor,
                      onTap: onManualAdd,
                    ),
                    const SizedBox(height: 8),
                    _buildExtendedFab(
                      context: context,
                      icon: Icons.search,
                      label: 'Поиск',
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
    required BuildContext context,
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
        alignment: Alignment.centerLeft,
        backgroundColor: color,
        foregroundColor: fgColor,
        elevation: 2,
        shadowColor: Colors.black38,
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        shape: const StadiumBorder(),
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered)) {
            return hoverColor;
          }
          if (states.contains(WidgetState.pressed)) {
            return hoverColor.withOpacity(0.92);
          }
          return color;
        }),
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered)) {
            return Colors.transparent;
          }
          if (states.contains(WidgetState.pressed)) {
            return Colors.transparent;
          }
          return null;
        }),
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: context.appTextStyles.button.copyWith(
          fontSize: 13,
          color: fgColor,
        ),
      ),
    );
  }
}
