import 'package:flutter/material.dart';

class TextInputDialog extends StatefulWidget {
  final String title;
  final String labelText;
  final String? descriptionLabelText;
  final String confirmText;
  final String cancelText;
  final String? initialValue;
  final String? initialDescription;

  const TextInputDialog({
    super.key,
    required this.title,
    required this.labelText,
    this.descriptionLabelText,
    this.confirmText = 'Сохранить',
    this.cancelText = 'Отмена',
    this.initialValue,
    this.initialDescription,
  });

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late TextEditingController _textController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue);
    _descController = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _textController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: widget.labelText,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          if (widget.descriptionLabelText != null) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: widget.descriptionLabelText,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
          ),
          child: Text(widget.cancelText),
        ),
        FilledButton(
          onPressed: () {
            if (_textController.text.trim().isEmpty) return;
            // Return Map or String dependent on fields
            final result = _textController.text;
            if (widget.descriptionLabelText != null) {
              Navigator.pop(context, {
                'text': result,
                'description': _descController.text,
              });
            } else {
              Navigator.pop(context, result);
            }
          },
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}
