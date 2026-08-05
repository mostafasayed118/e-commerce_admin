import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/entities/order.dart';
import '../../../../core/entities/order_status.dart';
import '../../../../core/entities/product.dart';
import '../../../../domain/repositories/order_repository.dart';
import '../../../../domain/repositories/product_repository.dart';

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

/// Drives the admin dashboard. The same manual two-stream combine as the
/// other feature cubits — orders + products — but with **no new queries**:
/// revenue, per-status counts, recent orders and low-stock alerts are all
/// derived in memory from what the watch streams already deliver.
class AdminOverviewCubit extends Cubit<AdminOverviewState> {
  AdminOverviewCubit(this._orders, this._products)
      : super(const AdminOverviewLoading()) {
    _subscribe();
  }

  final OrderRepository _orders;
  final ProductRepository _products;

  List<Order>? _allOrders;
  List<Product>? _allProducts;
  bool _failed = false;

  StreamSubscription<List<Order>>? _ordersSub;
  StreamSubscription<List<Product>>? _productsSub;

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
  }

  void _recompute() {
    if (_failed) return; // sticky error, as in the other feature cubits
    final orders = _allOrders;
    final products = _allProducts;
    if (orders == null || products == null) return;

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

    emit(AdminOverviewLoaded(
      revenueCents: revenue,
      totalOrders: orders.length,
      ordersByStatus: byStatus,
      recentOrders: orders.take(AdminOverviewLoaded.recentLimit).toList(),
      lowStockProducts: lowStock,
    ));
  }

  @override
  Future<void> close() {
    _ordersSub?.cancel();
    _productsSub?.cancel();
    return super.close();
  }
}
