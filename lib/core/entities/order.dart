import 'package:equatable/equatable.dart';

import 'order_item.dart';
import 'order_status.dart';
import 'shipping_info.dart';

/// A single step in an order's status timeline, timestamped at write time.
class OrderStatusEntry extends Equatable {
  const OrderStatusEntry({required this.status, required this.changedAt});

  final OrderStatus status;
  final DateTime changedAt;

  @override
  List<Object?> get props => [status, changedAt];
}

/// A placed order with snapshot pricing. Totals are captured at purchase time
/// and never recomputed from current product prices (Decision E).
///
/// Deliberately no `copyWith`: after creation the only change is the status,
/// and the UI re-reads from the reactive drift stream (stream-authoritative
/// — the concurrency strategy from the plan).
///
/// The list fields ([items], [statusHistory]) should be treated as immutable:
/// callers own them and must not mutate them after construction.
class Order extends Equatable {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotalCents,
    required this.discountCents,
    required this.totalCents,
    required this.shipping,
    this.items = const [],
    this.statusHistory = const [],
    this.couponCode,
    this.couponDiscountCents = 0,
    this.createdAt,
    this.updatedAt,
  });

  final int id;

  /// Stable human-readable identifier (e.g. `ORD-000001`), generated once at
  /// purchase and never reused. Rendered **canonically in every locale** — the
  /// digits stay Western even in Arabic mode, the same treatment coupon codes
  /// get (identifiers stay stable so they can be quoted back verbatim); only
  /// the UI's *display* helpers convert it if ever needed.
  final String orderNumber;
  final OrderStatus status;

  /// Sum of all line items at undiscounted prices, snapshot at purchase.
  final int subtotalCents;

  /// Total discount applied, snapshot at purchase: line savings + any coupon.
  final int discountCents;

  /// Snapshot of the applied promo code, if any (the receipt shows it).
  final String? couponCode;

  /// The coupon's contribution to [discountCents]; 0 when no coupon.
  final int couponDiscountCents;

  /// Line-item (product) savings only — what the receipt's "Savings" row
  /// shows, so the coupon is itemized separately.
  int get lineDiscountCents => discountCents - couponDiscountCents;

  /// What the customer actually pays: subtotal - discount.
  final int totalCents;
  final ShippingInfo shipping;
  final List<OrderItem> items;

  /// Chronological status timeline, oldest first.
  final List<OrderStatusEntry> statusHistory;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        status,
        subtotalCents,
        discountCents,
        totalCents,
        shipping,
        items,
        statusHistory,
        couponCode,
        couponDiscountCents,
        createdAt,
        updatedAt,
      ];
}
