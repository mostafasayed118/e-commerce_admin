import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';

/// The cart's pinned bottom bar: subtotal / savings / total rows (integer-
/// cents math) and the checkout button.
class CartTotalsBar extends StatelessWidget {
  const CartTotalsBar({
    super.key,
    required this.subtotalCents,
    required this.discountCents,
    required this.totalCents,
    required this.onCheckout,
  });

  final int subtotalCents;
  final int discountCents;
  final int totalCents;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(l10n.subtotal, style: theme.textTheme.bodyMedium),
                const Spacer(),
                Text(
                  context.formatCents(subtotalCents),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            if (discountCents > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(l10n.savings, style: theme.textTheme.bodyMedium),
                  const Spacer(),
                  Text(
                    // Negative cents: the locale places the sign correctly
                    // ("-$12.34" LTR, "‏-12.34 $" RTL) — a hand-written
                    // prefix would land on the wrong side in RTL.
                    context.formatCents(-discountCents),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 20),
            Row(
              children: [
                Text(
                  l10n.total,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  context.formatCents(totalCents),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onCheckout,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l10n.checkout),
            ),
          ],
        ),
      ),
    );
  }
}
