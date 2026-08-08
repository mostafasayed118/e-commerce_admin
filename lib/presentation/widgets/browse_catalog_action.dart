import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n_ext.dart';

/// The empty-state "back to the catalog" button: a tonal storefront CTA that
/// goes to `/` (the catalog) and reads its own label so every empty state
/// reads identically — cart, wishlist, and the orders history all showed the
/// same `FilledButton.tonalIcon` block.
class BrowseCatalogAction extends StatelessWidget {
  const BrowseCatalogAction({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () => context.go('/'),
      icon: const Icon(Icons.storefront_outlined),
      label: Text(context.l10n.browseProducts),
    );
  }
}
