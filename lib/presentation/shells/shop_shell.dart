import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shell_scaffold.dart';

/// The customer-facing shell: Shop, Cart, Orders, Profile.
class ShopShell extends StatelessWidget {
  const ShopShell(this.navigationShell, {super.key});

  final StatefulNavigationShell navigationShell;

  static const List<ShellDestination> destinations = [
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
    return ShellScaffold(
      navigationShell: navigationShell,
      destinations: destinations,
    );
  }
}
