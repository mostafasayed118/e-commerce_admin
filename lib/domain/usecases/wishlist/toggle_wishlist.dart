import '../../../core/error/result.dart';
import '../../repositories/wishlist_repository.dart';

/// Adds [productId] when it is not saved yet, removes it when it is — the
/// wishlist's single business rule (Decision A: rules live in use cases, the
/// repository stays a dumb storage gate).
///
/// Returns whether the product is **now saved** (true = added, false =
/// removed) so callers can report the outcome without guessing from
/// potentially stale state.
class ToggleWishlist {
  ToggleWishlist(this._wishlist);

  final WishlistRepository _wishlist;

  Future<Result<bool>> call(int productId) async {
    final items = await _wishlist.watchWishlist().first;
    final wasSaved = items.any((item) => item.productId == productId);
    final result = wasSaved
        ? await _wishlist.remove(productId)
        : await _wishlist.add(productId);
    return result.map((_) => !wasSaved);
  }
}
