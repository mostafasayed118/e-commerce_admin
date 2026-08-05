import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../features/admin/gate/admin_gate_screen.dart';
import '../placeholder_screen.dart';
import '../shells/admin_shell.dart';
import '../shells/shop_shell.dart';
import 'admin_session.dart';

/// Route names — used by navigation code instead of string literals so a
/// rename fails at compile time, not in a redirect.
abstract final class RouteNames {
  // Shop shell branches.
  static const String shop = 'shop';
  static const String cart = 'cart';
  static const String orders = 'orders';
  static const String profile = 'profile';
  // Admin.
  static const String adminGate = 'admin-gate';
  static const String adminOverview = 'admin-overview';
  static const String adminProducts = 'admin-products';
  static const String adminCategories = 'admin-categories';
  static const String adminOrders = 'admin-orders';
}

/// The app's single router: a shop shell, an admin shell, and the admin gate
/// between them.
///
/// The gate redirect is the "route guard": every `/admin/...` location passes
/// only when [AdminSession.unlocked] is true; otherwise it is redirected to
/// `/admin/gate`, which either asks for the PIN or (first run) sets one
/// (Task 9's SettingsRepository decides which).
GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: '/',
    redirect: _adminRedirect,
    routes: [
      // --- Customer shop: bottom/rail navigation across four branches. ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShopShell(navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: RouteNames.shop,
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Shop', arrivingIn: 'Task 13'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                name: RouteNames.cart,
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Cart', arrivingIn: 'Task 15'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                name: RouteNames.orders,
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'My Orders', arrivingIn: 'Task 16'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: RouteNames.profile,
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Profile', arrivingIn: 'Task 21'),
              ),
            ],
          ),
        ],
      ),

      // --- Admin gate: outside any shell so it can float above them. ---
      GoRoute(
        path: '/admin/gate',
        name: RouteNames.adminGate,
        builder: (context, state) => const AdminGateScreen(),
      ),

      // --- Admin dashboard: gated shell with its own four branches. ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShell(navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/overview',
                name: RouteNames.adminOverview,
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Overview', arrivingIn: 'Task 13'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/products',
                name: RouteNames.adminProducts,
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Products', arrivingIn: 'Task 14'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/categories',
                name: RouteNames.adminCategories,
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Categories', arrivingIn: 'Task 14'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/orders',
                name: RouteNames.adminOrders,
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Orders', arrivingIn: 'Task 17'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Route guard for the admin area.
String? _adminRedirect(BuildContext context, GoRouterState state) {
  final path = state.uri.path;
  // Exact segment match, not a bare prefix: `/administrator` must not be
  // treated as an admin route (this guard is the security boundary).
  if (path != '/admin' && !path.startsWith('/admin/')) return null;
  // The gate itself is always reachable (it is where you get unlocked).
  if (path == '/admin/gate') return null;
  if (!getIt<AdminSession>().unlocked) return '/admin/gate';
  return null;
}
