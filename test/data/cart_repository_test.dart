import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/daos/cart_dao.dart';
import 'package:shop_admin/data/repositories/cart_repository_impl.dart';
import 'package:shop_admin/domain/repositories/cart_repository.dart';

void main() {
  late AppDatabase db;
  late CartRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CartRepositoryImpl(CartDao(db));
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

  test('setQuantity inserts a new row', () async {
    final categoryId = await insertCategory('Clothing');
    final productId = await insertProduct(categoryId, 'T-Shirt');

    final result = await repo.setQuantity(productId, 2);

    expect(result, isA<Success<void>>());
    final item = (await repo.watchCart().first).single;
    expect(item.productId, productId);
    expect(item.quantity, 2);
    expect(item.addedAt, isNotNull);
  });

  test('setQuantity updates an existing row and preserves addedAt', () async {
    final categoryId = await insertCategory('Clothing');
    final productId = await insertProduct(categoryId, 'T-Shirt');
    await repo.setQuantity(productId, 2);
    final firstAddedAt = (await repo.watchCart().first).single.addedAt;

    await repo.setQuantity(productId, 7);

    final updated = (await repo.watchCart().first).single;
    expect(updated.quantity, 7);
    expect(updated.addedAt, firstAddedAt,
        reason: 'quantity changes must keep the original cart position');
    expect(await repo.watchCart().first, hasLength(1),
        reason: 'updating must not duplicate the row');
  });

  test('setQuantity rejects quantities below 1', () async {
    final result = await repo.setQuantity(1, 0);
    expect(result, isA<Failure<void>>());
    expect((result as Failure<void>).error, isA<ValidationError>());
  });

  test('removeItem removes the row and is idempotent for absent items', () async {
    final categoryId = await insertCategory('Clothing');
    final productId = await insertProduct(categoryId, 'T-Shirt');
    await repo.setQuantity(productId, 1);

    expect(await repo.removeItem(productId), isA<Success<void>>());
    expect(await repo.watchCart().first, isEmpty);

    // Removing an already-absent item is still Success (end state matters).
    expect(await repo.removeItem(productId), isA<Success<void>>());
  });

  test('clear empties the cart', () async {
    final categoryId = await insertCategory('Clothing');
    for (final name in ['A', 'B', 'C']) {
      await repo.setQuantity(await insertProduct(categoryId, name), 1);
    }
    expect(await repo.watchCart().first, hasLength(3));

    expect(await repo.clear(), isA<Success<void>>());
    expect(await repo.watchCart().first, isEmpty);
  });

  test('watchCart emits the initial list and re-emits on changes', () async {
    final categoryId = await insertCategory('Clothing');
    final a = await insertProduct(categoryId, 'A');
    final b = await insertProduct(categoryId, 'B');
    await repo.setQuantity(a, 1);

    final done = expectLater(
      repo.watchCart(),
      emitsInOrder([hasLength(1), hasLength(2)]),
    );

    await pumpEventQueue();
    await repo.setQuantity(b, 3);

    await done;
  });

  test('deleting a product cascades its cart row away (through the stream)',
      () async {
    final categoryId = await insertCategory('Clothing');
    final a = await insertProduct(categoryId, 'A');
    final b = await insertProduct(categoryId, 'B');
    await repo.setQuantity(a, 1);
    await repo.setQuantity(b, 2);

    final done = expectLater(
      repo.watchCart(),
      emitsInOrder([hasLength(2), hasLength(1)]),
    );

    await pumpEventQueue();
    await (db.delete(db.products)..where((t) => t.id.equals(a))).go();

    await done;
    final remaining = (await repo.watchCart().first).single;
    expect(remaining.productId, b);
    expect(remaining.quantity, 2);
  });

  test('setQuantity on a non-existent product yields DatabaseError', () async {
    final result = await repo.setQuantity(999, 1);
    expect(result, isA<Failure<void>>());
    expect((result as Failure<void>).error, isA<DatabaseError>());
  });
}
