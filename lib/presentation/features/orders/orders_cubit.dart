import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/order.dart';
import '../../../domain/repositories/order_repository.dart';

/// Sealed orders states.
sealed class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

final class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

final class OrdersError extends OrdersState {
  const OrdersError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// The customer's order history, newest first. An empty [orders] list is the
/// normal fresh state — the screen renders the empty view.
final class OrdersLoaded extends OrdersState {
  const OrdersLoaded(this.orders);

  final List<Order> orders;

  @override
  List<Object?> get props => [orders];
}

/// Drives the order history list. Read-only: the customer has no order
/// mutations (admin order management is a separate feature), so this cubit
/// is just a watch stream with explicit states — the same sealed-state
/// contract every feature screen renders against.
class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this._orders) : super(const OrdersLoading()) {
    _subscribe();
  }

  final OrderRepository _orders;

  bool _failed = false;
  StreamSubscription<List<Order>>? _sub;

  void _subscribe() {
    _sub = _orders.watchOrders().listen(
      (orders) {
        if (_failed) return; // sticky error, as in the other feature cubits
        emit(OrdersLoaded(orders));
      },
      onError: (Object error) {
        _failed = true;
        emit(const OrdersError('Could not load your orders'));
      },
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
