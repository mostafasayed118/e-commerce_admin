import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'cart_dao.g.dart';

/// Data access for cart rows (one row per product, keyed by product id).
/// Raw primitives only — upsert semantics live in the repository.
@DriftAccessor(tables: [CartItems])
class CartDao extends DatabaseAccessor<AppDatabase> with _$CartDaoMixin {
  CartDao(super.attachedDatabase);

  /// Reactive cart contents in addition order.
  Stream<List<CartItemRow>> watchAll() {
    return (select(cartItems)..orderBy([(t) => OrderingTerm.asc(t.addedAt)]))
        .watch();
  }

  Future<CartItemRow?> getById(int productId) {
    return (select(cartItems)..where((t) => t.productId.equals(productId)))
        .getSingleOrNull();
  }

  /// Stamps a new row; throws on an existing productId (callers upsert
  /// read-modify-write instead).
  Future<void> insert(CartItemsCompanion companion) =>
      into(cartItems).insert(companion);

  /// Updates only the quantity, leaving [CartItemRow.addedAt] untouched.
  Future<void> updateQuantityById(int productId, int quantity) {
    return (update(cartItems)..where((t) => t.productId.equals(productId)))
        .write(CartItemsCompanion(quantity: Value(quantity)));
  }

  Future<void> deleteById(int productId) {
    return (delete(cartItems)..where((t) => t.productId.equals(productId)))
        .go();
  }

  Future<void> deleteAll() => delete(cartItems).go();
}
