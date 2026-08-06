import 'package:equatable/equatable.dart';

import '../../../core/entities/product.dart';

/// A cart line: the joined product + its quantity. Product details (price,
/// discount, stock, image) are *live* — read from the products watch stream
/// at every emission, so an admin's price or stock change reflects in the
/// cart immediately (only the placed order freezes a snapshot, Decision E).
class CartLine extends Equatable {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  /// Line totals at *undiscounted* prices (money is integer cents).
  int get lineSubtotalCents => product.priceCents * quantity;

  /// Amount saved by the discount on this line.
  int get lineDiscountCents => product.savingsCents * quantity;

  /// What the customer actually pays for this line.
  int get lineTotalCents => product.finalPriceCents * quantity;

  /// True when stock has dropped below what's in the cart (an admin cut it).
  /// The line is flagged in the UI and the + button disabled.
  bool get exceedsStock => product.stock < quantity;

  @override
  List<Object?> get props => [product, quantity];
}

/// Sealed cart states.
sealed class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

final class CartLoading extends CartState {
  const CartLoading();
}

final class CartError extends CartState {
  const CartError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Cart contents with derived totals. An empty [lines] list is the normal
/// fresh state — the screen renders the empty view, not an error.
final class CartLoaded extends CartState {
  const CartLoaded({
    required this.lines,
    required this.subtotalCents,
    required this.discountCents,
    required this.totalCents,
    required this.itemCount,
  });

  final List<CartLine> lines;

  /// Sum of all lines at undiscounted prices.
  final int subtotalCents;

  /// Total savings from discounts across all lines.
  final int discountCents;

  /// What the customer pays: subtotal - discount.
  final int totalCents;

  /// Total units across all lines (the shell badge shows this).
  final int itemCount;

  @override
  List<Object?> get props => [
        lines,
        subtotalCents,
        discountCents,
        totalCents,
        itemCount,
      ];
}
