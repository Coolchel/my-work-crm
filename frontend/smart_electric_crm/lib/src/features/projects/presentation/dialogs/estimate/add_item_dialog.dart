import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/theme/app_design_tokens.dart';
import 'package:smart_electric_crm/src/core/theme/app_typography.dart';
import 'package:smart_electric_crm/src/features/catalog/data/catalog_repository.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/app_dialog_scrollbar.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';

/// Dialog for searching and adding catalog items to an estimate
class AddItemDialog extends ConsumerStatefulWidget {
  final Function(CatalogItem) onAdd;
  final String itemType;
  final bool hidePrices;

  const AddItemDialog(
      {super.key,
      required this.onAdd,
      required this.itemType,
      this.hidePrices = false});

  @override
  ConsumerState<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends ConsumerState<AddItemDialog> {
  final _searchController = TextEditingController();
  List<CatalogItem> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search(query);
    });
  }

  void _search(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _results = []);
      return;
    }
    if (mounted) setState(() => _loading = true);
    try {
      final repo = ref.read(catalogRepositoryProvider);
      final items = await repo.searchItems(query, itemType: widget.itemType);
      if (mounted) setState(() => _results = items);
    } catch (e) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onItemAdded(CatalogItem item) {
    widget.onAdd(item);
    _searchController.clear();
  }

  Color get _primaryColor =>
      widget.itemType == 'work' ? Colors.green : Colors.blue;

  Color get _lightColor => widget.itemType == 'work'
      ? Colors.green.shade50.withOpacity(0.5)
      : Colors.blue.shade50.withOpacity(0.5);

  @override
  Widget build(BuildContext context) {
    final themeColor = _primaryColor;
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppDesignTokens.isDark(context);
    final textStyles = context.appTextStyles;
    final headerColor =
        isDark ? AppDesignTokens.surface3(context) : _lightColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0, // Using internal styling
      backgroundColor: Colors.transparent,
      child: Container(
        height: 600,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
                color: headerColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Centered Title
                      Center(
                        child: Text(
                          "Добавить ${widget.itemType == 'work' ? 'работу' : 'материал'}",
                          style: textStyles.dialogTitle.copyWith(
                            color: isDark
                                ? scheme.onSurface
                                : themeColor.withOpacity(0.8),
                          ),
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: textStyles.input.copyWith(color: scheme.onSurface),
                    decoration: InputDecoration(
                      hintText: "Начните вводить название...",
                      hintStyle: textStyles.secondaryBody.copyWith(
                        color: scheme.onSurfaceVariant.withOpacity(0.72),
                      ),
                      prefixIcon:
                          Icon(Icons.search, color: themeColor, size: 20),
                      filled: true,
                      fillColor: isDark
                          ? scheme.surfaceContainerHigh
                          : Theme.of(context).colorScheme.surface,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: AppDesignTokens.softBorder(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: AppDesignTokens.softBorder(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: themeColor, width: 2),
                      ),
                      suffixIcon: _loading
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(themeColor),
                                ),
                              ),
                            )
                          : null,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _results.isEmpty &&
                      _searchController.text.isNotEmpty &&
                      !_loading
                  ? FriendlyEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Ничего не найдено',
                      subtitle:
                          'Попробуйте другой запрос или добавьте новую позицию вручную.',
                      accentColor: themeColor,
                      iconSize: 62,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                    )
                  : AppDialogScrollbar.builder(
                      builder: (scrollController) => ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _results.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 6),
                        itemBuilder: (ctx, i) {
                          final item = _results[i];
                          return _buildItemCard(item, themeColor);
                        },
                      ),
                    ),
            ),

            // Footer (Manual Add)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                    top:
                        BorderSide(color: AppDesignTokens.softBorder(context))),
              ),
              child: Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Manual Add: Create dummy item
                      final dummy = CatalogItem(
                          id: 0, // 0 signals manual
                          name: '',
                          category: 0,
                          unit: 'шт',
                          defaultPrice: 0,
                          defaultCurrency: 'USD',
                          itemType: widget.itemType);
                      widget.onAdd(dummy);
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text("Новая позиция",
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

  Widget _buildItemCard(CatalogItem item, Color themeColor) {
    final textStyles = context.appTextStyles;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppDesignTokens.softBorder(context)),
      ),
      child: InkWell(
        onTap: () => _onItemAdded(item),
        borderRadius: BorderRadius.circular(10),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppDesignTokens.pressedOverlay(context);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppDesignTokens.hoverOverlay(context);
          }
          return null;
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  widget.itemType == 'work'
                      ? Icons.handyman_outlined
                      : Icons.inventory_2_outlined,
                  color: themeColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: textStyles.bodyStrong.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    if (!widget.hidePrices) ...[
                      const SizedBox(height: 2),
                      Text(
                        "${item.defaultPrice} ${item.defaultCurrency} / ${item.unit}",
                        style: textStyles.caption.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.add, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
