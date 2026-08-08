import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/entities/product.dart';
import '../../../../l10n/l10n_ext.dart';
import 'overview_list_tile.dart';

/// A low-stock / out-of-stock product row on the dashboard, tapping into the
/// product edit form.
class LowStockTile extends StatelessWidget {
  const LowStockTile({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final out = product.isOutOfStock;
    final color = out ? scheme.error : scheme.tertiary;
    final background = out ? scheme.errorContainer : scheme.tertiaryContainer;

    return OverviewListTile(
      avatarBackground: background,
      avatarForeground: color,
      avatarIcon: out ? Icons.block : Icons.warning_amber_outlined,
      title: context.productName(product),
      titleStyle: theme.textTheme.titleSmall,
      onTap: () => context.push('/admin/products/${product.id}/edit'),
      subtitle: Text(
        out
            ? l10n.outOfStock
            : context.localizeDigits(l10n.onlyXLeft(product.stock)),
        style: theme.textTheme.bodySmall?.copyWith(color: color),
      ),
      trailing: Text(
        context.formatCents(product.finalPriceCents),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
