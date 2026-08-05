import 'package:equatable/equatable.dart';

import '../utils/money.dart';

/// A single line of an order. Name, unit price and discount are **snapshots**
/// captured at purchase time so order history survives product edits and
/// deletions (the product FK is SET NULL on delete — Decision E).
class OrderItem extends Equatable {
  const OrderItem({
    this.id,
    required this.orderId,
    this.productId,
    required this.productName,
    required this.unitPriceCents,
    this.discountPercent = 0,
    required this.quantity,
  });

  final int? id;
  final int orderId;

  /// `null` once the referenced product has been deleted.
  final int? productId;

  /// Snapshot of the product name at purchase time.
  final String productName;

  /// Snapshot of the unit price in cents.
  final int unitPriceCents;

  /// Snapshot of the discount applied to this item.
  final int discountPercent;
  final int quantity;

  /// Paid price per unit after discount (integer math).
  int get unitFinalPriceCents =>
      discountedPriceCents(unitPriceCents, discountPercent);

  /// Total for this line: quantity x paid unit price.
  int get lineTotalCents => unitFinalPriceCents * quantity;

  @override
  List<Object?> get props =>
      [id, orderId, productId, productName, unitPriceCents, discountPercent, quantity];
}
