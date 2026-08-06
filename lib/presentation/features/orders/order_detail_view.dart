import 'package:flutter/material.dart';

import '../../../core/entities/order.dart';
import '../../../core/entities/order_item.dart';
import '../../l10n/l10n_ext.dart';
import 'order_date_format.dart';
import 'status_visuals.dart';

/// The full order detail body, shared by the **customer and admin** order
/// features (the admin feature imports from here — a deliberate presentation-
/// layer reuse, same direction as ProductImage): header (number + status chip
/// + placed date), shipping snapshot, snapshot items + totals, and the status
/// timeline.
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
        _SectionHeader(l10n.deliverTo),
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
        _SectionHeader(l10n.items),
        const SizedBox(height: 8),
        for (final item in order.items) _ItemRow(item: item),
        const SizedBox(height: 8),
        const Divider(),
        _TotalRow(label: l10n.subtotal, cents: order.subtotalCents),
        if (order.discountCents > 0)
          _TotalRow(
            label: l10n.savings,
            cents: order.discountCents,
            negative: true,
            highlight: true,
          ),
        _TotalRow(label: l10n.total, cents: order.totalCents, bold: true),
        const SizedBox(height: 24),

        // --- Status timeline ----------------------------------------------
        _SectionHeader(l10n.status),
        const SizedBox(height: 8),
        if (order.statusHistory.isEmpty)
          Text(
            l10n.noStatusHistory,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          _StatusTimeline(history: order.statusHistory),

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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      // All-caps for Latin scripts; a no-op for Arabic (no letter case).
      // The tracking is Latin-only too — spaced-out Arabic glyphs look broken.
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing:
                Directionality.of(context) == TextDirection.rtl ? 0 : 1.2,
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
            // Negative cents: the locale places the sign correctly
            // ("-$12.34" LTR, "‏-12.34 $" RTL) — a hand-written prefix
            // would land on the wrong side in RTL.
            context.formatCents(negative ? -cents : cents),
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
                  orderStatusLabel(context, entry.status),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: isLatest ? FontWeight.w700 : FontWeight.w500,
                    color: isLatest ? visuals.color : null,
                  ),
                ),
                Text(
                  formatOrderDateTime(
                    entry.changedAt,
                    locale: Localizations.localeOf(context).languageCode,
                  ),
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
