import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/entities/order.dart';
import '../../../../core/entities/order_status.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/repositories/order_repository.dart';
import 'admin_orders_state.dart';

export 'admin_orders_state.dart';

/// Drives the admin order management screens: watch-driven list with a
/// client-side status filter, plus [updateStatus] which delegates to the
/// repository (whose `canTransitionTo` state machine rejects illegal moves —
/// the UI only *shows* legal ones, but the repository is the enforcement
/// boundary). The watch stream re-emits the updated aggregate afterwards.
class AdminOrdersCubit extends Cubit<AdminOrdersState> {
  AdminOrdersCubit(this._orders) : super(const AdminOrdersLoading()) {
    _subscribe();
  }

  final OrderRepository _orders;

  bool _failed = false;
  OrderStatus? _filter;
  StreamSubscription<List<Order>>? _sub;

  void _subscribe() {
    _sub = _orders.watchOrders().listen(
      (orders) {
        if (_failed) return; // sticky error, as in the other feature cubits
        _recompute(orders);
      },
      onError: (Object error) {
        _failed = true;
        emit(const AdminOrdersError('Could not load orders'));
      },
    );
  }

  void _recompute(List<Order> orders) {
    emit(AdminOrdersLoaded(
      allOrders: orders,
      filter: _filter,
      visibleOrders: _filter == null
          ? orders
          : orders.where((o) => o.status == _filter).toList(),
    ));
  }

  /// Applies the status filter; `null` clears it (shows all).
  void setFilter(OrderStatus? filter) {
    if (_failed) return;
    _filter = filter;
    final state = this.state;
    if (state is AdminOrdersLoaded) {
      _recompute(state.allOrders);
    }
  }

  /// Delegates to the repository's transition validator. The returned
  /// [Result] feeds the detail screen's SnackBar; success re-emits the list
  /// automatically via the watch stream.
  Future<Result<Order>> updateStatus(int orderId, OrderStatus newStatus) =>
      _orders.updateStatus(orderId, newStatus);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
