import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/daos/wishlist_dao.dart';
import 'package:shop_admin/data/repositories/wishlist_repository_impl.dart';
import 'package:shop_admin/domain/repositories/wishlist_repository.dart';

void main() {
  late AppDatabase db;
  late WishlistRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WishlistRepositoryImpl(WishlistDao(db));
  });

  tearDown(() => db.close());

  Future<int> insertCategory(String name) => db.into(db.categories).insert(
        CategoriesCompanion.insert(name: name, createdAt: 1),
      );

  Future<int> insertProduct(int categoryId, String name) {
    return db.into(db.products).insert(ProductsCompanion.insert(
          categoryId: categoryId,
          name: name,
          priceCents: 1000,
          discountPercent: 0,
          stock: 10,
          createdAt: 1,
          updatedAt: 1,
        ));
  }

  test('add saves a new row', () async {
    final categoryId = await insertCategory('Clothing');
    final productId = await insertProduct(categoryId, 'T-Shirt');

    final result = await repo.add(productId);

    expect(result, isA<Success<void>>());
    final item = (await repo.watchWishlist().first).single;
    expect(item.productId, productId);
    expect(item.addedAt, isNotNull);
  });

  test('add is rejected for an already-saved product (duplicate key)',
      () async {
    final categoryId = await insertCategory('Clothing');
    final productId = await insertProduct(categoryId, 'T-Shirt');
    await repo.add(productId);

    final result = await repo.add(productId);

    expect(result, isA<Failure<void>>());
    expect((result as Failure<void>).error, isA<DatabaseError>());
    expect(await repo.watchWishlist().first, hasLength(1),
        reason: 'the duplicate add must not create a second row');
  });

  test('remove deletes the row and is idempotent for absent items', () async {
    final categoryId = await insertCategory('Clothing');
    final productId = await insertProduct(categoryId, 'T-Shirt');
    await repo.add(productId);

    expect(await repo.remove(productId), isA<Success<void>>());
    expect(await repo.watchWishlist().first, isEmpty);

    // Removing an already-absent item is still Success (end state matters).
    expect(await repo.remove(productId), isA<Success<void>>());
  });

  test('watchWishlist emits the initial list and re-emits on changes',
      () async {
    final categoryId = await insertCategory('Clothing');
    final a = await insertProduct(categoryId, 'A');
    final b = await insertProduct(categoryId, 'B');
    await repo.add(a);

    final done = expectLater(
      repo.watchWishlist(),
      emitsInOrder([hasLength(1), hasLength(2)]),
    );

    await pumpEventQueue();
    await repo.add(b);

    await done;
  });

  test('deleting a product cascades its wishlist row away (through the stream)',
      () async {
    final categoryId = await insertCategory('Clothing');
    final a = await insertProduct(categoryId, 'A');
    final b = await insertProduct(categoryId, 'B');
    await repo.add(a);
    await repo.add(b);

    final done = expectLater(
      repo.watchWishlist(),
      emitsInOrder([hasLength(2), hasLength(1)]),
    );

    await pumpEventQueue();
    await (db.delete(db.products)..where((t) => t.id.equals(a))).go();

    await done;
    final remaining = (await repo.watchWishlist().first).single;
    expect(remaining.productId, b);
  });

  test('add on a non-existent product yields DatabaseError (FK enforced)',
      () async {
    final result = await repo.add(999);

    expect(result, isA<Failure<void>>());
    expect((result as Failure<void>).error, isA<DatabaseError>());
  });
}
