import 'package:flutter/material.dart';

class TemplateSelectionDialog<T> extends StatelessWidget {
  final String title;
  final List<T> templates;
  final String Function(T) getName;
  final String Function(T) getDescription;
  final Function(T) onSelected;
  final Function(T)? onDelete;

  const TemplateSelectionDialog({
    super.key,
    required this.title,
    required this.templates,
    required this.getName,
    required this.getDescription,
    required this.onSelected,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: templates.isEmpty
            ? const Center(child: Text("Нет доступных шаблонов"))
            : ListView.separated(
                shrinkWrap: true,
                itemCount: templates.length,
                separatorBuilder: (ctx, i) => const Divider(),
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return ListTile(
                    title: Text(getName(template),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(getDescription(template),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      Navigator.pop(context); // Close dialog
                      onSelected(template); // Return selection
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () => _confirmDelete(context, template),
                          ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Отмена"),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, T template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Удалить шаблон?"),
        content: Text("Вы уверены, что хотите удалить '${getName(template)}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Удалить", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && onDelete != null) {
      onDelete!(template);
    }
  }
}
