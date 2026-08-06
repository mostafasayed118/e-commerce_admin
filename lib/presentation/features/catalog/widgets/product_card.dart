import 'package:flutter/material.dart';

import '../../../../core/entities/product.dart';
import '../../../l10n/l10n_ext.dart';
import 'product_image.dart';

/// A catalog tile: image, name, price (with strikethrough when discounted)
/// and a stock badge. Tapping opens the product detail screen.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ProductImage(),
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _Badge(
                        label: '-${product.discountPercent}%',
                        background: scheme.primary,
                        foreground: scheme.onPrimary,
                      ),
                    ),
                  if (product.isOutOfStock)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _Badge(
                        label: context.l10n.outOfStock,
                        background: Colors.black54,
                        foreground: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.productName(product),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  // The discounted price sits in a Flexible so it ellipsizes
                  // instead of overflowing on narrow two-column grids.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        context.formatCents(product.finalPriceCents),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            context.formatCents(product.priceCents),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (product.isLowStock) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.lowStockLeft(product.stock),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: scheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
