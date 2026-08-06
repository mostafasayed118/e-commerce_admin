import 'package:equatable/equatable.dart';

import '../../../../core/entities/order.dart';
import '../../../../core/entities/order_status.dart';
import '../../../../core/entities/product.dart';

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

  /// How many recent orders the dashboard shows.
  static const int recentLimit = 5;

  @override
  List<Object?> get props => [
        revenueCents,
        totalOrders,
        ordersByStatus,
        recentOrders,
        lowStockProducts,
      ];
}
