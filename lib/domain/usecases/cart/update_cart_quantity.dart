import '../../../core/entities/product.dart';
import '../../../core/error/app_error.dart';
import '../../../core/error/result.dart';
import '../../repositories/cart_repository.dart';
import '../../repositories/product_repository.dart';

/// Sets the cart quantity of a product to the absolute target [quantity]
/// (the cart-screen stepper's operation), enforcing the stock cap.
///
/// **Reductions always pass; only raises beyond stock are rejected.** When
/// stock has dropped below the cart's current quantity (an admin cut it), the
/// user must be able to step the quantity *down* toward compliance — blocking
/// a reduction would trap them above the cap with removal as the only way
/// out. So the validation is: reject when [quantity] exceeds stock *and* is a
/// raise over the current quantity. Same reject-don't-clamp philosophy as
/// [AddToCart] for the raise direction.
class UpdateCartQuantity {
  UpdateCartQuantity(this._cart, this._products);

  final CartRepository _cart;
  final ProductRepository _products;

  Future<Result<void>> call(int productId, int quantity) async {
    if (quantity < 1) {
      return const Failure(
        ValidationError(message: 'Quantity must be at least 1'),
      );
    }
    return (await _products.getById(productId)).fold(
      onSuccess: (product) => _set(product, quantity),
      onFailure: (error) => Failure(error),
    );
  }

  Future<Result<void>> _set(Product product, int quantity) async {
    // Current quantity in the cart (0 when absent) — needed to distinguish a
    // raise from a reduction.
    final items = await _cart.watchCart().first;
    final current = items
        .where((item) => item.productId == product.id)
        .fold(0, (sum, item) => sum + item.quantity);

    if (quantity > current && quantity > product.stock) {
      return Failure(ValidationError(
        message: 'Only ${product.stock} left in stock for ${product.name}',
      ));
    }
    return _cart.setQuantity(product.id, quantity);
  }
}
