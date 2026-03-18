import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_electric_crm/src/core/utils/app_number_formatter.dart';
import '../../data/catalog_repository.dart';
import '../../domain/catalog_item.dart';
import 'package:smart_electric_crm/src/shared/presentation/widgets/friendly_empty_state.dart';

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
      return const FriendlyEmptyState(
        icon: Icons.search_rounded,
        title: 'Введите название для поиска',
        subtitle: 'Начните вводить запрос, и результаты появятся сразу.',
        accentColor: Colors.blueGrey,
        iconSize: 58,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
          return const FriendlyEmptyState(
            icon: Icons.search_off_rounded,
            title: 'Ничего не найдено',
            subtitle: 'Попробуйте другой запрос.',
            accentColor: Colors.blueGrey,
            iconSize: 58,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          );
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
                  "${AppNumberFormatter.decimal(item.defaultPrice)} ${item.defaultCurrency} / ${item.unit}"),
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
