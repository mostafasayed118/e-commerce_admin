import 'package:flutter/material.dart';

import '../../../core/entities/order.dart';
import '../../l10n/l10n_ext.dart';
import '../../widgets/section_header.dart';
import 'order_date_format.dart';
import 'status_visuals.dart';
import 'widgets/order_item_row.dart';
import 'widgets/order_status_timeline.dart';
import 'widgets/order_total_row.dart';

/// The full order detail body, shared by the **customer and admin** order
/// features (the admin feature imports from here — a deliberate presentation-
/// layer reuse, same direction as ProductImage): header (number + status chip
/// + placed date), shipping snapshot, snapshot items + totals, and the status
/// timeline. The section widgets live in `widgets/`.
///
/// [actions] is an optional widget rendered after the timeline — the admin
/// detail passes the status-change action bar there; the customer screen
/// passes nothing.
class OrderDetailView extends StatelessWidget {
  const OrderDetailView({super.key, required this.order, this.actions});

  final Order order;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final placedAt = order.createdAt;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Header --------------------------------------------------------
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (placedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.placedAt(
                        formatOrderDateTime(placedAt, locale: locale),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            StatusChip(order.status),
          ],
        ),
        const SizedBox(height: 24),

        // --- Shipping ------------------------------------------------------
        SectionHeader(l10n.deliverTo),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.person_outline, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.shipping.name,
                      style: theme.textTheme.bodyMedium),
                  Text(
                    context.localizeDigits(order.shipping.phone),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(order.shipping.address,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      )),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- Items + totals ------------------------------------------------
        SectionHeader(l10n.items),
        const SizedBox(height: 8),
        for (final item in order.items) OrderItemRow(item: item),
        const SizedBox(height: 8),
        const Divider(),
        OrderTotalRow(label: l10n.subtotal, cents: order.subtotalCents),
        if (order.lineDiscountCents > 0)
          OrderTotalRow(
            label: l10n.savings,
            cents: order.lineDiscountCents,
            negative: true,
            highlight: true,
          ),
        if (order.couponDiscountCents > 0)
          OrderTotalRow(
            label: l10n.couponLabel(order.couponCode ?? ''),
            cents: order.couponDiscountCents,
            negative: true,
            highlight: true,
          ),
        OrderTotalRow(label: l10n.total, cents: order.totalCents, bold: true),
        const SizedBox(height: 24),

        // --- Status timeline ----------------------------------------------
        SectionHeader(l10n.status),
        const SizedBox(height: 8),
        if (order.statusHistory.isEmpty)
          Text(
            l10n.noStatusHistory,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          OrderStatusTimeline(history: order.statusHistory),

        if (actions != null) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          actions!,
        ],
      ],
    );
  }
}
