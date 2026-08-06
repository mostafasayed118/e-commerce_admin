import 'package:flutter/material.dart';

import '../../../core/entities/order.dart';
import '../../l10n/l10n_ext.dart';
import 'order_date_format.dart';
import 'status_visuals.dart';

/// One order row, shared by the customer and admin order lists: status
/// avatar, order number, `date · items · total` subtitle, and the status
/// chip. Both lists rendered the same tile before this extraction — one
/// copy keeps the two features visually identical by construction.
class OrderListTile extends StatelessWidget {
  const OrderListTile({super.key, required this.order, this.onTap});

  final Order order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final visuals = orderStatusVisuals(order.status, scheme);
    final locale = Localizations.localeOf(context).languageCode;
    // The date part is omitted when absent rather than fabricated — a
    // made-up timestamp would be a lie on the history screen.
    final subtitleParts = [
      if (order.createdAt != null)
        formatOrderDate(order.createdAt!, locale: locale),
      l10n.itemCount(order.items.length),
      context.formatCents(order.totalCents),
    ];
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: visuals.background,
        foregroundColor: visuals.color,
        child: Icon(visuals.icon),
      ),
      title: Text(
        order.orderNumber,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitleParts.join(' · ')),
      trailing: StatusChip(order.status),
    );
  }
}
