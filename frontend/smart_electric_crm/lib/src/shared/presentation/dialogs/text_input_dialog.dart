import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../widgets/app_dialog_scrollbar.dart';
import '../widgets/desktop_web_frame.dart';

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
  final ScrollController _scrollController = ScrollController();
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textStyles = context.appTextStyles;
    final isDark = theme.brightness == Brightness.dark;
    final isMobileWeb = DesktopWebFrame.isMobileWeb(context, maxWidth: 560);
    final headerPadding = EdgeInsets.symmetric(
      horizontal: isMobileWeb ? 16 : 20,
      vertical: isMobileWeb ? 14 : 16,
    );
    final contentPadding = EdgeInsets.all(isMobileWeb ? 16 : 24);
    final footerPadding = EdgeInsets.fromLTRB(
      isMobileWeb ? 16 : 24,
      0,
      isMobileWeb ? 16 : 24,
      isMobileWeb ? 16 : 24,
    );

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobileWeb ? 10 : 16,
        vertical: isMobileWeb ? 8 : 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 450,
              maxHeight: constraints.maxHeight * 0.84,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: headerPadding,
                    decoration: BoxDecoration(
                      color: widget.themeColor.withOpacity(0.08),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      border: Border(
                        bottom: BorderSide(
                            color: widget.themeColor.withOpacity(0.1)),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          widget.title,
                          style: textStyles.dialogTitle.copyWith(
                            fontSize: isMobileWeb ? 16 : 18,
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
                  Flexible(
                    child: AppDialogScrollbar(
                      controller: _scrollController,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: contentPadding,
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
                    ),
                  ),
                  // Footer
                  Padding(
                    padding: footerPadding,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: isMobileWeb ? 0 : 8,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: isMobileWeb ? double.infinity : null,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: scheme.onSurfaceVariant,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            child: Text(widget.cancelText),
                          ),
                        ),
                        SizedBox(
                          width: isMobileWeb ? double.infinity : null,
                          child: FilledButton(
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
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            child: Text(widget.confirmText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textStyles = context.appTextStyles;
    final isMobileWeb = DesktopWebFrame.isMobileWeb(context, maxWidth: 560);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textStyles.fieldLabel.copyWith(
            color: scheme.onSurfaceVariant,
            fontSize: isMobileWeb ? 12.5 : 13.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          autofocus: autoFocus,
          maxLines: maxLines,
          style: textStyles.input.copyWith(color: scheme.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: scheme.surfaceContainer.withOpacity(0.5),
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
