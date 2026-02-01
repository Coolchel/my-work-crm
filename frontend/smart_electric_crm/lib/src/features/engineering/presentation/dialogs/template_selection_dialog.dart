import 'package:flutter/material.dart';
import '../../../../shared/presentation/dialogs/confirmation_dialog.dart';

class TemplateSelectionDialog<T> extends StatelessWidget {
  final String title;
  final List<T> templates;
  final String Function(T) getName;
  final String Function(T) getDescription;
  final Function(T) onSelected;
  final Function(T)? onDelete;
  final Color themeColor;
  final VoidCallback? onCreate;

  const TemplateSelectionDialog({
    super.key,
    required this.title,
    required this.templates,
    required this.getName,
    required this.getDescription,
    required this.onSelected,
    this.onDelete,
    this.themeColor = Colors.blue, // Default color
    this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        height: 600,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color:
                    themeColor.withOpacity(0.1), // Light background for header
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Centered Title
                  Center(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeColor.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Close button on the right
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: themeColor),
                      tooltip: "Закрыть",
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: templates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.content_paste_off,
                              size: 40, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(
                            "Нет доступных шаблонов",
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: templates.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return _buildTemplateCard(context, template);
                      },
                    ),
            ),

            // Footer (Create New)
            if (onCreate != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Center(
                  child: SizedBox(
                    width: 250,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        onCreate!(); // Trigger create action
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text("Сохранить текущую смету",
                          style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: themeColor.withOpacity(0.1),
                        foregroundColor: themeColor,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, T template) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onSelected(template);
        },
        borderRadius: BorderRadius.circular(10),
        hoverColor: Colors.grey.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              // Leading Icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.description_outlined, // Generic template icon
                  color: themeColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getName(template),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (getDescription(template).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        getDescription(template),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Delete Action
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.close, // Changed to Cross
                      size: 16,
                      color: Colors.grey.shade400),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: "Удалить шаблон",
                  onPressed: () => _confirmDelete(context, template),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, T template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => ConfirmationDialog(
        title: "Удалить шаблон?",
        content: "Вы уверены, что хотите удалить '${getName(template)}'?",
        confirmText: "Удалить",
        isDestructive: true,
        themeColor: themeColor,
      ),
    );

    if (confirmed == true && onDelete != null) {
      onDelete!(template);
    }
  }
}
