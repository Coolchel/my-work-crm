import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/app_dialog_scrollbar.dart';
import '../../../../shared/presentation/dialogs/confirmation_dialog.dart';
import '../../../../shared/presentation/widgets/friendly_empty_state.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final textStyles = context.appTextStyles;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        height: 600,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.34)
                  : Colors.black.withOpacity(0.12),
              blurRadius: isDark ? 12 : 20,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppDesignTokens.surface3(context)
                    : themeColor.withOpacity(0.1),
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
                      style: textStyles.dialogTitle.copyWith(
                        color: isDark
                            ? scheme.onSurface
                            : themeColor.withOpacity(0.8),
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
                  ? FriendlyEmptyState(
                      icon: Icons.content_paste_off_rounded,
                      title: 'Нет доступных шаблонов',
                      subtitle:
                          'Сохраните текущий набор как шаблон и используйте его повторно.',
                      accentColor: themeColor,
                      iconSize: 62,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 22),
                    )
                  : AppDialogScrollbar.builder(
                      builder: (scrollController) => ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: templates.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final template = templates[index];
                          return _buildTemplateCard(context, template);
                        },
                      ),
                    ),
            ),

            // Footer (Create New)
            if (onCreate != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: AppDesignTokens.softBorder(context))),
                ),
                child: Center(
                  child: SizedBox(
                    width: 250,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        onCreate!(); // Trigger create action
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text("Сохранить текущий щит",
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final textStyles = context.appTextStyles;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppDesignTokens.softBorder(context)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onSelected(template);
        },
        borderRadius: BorderRadius.circular(10),
        hoverColor: isDark
            ? AppDesignTokens.hoverOverlay(context)
            : Colors.grey.withOpacity(0.1),
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
                      style: textStyles.bodyStrong.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    if (getDescription(template).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        getDescription(template),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.caption.copyWith(
                          color: scheme.onSurfaceVariant,
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
