import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../features/admin/catalog/categories_screen.dart';
import '../features/admin/catalog/product_form_screen.dart';
import '../features/admin/catalog/products_screen.dart';
import '../features/admin/gate/admin_gate_screen.dart';
import '../features/admin/orders/admin_order_detail_screen.dart';
import '../features/admin/orders/admin_orders_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/catalog/catalog_screen.dart';
import '../features/catalog/product_detail_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/orders/order_detail_screen.dart';
import '../features/orders/orders_screen.dart';
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
  // Top-level shop pages (above the shell).
  static const String productDetail = 'product-detail';
  static const String checkout = 'checkout';
  static const String orderDetail = 'order-detail';
  // Admin.
  static const String adminGate = 'admin-gate';
  static const String adminOverview = 'admin-overview';
  static const String adminProducts = 'admin-products';
  static const String adminProductNew = 'admin-product-new';
  static const String adminProductEdit = 'admin-product-edit';
  static const String adminCategories = 'admin-categories';
  static const String adminOrders = 'admin-orders';
  static const String adminOrderDetail = 'admin-order-detail';
}

/// The app's single router: a shop shell, an admin shell, and the admin gate
/// between them.
///
/// The gate redirect is the "route guard": every `/admin/...` location passes
/// only when [AdminSession.unlocked] is true; otherwise it is redirected to
/// `/admin/gate`, which either asks for the PIN or (first run) sets one
/// (Task 9's SettingsRepository decides which).
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
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
                builder: (context, state) => const CatalogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                name: RouteNames.cart,
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                name: RouteNames.orders,
                builder: (context, state) => const OrdersScreen(),
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

      // --- Product detail: pushed on the root navigator so it covers the
      // shell (full-screen, standard shop UX). ---
      GoRoute(
        path: '/product/:productId',
        name: RouteNames.productDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ProductDetailScreen(
          // Guarded: a malformed deep link resolves to -1, which the detail
          // screen's watch stream maps to its "Product not found" view.
          productId:
              int.tryParse(state.pathParameters['productId'] ?? '') ?? -1,
        ),
      ),

      // --- Admin gate: outside any shell so it can float above them. ---
      GoRoute(
        path: '/admin/gate',
        name: RouteNames.adminGate,
        builder: (context, state) => const AdminGateScreen(),
      ),

      // --- Order detail: pushed on the root navigator (same pattern as the
      // product detail page). ---
      GoRoute(
        path: '/orders/:orderId',
        name: RouteNames.orderDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => OrderDetailScreen(
          orderId: int.tryParse(state.pathParameters['orderId'] ?? '') ?? -1,
        ),
      ),

      // --- Checkout: pushed on the root navigator (full-screen form over
      // the shell), customer side — no guard. ---
      GoRoute(
        path: '/checkout',
        name: RouteNames.checkout,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CheckoutScreen(),
      ),

      // --- Admin order detail: pushed on the root navigator (gated by the
      // same /admin/ guard as everything else). ---
      GoRoute(
        path: '/admin/orders/:orderId',
        name: RouteNames.adminOrderDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AdminOrderDetailScreen(
          orderId: int.tryParse(state.pathParameters['orderId'] ?? '') ?? -1,
        ),
      ),

      // --- Product create/edit forms: pushed on the root navigator so they
      // cover the admin shell (same pattern as /product/:productId). The
      // redirect guard gates them automatically (they live under /admin/). ---
      GoRoute(
        path: '/admin/products/new',
        name: RouteNames.adminProductNew,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/admin/products/:productId/edit',
        name: RouteNames.adminProductEdit,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ProductFormScreen(
          productId:
              int.tryParse(state.pathParameters['productId'] ?? '') ?? -1,
        ),
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
                builder: (context, state) => const ProductsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/categories',
                name: RouteNames.adminCategories,
                builder: (context, state) => const CategoriesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/orders',
                name: RouteNames.adminOrders,
                builder: (context, state) => const AdminOrdersScreen(),
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
