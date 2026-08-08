import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/entities/product.dart';
import '../../../core/error/result.dart';
import '../../../domain/usecases/wishlist/move_wishlist_item_to_cart.dart';
import '../../l10n/l10n_ext.dart';
import '../../widgets/error_view.dart';
import '../../widgets/snack_bar.dart';
import 'wishlist_cubit.dart';
import 'widgets/wishlist_empty_view.dart';
import 'widgets/wishlist_tile.dart';

/// The customer wishlist: saved products with move-to-cart and remove
/// actions. DI-owned [WishlistCubit] provided by **value** (same lifecycle
/// rule as every other feature screen).
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WishlistCubit>.value(
      value: getIt<WishlistCubit>(),
      child: const _WishlistView(),
    );
  }
}

class _WishlistView extends StatelessWidget {
  const _WishlistView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.wishlistTitle)),
      body: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) => switch (state) {
          WishlistLoading() =>
            const Center(child: CircularProgressIndicator()),
          WishlistError() => const ErrorView(),
          WishlistLoaded() => state.lines.isEmpty
              ? const WishlistEmptyView()
              : _FilledWishlist(state: state),
        },
      ),
    );
  }
}

class _FilledWishlist extends StatelessWidget {
  const _FilledWishlist({required this.state});

  final WishlistLoaded state;

  /// "Move to cart" delegates to [MoveWishlistItemToCart], which composes
  /// AddToCart's stock rules with the wishlist removal (a business rule, not
  /// screen orchestration) and reports the outcome.
  Future<void> _moveToCart(BuildContext context, Product product) async {
    final result = await getIt<MoveWishlistItemToCart>()(product.id);
    if (!context.mounted) return;
    result.fold(
      onSuccess: (_) => showSuccessSnackBar(
        context,
        context.l10n.addedToCart(context.productName(product)),
      ),
      onFailure: (error) => showErrorSnackBar(context, error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.lines.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
      itemBuilder: (context, index) {
        final line = state.lines[index];
        final cubit = context.read<WishlistCubit>();
        return WishlistTile(
          line: line,
          onRemove: () async {
            final result = await cubit.toggle(line.product.id);
            if (context.mounted) {
              result.fold(
                onSuccess: (_) {},
                onFailure: (error) => showErrorSnackBar(context, error),
              );
            }
          },
          onMoveToCart: () => _moveToCart(context, line.product),
        );
      },
    );
  }
}
