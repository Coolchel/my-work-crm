import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';

import '../../../projects/presentation/providers/project_providers.dart';

class SmartSearchBar extends ConsumerStatefulWidget {
  final ValueChanged<bool>? onFocusChanged;
  final ValueChanged<String>? onQueryChanged;
  final VoidCallback? onCleared;

  const SmartSearchBar({
    super.key,
    this.onFocusChanged,
    this.onQueryChanged,
    this.onCleared,
  });

  @override
  ConsumerState<SmartSearchBar> createState() => _SmartSearchBarState();
}

class _SmartSearchBarState extends ConsumerState<SmartSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChange);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _searchFocusNode.hasFocus);
    }
    widget.onFocusChanged?.call(_searchFocusNode.hasFocus);

    if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty) {
      final normalized = _searchController.text.trim();
      ref.read(projectSearchQueryProvider.notifier).state =
          normalized.isEmpty ? null : normalized;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final isInteractive = _isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.text,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color:
              AppDesignTokens.cardBackground(context, hovered: isInteractive),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isFocused
                ? scheme.primary.withOpacity(isDark ? 0.34 : 0.28)
                : AppDesignTokens.cardBorder(context, hovered: isInteractive),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  AppDesignTokens.cardShadow(context, hovered: isInteractive),
              blurRadius: isInteractive ? 12 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: TextStyle(color: scheme.onSurface),
          cursorColor: scheme.primary,
          decoration: InputDecoration(
            hintText: 'Поиск: объект, домофон, заказчик...',
            hintStyle: TextStyle(
              color: scheme.onSurfaceVariant.withOpacity(0.75),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: scheme.onSurfaceVariant.withOpacity(0.85),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(projectSearchQueryProvider.notifier).state =
                          null;
                      widget.onQueryChanged?.call('');
                      widget.onCleared?.call();
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            filled: true,
            fillColor: isDark
                ? scheme.surfaceContainer.withOpacity(0.36)
                : scheme.surface.withOpacity(0.88),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (value) {
            final normalized = value.trim();
            ref.read(projectSearchQueryProvider.notifier).state =
                normalized.isEmpty ? null : normalized;
            widget.onQueryChanged?.call(value);
          },
        ),
      ),
    );
  }
}
