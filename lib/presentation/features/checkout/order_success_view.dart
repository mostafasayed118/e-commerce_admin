import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/entities/order.dart';
import '../../l10n/l10n_ext.dart';

/// The post-checkout **success screen**: snapshot totals, order number, and a
/// "back to shop" action. The cart is already cleared by `placeOrder` (Task 8)
/// by the time this renders.
class OrderSuccessView extends StatelessWidget {
  const OrderSuccessView({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 72, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.orderPlaced,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              // The summary keeps the *canonical* order number (an
              // identifier, like coupon codes); the total is already Eastern
              // via formatCents — so no blanket localizeDigits here.
              Text(
                l10n.orderPlacedSummary(
                  order.orderNumber,
                  context.formatCents(order.totalCents),
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                context.localizeDigits(l10n.weWillCall(order.shipping.phone)),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.go('/'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(l10n.backToShop),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
