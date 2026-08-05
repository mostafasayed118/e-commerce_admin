import '../../../core/error/result.dart';
import '../../repositories/cart_repository.dart';

/// Empties the cart.
///
/// Thin for the same reason as [RemoveFromCart]: the repository's `clear`
/// owns the storage semantics, and the use case keeps the cart feature's
/// operation set uniform for its Cubit.
class ClearCart {
  ClearCart(this._cart);

  final CartRepository _cart;

  Future<Result<void>> call() => _cart.clear();
}
