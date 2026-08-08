import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import '../../catalog/widgets/product_image.dart';
import '../../catalog/widgets/product_price_row.dart';
import '../cart_state.dart';

/// One cart line: product image, name, prices, stock warning, and the
/// quantity stepper. At quantity 1, stepping down removes the line entirely —
/// the stepper is the only removal affordance per line.
class CartLineTile extends StatelessWidget {
  const CartLineTile({
    super.key,
    required this.line,
    required this.onAdd,
    required this.onRemoveOne,
  });

  final CartLine line;
  final VoidCallback onAdd;
  final VoidCallback onRemoveOne;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final product = line.product;
    final canAdd = !line.exceedsStock;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
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
                // The struck-through original price is Flexible so a tight
                // name column ellipsizes it instead of overflowing.
                ProductPriceRow(product: product),
                if (line.exceedsStock) ...[
                  const SizedBox(height: 2),
                  Text(
                    context.localizeDigits(l10n.onlyXLeftInStock(product.stock)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                context.formatCents(line.lineTotalCents),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l10n.removeOne,
                    icon: const Icon(Icons.remove_circle_outline),
                    visualDensity: VisualDensity.compact,
                    onPressed: onRemoveOne,
                  ),
                  SizedBox(
                    width: 24,
                    child: Text(
                      context.localizeDigits('${line.quantity}'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.addOne,
                    icon: const Icon(Icons.add_circle_outline),
                    visualDensity: VisualDensity.compact,
                    onPressed: canAdd ? onAdd : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
