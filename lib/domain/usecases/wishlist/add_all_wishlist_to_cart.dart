import '../../../core/error/result.dart';
import '../../repositories/wishlist_repository.dart';
import 'move_wishlist_item_to_cart.dart';

/// How a bulk wishlist → cart move went: [added] items were moved
/// successfully, [skipped] could not (out of stock / at the stock cap — the
/// per-item `AddToCart` rules decide). Failed moves keep their wishlist
/// entry, exactly like the single-item move.
class AddAllWishlistResult {
  const AddAllWishlistResult({required this.added, required this.skipped});

  final int added;
  final int skipped;

  /// Every saved item made it into the cart.
  bool get allAdded => skipped == 0;

  /// Nothing could be added (everything was unavailable).
  bool get noneAdded => added == 0 && skipped > 0;
}

/// Moves every saved product into the cart by composing
/// [MoveWishlistItemToCart] over the current wishlist, in save order — so
/// each move runs the same stock-cap/out-of-stock rules and only removes the
/// wishlist entry on success (Decision A: the composition is a business
/// rule, so it lives here rather than in the screen, same as the single
/// move). Items are processed sequentially: each move reads the live cart
/// quantity, so a parallel fan-out would race on the stock cap.
class AddAllWishlistToCart {
  AddAllWishlistToCart(this._move, this._wishlist);

  final MoveWishlistItemToCart _move;
  final WishlistRepository _wishlist;

  Future<AddAllWishlistResult> call() async {
    final items = await _wishlist.watchWishlist().first;
    var added = 0;
    var skipped = 0;
    for (final item in items) {
      final result = await _move(item.productId);
      // Any failure counts as skipped — including a wishlist-removal failure
      // *after* a successful cart add (MoveWishlistItemToCart surfaces that
      // as a Failure). That rare DB fault is then reported as "unavailable"
      // even though the item landed in the cart — acceptable: it is not a
      // stock condition, and restructuring the summary for it is not worth
      // the complexity.
      result.fold(
        onSuccess: (_) => added++,
        onFailure: (_) => skipped++,
      );
    }
    return AddAllWishlistResult(added: added, skipped: skipped);
  }
}
