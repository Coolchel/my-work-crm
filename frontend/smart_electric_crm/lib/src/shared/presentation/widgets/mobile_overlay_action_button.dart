import 'package:flutter/material.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';

import 'desktop_web_frame.dart';

class MobileOverlayActionButton extends StatefulWidget {
  const MobileOverlayActionButton({
    required this.onPressed,
    super.key,
    this.tooltip,
    this.message,
    this.icon = Icons.add_rounded,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String? tooltip;
  final String? message;
  final VoidCallback onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<MobileOverlayActionButton> createState() =>
      _MobileOverlayActionButtonState();
}

class _MobileOverlayActionButtonState extends State<MobileOverlayActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tooltipLabel = widget.tooltip ?? widget.message ?? '';
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final baseBackground = widget.backgroundColor ??
        theme.floatingActionButtonTheme.backgroundColor ??
        scheme.primary;
    final foreground = widget.foregroundColor ??
        theme.floatingActionButtonTheme.foregroundColor ??
        scheme.onPrimary;
    final surfaceBlend = isDark ? scheme.surfaceContainerHigh : scheme.surface;
    final topColor = Color.alphaBlend(
      Colors.white.withOpacity(isDark ? 0.08 : 0.18),
      baseBackground,
    );
    final bottomColor = Color.alphaBlend(
      Colors.black.withOpacity(isDark ? 0.08 : 0.04),
      baseBackground,
    );
    final borderColor = Color.alphaBlend(
      (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.12 : 0.08),
      baseBackground,
    );
    final haloColor = baseBackground.withOpacity(isDark ? 0.26 : 0.22);
    final shellColor = Color.alphaBlend(
      surfaceBlend.withOpacity(isDark ? 0.14 : 0.08),
      baseBackground,
    );
    final borderRadius = BorderRadius.circular(20);

    final button = Semantics(
      button: true,
      label: tooltipLabel.isEmpty ? null : tooltipLabel,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _isPressed ? 0.97 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: (value) {
              if (_isPressed == value) {
                return;
              }
              setState(() => _isPressed = value);
            },
            borderRadius: borderRadius,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            child: Ink(
              width: DesktopWebFrame.mobileOverlayActionSize,
              height: DesktopWebFrame.mobileOverlayActionSize,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [topColor, shellColor, bottomColor],
                ),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.30 : 0.13),
                    blurRadius: isDark ? 18 : 16,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: haloColor,
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: 25,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltipLabel.isEmpty) {
      return button;
    }

    return Tooltip(
      message: tooltipLabel,
      preferBelow: false,
      verticalOffset: 32,
      child: button,
    );
  }
}
