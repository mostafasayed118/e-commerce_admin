import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/entities/product.dart';
import '../../../../core/error/result.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../widgets/snack_bar.dart';
import '../wishlist_cubit.dart';

/// True when [productId] is saved in the wishlist, given the current cubit
/// state. Shared by the card and detail hearts to pick the fill + message.
bool isWishlisted(WishlistState state, int productId) =>
    state is WishlistLoaded &&
    state.lines.any((line) => line.product.id == productId);

/// Toggles [product] in the wishlist (via the DI-owned [WishlistCubit]) and
/// reports the outcome in a SnackBar: "added/removed" on success, the mapped
/// error text on failure. Shared by the catalog-card and detail hearts.
Future<void> toggleWishlistAndNotify(
  BuildContext context,
  Product product,
) async {
  final result = await getIt<WishlistCubit>().toggle(product.id);
  if (!context.mounted) return;
  // The message derives from what the toggle actually did (the returned
  // bool), never from pre-action state — race-free under rapid taps.
  result.fold(
    onSuccess: (nowSaved) => showSuccessSnackBar(
      context,
      nowSaved
          ? context.l10n.addedToWishlist(context.productName(product))
          : context.l10n.removedFromWishlist(context.productName(product)),
    ),
    onFailure: (error) => showErrorSnackBar(context, error),
  );
}

/// Self-contained heart toggle for screens outside the wishlist feature's
/// provider scope (product detail). Reads the DI-owned [WishlistCubit] and
/// rebuilds only when THIS product's membership changes.
class WishlistHeartButton extends StatelessWidget {
  const WishlistHeartButton({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<WishlistCubit, WishlistState>(
      bloc: getIt<WishlistCubit>(),
      buildWhen: (previous, current) =>
          isWishlisted(previous, product.id) !=
          isWishlisted(current, product.id),
      builder: (context, state) {
        final saved = isWishlisted(state, product.id);
        return IconButton.filledTonal(
          tooltip: saved
              ? context.l10n.removeFromWishlist
              : context.l10n.addToWishlist,
          icon: Icon(
            saved ? Icons.favorite : Icons.favorite_border,
            color: saved ? scheme.error : scheme.onSurfaceVariant,
          ),
          onPressed: () => toggleWishlistAndNotify(context, product),
        );
      },
    );
  }
}
