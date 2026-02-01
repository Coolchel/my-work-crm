import 'package:flutter/material.dart';

class TextInputDialog extends StatefulWidget {
  final String title;
  final String labelText;
  final String? descriptionLabelText;
  final String confirmText;
  final String cancelText;
  final String? initialValue;
  final String? initialDescription;
  final Color themeColor;

  const TextInputDialog({
    super.key,
    required this.title,
    required this.labelText,
    this.descriptionLabelText,
    this.confirmText = 'Сохранить',
    this.cancelText = 'Отмена',
    this.initialValue,
    this.initialDescription,
    this.themeColor = Colors.blue,
  });

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late TextEditingController _textController;
  late TextEditingController _descController;
  final _formKey = GlobalKey<FormState>();

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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.themeColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: widget.themeColor.withOpacity(0.12),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.themeColor.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Tooltip(
                      message: "Закрыть",
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: widget.themeColor),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _textController,
                      label: widget.labelText,
                      autoFocus: true,
                    ),
                    if (widget.descriptionLabelText != null) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descController,
                        label: widget.descriptionLabelText!,
                        maxLines: 3,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: Text(widget.cancelText),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered) ||
                            states.contains(WidgetState.pressed)) {
                          return widget.themeColor;
                        }
                        return widget.themeColor.withOpacity(0.8);
                      }),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    child: Text(widget.confirmText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool autoFocus = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          autofocus: autoFocus,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: widget.themeColor.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: widget.themeColor.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: widget.themeColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (_textController.text.trim().isEmpty) return;

    final result = _textController.text;
    if (widget.descriptionLabelText != null) {
      Navigator.pop(context, {
        'text': result,
        'description': _descController.text,
      });
    } else {
      Navigator.pop(context, result);
    }
  }
}
