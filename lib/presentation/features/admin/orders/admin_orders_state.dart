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

/// All orders plus the active status/query/date-range filters; [visibleOrders]
/// is derived from them.
final class AdminOrdersLoaded extends AdminOrdersState {
  const AdminOrdersLoaded({
    required this.allOrders,
    required this.filter,
    required this.query,
    required this.fromDate,
    required this.toDate,
    required this.visibleOrders,
  });

  final List<Order> allOrders;

  /// `null` = no status filter (all statuses).
  final OrderStatus? filter;

  /// The raw text search (order number / customer name / phone); empty =
  /// no search.
  final String query;

  /// Inclusive range start (start of day); `null` = no lower bound.
  final DateTime? fromDate;

  /// Inclusive range end (end of day); `null` = no upper bound.
  final DateTime? toDate;

  final List<Order> visibleOrders;

  bool get hasActiveFilter =>
      filter != null ||
      query.trim().isNotEmpty ||
      fromDate != null ||
      toDate != null;

  @override
  List<Object?> get props =>
      [allOrders, filter, query, fromDate, toDate, visibleOrders];
}
