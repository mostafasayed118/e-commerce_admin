import 'package:equatable/equatable.dart';

import '../../../core/entities/order.dart';

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
