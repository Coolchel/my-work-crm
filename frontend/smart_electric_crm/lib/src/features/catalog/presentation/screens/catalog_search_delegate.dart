import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/catalog_repository.dart';
import '../../domain/catalog_item.dart';

class CatalogSearchDelegate extends SearchDelegate<CatalogItem?> {
  final WidgetRef ref;
  final String? filterItemType;

  CatalogSearchDelegate({required this.ref, this.filterItemType});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text("Введите название для поиска..."),
      );
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final searchProvider = FutureProvider.autoDispose((ref) {
      final repo = ref.read(catalogRepositoryProvider);
      return repo.searchItems(query, itemType: filterItemType);
    });

    final asyncValue = ref.watch(searchProvider);

    return asyncValue.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text("Ничего не найдено"));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              leading: Icon(
                item.itemType == 'work' ? Icons.handyman : Icons.inventory_2,
                color: item.itemType == 'work' ? Colors.green : Colors.blue,
              ),
              title: Text(item.name),
              subtitle: Text(
                  "${item.defaultPrice} ${item.defaultCurrency} / ${item.unit}"),
              onTap: () {
                close(context, item);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Ошибка: $err")),
    );
  }
}
