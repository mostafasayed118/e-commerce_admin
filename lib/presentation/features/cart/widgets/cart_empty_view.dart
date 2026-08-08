import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../widgets/browse_catalog_action.dart';
import '../../../widgets/message_view.dart';

/// The empty-cart state with a "browse products" action back to the catalog.
class CartEmptyView extends StatelessWidget {
  const CartEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MessageView(
      icon: Icons.shopping_cart_outlined,
      title: l10n.cartEmptyTitle,
      message: l10n.cartEmptyMessage,
      action: const BrowseCatalogAction(),
    );
  }
}
