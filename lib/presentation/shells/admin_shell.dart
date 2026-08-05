import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shell_scaffold.dart';

/// The admin-facing shell: Overview, Products, Categories, Orders. Only
/// reachable after the gate (Task 12's router guard).
class AdminShell extends StatelessWidget {
  const AdminShell(this.navigationShell, {super.key});

  final StatefulNavigationShell navigationShell;

  static const List<ShellDestination> destinations = [
    ShellDestination(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Overview',
    ),
    ShellDestination(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'Products',
    ),
    ShellDestination(
      icon: Icons.category_outlined,
      selectedIcon: Icons.category,
      label: 'Categories',
    ),
    ShellDestination(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Orders',
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
