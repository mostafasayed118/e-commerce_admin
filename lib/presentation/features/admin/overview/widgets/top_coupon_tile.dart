import 'package:flutter/material.dart';

import '../../../../l10n/l10n_ext.dart';
import '../admin_overview_state.dart';
import 'overview_list_tile.dart';

/// One row of the dashboard's "Top coupons" ranking: the code, a usage bar
/// filled to [TopCouponRanking.fraction] (toward the coupon's cap when one
/// is set, otherwise relative to the most-used coupon), and a trailing label
/// — the exhaustion percentage for capped coupons, the redemption count for
/// unlimited ones. Purely presentational.
class TopCouponTile extends StatelessWidget {
  const TopCouponTile({super.key, required this.ranking, this.onTap});

  final TopCouponRanking ranking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cap = ranking.maxUses;
    return OverviewListTile(
      avatarBackground: scheme.secondaryContainer,
      avatarForeground: scheme.secondary,
      avatarIcon: Icons.stars_outlined,
      title: ranking.code,
      onTap: onTap,
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ranking.fraction,
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHighest,
            color: scheme.secondary,
          ),
        ),
      ),
      trailing: Text(
        // A capped coupon's label is its exhaustion percentage — the same
        // "how close to exhausted" answer as the bar, clamped to 100% when
        // an admin lowered a cap below past redemptions (the bar clamps
        // too). Unlimited coupons keep the plain count. Digits follow the
        // active locale (Eastern Arabic in `ar`, like prices and dates).
        context.localizeDigits(
          cap != null && cap > 0
              ? context.l10n.couponUsedPercent(_exhaustionPercent(ranking))
              : context.l10n.couponUsesCount(ranking.usedCount),
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Percent of the cap consumed, 0..100 (floored integer math), clamped so
  /// an over-cap coupon reads as fully used rather than "133% used".
  static int _exhaustionPercent(TopCouponRanking ranking) {
    final max = ranking.maxUses!;
    final used = ranking.usedCount > max ? max : ranking.usedCount;
    return used * 100 ~/ max;
  }
}
