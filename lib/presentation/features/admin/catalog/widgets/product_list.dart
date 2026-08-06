import 'package:flutter/material.dart';

import '../../../../../core/entities/product.dart';
import '../../../../l10n/l10n_ext.dart';
import '../../../../widgets/message_view.dart';
import '../../../catalog/widgets/product_image.dart';
import '../admin_catalog_cubit.dart';
import 'stock_chip.dart';

/// The admin product list: rows with stock badges, edit on tap, delete via a
/// confirm dialog. Purely presentational — navigation and the delete flow are
/// delegated to the screen through [onEdit] / [onDelete] / [onCreate].
class ProductList extends StatelessWidget {
  const ProductList({
    super.key,
    required this.state,
    required this.onEdit,
    required this.onDelete,
    required this.onCreate,
  });

  final AdminCatalogLoaded state;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onDelete;
  final VoidCallback onCreate;

  String _categoryName(BuildContext context, int id) {
    final category = state.categories.where((c) => c.id == id).firstOrNull;
    return category == null ? '—' : context.categoryName(category);
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
          onPressed: onCreate,
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
          onTap: () => onEdit(product),
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
                StockChip(
                  label: l10n.outOfStock,
                  color: scheme.error,
                  background: scheme.errorContainer,
                )
              else if (product.isLowStock)
                StockChip(
                  label: l10n.lowStockShort,
                  color: scheme.tertiary,
                  background: scheme.tertiaryContainer,
                )
              else
                StockChip(
                  label: l10n.stockInStock(product.stock),
                  color: scheme.primary,
                  background: scheme.primaryContainer,
                ),
              IconButton(
                tooltip: l10n.deleteProductTooltip(context.productName(product)),
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onDelete(product),
              ),
            ],
          ),
        );
      },
    );
  }
}
