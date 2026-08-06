import 'package:flutter/material.dart';

import '../../../core/entities/order_status.dart';
import '../../l10n/l10n_ext.dart';

/// Localized label for an [OrderStatus] (Task 23). The enum keeps its English
/// `label` for tooling/logs; every UI string goes through this so statuses
/// render in the active locale. Shared by the customer and admin order
/// features (admin imports from here).
String orderStatusLabel(BuildContext context, OrderStatus status) =>
    switch (status) {
      OrderStatus.pending => context.l10n.statusPending,
      OrderStatus.confirmed => context.l10n.statusConfirmed,
      OrderStatus.shipped => context.l10n.statusShipped,
      OrderStatus.delivered => context.l10n.statusDelivered,
      OrderStatus.cancelled => context.l10n.statusCancelled,
    };

/// Icon + color mapping for an [OrderStatus], from Material 3 scheme tokens
/// only (no hardcoded colors). Used by the list avatars, the chips, and the
/// detail timeline so every status looks identical everywhere. Shared by the
/// customer and admin order features (admin imports from here).
({IconData icon, Color color, Color background}) orderStatusVisuals(
  OrderStatus status,
  ColorScheme scheme,
) =>
    switch (status) {
      OrderStatus.pending => (
          icon: Icons.schedule,
          color: scheme.onSecondaryContainer,
          background: scheme.secondaryContainer,
        ),
      OrderStatus.confirmed => (
          icon: Icons.check,
          color: scheme.onPrimaryContainer,
          background: scheme.primaryContainer,
        ),
      OrderStatus.shipped => (
          icon: Icons.local_shipping_outlined,
          color: scheme.onTertiaryContainer,
          background: scheme.tertiaryContainer,
        ),
      OrderStatus.delivered => (
          icon: Icons.check_circle_outline,
          color: scheme.onSurface,
          background: scheme.surfaceContainerHighest,
        ),
      OrderStatus.cancelled => (
          icon: Icons.cancel_outlined,
          color: scheme.onErrorContainer,
          background: scheme.errorContainer,
        ),
    };

/// The pill-shaped status badge shared by the order list and detail screens.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visuals = orderStatusVisuals(status, scheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: visuals.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visuals.icon, size: 14, color: visuals.color),
          const SizedBox(width: 4),
          Text(
            orderStatusLabel(context, status),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: visuals.color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
