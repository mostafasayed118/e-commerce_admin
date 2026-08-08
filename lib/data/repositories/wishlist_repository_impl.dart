import 'package:drift/drift.dart';

import '../../core/entities/wishlist_item.dart';
import '../../core/error/result.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../database/app_database.dart';
import '../database/daos/wishlist_dao.dart';
import '../guarded_result.dart';

/// drift-backed [WishlistRepository].
class WishlistRepositoryImpl implements WishlistRepository {
  WishlistRepositoryImpl(this._dao);

  final WishlistDao _dao;

  @override
  Stream<List<WishlistItem>> watchWishlist() => _dao.watchAll().map(
        (rows) => rows
            .map((r) => WishlistItem(
                  productId: r.productId,
                  addedAt: DateTime.fromMillisecondsSinceEpoch(r.addedAt),
                ))
            .toList(),
      );

  @override
  Future<Result<void>> add(int productId) => guardedResult(
        () async {
          await _dao.insert(WishlistItemsCompanion.insert(
            // productId is the (non-autoIncrement) primary key, hence Value().
            productId: Value(productId),
            addedAt: DateTime.now().millisecondsSinceEpoch,
          ));
          return const Success<void>(null);
        },
        message: 'Could not save to wishlist',
      );

  @override
  Future<Result<void>> remove(int productId) => guardedResult(
        () async {
          await _dao.deleteById(productId);
          return const Success<void>(null);
        },
        message: 'Could not remove from wishlist',
      );
}
