import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/catalog/product_form_screen.dart';
import '../../features/admin/coupons/coupon_form_screen.dart';
import '../../features/admin/orders/admin_order_detail_screen.dart';
import '../../features/catalog/product_detail_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import 'route_names.dart';

/// Parses a `:param` path segment as an id. Guarded: a malformed deep link
/// (missing or non-numeric) resolves to -1, which each screen's watch stream
/// maps to its "not found" view.
int _pathId(GoRouterState state, String param) =>
    int.tryParse(state.pathParameters[param] ?? '') ?? -1;

/// Top-level pages pushed on the root navigator so they cover the shells
/// (full-screen, standard shop UX).
List<RouteBase> detailRoutes(GlobalKey<NavigatorState> rootNavigatorKey) => [
      // --- Product detail: pushed on the root navigator so it covers the
      // shell (full-screen, standard shop UX). ---
      GoRoute(
        path: '/product/:productId',
        name: RouteNames.productDetail,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ProductDetailScreen(
          productId: _pathId(state, 'productId'),
        ),
      ),

      // --- Order detail: pushed on the root navigator (same pattern as the
      // product detail page). ---
      GoRoute(
        path: '/orders/:orderId',
        name: RouteNames.orderDetail,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => OrderDetailScreen(
          orderId: _pathId(state, 'orderId'),
        ),
      ),

      // --- Checkout: pushed on the root navigator (full-screen form over
      // the shell), customer side — no guard. ---
      GoRoute(
        path: '/checkout',
        name: RouteNames.checkout,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CheckoutScreen(),
      ),

      // --- Admin order detail: pushed on the root navigator (gated by the
      // same /admin/ guard as everything else). ---
      GoRoute(
        path: '/admin/orders/:orderId',
        name: RouteNames.adminOrderDetail,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => AdminOrderDetailScreen(
          orderId: _pathId(state, 'orderId'),
        ),
      ),

      // --- Product create/edit forms: pushed on the root navigator so they
      // cover the admin shell (same pattern as /product/:productId). The
      // redirect guard gates them automatically (they live under /admin/). ---
      GoRoute(
        path: '/admin/products/new',
        name: RouteNames.adminProductNew,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/admin/products/:productId/edit',
        name: RouteNames.adminProductEdit,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ProductFormScreen(
          productId: _pathId(state, 'productId'),
        ),
      ),

      // --- Coupon create/edit forms: same pattern as the product forms
      // (root navigator, gated by the /admin/ guard automatically). ---
      GoRoute(
        path: '/admin/coupons/new',
        name: RouteNames.adminCouponNew,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CouponFormScreen(),
      ),
      GoRoute(
        path: '/admin/coupons/:couponId/edit',
        name: RouteNames.adminCouponEdit,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => CouponFormScreen(
          couponId: _pathId(state, 'couponId'),
        ),
      ),
    ];
