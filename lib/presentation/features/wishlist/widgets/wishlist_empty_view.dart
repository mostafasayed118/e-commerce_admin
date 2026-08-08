import 'package:flutter/material.dart';

import '../../../l10n/l10n_ext.dart';
import '../../../widgets/browse_catalog_action.dart';
import '../../../widgets/message_view.dart';

/// The empty-wishlist state with a "browse products" action back to the
/// catalog (the CTA is the shared [BrowseCatalogAction]).
class WishlistEmptyView extends StatelessWidget {
  const WishlistEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MessageView(
      icon: Icons.favorite_border,
      title: l10n.wishlistEmptyTitle,
      message: l10n.wishlistEmptyMessage,
      action: const BrowseCatalogAction(),
    );
  }
}
