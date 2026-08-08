import 'package:flutter/material.dart';

import '../../../../l10n/l10n_ext.dart';
import '../../../orders/order_date_format.dart';
import '../admin_overview_state.dart';
import 'overview_list_tile.dart';

/// A recent coupon redemption on the dashboard: the code, the order that
/// used it (with its date), and the discount it contributed. Tapping opens
/// the order — same cross-link as the recent-orders list.
class CouponUsageTile extends StatelessWidget {
  const CouponUsageTile({super.key, required this.usage, this.onTap});

  final CouponUsageLine usage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final createdAt = usage.createdAt;

    return OverviewListTile(
      avatarBackground: scheme.primaryContainer,
      avatarForeground: scheme.primary,
      avatarIcon: Icons.confirmation_number,
      title: usage.code,
      onTap: onTap,
      subtitle: Text(
        [
          usage.orderNumber,
          if (createdAt != null) formatOrderDate(createdAt, locale: locale),
        ].join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        context.formatCents(-usage.discountCents),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
