import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../features/cart/cart_cubit.dart';
import '../features/wishlist/wishlist_cubit.dart';
import '../l10n/l10n_ext.dart';
import 'shell_scaffold.dart';

/// The customer-facing shell: Shop, Wishlist (with a live count badge),
/// Cart (with a live item-count badge), Orders, Profile.
class ShopShell extends StatelessWidget {
  const ShopShell(this.navigationShell, {super.key});

  final StatefulNavigationShell navigationShell;

  /// The labels are resolved per-build (not `static const`) so they follow
  /// the active locale (Task 23).
  static List<ShellDestination> baseDestinations(BuildContext context) => [
        ShellDestination(
          icon: Icons.storefront_outlined,
          selectedIcon: Icons.storefront,
          label: context.l10n.tabShop,
        ),
        ShellDestination(
          icon: Icons.favorite_border,
          selectedIcon: Icons.favorite,
          label: context.l10n.tabWishlist,
        ),
        ShellDestination(
          icon: Icons.shopping_cart_outlined,
          selectedIcon: Icons.shopping_cart,
          label: context.l10n.tabCart,
        ),
        ShellDestination(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: context.l10n.tabOrders,
        ),
        ShellDestination(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: context.l10n.tabProfile,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    // Both badges listen to the DI-owned cubits (never closed here). The
    // counts come from the Loaded states; any other state means no badge.
    return BlocBuilder<CartCubit, CartState>(
      bloc: getIt<CartCubit>(),
      // Rebuild only when the count could actually have changed — the badge
      // is the only thing this builder renders differently.
      buildWhen: (previous, current) =>
          previous is! CartLoaded ||
          current is! CartLoaded ||
          previous.itemCount != current.itemCount,
      builder: (context, cartState) {
        return BlocBuilder<WishlistCubit, WishlistState>(
          bloc: getIt<WishlistCubit>(),
          buildWhen: (previous, current) =>
              previous is! WishlistLoaded ||
              current is! WishlistLoaded ||
              previous.itemCount != current.itemCount,
          builder: (context, wishlistState) {
            final cartCount = switch (cartState) {
              CartLoaded(:final itemCount) => itemCount,
              _ => 0,
            };
            final wishlistCount = switch (wishlistState) {
              WishlistLoaded(:final itemCount) => itemCount,
              _ => 0,
            };
            final destinations = List<ShellDestination>.of(
              baseDestinations(context),
            );
            destinations[1] = _withBadge(destinations[1], wishlistCount);
            destinations[2] = _withBadge(destinations[2], cartCount);
            return ShellScaffold(
              navigationShell: navigationShell,
              destinations: destinations,
            );
          },
        );
      },
    );
  }

  /// Copies a destination with [badgeCount] applied (the badge hides at 0
  /// in ShellScaffold).
  static ShellDestination _withBadge(
    ShellDestination destination,
    int count,
  ) {
    return ShellDestination(
      icon: destination.icon,
      selectedIcon: destination.selectedIcon,
      label: destination.label,
      badgeCount: count,
    );
  }
}
