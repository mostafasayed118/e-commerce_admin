import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'wishlist_dao.g.dart';

/// Data access for wishlist rows (one row per saved product, keyed by product
/// id). Raw primitives only — toggle semantics live in the use case.
@DriftAccessor(tables: [WishlistItems])
class WishlistDao extends DatabaseAccessor<AppDatabase>
    with _$WishlistDaoMixin {
  WishlistDao(super.attachedDatabase);

  /// Reactive wishlist contents in save order.
  Stream<List<WishlistItemRow>> watchAll() {
    return (select(wishlistItems)
          ..orderBy([(t) => OrderingTerm.asc(t.addedAt)]))
        .watch();
  }

  Future<WishlistItemRow?> getById(int productId) {
    return (select(wishlistItems)
          ..where((t) => t.productId.equals(productId)))
        .getSingleOrNull();
  }

  /// Stamps a new row; throws on an existing productId (the ToggleWishlist
  /// use case checks membership first — this insert is the storage gate).
  Future<void> insert(WishlistItemsCompanion companion) =>
      into(wishlistItems).insert(companion);

  Future<void> deleteById(int productId) {
    return (delete(wishlistItems)
          ..where((t) => t.productId.equals(productId)))
        .go();
  }
}
