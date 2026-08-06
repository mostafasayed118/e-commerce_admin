import 'package:flutter/material.dart';

import '../../../../core/entities/order_item.dart';
import '../../../l10n/l10n_ext.dart';

/// A single snapshot line in an order receipt: name, quantity × unit price
/// (with the per-unit discount note), and the line total.
class OrderItemRow extends StatelessWidget {
  const OrderItemRow({super.key, required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.orderItemName(item),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity} × ${context.formatCents(item.unitFinalPriceCents)}'
                  '${item.discountPercent > 0 ? ' ${l10n.percentOff(item.discountPercent)}' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            context.formatCents(item.lineTotalCents),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
