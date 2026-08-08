import 'package:flutter/material.dart';

import '../../../../core/entities/product.dart';
import '../../../l10n/l10n_ext.dart';
import 'product_image.dart';
import 'product_price_row.dart';
import 'stock_status_label.dart';

/// A catalog tile: image, name, price (with strikethrough when discounted),
/// a stock badge, and an optional wishlist heart. Tapping the tile opens the
/// product detail screen.
///
/// The heart is injected (`wishlisted` + [onToggleWishlist]) so this widget
/// stays dumb and testable without DI — the catalog wiring decides how the
/// wishlist state is read (see LoadedCatalog).
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.wishlisted = false,
    this.onToggleWishlist,
  });

  final Product product;
  final VoidCallback onTap;

  /// Whether the product is saved in the wishlist (drives the heart fill).
  final bool wishlisted;

  /// Toggles the wishlist membership. When null the heart is hidden, so the
  /// card remains usable without wishlist wiring.
  final VoidCallback? onToggleWishlist;

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
                        // Hardcoded label, not an ARB string — digits still
                        // follow the active locale (Eastern Arabic in `ar`).
                        label: context.localizeDigits('-${product.discountPercent}%'),
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
                  // Bottom-right so it never collides with the top badges.
                  if (onToggleWishlist != null)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _WishlistHeart(
                        saved: wishlisted,
                        onPressed: onToggleWishlist!,
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
                  ProductPriceRow(
                    product: product,
                    baseline: true,
                    finalPriceStyle: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (product.isLowStock) ...[
                    const SizedBox(height: 4),
                    // The card's inline label is low-stock only — its
                    // out-of-stock state is the image badge, not this line.
                    StockStatusLabel(
                      product: product,
                      style: theme.textTheme.labelSmall,
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

/// The card's wishlist heart: a small tonal circle over the image so it is
/// tappable regardless of the image behind it.
class _WishlistHeart extends StatelessWidget {
  const _WishlistHeart({required this.saved, required this.onPressed});

  final bool saved;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 1,
      child: IconButton(
        tooltip: saved
            ? context.l10n.removeFromWishlist
            : context.l10n.addToWishlist,
        visualDensity: VisualDensity.compact,
        icon: Icon(
          saved ? Icons.favorite : Icons.favorite_border,
          size: 20,
          color: saved ? scheme.error : scheme.onSurfaceVariant,
        ),
        onPressed: onPressed,
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
