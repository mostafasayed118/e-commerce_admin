import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../features/cart/cart_cubit.dart';
import 'shell_scaffold.dart';

/// The customer-facing shell: Shop, Cart (with a live item-count badge),
/// Orders, Profile.
class ShopShell extends StatelessWidget {
  const ShopShell(this.navigationShell, {super.key});

  final StatefulNavigationShell navigationShell;

  static const List<ShellDestination> baseDestinations = [
    ShellDestination(
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
      label: 'Shop',
    ),
    ShellDestination(
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart,
      label: 'Cart',
    ),
    ShellDestination(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Orders',
    ),
    ShellDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
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
        final destinations = List<ShellDestination>.of(baseDestinations);
        destinations[1] = ShellDestination(
          icon: baseDestinations[1].icon,
          selectedIcon: baseDestinations[1].selectedIcon,
          label: baseDestinations[1].label,
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
