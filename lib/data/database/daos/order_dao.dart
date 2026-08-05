import 'package:drift/drift.dart';

import '../../../core/entities/order_status.dart';
import '../app_database.dart';
import '../tables.dart';

part 'order_dao.g.dart';

/// Data access for orders and their aggregates (lines + status history).
/// Raw primitives only — aggregate assembly, totals and business rules live
/// in the repository.
@DriftAccessor(tables: [Orders, OrderItems, OrderStatusHistory])
class OrderDao extends DatabaseAccessor<AppDatabase> with _$OrderDaoMixin {
  OrderDao(super.attachedDatabase);

  /// Reactive orders, newest first.
  Stream<List<OrderRow>> watchAll() {
    return (select(orders)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Reactive single order; emits `null` when it is missing or deleted.
  Stream<OrderRow?> watchById(int id) {
    return (select(orders)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<OrderRow?> getById(int id) {
    return (select(orders)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// All lines for one order, in insertion order.
  Future<List<OrderItemRow>> getItemsForOrder(int orderId) {
    return (select(orderItems)..where((t) => t.orderId.equals(orderId))).get();
  }

  /// Status timeline for one order, chronological (oldest first).
  Future<List<OrderStatusHistoryRow>> getHistoryForOrder(int orderId) {
    return (select(orderStatusHistory)
          ..where((t) => t.orderId.equals(orderId))
          ..orderBy([(t) => OrderingTerm.asc(t.changedAt)]))
        .get();
  }

  /// Returns the new row id.
  Future<int> insertOrder(OrdersCompanion companion) =>
      into(orders).insert(companion);

  Future<void> insertOrderItem(OrderItemsCompanion companion) =>
      into(orderItems).insert(companion);

  Future<void> insertHistoryEntry(OrderStatusHistoryCompanion companion) =>
      into(orderStatusHistory).insert(companion);

  /// Updates status + updatedAt in one write; returns affected rows.
  Future<int> updateStatusById(int id, OrderStatus status, int updatedAtMs) {
    return (update(orders)..where((t) => t.id.equals(id))).write(
          OrdersCompanion(status: Value(status), updatedAt: Value(updatedAtMs)),
        );
  }

  /// Highest order row id, or `null` on an empty table — used to mint
  /// sequential order numbers (ORD-00000N) inside placeOrder's transaction.
  Future<int?> maxOrderId() async {
    final query = selectOnly(orders)..addColumns([orders.id.max()]);
    final row = await query.getSingle();
    return row.read(orders.id.max());
  }
}
