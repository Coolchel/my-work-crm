import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';

const double appPopupSelectFieldHeight = 56;

List<PopupMenuEntry<T>> buildPopupMenuEntriesWithDividers<T>(
  List<PopupMenuEntry<T>> entries,
) {
  final result = <PopupMenuEntry<T>>[];
  for (var index = 0; index < entries.length; index++) {
    if (index > 0) {
      result.add(const PopupMenuDivider(height: 1));
    }
    result.add(entries[index]);
  }
  return result;
}

bool _isPopupTouchPlatform() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
      return true;
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return false;
  }
}

Color _popupFieldFillColor(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return AppDesignTokens.isDark(context)
      ? scheme.surfaceContainerHigh
      : scheme.surfaceContainer.withOpacity(0.4);
}

InputDecoration _popupFieldDecoration(
  BuildContext context, {
  required String label,
  required Color accentColor,
  BoxConstraints? constraints,
  EdgeInsetsGeometry? contentPadding,
}) {
  final scheme = Theme.of(context).colorScheme;
  final textStyles = context.appTextStyles;
  final labelStyle = textStyles.fieldLabel.copyWith(
    fontSize: 12.5,
    color: accentColor.withOpacity(0.82),
  );

  return InputDecoration(
    labelText: label,
    labelStyle: labelStyle,
    floatingLabelStyle: labelStyle,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    constraints: constraints,
    isDense: true,
    filled: true,
    fillColor: _popupFieldFillColor(context),
    hintStyle: textStyles.secondaryBody.copyWith(
      color: scheme.onSurfaceVariant.withOpacity(0.75),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppDesignTokens.softBorder(context)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppDesignTokens.softBorder(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: accentColor.withOpacity(0.9), width: 1.25),
    ),
    contentPadding: contentPadding ?? const EdgeInsets.fromLTRB(16, 18, 12, 10),
  );
}

class AppPopupSelectField<T> extends StatefulWidget {
  final String fieldLabel;
  final String valueLabel;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T> onSelected;
  final bool enabled;
  final Color accentColor;

  const AppPopupSelectField({
    super.key,
    required this.fieldLabel,
    required this.valueLabel,
    required this.items,
    required this.onSelected,
    this.enabled = true,
    this.accentColor = Colors.indigo,
  });

  @override
  State<AppPopupSelectField<T>> createState() => _AppPopupSelectFieldState<T>();
}

class _AppPopupSelectFieldState<T> extends State<AppPopupSelectField<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isTouchPlatform = _isPopupTouchPlatform();
    final menuHoverColor = AppDesignTokens.isDark(context)
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.045);

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onEnter:
              widget.enabled ? (_) => setState(() => _isHovered = true) : null,
          onExit:
              widget.enabled ? (_) => setState(() => _isHovered = false) : null,
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: Theme(
            data: theme.copyWith(
              hoverColor: menuHoverColor,
              highlightColor: menuHoverColor,
              splashColor: menuHoverColor,
              popupMenuTheme: theme.popupMenuTheme.copyWith(
                color: scheme.surface,
                surfaceTintColor: Colors.transparent,
                mouseCursor: const WidgetStatePropertyAll<MouseCursor>(
                  SystemMouseCursors.click,
                ),
              ),
            ),
            child: PopupMenuButton<T>(
              enabled: widget.enabled,
              tooltip: '',
              padding: EdgeInsets.zero,
              menuPadding: EdgeInsets.zero,
              elevation: 6,
              shadowColor: AppDesignTokens.cardShadow(context),
              surfaceTintColor: Colors.transparent,
              color: scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppDesignTokens.softBorder(context),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              position: isTouchPlatform
                  ? PopupMenuPosition.under
                  : PopupMenuPosition.over,
              offset: Offset(0, isTouchPlatform ? 2 : 48),
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth,
              ),
              onSelected: widget.onSelected,
              itemBuilder: (context) => widget.items,
              child: Opacity(
                opacity: widget.enabled ? 1 : 0.6,
                child: IgnorePointer(
                  child: InputDecorator(
                    isEmpty: widget.valueLabel.isEmpty,
                    decoration: _popupFieldDecoration(
                      context,
                      label: widget.fieldLabel,
                      accentColor: widget.accentColor,
                      constraints: const BoxConstraints(
                        minHeight: appPopupSelectFieldHeight,
                        maxHeight: appPopupSelectFieldHeight,
                      ),
                    ).copyWith(
                      fillColor: _isHovered
                          ? widget.accentColor.withOpacity(0.04)
                          : _popupFieldFillColor(context),
                      suffixIcon: Align(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 24,
                      ),
                    ),
                    child: Text(
                      widget.valueLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.appTextStyles.input.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
