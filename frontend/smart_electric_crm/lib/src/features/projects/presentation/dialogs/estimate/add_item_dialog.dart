import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/features/catalog/data/catalog_repository.dart';
import 'package:smart_electric_crm/src/features/catalog/domain/catalog_item.dart';

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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0, // Using internal styling
      backgroundColor: Colors.transparent,
      child: Container(
        height: 600,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _lightColor,
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeColor.withOpacity(0.8),
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
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Начните вводить название...",
                      hintStyle: TextStyle(
                        color: Colors.grey.withOpacity(0.35),
                      ),
                      prefixIcon:
                          Icon(Icons.search, color: themeColor, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: themeColor.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: themeColor.withOpacity(0.2)),
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 40, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(
                            "Ничего не найдено",
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _results.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 6),
                      itemBuilder: (ctx, i) {
                        final item = _results[i];
                        return _buildItemCard(item, themeColor);
                      },
                    ),
            ),

            // Footer (Manual Add)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
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
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _onItemAdded(item),
        borderRadius: BorderRadius.circular(10),
        hoverColor: Colors.grey.withOpacity(0.1), // Match estimate menu style
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (!widget.hidePrices) ...[
                      const SizedBox(height: 2),
                      Text(
                        "${item.defaultPrice} ${item.defaultCurrency} / ${item.unit}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
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
