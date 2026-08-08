import '../../../core/entities/product.dart';
import '../../../core/error/app_error.dart';
import '../../../core/error/result.dart';
import '../../repositories/cart_repository.dart';
import '../../repositories/product_repository.dart';

/// Adds [quantity] (default 1) of a product to the cart, enforcing the stock
/// cap (Decision A — business rules live in use cases, never in the
/// repository, which stays a dumb storage gate).
///
/// Incremental: reads the current cart quantity and computes the target as
/// `current + quantity`, then funnels through [CartRepository.setQuantity].
///
/// **Reject, don't clamp.** If the target would exceed stock, this returns a
/// [ValidationError] with the remaining count — never a silent clamp that
/// makes the cart lie about what the user asked for. An explicit error
/// surfaces the stock reality at the point of action and composes with
/// `OrderRepository.placeOrder`'s own re-validation at checkout.
class AddToCart {
  AddToCart(this._cart, this._products);

  final CartRepository _cart;
  final ProductRepository _products;

  Future<Result<void>> call(int productId, {int quantity = 1}) async {
    if (quantity < 1) {
      return const Failure(
        ValidationError(
          code: AppErrorCode.quantityMin,
          message: 'Quantity must be at least 1',
        ),
      );
    }
    return (await _products.getById(productId)).flatMapAsync(
      (product) => _add(product, quantity),
    );
  }

  Future<Result<void>> _add(Product product, int quantity) async {
    if (product.isOutOfStock) {
      return Failure(ProductOutOfStockError(
        productName: product.name,
        message: '${product.name} is out of stock',
      ));
    }

    // Current quantity in the cart (0 when absent — one row per product).
    final current = await currentCartQuantity(_cart, product.id);

    final target = current + quantity;
    if (target > product.stock) {
      final hint = current > 0 ? ' (you have $current in your cart)' : '';
      return Failure(StockLimitError(
        productName: product.name,
        stock: product.stock,
        currentInCart: current,
        message:
            'Only ${product.stock} left in stock for ${product.name}$hint',
      ));
    }

    return _cart.setQuantity(product.id, target);
  }
}
