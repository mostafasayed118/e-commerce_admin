// hide isNull/isNotNull — drift re-exports them and they collide with
// flutter_test's matchers (which is what these tests want).
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/data/database/app_database.dart';
import 'package:shop_admin/data/database/daos/int_id_crud_mixin.dart';

/// A minimal mixin consumer on the Categories table — deliberately NOT the
/// production CategoryDao, so the test pins the mixin's contract alone
/// (no generated `_$CategoryDaoMixin`, no repository, no mapper involved).
class _CategoryCrudDao extends DatabaseAccessor<AppDatabase>
    with IntIdCrudDaoMixin<$CategoriesTable, CategoryRow, CategoriesCompanion> {
  _CategoryCrudDao(super.attachedDatabase);

  @override
  $CategoriesTable get table => attachedDatabase.categories;

  @override
  GeneratedColumn<int> get idColumn => attachedDatabase.categories.id;
}

/// The same mixin on a *different* table — proves the generic contract is
/// table-agnostic and not accidentally Category-shaped.
class _ProductCrudDao extends DatabaseAccessor<AppDatabase>
    with IntIdCrudDaoMixin<$ProductsTable, ProductRow, ProductsCompanion> {
  _ProductCrudDao(super.attachedDatabase);

  @override
  $ProductsTable get table => attachedDatabase.products;

  @override
  GeneratedColumn<int> get idColumn => attachedDatabase.products.id;
}

void main() {
  late AppDatabase db;
  late _CategoryCrudDao categories;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    categories = _CategoryCrudDao(db);
  });

  tearDown(() => db.close());

  CategoriesCompanion newCategory(String name, {int createdAt = 1}) =>
      CategoriesCompanion.insert(name: name, createdAt: createdAt);

  test('insert returns the generated id and getById reads the row back', () async {
    final id = await categories.insert(newCategory('Books'));

    expect(id, greaterThan(0));
    final row = await categories.getById(id);
    expect(row, isNotNull);
    expect(row!.name, 'Books');
  });

  test('getById returns null for a missing id', () async {
    expect(await categories.getById(999), isNull);
  });

  test('updateById applies the change and reports one affected row', () async {
    final id = await categories.insert(newCategory('Books'));

    final affected = await categories.updateById(
      id,
      CategoriesCompanion(name: Value('Reading')),
    );

    expect(affected, 1);
    expect((await categories.getById(id))!.name, 'Reading');
  });

  test('updateById on a missing id reports zero affected rows', () async {
    final affected = await categories.updateById(
      999,
      CategoriesCompanion(name: Value('Ghost')),
    );
    expect(affected, 0);
  });

  test('deleteById removes the row and reports one affected row', () async {
    final id = await categories.insert(newCategory('Books'));

    final affected = await categories.deleteById(id);

    expect(affected, 1);
    expect(await categories.getById(id), isNull);
  });

  test('deleteById on a missing id reports zero affected rows', () async {
    expect(await categories.deleteById(999), 0);
  });

  test('the same CRUD contract works on a different table (Products)', () async {
    final products = _ProductCrudDao(db);
    // Products carries a NOT NULL FK to Categories — create the referenced
    // row first so the insert is valid.
    final categoryId = await categories.insert(newCategory('Clothing'));
    final productId = await products.insert(ProductsCompanion.insert(
      categoryId: categoryId,
      name: 'T-Shirt',
      priceCents: 1000,
      discountPercent: 0,
      stock: 5,
      createdAt: 1,
      updatedAt: 1,
    ));

    expect(productId, greaterThan(0));
    expect((await products.getById(productId))!.name, 'T-Shirt');
    expect(
      await products.updateById(
        productId,
        ProductsCompanion(name: Value('Hoodie')),
      ),
      1,
    );
    expect((await products.getById(productId))!.name, 'Hoodie');
    expect(await products.deleteById(productId), 1);
    expect(await products.getById(productId), isNull);
  });
}
