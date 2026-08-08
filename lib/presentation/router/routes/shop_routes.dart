import 'package:go_router/go_router.dart';

import '../../features/cart/cart_screen.dart';
import '../../features/catalog/catalog_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/wishlist/wishlist_screen.dart';
import '../../shells/shop_shell.dart';
import 'route_names.dart';

/// The customer shop: bottom/rail navigation across four branches.
RouteBase shopShellRoutes() {
  return StatefulShellRoute.indexedStack(
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
            path: '/wishlist',
            name: RouteNames.wishlist,
            builder: (context, state) => const WishlistScreen(),
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
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
