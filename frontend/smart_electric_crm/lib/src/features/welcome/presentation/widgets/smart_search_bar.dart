import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';

import '../../../projects/presentation/providers/project_providers.dart';

class SmartSearchBar extends ConsumerStatefulWidget {
  const SmartSearchBar({super.key});

  @override
  ConsumerState<SmartSearchBar> createState() => _SmartSearchBarState();
}

class _SmartSearchBarState extends ConsumerState<SmartSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

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

    return Container(
      decoration: BoxDecoration(
        color: AppDesignTokens.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppDesignTokens.cardBorder(context)),
        boxShadow: [
          BoxShadow(
            color: AppDesignTokens.cardShadow(context),
            blurRadius: 10,
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
                    ref.read(projectSearchQueryProvider.notifier).state = null;
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
        },
      ),
    );
  }
}
