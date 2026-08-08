import '../../core/entities/wishlist_item.dart';
import '../../core/error/result.dart';

/// Read/write access to the wishlist (persisted in drift, one row per
/// product).
///
/// Deliberately *dumb* (Decision A): add/remove are plain storage operations;
/// the membership decision that turns them into a "toggle" lives in the
/// [ToggleWishlist] use case.
abstract interface class WishlistRepository {
  /// Reactive wishlist contents in save order.
  Stream<List<WishlistItem>> watchWishlist();

  /// Saves [productId] to the wishlist. Insert-only: adding a product that
  /// is already saved is a duplicate-key failure (callers should go through
  /// the ToggleWishlist use case instead of guessing membership).
  Future<Result<void>> add(int productId);

  /// Removes [productId]. Idempotent: removing an already-absent row is
  /// Success — the end state (item absent) is what matters, unlike a read.
  Future<Result<void>> remove(int productId);
}
