import 'package:drift/drift.dart';

import '../../core/entities/cart_item.dart';
import '../../core/error/app_error.dart';
import '../../core/error/result.dart';
import '../../domain/repositories/cart_repository.dart';
import '../database/app_database.dart';
import '../database/daos/cart_dao.dart';

/// drift-backed [CartRepository].
class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._dao);

  final CartDao _dao;

  @override
  Stream<List<CartItem>> watchCart() => _dao.watchAll().map(
        (rows) => rows
            .map((r) => CartItem(
                  productId: r.productId,
                  quantity: r.quantity,
                  addedAt: DateTime.fromMillisecondsSinceEpoch(r.addedAt),
                ))
            .toList(),
      );

  @override
  Future<Result<void>> setQuantity(int productId, int quantity) async {
    if (quantity < 1) {
      return const Failure(
        ValidationError(message: 'Quantity must be at least 1'),
      );
    }
    try {
      // Read-modify-write upsert: preserves addedAt on quantity changes so
      // items keep their original position in the cart.
      final existing = await _dao.getById(productId);
      if (existing == null) {
        await _dao.insert(CartItemsCompanion.insert(
          // productId is the (non-autoIncrement) primary key, hence Value().
          productId: Value(productId),
          quantity: quantity,
          addedAt: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        await _dao.updateQuantityById(productId, quantity);
      }
      return const Success<void>(null);
    } on Exception catch (error) {
      return Failure(
        DatabaseError(message: 'Could not update cart', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> removeItem(int productId) async {
    try {
      await _dao.deleteById(productId);
      return const Success<void>(null);
    } on Exception catch (error) {
      return Failure(
        DatabaseError(message: 'Could not remove item from cart', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> clear() async {
    try {
      await _dao.deleteAll();
      return const Success<void>(null);
    } on Exception catch (error) {
      return Failure(
        DatabaseError(message: 'Could not clear cart', cause: error),
      );
    }
  }
}
