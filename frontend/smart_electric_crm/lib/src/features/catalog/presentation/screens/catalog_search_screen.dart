import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/utils/app_number_formatter.dart';
import '../../data/catalog_repository.dart';
import '../../domain/catalog_item.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';

class CatalogSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? filterItemType; // 'work' or 'material'

  const CatalogSearchScreen({
    super.key,
    this.initialQuery,
    this.filterItemType,
  });

  @override
  ConsumerState<CatalogSearchScreen> createState() =>
      _CatalogSearchScreenState();
}

class _CatalogSearchScreenState extends ConsumerState<CatalogSearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<CatalogItem> _results = [];
  bool _isLoading = false;
  Timer? _debounce;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchCtrl.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    } else {
      // Focus on text field immediately if no initial query
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(catalogRepositoryProvider);
      final items =
          await repo.searchItems(query, itemType: widget.filterItemType);

      if (mounted) {
        setState(() {
          _results = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Поиск в каталоге...",
            border: InputBorder.none,
            hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
          ),
          cursorColor: Theme.of(context).colorScheme.onSurface,
          onChanged: _onSearchChanged,
        ),
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Ошибка поиска: $_error",
                  style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: _results.isEmpty &&
                    !_isLoading &&
                    _searchCtrl.text.isNotEmpty
                ? const FriendlyEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Ничего не найдено',
                    subtitle: 'Попробуйте изменить поисковый запрос.',
                    accentColor: Colors.blueGrey,
                    iconSize: 62,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      return ListTile(
                        leading: Icon(
                          item.itemType == 'work'
                              ? Icons.handyman
                              : Icons.inventory_2,
                          color: item.itemType == 'work'
                              ? Colors.green
                              : Colors.blue,
                        ),
                        title: Text(item.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(
                            "${AppNumberFormatter.decimal(item.defaultPrice)} ${item.defaultCurrency} / ${item.unit}"),
                        trailing: const Icon(Icons.add_circle_outline,
                            color: Colors.grey),
                        onTap: () {
                          Navigator.pop(context, item);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
