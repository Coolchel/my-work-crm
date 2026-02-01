import 'package:flutter/material.dart';

class EstimateBottomActions extends StatefulWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onDeleteAll;
  final VoidCallback onSaveToTemplate;
  final VoidCallback onApplyTemplate;
  final VoidCallback onImport;
  final String automationText;
  final IconData automationIcon;
  final Color? automationColor;
  final bool showPrices;
  final VoidCallback onTogglePrices;
  final Color? buttonColor;
  final bool hidePriceToggle;

  const EstimateBottomActions({
    super.key,
    required this.onSearchTap,
    required this.onDeleteAll,
    required this.onSaveToTemplate,
    required this.onApplyTemplate,
    required this.onImport,
    this.automationText = "Импорт оборудования",
    this.automationIcon = Icons.download_rounded,
    this.automationColor,
    required this.showPrices,
    required this.onTogglePrices,
    this.buttonColor,
    this.hidePriceToggle = false,
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

    final Size buttonSize = renderBox.size;
    final Offset buttonPosition =
        renderBox.localToGlobal(Offset.zero, ancestor: overlay);

    // Calculate position same as before
    const double estimatedMenuHeight = 184.0;
    const double desiredGap = 12.0;

    // Top position for the menu
    final double targetTop =
        buttonPosition.dy - estimatedMenuHeight - desiredGap;

    // Calculate right offset to align menu right-to-right with the button
    // Distance from right edge of screen = ScreenWidth - (ButtonX + ButtonWidth)
    final double targetRight =
        overlay.size.width - (buttonPosition.dx + buttonSize.width);

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54, // Standard darkening
        pageBuilder: (context, animation, secondaryAnimation) {
          return Stack(
            children: [
              Positioned(
                right: targetRight, // Align right edge
                top: targetTop,
                child: Container(
                  width: 250, // Fixed width suitable for the content
                  decoration: BoxDecoration(
                    color: Colors
                        .transparent, // Transparent container, shadow only
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color:
                        Colors.white, // Material provides the white background
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias, // Clip splashes to corners
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCustomMenuItem('delete', Icons.delete_forever,
                              "Удалить все", Colors.red.shade200, () {
                            Navigator.pop(context);
                            widget.onDeleteAll();
                          }),
                          const Divider(height: 8, thickness: 1),
                          _buildCustomMenuItem(
                              'save_template',
                              Icons.save_as,
                              "Сохранить в шаблон",
                              widget.buttonColor ?? Colors.blue.shade200, () {
                            Navigator.pop(context);
                            widget.onSaveToTemplate();
                          }),
                          _buildCustomMenuItem(
                              'apply_template',
                              Icons.copy_all_rounded,
                              "По шаблону",
                              widget.buttonColor ?? Colors.blue.shade200, () {
                            Navigator.pop(context);
                            widget.onApplyTemplate();
                          }),
                          _buildCustomMenuItem(
                              'import',
                              widget.automationIcon,
                              widget.automationText,
                              widget.automationColor ?? Colors.purple.shade200,
                              () {
                            Navigator.pop(context);
                            widget.onImport();
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide from bottom to top
          const begin = Offset(0.0, 0.1); // Start slightly lower
          const end = Offset.zero;
          const curve = Curves.easeOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomMenuItem(String value, IconData icon, String text,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.grey.withOpacity(0.1), // Added hover effect
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10), // Matched padding
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Price Toggle Button (New - Round with Icon+Text)
        if (!widget.hidePriceToggle) ...[
          Tooltip(
            message: widget.showPrices ? "Скрыть цены" : "Показать цены",
            verticalOffset: 40, // Lift tooltip higher
            child: FloatingActionButton(
              heroTag: 'material_price_toggle_fab',
              onPressed: widget.onTogglePrices,
              backgroundColor: widget.buttonColor ?? Colors.blue.shade200,
              foregroundColor: Colors.black87,
              elevation: 2,
              tooltip: null, // Disable built-in tooltip
              child: Center(
                child: Text(
                  "Цены",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    decoration:
                        widget.showPrices ? TextDecoration.lineThrough : null,
                    decorationThickness: 2.0,
                    decorationColor: Colors.black87,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],

        // 2. Actions Menu Button
        Tooltip(
          message: "Действия",
          verticalOffset: 40,
          child: FloatingActionButton(
            key: _actionsButtonKey,
            heroTag: 'material_actions_fab',
            onPressed: _showActionsMenu,
            backgroundColor: widget.buttonColor ?? Colors.blue.shade200,
            foregroundColor: Colors.black87,
            elevation: 2,
            child: const Icon(Icons.grid_view_rounded),
          ),
        ),

        const SizedBox(width: 16),

        // 3. Search Button
        Tooltip(
          message: "Добавить",
          verticalOffset: 40,
          child: FloatingActionButton(
            heroTag: 'material_search_fab',
            onPressed: widget.onSearchTap,
            backgroundColor: widget.buttonColor ?? Colors.blue.shade200,
            foregroundColor: Colors.black87,
            elevation: 2,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
