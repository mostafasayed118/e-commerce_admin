import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/entities/product.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/money.dart';
import '../../../widgets/message_view.dart';
import '../../catalog/widgets/product_image.dart';
import 'admin_catalog_cubit.dart';

/// Admin product management: list with stock badges, create (FAB), edit
/// (tap row), delete (confirm dialog). The DI-registered [AdminCatalogCubit]
/// is provided by **value** — DI owns its lifecycle (same rule as
/// CatalogScreen), so this never closes it.
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminCatalogCubit>.value(
      value: getIt<AdminCatalogCubit>(),
      child: const _ProductsView(),
    );
  }
}

class _ProductsView extends StatelessWidget {
  const _ProductsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('New product'),
      ),
      body: BlocBuilder<AdminCatalogCubit, AdminCatalogState>(
        builder: (context, state) => switch (state) {
          AdminCatalogLoading() =>
            const Center(child: CircularProgressIndicator()),
          AdminCatalogError(:final message) => MessageView(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              message: message,
            ),
          AdminCatalogLoaded() => _ProductList(state: state),
        },
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({required this.state});

  final AdminCatalogLoaded state;

  String _categoryName(int id) => state.categories
      .where((c) => c.id == id)
      .firstOrNull
      ?.name ?? '—';

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          '${product.name} will be removed permanently. '
          'Orders that reference it keep their snapshot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await context.read<AdminCatalogCubit>().deleteProduct(
          product.id,
        );
    if (!context.mounted) return;
    result.fold(
      onSuccess: (_) {},
      // Success is silent — the watch stream re-emits the shorter list.
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (state.products.isEmpty) {
      return MessageView(
        icon: Icons.inventory_2_outlined,
        title: 'No products yet',
        message: 'Create the first product to start selling.',
        action: FilledButton.tonalIcon(
          onPressed: () => context.push('/admin/products/new'),
          icon: const Icon(Icons.add),
          label: const Text('New product'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.products.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final product = state.products[index];
        final scheme = Theme.of(context).colorScheme;
        return ListTile(
          onTap: () => context.push('/admin/products/${product.id}/edit'),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: ProductImage(imagePath: product.imagePath, iconSize: 24),
            ),
          ),
          title: Text(product.name),
          subtitle: Text(
            '${_categoryName(product.categoryId)} · '
            '${formatCents(product.finalPriceCents)}'
            '${product.hasDiscount ? ' (${product.discountPercent}% off)' : ''}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (product.isOutOfStock)
                _StockChip(
                  label: 'Out of stock',
                  color: scheme.error,
                  background: scheme.errorContainer,
                )
              else if (product.isLowStock)
                _StockChip(
                  label: 'Low stock',
                  color: scheme.tertiary,
                  background: scheme.tertiaryContainer,
                )
              else
                _StockChip(
                  label: '${product.stock} in stock',
                  color: scheme.primary,
                  background: scheme.primaryContainer,
                ),
              IconButton(
                tooltip: 'Delete ${product.name}',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, product),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
