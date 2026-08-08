import 'package:flutter/material.dart';

import '../../../../../core/utils/money.dart';
import '../../../../l10n/l10n_ext.dart';
import '../admin_overview_state.dart';
import 'overview_list_tile.dart';

/// One row of the dashboard's "Top products" ranking: the product's
/// localized snapshot name, the units sold (localized plural), and the
/// revenue. Purely presentational — the order of the list is the ranking.
class TopProductTile extends StatelessWidget {
  const TopProductTile({super.key, required this.ranking});

  final TopProductRanking ranking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    // The snapshot label follows the viewer's locale with an English
    // fallback — the same convention as the receipt's item rows (emptyToNull
    // normalizes whitespace-only labels to null so they degrade to English).
    final title = locale == 'ar'
        ? emptyToNull(ranking.nameAr ?? '') ?? ranking.name
        : ranking.name;
    return OverviewListTile(
      avatarBackground: scheme.primaryContainer,
      avatarForeground: scheme.primary,
      avatarIcon: Icons.sell_outlined,
      title: title,
      subtitle: Text(
        // The plural carries the count; localizeDigits converts it under
        // `ar` (idempotent otherwise).
        context.localizeDigits(context.l10n.unitsSold(ranking.unitsSold)),
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        formatCents(ranking.revenueCents, locale: locale),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
