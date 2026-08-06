import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/entities/order.dart';
import '../../../../core/entities/order_status.dart';
import '../../../../core/entities/product.dart';
import '../../../../domain/repositories/order_repository.dart';
import '../../../../domain/repositories/product_repository.dart';
import 'admin_overview_state.dart';

export 'admin_overview_state.dart';

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
