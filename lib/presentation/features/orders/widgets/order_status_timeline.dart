import 'package:flutter/material.dart';

import '../../../../core/entities/order.dart';
import '../order_date_format.dart';
import '../status_visuals.dart';

/// Vertical timeline of status changes, oldest first, latest highlighted.
class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({super.key, required this.history});

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
