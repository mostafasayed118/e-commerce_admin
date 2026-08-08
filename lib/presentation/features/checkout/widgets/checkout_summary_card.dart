import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../l10n/l10n_ext.dart';
import '../../cart/cart_cubit.dart';
import '../../orders/widgets/order_total_row.dart';

/// The checkout order summary: subtotal, line savings, the applied coupon
/// line (when one is applied), and the total the customer will pay.
///
/// Totals are derived from the DI-owned [CartCubit] (the checkout route sits
/// above the shop shell, so there is no provider in scope — same direct-bloc
/// pattern as the shell badge) plus the checkout screen's applied-coupon
/// state. The total is a *preview*: placement re-validates the coupon and
/// recomputes the snapshot atomically.
class CheckoutSummaryCard extends StatelessWidget {
  const CheckoutSummaryCard({
    super.key,
    required this.couponCode,
    required this.couponDiscountCents,
  });

  /// `null` = no coupon applied.
  final String? couponCode;
  final int couponDiscountCents;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<CartCubit, CartState>(
      bloc: getIt<CartCubit>(),
      builder: (context, state) {
        final subtotal = switch (state) {
          CartLoaded(:final subtotalCents) => subtotalCents,
          _ => 0,
        };
        final savings = switch (state) {
          CartLoaded(:final discountCents) => discountCents,
          _ => 0,
        };
        final total = subtotal - savings - couponDiscountCents;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                OrderTotalRow(label: l10n.subtotal, cents: subtotal),
                if (savings > 0)
                  OrderTotalRow(
                    label: l10n.savings,
                    cents: savings,
                    negative: true,
                    highlight: true,
                  ),
                if (couponCode != null)
                  OrderTotalRow(
                    label: l10n.couponLabel(couponCode!),
                    cents: couponDiscountCents,
                    negative: true,
                    highlight: true,
                  ),
                const Divider(height: 16),
                OrderTotalRow(label: l10n.total, cents: total, bold: true),
              ],
            ),
          ),
        );
      },
    );
  }
}
