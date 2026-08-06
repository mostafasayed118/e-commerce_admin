import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/entities/product.dart';
import '../../../../core/error/result.dart';
import '../../../l10n/l10n_ext.dart';
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.productsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/products/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.newProduct),
      ),
      body: BlocBuilder<AdminCatalogCubit, AdminCatalogState>(
        builder: (context, state) => switch (state) {
          AdminCatalogLoading() =>
            const Center(child: CircularProgressIndicator()),
          AdminCatalogError() => MessageView(
              icon: Icons.error_outline,
              title: l10n.somethingWentWrong,
              message: l10n.errorLoadFailed,
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

  String _categoryName(BuildContext context, int id) {
    final category = state.categories.where((c) => c.id == id).firstOrNull;
    return category == null ? '—' : context.categoryName(category);
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteProductTitle),
        content: Text(l10n.deleteProductMessage(context.productName(product))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
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
          SnackBar(content: Text(context.errorText(error))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (state.products.isEmpty) {
      return MessageView(
        icon: Icons.inventory_2_outlined,
        title: l10n.noProductsTitle,
        message: l10n.noProductsMessage,
        action: FilledButton.tonalIcon(
          onPressed: () => context.push('/admin/products/new'),
          icon: const Icon(Icons.add),
          label: Text(l10n.newProduct),
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
          title: Text(context.productName(product)),
          subtitle: Text(
            '${_categoryName(context, product.categoryId)} · '
            '${context.formatCents(product.finalPriceCents)}'
            '${product.hasDiscount ? ' ${context.l10n.percentOff(product.discountPercent)}' : ''}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (product.isOutOfStock)
                _StockChip(
                  label: l10n.outOfStock,
                  color: scheme.error,
                  background: scheme.errorContainer,
                )
              else if (product.isLowStock)
                _StockChip(
                  label: l10n.lowStockShort,
                  color: scheme.tertiary,
                  background: scheme.tertiaryContainer,
                )
              else
                _StockChip(
                  label: l10n.stockInStock(product.stock),
                  color: scheme.primary,
                  background: scheme.primaryContainer,
                ),
              IconButton(
                tooltip: l10n.deleteProductTooltip(context.productName(product)),
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
