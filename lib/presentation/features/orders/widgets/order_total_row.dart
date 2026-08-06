import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';

/// One labeled amount row in an order's totals block (subtotal / savings /
/// total). [negative] flips the sign so the locale places it correctly;
/// [highlight] tints the value; [bold] emphasizes label and value.
class OrderTotalRow extends StatelessWidget {
  const OrderTotalRow({
    super.key,
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
