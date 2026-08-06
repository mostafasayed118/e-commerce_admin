import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../features/cart/cart_cubit.dart';
import '../l10n/l10n_ext.dart';
import 'shell_scaffold.dart';

/// The customer-facing shell: Shop, Cart (with a live item-count badge),
/// Orders, Profile.
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
    // The badge listens to the DI-owned CartCubit (never closed here). The
    // count comes from CartLoaded; any other state means no badge.
    return BlocBuilder<CartCubit, CartState>(
      bloc: getIt<CartCubit>(),
      // Rebuild only when the count could actually have changed — the badge
      // is the only thing this builder renders differently.
      buildWhen: (previous, current) =>
          previous is! CartLoaded ||
          current is! CartLoaded ||
          previous.itemCount != current.itemCount,
      builder: (context, state) {
        final count = switch (state) {
          CartLoaded(:final itemCount) => itemCount,
          _ => 0,
        };
        final destinations = List<ShellDestination>.of(
          baseDestinations(context),
        );
        destinations[1] = ShellDestination(
          icon: destinations[1].icon,
          selectedIcon: destinations[1].selectedIcon,
          label: destinations[1].label,
          badgeCount: count,
        );
        return ShellScaffold(
          navigationShell: navigationShell,
          destinations: destinations,
        );
      },
    );
  }
}
