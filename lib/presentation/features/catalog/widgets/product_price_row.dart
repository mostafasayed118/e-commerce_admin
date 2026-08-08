import 'package:flutter/material.dart';

import '../../../../core/entities/product.dart';
import '../../../l10n/l10n_ext.dart';

/// The product's price row: the paid price, plus the struck-through original
/// when discounted — and, in the large (detail) treatment, a percent-off
/// badge after it.
///
/// The card, cart tile, wishlist tile, and detail screen each built this
/// same row; [ProductPriceRow] is their single source. The struck price sits
/// in a [Flexible] so a tight column ellipsizes it instead of overflowing —
/// except the badge variant, where the *badge* is the [Flexible] (the badge
/// ellipsizes, keeping the struck price whole — the detail screen's
/// contract, since Arabic digits + bidi marks are wider).
class ProductPriceRow extends StatelessWidget {
  const ProductPriceRow({
    super.key,
    required this.product,
    this.finalPriceStyle,
    this.baseline = false,
    this.gap = 6,
    this.showDiscountBadge = false,
  });

  final Product product;

  /// The paid price's style; defaults to the tile treatment (bold body).
  final TextStyle? finalPriceStyle;

  /// Baseline-aligns the row (the card/detail treatment); the tiles keep
  /// center alignment.
  final bool baseline;

  /// Horizontal gap between price elements (the detail screen uses 8).
  final double gap;

  /// Renders a percent-off badge after the struck price (detail treatment)
  /// instead of the plain struck-price-only row.
  final bool showDiscountBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment:
          baseline ? CrossAxisAlignment.baseline : CrossAxisAlignment.center,
      textBaseline: baseline ? TextBaseline.alphabetic : null,
      children: [
        Text(
          context.formatCents(product.finalPriceCents),
          style: finalPriceStyle ??
              theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (product.hasDiscount) ...[
          SizedBox(width: gap),
          if (showDiscountBadge) ...[
            Text(
              context.formatCents(product.priceCents),
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            SizedBox(width: gap),
            Flexible(
              child: _DiscountBadge(discountPercent: product.discountPercent),
            ),
          ] else
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
    );
  }
}

/// The percent-off chip (the detail screen's price-row badge). Distinct from
/// the card's `_Badge` — that one is a parameterized pill for the image
/// overlay (and the out-of-stock state); this one is the fixed percent chip
/// with the detail screen's primaryContainer styling. Hardcoded label, not
/// an ARB string — digits still follow the active locale (Eastern Arabic in
/// `ar`).
class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.discountPercent});

  final int discountPercent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        // Hardcoded label, not an ARB string — digits still follow the
        // active locale (Eastern Arabic in `ar`).
        context.localizeDigits('-$discountPercent%'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
