import 'package:drift/drift.dart';

import '../../core/entities/cart_item.dart';
import '../../core/error/app_error.dart';
import '../../core/error/result.dart';
import '../../domain/repositories/cart_repository.dart';
import '../database/app_database.dart';
import '../database/daos/cart_dao.dart';
import '../guarded_result.dart';

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
        ValidationError(
          code: AppErrorCode.quantityMin,
          message: 'Quantity must be at least 1',
        ),
      );
    }
    // Read-modify-write upsert: preserves addedAt on quantity changes so
    // items keep their original position in the cart.
    return guardedResult(() async {
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
    }, message: 'Could not update cart');
  }

  @override
  Future<Result<void>> removeItem(int productId) => guardedResult(
        () async {
          await _dao.deleteById(productId);
          return const Success<void>(null);
        },
        message: 'Could not remove item from cart',
      );

  @override
  Future<Result<void>> clear() => guardedResult(
        () async {
          await _dao.deleteAll();
          return const Success<void>(null);
        },
        message: 'Could not clear cart',
      );
}
