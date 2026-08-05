import '../../../core/entities/order.dart';
import '../../../core/entities/order_item.dart';
import '../../../core/entities/shipping_info.dart';
// Row classes are generated in app_database.g.dart (part of app_database.dart).
import '../app_database.dart';

/// Assembles the [Order] aggregate (order row + lines + status history).
/// Mapping belongs in the data layer (Section C.1) — entities never see
/// drift types.
///
/// Writes go through companions built in the repository, so there is no
/// entity -> row mapping here (same decision as ProductMapper).
class OrderMapper {
  Order toEntity({
    required OrderRow order,
    required List<OrderItemRow> items,
    required List<OrderStatusHistoryRow> history,
  }) {
    return Order(
      id: order.id,
      orderNumber: order.orderNumber,
      status: order.status,
      subtotalCents: order.subtotalCents,
      discountCents: order.discountCents,
      totalCents: order.totalCents,
      shipping: ShippingInfo(
        name: order.shippingName,
        phone: order.shippingPhone,
        address: order.shippingAddress,
      ),
      items: items.map(_itemToEntity).toList(growable: false),
      statusHistory: [
        for (final entry in history)
          OrderStatusEntry(
            status: entry.status,
            changedAt: DateTime.fromMillisecondsSinceEpoch(entry.changedAt),
          ),
      ],
      createdAt: DateTime.fromMillisecondsSinceEpoch(order.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(order.updatedAt),
    );
  }

  OrderItem _itemToEntity(OrderItemRow row) => OrderItem(
        id: row.id,
        orderId: row.orderId,
        productId: row.productId,
        productName: row.productName,
        unitPriceCents: row.unitPriceCents,
        discountPercent: row.discountPercent,
        quantity: row.quantity,
      );
}
