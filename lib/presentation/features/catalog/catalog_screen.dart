import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/entities/category.dart';
import '../../widgets/message_view.dart';
import 'catalog_cubit.dart';
import 'catalog_sort.dart';
import 'widgets/product_card.dart';

/// The customer catalog. Provides the DI-registered [CatalogCubit] via a
/// **value** provider: DI owns the cubit's lifecycle (lazy singleton), so
/// this must never close it — a `create` provider (closeOnDispose: true)
/// would poison the shared instance the moment the screen unmounts.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CatalogCubit>.value(
      value: getIt<CatalogCubit>(),
      child: const _CatalogView(),
    );
  }
}

class _CatalogView extends StatelessWidget {
  const _CatalogView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: BlocBuilder<CatalogCubit, CatalogState>(
        builder: (context, state) => switch (state) {
          CatalogLoading() => const Center(child: CircularProgressIndicator()),
          CatalogError(:final message) => MessageView(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              message: message,
            ),
          CatalogEmpty() => const MessageView(
              icon: Icons.inventory_2_outlined,
              title: 'The catalog is empty',
              message: 'Products will appear here once they exist.',
            ),
          CatalogLoaded() => _LoadedCatalog(state: state),
        },
      ),
    );
  }
}

class _LoadedCatalog extends StatefulWidget {
  const _LoadedCatalog({required this.state});

  final CatalogLoaded state;

  @override
  State<_LoadedCatalog> createState() => _LoadedCatalogState();
}

class _LoadedCatalogState extends State<_LoadedCatalog> {
  // Owned here so "Clear filters" can also empty the visible text — an
  // uncontrolled field would keep showing the stale query.
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: cubit.setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search products',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _CategoryFilterChips(
          categories: state.categories,
          selectedCategoryId: state.selectedCategoryId,
          onSelected: cubit.selectCategory,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${state.products.length} product${state.products.length == 1 ? '' : 's'}',
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
                      child: Text(sort.label),
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
                        state.sort.label,
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
                  title: 'No matches',
                  message: state.hasActiveFilter
                      ? 'Nothing matches your current search or filter.'
                      : 'No products in this category yet.',
                  action: state.hasActiveFilter
                      ? TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear filters'),
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

class _CategoryFilterChips extends StatelessWidget {
  const _CategoryFilterChips({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<Category> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(context, label: 'All', selected: selectedCategoryId == null, value: null),
          for (final category in categories)
            _chip(
              context,
              label: category.name,
              selected: selectedCategoryId == category.id,
              value: category.id,
            ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool selected,
    required int? value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(value),
        showCheckmark: false,
      ),
    );
  }
}
