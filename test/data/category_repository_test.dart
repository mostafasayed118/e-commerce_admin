import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/category.dart';
import 'package:shop_admin/core/error/app_error.dart';
import 'package:shop_admin/core/error/result.dart';
import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/daos/category_dao.dart';
import 'package:shop_admin/data/database/mappers/category_mapper.dart';
import 'package:shop_admin/data/repositories/category_repository_impl.dart';
import 'package:shop_admin/domain/repositories/category_repository.dart';

void main() {
  late AppDatabase db;
  late CategoryRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CategoryRepositoryImpl(CategoryDao(db), CategoryMapper());
  });

  tearDown(() => db.close());

  test('watchCategories is ordered by name', () async {
    await db.into(db.categories).insert(CategoriesCompanion.insert(name: 'Books', createdAt: 1));
    await db.into(db.categories).insert(CategoriesCompanion.insert(name: 'Clothing', createdAt: 1));
    await db.into(db.categories).insert(CategoriesCompanion.insert(name: 'Electronics', createdAt: 1));

    final categories = await repo.watchCategories().first;

    expect(categories.map((c) => c.name).toList(), ['Books', 'Clothing', 'Electronics']);
  });

  test('createCategory returns the entity with a generated id', () async {
    const draft = Category(id: 0, name: 'Sports');

    final result = await repo.createCategory(draft);

    final created = result.getOrThrow();
    expect(created.id, greaterThan(0));
    expect(created.name, 'Sports');
    expect(created.createdAt, isNotNull);

    final loaded = (await repo.getById(created.id)).getOrThrow();
    expect(loaded.name, 'Sports');
  });

  test('updateCategory persists the new name', () async {
    final created = (await repo.createCategory(const Category(id: 0, name: 'Old'))).getOrThrow();

    final result = await repo.updateCategory(created.copyWith(name: 'New'));

    expect(result.getOrThrow().name, 'New');
    final loaded = (await repo.getById(created.id)).getOrThrow();
    expect(loaded.name, 'New');
  });

  test('updateCategory yields NotFoundError for a missing category', () async {
    const ghost = Category(id: 999, name: 'X');
    final result = await repo.updateCategory(ghost);
    expect((result as Failure<Category>).error, isA<NotFoundError>());
  });

  test('deleteCategory succeeds for an empty category', () async {
    final created = (await repo.createCategory(const Category(id: 0, name: 'Empty'))).getOrThrow();

    final result = await repo.deleteCategory(created.id);

    expect(result, isA<Success<void>>());
    expect((await repo.getById(created.id)), isA<Failure<Category>>());
  });

  test('deleteCategory is blocked while products reference it', () async {
    final created = (await repo.createCategory(const Category(id: 0, name: 'Clothing'))).getOrThrow();
    await db.into(db.products).insert(ProductsCompanion.insert(
          categoryId: created.id,
          name: 'T-Shirt',
          priceCents: 1000,
          discountPercent: 0,
          stock: 5,
          createdAt: 1,
          updatedAt: 1,
        ));

    final result = await repo.deleteCategory(created.id);

    expect(result, isA<Failure<void>>());
    final error = (result as Failure<void>).error;
    expect(error, isA<ValidationError>());
    expect(error.message, contains('delete them first'));
  });

  test('deleteCategory yields NotFoundError for a missing category', () async {
    final result = await repo.deleteCategory(999);
    expect((result as Failure<void>).error, isA<NotFoundError>());
  });
}
