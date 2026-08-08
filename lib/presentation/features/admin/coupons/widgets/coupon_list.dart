import 'package:flutter/material.dart';

import '../../../../../core/entities/coupon.dart';
import '../../../../l10n/l10n_ext.dart';
import '../../../../widgets/message_view.dart';
import '../admin_coupons_state.dart';

/// The admin coupon list: rows with the discount summary, a status chip, and
/// delete. Purely presentational — navigation and the delete flow are
/// delegated to the screen through [onEdit] / [onDelete] / [onCreate].
class CouponList extends StatelessWidget {
  const CouponList({
    super.key,
    required this.state,
    required this.onEdit,
    required this.onDelete,
    required this.onCreate,
  });

  final AdminCouponsLoaded state;
  final ValueChanged<Coupon> onEdit;
  final ValueChanged<Coupon> onDelete;
  final VoidCallback onCreate;

  String _valueLabel(BuildContext context, Coupon coupon) =>
      switch (coupon.type) {
        CouponDiscountType.percent =>
          context.l10n.couponPercentOff(coupon.value),
        CouponDiscountType.fixed =>
          context.l10n.couponFixedOff(context.formatCents(coupon.value)),
      };

  String _usageLabel(BuildContext context, Coupon coupon) {
    final l10n = context.l10n;
    final cap = coupon.maxUses;
    return cap == null
        ? l10n.unlimited
        : l10n.couponUsesLeft(coupon.usedCount, cap);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (state.coupons.isEmpty) {
      return MessageView(
        icon: Icons.confirmation_number_outlined,
        title: l10n.noCouponsTitle,
        message: l10n.noCouponsMessage,
        action: FilledButton.tonalIcon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: Text(l10n.newCoupon),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.coupons.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, index) {
        final coupon = state.coupons[index];
        final scheme = Theme.of(context).colorScheme;
        final expired = coupon.isActive && coupon.isExpired;
        final (statusLabel, chipColor, chipBackground) = expired
            ? (l10n.expiredStatus, scheme.error, scheme.errorContainer)
            : coupon.isActive
                ? (l10n.activeStatus, scheme.primary, scheme.primaryContainer)
                : (l10n.inactiveStatus, scheme.onSurfaceVariant, scheme.surfaceContainerHighest);

        final subtitleParts = <String>[
          _valueLabel(context, coupon),
          if (coupon.minSpendCents > 0)
            l10n.couponMinSpendShort(context.formatCents(coupon.minSpendCents)),
          _usageLabel(context, coupon),
        ];

        return ListTile(
          onTap: () => onEdit(coupon),
          leading: const Icon(Icons.confirmation_number_outlined),
          title: Text(
            coupon.code,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          // Digits in every subtitle part (the discount %, the usage label)
          // follow the active locale — Eastern Arabic in `ar`, like prices
          // and dates. Idempotent: money already went through formatCents.
          subtitle: Text(context.localizeDigits(subtitleParts.join(' · '))),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: chipBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: chipColor),
                ),
              ),
              IconButton(
                tooltip: l10n.deleteCouponTooltip(coupon.code),
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onDelete(coupon),
              ),
            ],
          ),
        );
      },
    );
  }
}
