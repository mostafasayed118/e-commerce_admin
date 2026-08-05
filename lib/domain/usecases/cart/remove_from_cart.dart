import '../../../core/error/result.dart';
import '../../repositories/cart_repository.dart';

/// Removes a product from the cart.
///
/// Deliberately thin: the repository's `removeItem` already owns the
/// idempotent semantics (removing an absent item is Success — the end state
/// is what matters). This use case exists so the cart feature exposes a
/// uniform four-operation API to its Cubit (Task 15) and never reaches into
/// the repository directly. If a rule ever needs to gate removal, it lands
/// here.
class RemoveFromCart {
  RemoveFromCart(this._cart);

  final CartRepository _cart;

  Future<Result<void>> call(int productId) => _cart.removeItem(productId);
}
