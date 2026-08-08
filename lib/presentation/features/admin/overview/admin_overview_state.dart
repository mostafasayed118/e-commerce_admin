import 'package:equatable/equatable.dart';

import '../../../../core/entities/order.dart';
import '../../../../core/entities/order_status.dart';
import '../../../../core/entities/product.dart';

/// One coupon in the dashboard's "Top coupons" ranking: its redemption
/// count and the bar's fill fraction.
final class TopCouponRanking extends Equatable {
  const TopCouponRanking({
    required this.code,
    required this.usedCount,
    required this.fraction,
    this.maxUses,
  });

  final String code;
  final int usedCount;

  /// The bar's fill, always 0..1: progress toward [maxUses] when a cap is
  /// set, otherwise relative to the most-used coupon in the ranking.
  final double fraction;

  /// The coupon's usage cap; `null` = unlimited (relative fill).
  final int? maxUses;

  @override
  List<Object?> get props => [code, usedCount, fraction, maxUses];
}

/// One day of the dashboard's sales trend: the revenue and order count for
/// a single calendar day within the trailing [AdminOverviewLoaded.trendDays]
/// window. Both values exclude cancelled orders — a cancellation is not a
/// sale, and the status chart already shows cancellations separately — so
/// the revenue and volume lines tell one coherent story.
final class DailyTrend extends Equatable {
  const DailyTrend({
    required this.day,
    required this.revenueCents,
    required this.orderCount,
  });

  /// The calendar day (date-only, local midnight).
  final DateTime day;

  /// Sum of non-cancelled order totals on [day], in cents.
  final int revenueCents;

  /// Number of non-cancelled orders placed on [day].
  final int orderCount;

  @override
  List<Object?> get props => [day, revenueCents, orderCount];
}

/// One product in the dashboard's "Top products" ranking: units sold and
/// revenue, aggregated from the order-line snapshots of non-cancelled
/// orders. Snapshot names survive later product edits/deletes (Decision E),
/// so the ranking keeps showing what actually sold.
final class TopProductRanking extends Equatable {
  const TopProductRanking({
    required this.name,
    this.nameAr,
    required this.unitsSold,
    required this.revenueCents,
  });

  /// Snapshot of the product name at purchase time.
  final String name;

  /// The line snapshots' Arabic label (the first non-null one seen), so the
  /// ranking renders localized like the receipt does.
  final String? nameAr;
  final int unitsSold;

  /// Sum of line totals (unit price after discount × quantity) in cents.
  final int revenueCents;

  @override
  List<Object?> get props => [name, nameAr, unitsSold, revenueCents];
}

/// One coupon redemption on the dashboard: derived from an order that
/// carried a coupon snapshot (Decision E), so it survives later coupon
/// edits/deletes.
final class CouponUsageLine extends Equatable {
  const CouponUsageLine({
    required this.code,
    required this.orderId,
    required this.orderNumber,
    required this.discountCents,
    this.createdAt,
  });

  final String code;
  final int orderId;
  final String orderNumber;
  final int discountCents;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        code,
        orderId,
        orderNumber,
        discountCents,
        createdAt,
      ];
}

/// Sealed admin-overview states.
sealed class AdminOverviewState extends Equatable {
  const AdminOverviewState();

  @override
  List<Object?> get props => [];
}

final class AdminOverviewLoading extends AdminOverviewState {
  const AdminOverviewLoading();
}

final class AdminOverviewError extends AdminOverviewState {
  const AdminOverviewError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// The dashboard's derived metrics. Nothing here is stored — every value is
/// recomputed from the live orders + products watch streams on each emission,
/// so the overview reflects admin edits (a status change, a price change, a
/// stock adjustment) immediately.
final class AdminOverviewLoaded extends AdminOverviewState {
  const AdminOverviewLoaded({
    required this.revenueCents,
    required this.totalOrders,
    required this.ordersByStatus,
    required this.recentOrders,
    required this.lowStockProducts,
    required this.activeCouponCount,
    required this.recentCouponUses,
    required this.topCoupons,
    required this.dailyTrend,
    required this.topProducts,
  });

  /// Sum of order totals, **excluding cancelled orders** (a cancellation is
  /// not revenue — the metric is defined, not ambiguous).
  final int revenueCents;

  /// All orders, including cancelled.
  final int totalOrders;

  /// Count per status (every status present, zero-filled) — the chart's data.
  final Map<OrderStatus, int> ordersByStatus;

  /// Newest orders, capped at [recentLimit].
  final List<Order> recentOrders;

  /// Products that are low on stock or out of stock, most critical first.
  final List<Product> lowStockProducts;

  /// Coupons that are active and not expired (at the cubit's injectable now).
  final int activeCouponCount;

  /// The most recent orders that applied a coupon, newest first.
  final List<CouponUsageLine> recentCouponUses;

  /// The most-used coupons — capped ones first, ordered by how close they
  /// are to exhausting their cap, then unlimited ones by redemption count —
  /// with a bar that fills toward the cap (or relative to the top count).
  final List<TopCouponRanking> topCoupons;

  /// Daily revenue + order count for the trailing [trendDays] days, oldest
  /// first, zero-filled so the chart axis is stable.
  final List<DailyTrend> dailyTrend;

  /// Best-selling products (by revenue, then units) among non-cancelled
  /// orders, capped at [topProductsLimit].
  final List<TopProductRanking> topProducts;

  /// How many recent orders the dashboard shows.
  static const int recentLimit = 5;

  /// How many recent coupon redemptions the dashboard shows.
  static const int couponUsesLimit = 4;

  /// How many coupons the top ranking shows.
  static const int topCouponsLimit = 4;

  /// How many days the sales-trend window spans (trailing days, today
  /// included when it is the latest order day).
  static const int trendDays = 7;

  /// How many products the top ranking shows.
  static const int topProductsLimit = 5;

  @override
  List<Object?> get props => [
        revenueCents,
        totalOrders,
        ordersByStatus,
        recentOrders,
        lowStockProducts,
        activeCouponCount,
        recentCouponUses,
        topCoupons,
        dailyTrend,
        topProducts,
      ];
}
