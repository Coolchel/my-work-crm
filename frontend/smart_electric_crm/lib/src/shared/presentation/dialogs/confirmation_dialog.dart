import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import 'desktop_dialog_foundation.dart';
import '../widgets/app_dialog_scrollbar.dart';
import '../widgets/desktop_web_frame.dart';

class ConfirmationDialog extends StatefulWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final Color themeColor;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Подтвердить',
    this.cancelText = 'Отмена',
    this.isDestructive = false,
    this.themeColor = Colors.blue,
  });

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (usesDesktopDialogFoundation(context)) {
      return _buildDesktopDialog(context);
    }
    return _buildMobileDialog(context);
  }

  Widget _buildDesktopDialog(BuildContext context) {
    final textStyles = context.appTextStyles;
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor =
        widget.isDestructive ? Colors.red : widget.themeColor;

    return DesktopDialogShell(
      title: widget.title,
      accentColor: effectiveColor,
      maxWidth: 440,
      onClose: () => Navigator.of(context).pop(false),
      scrollController: _scrollController,
      actions: [
        if (widget.cancelText.isNotEmpty)
          DesktopDialogSecondaryButton(
            onPressed: () => Navigator.pop(context, false),
            label: widget.cancelText,
            accentColor: effectiveColor,
          ),
        DesktopDialogPrimaryButton(
          onPressed: () => Navigator.pop(context, true),
          accentColor: effectiveColor,
          child: Text(widget.confirmText),
        ),
      ],
      child: Text(
        widget.content,
        style: textStyles.body.copyWith(
          fontSize: 15,
          height: 1.4,
          color: scheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMobileDialog(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textStyles = context.appTextStyles;
    final isDark = theme.brightness == Brightness.dark;
    final effectiveColor =
        widget.isDestructive ? Colors.red : widget.themeColor;
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
    final actionWidth = isMobileWeb ? double.infinity : 140.0;
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
              maxWidth: 400,
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
                    blurRadius: 12,
                    offset: const Offset(0, 4),
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
                      color: effectiveColor.withOpacity(0.08),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      border: Border(
                        bottom:
                            BorderSide(color: effectiveColor.withOpacity(0.1)),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          widget.title,
                          style: textStyles.dialogTitle.copyWith(
                            fontSize: isMobileWeb ? 16 : 18,
                            color: effectiveColor.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Tooltip(
                            message: "Закрыть",
                            child: IconButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              icon: Icon(Icons.close, color: effectiveColor),
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
                        child: Text(
                          widget.content,
                          style: textStyles.body.copyWith(
                            fontSize: isMobileWeb ? 14 : 15,
                            height: 1.4,
                            color: scheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  // Footer
                  Padding(
                    padding: footerPadding,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: isMobileWeb ? 0 : 12,
                      runSpacing: 8,
                      children: [
                        if (widget.cancelText.isNotEmpty) ...[
                          SizedBox(
                            width: actionWidth,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: TextButton.styleFrom(
                                foregroundColor: scheme.onSurfaceVariant,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(widget.cancelText),
                            ),
                          ),
                          SizedBox(
                            width: actionWidth,
                            child: FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.hovered) ||
                                      states.contains(WidgetState.pressed)) {
                                    return effectiveColor;
                                  }
                                  return effectiveColor.withOpacity(0.8);
                                }),
                                padding: WidgetStateProperty.all(
                                  const EdgeInsets.symmetric(vertical: 12),
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
                        ] else
                          SizedBox(
                            width: actionWidth,
                            child: FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.hovered) ||
                                      states.contains(WidgetState.pressed)) {
                                    return effectiveColor;
                                  }
                                  return effectiveColor.withOpacity(0.8);
                                }),
                                padding: WidgetStateProperty.all(
                                  const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 24),
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
}

Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Подтвердить',
  String cancelText = 'Отмена',
  bool isDangerous = false,
  Color themeColor = Colors.blue,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ConfirmationDialog(
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDangerous,
      themeColor: themeColor,
    ),
  );
}
