import 'package:equatable/equatable.dart';

import '../../../../core/entities/order.dart';
import '../../../../core/entities/order_status.dart';

/// Sealed admin-orders states.
sealed class AdminOrdersState extends Equatable {
  const AdminOrdersState();

  @override
  List<Object?> get props => [];
}

final class AdminOrdersLoading extends AdminOrdersState {
  const AdminOrdersLoading();
}

final class AdminOrdersError extends AdminOrdersState {
  const AdminOrdersError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// All orders plus the active status filter; [visibleOrders] is derived.
final class AdminOrdersLoaded extends AdminOrdersState {
  const AdminOrdersLoaded({
    required this.allOrders,
    required this.filter,
    required this.visibleOrders,
  });

  final List<Order> allOrders;

  /// `null` = no filter (all statuses).
  final OrderStatus? filter;
  final List<Order> visibleOrders;

  @override
  List<Object?> get props => [allOrders, filter, visibleOrders];
}
