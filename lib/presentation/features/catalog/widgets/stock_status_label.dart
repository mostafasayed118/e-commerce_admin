import 'package:flutter/material.dart';

import '../../../../core/entities/product.dart';
import '../../../l10n/l10n_ext.dart';

/// The product's stock-status line: 'Out of stock' or 'Low stock: N left'
/// (in the error color), and optionally 'In stock' (in the primary color).
///
/// The card, wishlist tile, and detail screen each built this same
/// out-of-stock / low-stock / in-stock decision; [StockStatusLabel] is their
/// single source. [style] is the caller's text style (the color is overlaid
/// by the status — the tile/card/detail each use their own size). Callers
/// that show no label when the product is in stock (card, tile) leave
/// [showInStock] false — they also guard mounting (the card mounts only for
/// `isLowStock`, the tile for `isOutOfStock || isLowStock`) so the in-stock
/// case contributes no label *and* no spacing; the shrink branch is a
/// defensive fallback for any caller that mounts unconditionally. The detail
/// screen, which always shows a stock line, passes true.
class StockStatusLabel extends StatelessWidget {
  const StockStatusLabel({
    super.key,
    required this.product,
    this.style,
    this.showInStock = false,
  });

  final Product product;

  /// The caller's base text style; the status color is applied on top.
  final TextStyle? style;

  /// Whether to render 'In stock' when the product is neither out of nor
  /// low on stock (the detail screen shows a line in every state).
  final bool showInStock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    if (product.isOutOfStock) {
      return Text(
        l10n.outOfStock,
        style: style?.copyWith(color: scheme.error),
      );
    }
    if (product.isLowStock) {
      return Text(
        context.localizeDigits(l10n.lowStockLeft(product.stock)),
        style: style?.copyWith(color: scheme.error),
      );
    }
    if (!showInStock) return const SizedBox.shrink();
    return Text(
      l10n.inStock,
      style: style?.copyWith(color: scheme.primary),
    );
  }
}
