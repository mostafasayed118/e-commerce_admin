import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import '../../catalog/widgets/product_image.dart';
import '../../catalog/widgets/product_price_row.dart';
import '../../catalog/widgets/stock_status_label.dart';
import '../wishlist_state.dart';

/// One wishlist line: product image, name, prices, stock state, and the
/// move-to-cart / remove actions.
///
/// The Move to cart button sits on its own full-width row below the product
/// info, so a long label (e.g. in Arabic) can never squeeze the name column.
class WishlistTile extends StatelessWidget {
  const WishlistTile({
    super.key,
    required this.line,
    required this.onRemove,
    required this.onMoveToCart,
  });

  final WishlistLine line;
  final VoidCallback onRemove;
  final VoidCallback onMoveToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final product = line.product;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: ProductImage(imagePath: product.imagePath, iconSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.productName(product),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    ProductPriceRow(product: product),
                    if (product.isOutOfStock || product.isLowStock) ...[
                      const SizedBox(height: 2),
                      // Out-of-stock and low-stock render; in-stock shows no
                      // line (the tile has no in-stock state).
                      StockStatusLabel(
                        product: product,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.removeFromWishlist,
                icon: const Icon(Icons.delete_outline),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: onMoveToCart,
            icon: const Icon(Icons.add_shopping_cart, size: 18),
            label: Text(l10n.moveToCart),
          ),
        ],
      ),
    );
  }
}
