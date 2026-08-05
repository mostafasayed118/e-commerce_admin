import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/product.dart';
import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/daos/product_dao.dart';
import 'package:shop_admin/data/database/mappers/product_mapper.dart';
import 'package:shop_admin/data/repositories/product_repository_impl.dart';
import 'package:shop_admin/domain/repositories/product_repository.dart';

void main() {
  late AppDatabase db;
  late ProductRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ProductRepositoryImpl(ProductDao(db), ProductMapper());
  });

  tearDown(() => db.close());

  Future<int> insertCategory(String name) => db.into(db.categories).insert(
        CategoriesCompanion.insert(name: name, createdAt: 1),
      );

  Future<int> insertProduct(
    int categoryId,
    String name, {
    int priceCents = 1000,
  }) {
    return db.into(db.products).insert(ProductsCompanion.insert(
          categoryId: categoryId,
          name: name,
          priceCents: priceCents,
          discountPercent: 0,
          stock: 5,
          createdAt: 1,
          updatedAt: 1,
        ));
  }

  test('watchProducts emits the initial list and re-emits on changes', () async {
    final categoryId = await insertCategory('Clothing');
    await insertProduct(categoryId, 'Beanie');

    final done = expectLater(
      repo.watchProducts(),
      emitsInOrder([hasLength(1), hasLength(2)]),
    );

    await pumpEventQueue();
    await insertProduct(categoryId, 'T-Shirt');

    await done;
  });

  test('getById returns the mapped entity with DateTime timestamps', () async {
    final categoryId = await insertCategory('Clothing');
    final productId = await insertProduct(categoryId, 'T-Shirt', priceCents: 2000);

    final result = await repo.getById(productId);

    final product = result.getOrThrow();
    expect(product.id, productId);
    expect(product.name, 'T-Shirt');
    expect(product.priceCents, 2000);
    expect(product.createdAt, isNotNull);
    expect(product.updatedAt, isNotNull);
  });

  test('getById yields NotFoundError for a missing product', () async {
    final result = await repo.getById(999);
    expect(result, isA<Failure<Product>>());
    expect((result as Failure<Product>).error, isA<NotFoundError>());
  });

  test('createProduct persists and returns the entity with id and timestamps', () async {
    final categoryId = await insertCategory('Clothing');
    const draft = Product(id: 0, categoryId: 0, name: 'New', priceCents: 500);

    final result = await repo.createProduct(draft.copyWith(categoryId: categoryId));

    final created = result.getOrThrow();
    expect(created.id, greaterThan(0));
    expect(created.categoryId, categoryId);
    expect(created.createdAt, isNotNull);
    expect(created.updatedAt, isNotNull);

    final loaded = await repo.getById(created.id);
    expect(loaded.getOrThrow().name, 'New');
  });

  test('updateProduct persists changes and bumps updatedAt', () async {
    final categoryId = await insertCategory('Clothing');
    final productId = await insertProduct(categoryId, 'Old');

    final before = (await repo.getById(productId)).getOrThrow();
    final result = await repo.updateProduct(
      before.copyWith(name: 'New', priceCents: 9999),
    );

    final updated = result.getOrThrow();
    expect(updated.name, 'New');
    expect(updated.priceCents, 9999);
    expect(updated.updatedAt!.isAfter(before.updatedAt!), isTrue);

    final loaded = (await repo.getById(productId)).getOrThrow();
    expect(loaded.name, 'New');
    expect(loaded.priceCents, 9999);
  });

  test('updateProduct yields NotFoundError for a missing product', () async {
    const ghost = Product(id: 999, categoryId: 1, name: 'X', priceCents: 100);
    final result = await repo.updateProduct(ghost);
    expect(result, isA<Failure<Product>>());
    expect((result as Failure<Product>).error, isA<NotFoundError>());
  });

  test('deleteProduct removes the row and yields NotFoundError on retry', () async {
    final categoryId = await insertCategory('Clothing');
    final productId = await insertProduct(categoryId, 'Doomed');

    expect((await repo.deleteProduct(productId)), isA<Success<void>>());
    final after = await repo.getById(productId);
    expect(after, isA<Failure<Product>>());
    expect((after as Failure<Product>).error, isA<NotFoundError>());

    final again = await repo.deleteProduct(productId);
    expect((again as Failure<void>).error, isA<NotFoundError>());
  });

  test('watchProductById emits the product, then null after deletion', () async {
    final categoryId = await insertCategory('Clothing');
    final productId = await insertProduct(categoryId, 'Watched');

    final done = expectLater(
      repo.watchProductById(productId),
      emitsInOrder([isNotNull, isNull]),
    );

    await pumpEventQueue();
    await repo.deleteProduct(productId);

    await done;
  });
}
