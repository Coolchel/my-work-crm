import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/features/projects/presentation/search/project_search_texts.dart';

import '../../../projects/presentation/providers/project_providers.dart';

class SmartSearchBar extends ConsumerStatefulWidget {
  final StateProvider<String?> searchQueryProvider;
  final String hintText;
  final ValueChanged<bool>? onFocusChanged;
  final ValueChanged<String>? onQueryChanged;
  final VoidCallback? onCleared;

  const SmartSearchBar({
    super.key,
    required this.searchQueryProvider,
    this.hintText = ProjectSearchTexts.hint,
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

  @override
  void initState() {
    super.initState();
    _syncControllerWithProvider();
    _searchFocusNode.addListener(_onFocusChange);
  }

  void _syncControllerWithProvider() {
    final value = normalizeProjectSearchQuery(
          ref.read(widget.searchQueryProvider),
        ) ??
        '';
    if (_searchController.text == value) {
      return;
    }
    _searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChange);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    widget.onFocusChanged?.call(_searchFocusNode.hasFocus);

    if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty) {
      final normalized = _searchController.text.trim();
      ref.read(widget.searchQueryProvider.notifier).state =
          normalized.isEmpty ? null : normalized;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final textStyles = context.appTextStyles;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: textStyles.input.copyWith(
          color: scheme.onSurface,
          fontSize: 16,
        ),
        cursorColor: scheme.primary,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hintText,
          hintStyle: textStyles.secondaryBody.copyWith(
            color: scheme.onSurfaceVariant.withOpacity(0.75),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: scheme.onSurfaceVariant.withOpacity(0.85),
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: scheme.onSurfaceVariant.withOpacity(0.85),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(widget.searchQueryProvider.notifier).state = null;
                    setState(() {});
                    widget.onQueryChanged?.call('');
                    widget.onCleared?.call();
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withOpacity(
            isDark ? 0.40 : 0.56,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: scheme.outlineVariant.withOpacity(
                isDark ? 0.34 : 0.26,
              ),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: scheme.outlineVariant.withOpacity(
                isDark ? 0.34 : 0.26,
              ),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          final normalized = value.trim();
          ref.read(widget.searchQueryProvider.notifier).state =
              normalized.isEmpty ? null : normalized;
          setState(() {});
          widget.onQueryChanged?.call(value);
        },
      ),
    );
  }
}
