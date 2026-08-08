import 'package:go_router/go_router.dart';

import '../../features/admin/catalog/categories_screen.dart';
import '../../features/admin/catalog/products_screen.dart';
import '../../features/admin/coupons/coupons_screen.dart';
import '../../features/admin/gate/admin_gate_screen.dart';
import '../../features/admin/reviews/reviews_screen.dart';
import '../../features/admin/orders/admin_orders_screen.dart';
import '../../features/admin/overview/admin_overview_screen.dart';
import '../../shells/admin_shell.dart';
import 'route_names.dart';

/// The admin area: the gate (outside any shell so it can float above them)
/// plus the gated admin shell with its own four branches.
List<RouteBase> adminRoutes() => [
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
                builder: (context, state) => const AdminOverviewScreen(),
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
                path: '/admin/coupons',
                name: RouteNames.adminCoupons,
                builder: (context, state) => const CouponsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/reviews',
                name: RouteNames.adminReviews,
                builder: (context, state) => const ReviewsScreen(),
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
    ];
