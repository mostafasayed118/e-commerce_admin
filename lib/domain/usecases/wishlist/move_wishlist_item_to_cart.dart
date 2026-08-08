import '../../../core/error/result.dart';
import '../../repositories/wishlist_repository.dart';
import '../cart/add_to_cart.dart';

/// Moves a saved product into the cart: runs [AddToCart] (whose stock-cap
/// and out-of-stock rules compose for free) and, **only on success**, clears
/// the saved item — "moving" implies no longer wishlisted.
///
/// The removal is skipped when the cart add fails, so a failed move leaves
/// the wishlist entry intact (Decision A: the composition is a business rule,
/// so it lives here rather than in the screen).
class MoveWishlistItemToCart {
  MoveWishlistItemToCart(this._addToCart, this._wishlist);

  final AddToCart _addToCart;
  final WishlistRepository _wishlist;

  Future<Result<void>> call(int productId) async =>
      (await _addToCart(productId)).flatMapAsync(
        (_) => _wishlist.remove(productId),
      );
}
