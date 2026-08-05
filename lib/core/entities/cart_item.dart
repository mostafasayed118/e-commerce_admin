import 'package:equatable/equatable.dart';

/// A product quantity in the cart: one row per product, keyed by [productId].
///
/// Product details are joined in the data/presentation layers — this entity
/// only carries identity + quantity so it stays a thin value object.
class CartItem extends Equatable {
  const CartItem({
    required this.productId,
    required this.quantity,
    this.addedAt,
  });

  final int productId;

  /// Always >= 1; the upper bound is enforced by the AddToCart /
  /// UpdateCartQuantity use cases against the product's stock.
  final int quantity;
  final DateTime? addedAt;

  CartItem copyWith({int? quantity, DateTime? addedAt}) {
    return CartItem(
      productId: productId,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  List<Object?> get props => [productId, quantity, addedAt];
}
