import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../widgets/message_view.dart';
import '../catalog_cubit.dart';
import '../catalog_sort.dart';
import 'category_filter_chips.dart';
import 'product_card.dart';

/// The catalog's loaded body: search field, category filter chips, result
/// count + sort menu, and the product grid (or the no-matches view).
///
/// Owns the search [TextEditingController] so "Clear filters" can also empty
/// the visible text — an uncontrolled field would keep showing the stale
/// query.
class LoadedCatalog extends StatefulWidget {
  const LoadedCatalog({super.key, required this.state});

  final CatalogLoaded state;

  @override
  State<LoadedCatalog> createState() => _LoadedCatalogState();
}

class _LoadedCatalogState extends State<LoadedCatalog> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  CatalogLoaded get state => widget.state;

  void _clearFilters() {
    _searchController.clear();
    context.read<CatalogCubit>()..selectCategory(null)..setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CatalogCubit>();
    final l10n = context.l10n;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: cubit.setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.searchProducts,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 8),
        CategoryFilterChips(
          categories: state.categories,
          selectedCategoryId: state.selectedCategoryId,
          onSelected: cubit.selectCategory,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                l10n.productCount(state.products.length),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              PopupMenuButton<CatalogSort>(
                initialValue: state.sort,
                onSelected: cubit.setSort,
                itemBuilder: (context) => [
                  for (final sort in CatalogSort.values)
                    CheckedPopupMenuItem(
                      value: sort,
                      checked: sort == state.sort,
                      child: Text(_sortLabel(context, sort)),
                    ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        _sortLabel(context, state.sort),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.products.isEmpty
              ? MessageView(
                  icon: Icons.search_off,
                  title: l10n.noMatches,
                  message: state.hasActiveFilter
                      ? l10n.noMatchesMessage
                      : l10n.noProductsInCategory,
                  action: state.hasActiveFilter
                      ? TextButton(
                          onPressed: _clearFilters,
                          child: Text(l10n.clearFilters),
                        )
                      : null,
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return ProductCard(
                      product: product,
                      onTap: () => context.push('/product/${product.id}'),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Localized label for a [CatalogSort] (Task 23). The enum keeps its English
/// `label` for tooling; UI text goes through this so it follows the locale.
String _sortLabel(BuildContext context, CatalogSort sort) => switch (sort) {
      CatalogSort.newest => context.l10n.sortNewest,
      CatalogSort.name => context.l10n.sortName,
      CatalogSort.priceAsc => context.l10n.sortPriceAsc,
      CatalogSort.priceDesc => context.l10n.sortPriceDesc,
    };
