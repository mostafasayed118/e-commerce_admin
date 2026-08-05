import '../../core/entities/order.dart';
import '../../core/entities/order_status.dart';
import '../../core/entities/shipping_info.dart';
import '../../core/error/result.dart';

/// Read/write access to orders.
///
/// One-shot operations return [Result] — errors are caught at the repository
/// boundary (Section D.4). Watch streams carry plain data and surface
/// database errors as stream errors (consistent with the catalog and cart
/// repositories).
abstract interface class OrderRepository {
  /// Reactive orders, newest first. Each emission carries the full aggregate
  /// (items + status history).
  ///
  /// NOTE: the aggregate is assembled with per-order reads on every emission
  /// (N+1). Accepted for a local single-user app with a bounded order count;
  /// revisit with joins if this ever becomes a hot path.
  Stream<List<Order>> watchOrders();

  /// Reactive single order aggregate; emits `null` when missing or deleted.
  /// Assembles items + history per emission (same N+1 tradeoff as above).
  Stream<Order?> watchOrderById(int id);

  Future<Result<Order>> getById(int id);

  /// Places an order from the current cart, **atomically**: validates stock,
  /// snapshots item names/prices and totals at purchase time (Decision E),
  /// decrements stock, clears the cart and writes the initial `pending`
  /// history entry — all in one drift transaction, so any failure rolls
  /// everything back and the cart is untouched.
  ///
  /// Errors: [ValidationError] when the cart is empty or stock is
  /// insufficient; [NotFoundError] when a cart product no longer exists;
  /// [DatabaseError] on any storage failure.
  Future<Result<Order>> placeOrder(ShippingInfo shipping);

  /// Moves the order to [newStatus] if [OrderStatus.canTransitionTo] allows
  /// it, appending a timestamped history entry in the same transaction.
  /// Same-status and illegal moves are [ValidationError]; a missing order is
  /// [NotFoundError].
  Future<Result<Order>> updateStatus(int orderId, OrderStatus newStatus);
}
