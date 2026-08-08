import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/entities/coupon.dart';
import '../../../../core/entities/order.dart';
import '../../../../core/entities/order_status.dart';
import '../../../../core/entities/product.dart';
import '../../../../domain/repositories/coupon_repository.dart';
import '../../../../domain/repositories/order_repository.dart';
import '../../../../domain/repositories/product_repository.dart';
import 'admin_overview_state.dart';

export 'admin_overview_state.dart';

/// Drives the admin dashboard. The same manual three-stream combine as the
/// other feature cubits — orders + products + coupons — but with **no new
/// queries**: revenue, per-status counts, recent orders, low-stock alerts,
/// the active-coupon count and recent coupon redemptions are all derived in
/// memory from what the watch streams already deliver.
class AdminOverviewCubit extends Cubit<AdminOverviewState> {
  AdminOverviewCubit(
    this._orders,
    this._products,
    this._coupons, {
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        super(const AdminOverviewLoading()) {
    _subscribe();
  }

  final OrderRepository _orders;
  final ProductRepository _products;
  final CouponRepository _coupons;

  /// Injectable clock: the active-coupon count depends on "now", and tests
  /// must not depend on the wall clock.
  final DateTime Function() _now;

  List<Order>? _allOrders;
  List<Product>? _allProducts;
  List<Coupon>? _allCoupons;
  bool _failed = false;

  StreamSubscription<List<Order>>? _ordersSub;
  StreamSubscription<List<Product>>? _productsSub;
  StreamSubscription<List<Coupon>>? _couponsSub;

  void _subscribe() {
    _ordersSub = _orders.watchOrders().listen(
      (orders) {
        _allOrders = orders;
        _recompute();
      },
      onError: (Object error) {
        _failed = true;
        emit(const AdminOverviewError('Could not load order metrics'));
      },
    );
    _productsSub = _products.watchProducts().listen(
      (products) {
        _allProducts = products;
        _recompute();
      },
      onError: (Object error) {
        _failed = true;
        emit(const AdminOverviewError('Could not load stock'));
      },
    );
    _couponsSub = _coupons.watchCoupons().listen(
      (coupons) {
        _allCoupons = coupons;
        _recompute();
      },
      onError: (Object error) {
        _failed = true;
        emit(const AdminOverviewError('Could not load coupons'));
      },
    );
  }

  void _recompute() {
    if (_failed) return; // sticky error, as in the other feature cubits
    final orders = _allOrders;
    final products = _allProducts;
    final coupons = _allCoupons;
    if (orders == null || products == null || coupons == null) return;

    var revenue = 0;
    final byStatus = {for (final s in OrderStatus.values) s: 0};
    for (final order in orders) {
      byStatus[order.status] = byStatus[order.status]! + 1;
      if (order.status != OrderStatus.cancelled) {
        revenue += order.totalCents;
      }
    }

    final lowStock = products
        .where((p) => p.isLowStock || p.isOutOfStock)
        .toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    // Active = enabled AND not expired at the injected instant (the coupon
    // list's own status chip uses the wall clock; the dashboard stays
    // deterministic under tests).
    final activeCouponCount =
        coupons.where((c) => c.isActive && !c.isExpiredAt(_now())).length;

    // Recent usage is derived from the orders stream (already newest-first)
    // — orders carrying a coupon snapshot, capped like recent orders.
    final recentCouponUses = <CouponUsageLine>[];
    for (final order in orders) {
      final code = order.couponCode;
      if (code == null || code.isEmpty) continue;
      recentCouponUses.add(CouponUsageLine(
        code: code,
        orderId: order.id,
        orderNumber: order.orderNumber,
        discountCents: order.couponDiscountCents,
        createdAt: order.createdAt,
      ));
      if (recentCouponUses.length >= AdminOverviewLoaded.couponUsesLimit) {
        break;
      }
    }

    // Top coupons: coupons with at least one redemption. Capped coupons
    // (a usage cap) rank first, ordered by how close they are to exhausting
    // their cap (usedCount / maxUses); unlimited coupons follow, ordered by
    // raw count. Ties are broken alphabetically so the order is
    // deterministic — "close to exhausted" is more actionable than "most
    // used".
    double? exhaustion(Coupon c) {
      final cap = c.maxUses;
      return (cap != null && cap > 0) ? c.usedCount / cap : null;
    }

    final usedCoupons = coupons.where((c) => c.usedCount > 0).toList()
      ..sort((a, b) {
        final aRatio = exhaustion(a);
        final bRatio = exhaustion(b);
        // Capped coupons (a non-null ratio) always rank above unlimited ones.
        if (aRatio != null && bRatio == null) return -1;
        if (aRatio == null && bRatio != null) return 1;
        if (aRatio != null && bRatio != null) {
          final byRatio = bRatio.compareTo(aRatio);
          return byRatio != 0 ? byRatio : a.code.compareTo(b.code);
        }
        final byUses = b.usedCount.compareTo(a.usedCount);
        return byUses != 0 ? byUses : a.code.compareTo(b.code);
      });
    // Every ranked coupon has usedCount > 0 (filtered above), so the relative
    // divisor (topMax, the highest raw count across all used coupons) is
    // always ≥ 1. The empty guard only protects the reduce when nothing has
    // been used. A coupon with a usage cap fills its bar toward the cap
    // instead — that answers "how close to exhausted" rather than "how
    // dominant".
    final topMax = usedCoupons.isEmpty
        ? 0
        : usedCoupons
            .map((c) => c.usedCount)
            .reduce((m, v) => v > m ? v : m);
    final topCoupons = <TopCouponRanking>[];
    for (final coupon in usedCoupons.take(AdminOverviewLoaded.topCouponsLimit)) {
      final cap = coupon.maxUses;
      final ratio = exhaustion(coupon) ?? coupon.usedCount / topMax;
      topCoupons.add(TopCouponRanking(
        code: coupon.code,
        usedCount: coupon.usedCount,
        maxUses: cap,
        fraction: ratio > 1 ? 1.0 : ratio,
      ));
    }

    emit(AdminOverviewLoaded(
      revenueCents: revenue,
      totalOrders: orders.length,
      ordersByStatus: byStatus,
      recentOrders: orders.take(AdminOverviewLoaded.recentLimit).toList(),
      lowStockProducts: lowStock,
      activeCouponCount: activeCouponCount,
      recentCouponUses: recentCouponUses,
      topCoupons: topCoupons,
    ));
  }

  @override
  Future<void> close() {
    _ordersSub?.cancel();
    _productsSub?.cancel();
    _couponsSub?.cancel();
    return super.close();
  }
}
