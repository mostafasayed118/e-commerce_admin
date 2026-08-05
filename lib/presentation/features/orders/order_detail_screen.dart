import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/entities/order.dart';
import '../../../core/entities/order_item.dart';
import '../../../core/utils/money.dart';
import '../../../domain/repositories/order_repository.dart';
import '../../widgets/message_view.dart';
import 'order_date_format.dart';
import 'status_visuals.dart';

/// Order detail: the full aggregate (snapshot items, totals, shipping) plus
/// the status timeline. One read stream → StreamBuilder, no Cubit (the same
/// judgment as ProductDetailScreen — Section C.3).
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: StreamBuilder<Order?>(
        stream: getIt<OrderRepository>().watchOrderById(orderId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const MessageView(
              icon: Icons.error_outline,
              title: 'Could not load order',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final order = snapshot.data;
          if (order == null) {
            return const MessageView(
              icon: Icons.search_off,
              title: 'Order not found',
              message: 'This order may have been removed.',
            );
          }
          return _OrderDetailBody(order: order);
        },
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final placedAt = order.createdAt ?? DateTime.now();

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
                  const SizedBox(height: 4),
                  Text(
                    'Placed ${formatOrderDateTime(placedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(order.status),
          ],
        ),
        const SizedBox(height: 24),

        // --- Shipping ------------------------------------------------------
        const _SectionHeader('Deliver to'),
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
                  Text(order.shipping.phone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      )),
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
        const _SectionHeader('Items'),
        const SizedBox(height: 8),
        for (final item in order.items) _ItemRow(item: item),
        const SizedBox(height: 8),
        const Divider(),
        _TotalRow(label: 'Subtotal', cents: order.subtotalCents),
        if (order.discountCents > 0)
          _TotalRow(
            label: 'Savings',
            cents: order.discountCents,
            negative: true,
            highlight: true,
          ),
        _TotalRow(label: 'Total', cents: order.totalCents, bold: true),
        const SizedBox(height: 24),

        // --- Status timeline ----------------------------------------------
        const _SectionHeader('Status'),
        const SizedBox(height: 8),
        if (order.statusHistory.isEmpty)
          Text(
            'No status history yet.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          _StatusTimeline(history: order.statusHistory),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity} × ${formatCents(item.unitFinalPriceCents)}'
                  '${item.discountPercent > 0 ? ' (${item.discountPercent}% off)' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatCents(item.lineTotalCents),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.cents,
    this.negative = false,
    this.highlight = false,
    this.bold = false,
  });

  final String label;
  final int cents;
  final bool negative;
  final bool highlight;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w600 : null,
            ),
          ),
          const Spacer(),
          Text(
            '${negative ? '-' : ''}${formatCents(cents)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w700 : null,
              color: highlight ? scheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical timeline of status changes, oldest first, latest highlighted.
class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.history});

  final List<OrderStatusEntry> history;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < history.length; i++)
          _TimelineEntry(
            entry: history[i],
            isLatest: i == history.length - 1,
            showConnector: i != history.length - 1,
          ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.entry,
    required this.isLatest,
    required this.showConnector,
  });

  final OrderStatusEntry entry;
  final bool isLatest;
  final bool showConnector;

  /// Height of the vertical connector line — chosen so dot (16px) + connector
  /// fills the entry's content height (label + date + padding).
  static const double _connectorHeight = 36;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visuals = orderStatusVisuals(entry.status, scheme);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLatest ? visuals.color : null,
                border: isLatest
                    ? null
                    : Border.all(color: scheme.outlineVariant, width: 2),
              ),
            ),
            if (showConnector)
              // Explicit height: a childless Container would otherwise size
              // to 0 and the connecting line would be invisible.
              Container(
                width: 2,
                height: _connectorHeight,
                color: scheme.outlineVariant,
              )
            else
              const SizedBox(width: 2),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.status.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: isLatest ? FontWeight.w700 : FontWeight.w500,
                    color: isLatest ? visuals.color : null,
                  ),
                ),
                Text(
                  formatOrderDateTime(entry.changedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
