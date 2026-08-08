import 'dart:async';

import '../../core/entities/cart_item.dart';
import '../../core/error/result.dart';

/// Read/write access to the cart (persisted in drift, one row per product).
///
/// The repository is deliberately *dumb*: stock caps and increment math live
/// in the AddToCart/UpdateCartQuantity use cases (Decision A), which read
/// current quantity + stock and call [setQuantity] with the target amount.
///
/// NOTE: setQuantity is a read-modify-write upsert (chosen over
/// `insertOnConflictUpdate` because the latter would clobber addedAt). It is
/// not atomic, which is fine for this single-user local app (one writer, drift
/// serializes writes); Task 10's AddToCart must funnel through this same
/// method rather than re-implementing its own upsert.
abstract interface class CartRepository {
  /// Reactive cart contents in addition order.
  Stream<List<CartItem>> watchCart();

  /// Inserts a new row or updates an existing one's quantity.
  ///
  /// [quantity] must be >= 1 ([ValidationError] otherwise; the DB CHECK is
  /// the backstop). On insert the row is stamped; on update [CartItem.addedAt]
  /// is preserved so items keep their original position in the cart.
  Future<Result<void>> setQuantity(int productId, int quantity);

  /// Removes the item. Idempotent: removing an already-absent row is
  /// Success — the end state (item absent) is what matters, unlike a read.
  Future<Result<void>> removeItem(int productId);

  /// Empties the cart.
  Future<Result<void>> clear();
}

/// The current quantity of [productId] in [cart] (0 when absent — one row
/// per product). Shared by the quantity-changing use cases ([AddToCart],
/// [UpdateCartQuantity]) so the read-current-then-write shape lives in one
/// place instead of two near-identical folds.
Future<int> currentCartQuantity(CartRepository cart, int productId) async {
  final items = await cart.watchCart().first;
  var quantity = 0;
  for (final item in items) {
    if (item.productId == productId) {
      quantity += item.quantity;
    }
  }
  return quantity;
}
