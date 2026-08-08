import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';

/// The checkout coupon section: a code field with an Apply button, which
/// swaps to an "applied" chip (code + discount) with a remove action once a
/// code is applied. Errors from ApplyCoupon render inline below.
///
/// Purely presentational — the checkout screen owns the apply/remove logic
/// and passes the results in.
class CouponField extends StatelessWidget {
  const CouponField({
    super.key,
    required this.controller,
    required this.appliedCode,
    required this.appliedDiscountCents,
    required this.errorText,
    required this.onApply,
    required this.onRemove,
  });

  final TextEditingController controller;

  /// `null` = no coupon applied yet (show the entry field).
  final String? appliedCode;
  final int appliedDiscountCents;
  final String? errorText;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final applied = appliedCode != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!applied)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onApply(),
                  decoration: InputDecoration(
                    hintText: l10n.couponCodeHint,
                    prefixIcon: const Icon(Icons.confirmation_number_outlined),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: onApply,
                child: Text(l10n.couponApply),
              ),
            ],
          )
        else
          Row(
            children: [
              Icon(Icons.confirmation_number, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${appliedCode!} · '
                  '−${context.formatCents(appliedDiscountCents)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.removeCoupon,
                icon: const Icon(Icons.close),
                onPressed: onRemove,
              ),
            ],
          ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}
