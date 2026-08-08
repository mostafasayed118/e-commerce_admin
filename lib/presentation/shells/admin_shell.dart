import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/widgets/admin_storefront_action.dart';
import '../l10n/l10n_ext.dart';
import 'shell_scaffold.dart';

/// The admin-facing shell: Overview, Products, Categories, Coupons, Orders.
/// Only reachable after the gate (Task 12's router guard).
class AdminShell extends StatelessWidget {
  const AdminShell(this.navigationShell, {super.key});

  final StatefulNavigationShell navigationShell;

  /// The labels are resolved per-build (not `static const`) so they follow
  /// the active locale (Task 23).
  static List<ShellDestination> destinations(BuildContext context) => [
        ShellDestination(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: context.l10n.tabOverview,
        ),
        ShellDestination(
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          label: context.l10n.tabProducts,
        ),
        ShellDestination(
          icon: Icons.category_outlined,
          selectedIcon: Icons.category,
          label: context.l10n.tabCategories,
        ),
        ShellDestination(
          icon: Icons.confirmation_number_outlined,
          selectedIcon: Icons.confirmation_number,
          label: context.l10n.tabCoupons,
        ),
        ShellDestination(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: context.l10n.tabOrders,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      navigationShell: navigationShell,
      destinations: destinations(context),
      // The mirror of the profile tab's admin entry: a pinned way back to the
      // customer view. It only navigates — AdminSession deliberately has no
      // logout (mock gate), so exiting keeps the session unlocked.
      exitAction: (
        icon: AdminStorefrontAction.icon,
        label: context.l10n.backToStore,
        onTap: () => context.go('/'),
      ),
    );
  }
}
