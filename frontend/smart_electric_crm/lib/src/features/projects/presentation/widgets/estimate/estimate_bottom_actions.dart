import 'package:flutter/material.dart';

class EstimateBottomActions extends StatefulWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onDeleteAll;
  final VoidCallback onSaveToTemplate;
  final VoidCallback onApplyTemplate;
  final VoidCallback onImport;

  const EstimateBottomActions({
    super.key,
    required this.onSearchTap,
    required this.onDeleteAll,
    required this.onSaveToTemplate,
    required this.onApplyTemplate,
    required this.onImport,
  });

  @override
  State<EstimateBottomActions> createState() => _EstimateBottomActionsState();
}

class _EstimateBottomActionsState extends State<EstimateBottomActions> {
  final GlobalKey _actionsButtonKey = GlobalKey();

  void _showActionsMenu() {
    final RenderBox? renderBox =
        _actionsButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // Get button metrics
    final Size buttonSize = renderBox.size;
    final Offset buttonPosition =
        renderBox.localToGlobal(Offset.zero, ancestor: overlay);

    // Estimate Menu Height
    // 4 items * 40height + 1 divider (8) + 16 vertical padding (default Material padding) = 184
    const double estimatedMenuHeight = 184.0;
    const double desiredGap = 12.0;

    // We set the "target" rect to be at the calculated TOP of where the menu should be.
    // showMenu aligns top-left of menu to top-left of target.
    final double targetTop =
        buttonPosition.dy - estimatedMenuHeight - desiredGap;

    final Rect overlayRect = Offset.zero & overlay.size;

    final RelativeRect position = RelativeRect.fromLTRB(
      buttonPosition.dx, // Left aligned with button
      targetTop, // Top aligned with calculated top
      overlayRect.width - (buttonPosition.dx + buttonSize.width), // Right
      overlayRect.height - targetTop, // Bottom
    );

    showMenu<String>(
      context: context,
      position: position,
      useRootNavigator: true,
      items: [
        _buildMenuItem('delete', Icons.delete_forever, "Удалить все",
            color: Colors.red.shade200),
        const PopupMenuDivider(height: 8),
        // Unified colors: all Blue.shade200
        _buildMenuItem('save_template', Icons.save_as, "Сохранить в шаблон",
            color: Colors.blue.shade200),
        _buildMenuItem('apply_template', Icons.copy_all_rounded, "По шаблону",
            color: Colors.blue.shade200),
        _buildMenuItem('import', Icons.download_rounded, "Импорт оборудования",
            color: Colors.blue.shade200),
      ],
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'delete':
            widget.onDeleteAll();
            break;
          case 'save_template':
            widget.onSaveToTemplate();
            break;
          case 'apply_template':
            widget.onApplyTemplate();
            break;
          case 'import':
            widget.onImport();
            break;
        }
      }
    });
  }

  PopupMenuItem<String> _buildMenuItem(String value, IconData icon, String text,
      {Color? color}) {
    return PopupMenuItem<String>(
      value: value,
      height: 40, // Reduced height (default is 48)
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: color ?? Colors.blue.shade200,
              size: 20), // Reduced icon size (24->20)
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 13, // Reduced font size
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Actions Menu Button (Left)
        FloatingActionButton(
          key: _actionsButtonKey,
          heroTag: 'material_actions_fab',
          onPressed: _showActionsMenu,
          backgroundColor: Colors.blue.shade200,
          foregroundColor: Colors.black87,
          elevation: 2,
          child: const Icon(Icons.grid_view_rounded),
        ),

        const SizedBox(width: 16),

        // Search Button (Right)
        FloatingActionButton(
          heroTag: 'material_search_fab',
          onPressed: widget.onSearchTap,
          backgroundColor: Colors.blue.shade200,
          foregroundColor: Colors.black87,
          elevation: 2,
          child: const Icon(Icons.search),
        ),
      ],
    );
  }
}
