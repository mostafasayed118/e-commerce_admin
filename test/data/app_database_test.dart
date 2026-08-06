import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_admin/core/entities/order_status.dart';
import 'package:shop_admin/data/database/app_database.dart';

/// A database pinned to schema v1, so reopening the real (current-version)
/// database on the same file exercises the on-device upgrade path (a release
/// build on a device ships with an older schema version).
class _V1Database extends AppDatabase {
  // The implicit super constructor (AppDatabase()) takes no parameters, so
  // the executor must be forwarded explicitly — a super parameter would
  // resolve to the unnamed constructor and fail to compile.
  // ignore: use_super_parameters
  _V1Database.forTesting(QueryExecutor executor) : super.forTesting(executor);

  @override
  int get schemaVersion => 1;
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('migrates an old install: adds UiPrefs + Arabic columns, keeps data',
      () async {
    final file = File(
      '${Directory.systemTemp.path}/shop_admin_migration_'
      '${DateTime.now().millisecondsSinceEpoch}.db',
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    // 1. Write data the way an old install would (a profile row exists).
    final v1 = _V1Database.forTesting(NativeDatabase(file));
    await v1.into(v1.profile).insert(ProfileCompanion.insert(
          id: const Value(1),
          name: const Value('Legacy User'),
          phone: const Value('555-0100'),
          address: const Value('1 Old St'),
          updatedAt: Value(1),
        ));

    // The simulated old install is created from the CURRENT table
    // definitions (tables.dart is shared), so drop the v3 Arabic columns to
    // match the real v2-era shape — otherwise the upgrade's ALTER TABLE
    // would collide with columns that already exist.
    for (final statement in [
      'ALTER TABLE products DROP COLUMN name_ar;',
      'ALTER TABLE products DROP COLUMN description_ar;',
      'ALTER TABLE categories DROP COLUMN name_ar;',
      'ALTER TABLE order_items DROP COLUMN product_name_ar;',
    ]) {
      await v1.customStatement(statement);
    }
    await v1.close();

    // 2. Reopen with the real (current) schema: onUpgrade adds the UiPrefs
    // table and the Arabic columns without touching existing rows.
    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    final profile = await upgraded.select(upgraded.profile).getSingle();
    expect(profile.name, 'Legacy User'); // existing data survived

    // The new table works, and the single-row id=1 check is enforced.
    await upgraded.into(upgraded.uiPrefs).insert(UiPrefsCompanion.insert(
          id: const Value(1),
          themeMode: const Value('dark'),
        ));
    final prefs = await upgraded.select(upgraded.uiPrefs).getSingle();
    expect(prefs.themeMode, 'dark');

    // The added Arabic columns accept and return data.
    final categoryId = await upgraded.into(upgraded.categories).insert(
          CategoriesCompanion.insert(
            name: 'Clothing',
            nameAr: const Value('ملابس'),
            createdAt: 1,
          ),
        );
    await upgraded.into(upgraded.products).insert(ProductsCompanion.insert(
          categoryId: categoryId,
          name: 'T-Shirt',
          nameAr: const Value('تيشيرت'),
          priceCents: 2000,
          discountPercent: 0,
          stock: 5,
          createdAt: 1,
          updatedAt: 1,
        ));
    final product = await upgraded.select(upgraded.products).getSingle();
    expect(product.nameAr, 'تيشيرت');

    await upgraded.close();
  });

  test('opens with all ten tables empty', () async {
    expect(await db.select(db.categories).get(), isEmpty);
    expect(await db.select(db.products).get(), isEmpty);
    expect(await db.select(db.cartItems).get(), isEmpty);
    expect(await db.select(db.orders).get(), isEmpty);
    expect(await db.select(db.orderItems).get(), isEmpty);
    expect(await db.select(db.orderStatusHistory).get(), isEmpty);
    expect(await db.select(db.profile).get(), isEmpty);
    expect(await db.select(db.adminSettings).get(), isEmpty);
    expect(await db.select(db.uiPrefs).get(), isEmpty);
    expect(await db.select(db.appMeta).get(), isEmpty);
  });

  test('single-row tables reject any row other than id 1', () async {
    await expectLater(
      db.into(db.profile).insert(ProfileCompanion.insert(id: Value(2))),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      db.into(db.appMeta).insert(AppMetaCompanion.insert(id: Value(2))),
      throwsA(isA<SqliteException>()),
    );
  });

  test('category and product rows round-trip', () async {
    final categoryId = await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: 'Clothing', createdAt: 1),
        );
    await db.into(db.products).insert(ProductsCompanion.insert(
          categoryId: categoryId,
          name: 'T-Shirt',
          priceCents: 2000,
          discountPercent: 25,
          stock: 10,
          createdAt: 1,
          updatedAt: 1,
        ));

    final product = await db.select(db.products).getSingle();
    expect(product.name, 'T-Shirt');
    expect(product.priceCents, 2000);
    expect(product.discountPercent, 25);
    expect(product.stock, 10);
    expect(product.imagePath, isNull);
    expect(product.description, '');
  });

  test('CHECK constraints reject invalid product rows', () async {
    final categoryId = await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: 'C', createdAt: 1),
        );

    Future<void> insertProduct({
      required String name,
      required int priceCents,
      int discountPercent = 0,
      int stock = 1,
    }) {
      return db.into(db.products).insert(ProductsCompanion.insert(
            categoryId: categoryId,
            name: name,
            priceCents: priceCents,
            discountPercent: discountPercent,
            stock: stock,
            createdAt: 1,
            updatedAt: 1,
          ));
    }

    await expectLater(
      insertProduct(name: 'negative price', priceCents: -1),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      insertProduct(name: 'discount over 100', priceCents: 100, discountPercent: 101),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      insertProduct(name: 'negative stock', priceCents: 100, stock: -2),
      throwsA(isA<SqliteException>()),
    );
  });

  test('CHECK constraint rejects a zero-quantity cart row', () async {
    final categoryId = await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: 'C', createdAt: 1),
        );
    final productId = await db.into(db.products).insert(ProductsCompanion.insert(
          categoryId: categoryId,
          name: 'P',
          priceCents: 100,
          discountPercent: 0,
          stock: 1,
          createdAt: 1,
          updatedAt: 1,
        ));

    await expectLater(
      db.into(db.cartItems).insert(
        CartItemsCompanion.insert(
          productId: Value(productId),
          quantity: 0,
          addedAt: 1,
        ),
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('foreign keys are enforced: unknown category is rejected', () async {
    await expectLater(
      db.into(db.products).insert(ProductsCompanion.insert(
            categoryId: 999,
            name: 'Orphan',
            priceCents: 100,
            discountPercent: 0,
            stock: 1,
            createdAt: 1,
            updatedAt: 1,
          )),
      throwsA(isA<SqliteException>()),
    );
  });

  test('a category with products cannot be deleted (RESTRICT)', () async {
    final categoryId = await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: 'C', createdAt: 1),
        );
    await db.into(db.products).insert(ProductsCompanion.insert(
          categoryId: categoryId,
          name: 'P',
          priceCents: 100,
          discountPercent: 0,
          stock: 1,
          createdAt: 1,
          updatedAt: 1,
        ));

    await expectLater(
      (db.delete(db.categories)..where((t) => t.id.equals(categoryId))).go(),
      throwsA(isA<SqliteException>()),
    );
  });

  test('deleting a product cascades its cart rows away', () async {
    final categoryId = await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: 'C', createdAt: 1),
        );
    final productId = await db.into(db.products).insert(ProductsCompanion.insert(
          categoryId: categoryId,
          name: 'P',
          priceCents: 100,
          discountPercent: 0,
          stock: 1,
          createdAt: 1,
          updatedAt: 1,
        ));
    await db.into(db.cartItems).insert(
      CartItemsCompanion.insert(
        productId: Value(productId),
        quantity: 2,
        addedAt: 1,
      ),
    );
    expect(await db.select(db.cartItems).get(), hasLength(1));

    await (db.delete(db.products)..where((t) => t.id.equals(productId))).go();

    expect(await db.select(db.cartItems).get(), isEmpty);
  });

  test('deleting a product sets order item productId null but keeps snapshots', () async {
    final categoryId = await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: 'C', createdAt: 1),
        );
    final productId = await db.into(db.products).insert(ProductsCompanion.insert(
          categoryId: categoryId,
          name: 'T',
          priceCents: 2000,
          discountPercent: 25,
          stock: 3,
          createdAt: 1,
          updatedAt: 1,
        ));
    final orderId = await db.into(db.orders).insert(OrdersCompanion.insert(
          orderNumber: 'ORD-000001',
          status: OrderStatus.pending,
          subtotalCents: 1500,
          discountCents: 500,
          totalCents: 1000,
          shippingName: 'Ada',
          shippingPhone: '1',
          shippingAddress: 'X',
          createdAt: 1,
          updatedAt: 1,
        ));
    await db.into(db.orderItems).insert(OrderItemsCompanion.insert(
          orderId: orderId,
          productId: Value(productId),
          productName: 'T',
          unitPriceCents: 2000,
          quantity: 1,
        ));
    await db.into(db.orderStatusHistory).insert(
      OrderStatusHistoryCompanion.insert(
        orderId: orderId,
        status: OrderStatus.pending,
        changedAt: 1,
      ),
    );

    await (db.delete(db.products)..where((t) => t.id.equals(productId))).go();

    final item = await db.select(db.orderItems).getSingle();
    expect(item.productId, isNull);
    expect(item.productName, 'T'); // snapshot preserved after product deletion
    expect(item.unitPriceCents, 2000);
    expect(item.quantity, 1);
  });

  test('deleting an order cascades its items and status history', () async {
    final categoryId = await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: 'C', createdAt: 1),
        );
    await db.into(db.products).insert(ProductsCompanion.insert(
          categoryId: categoryId,
          name: 'T',
          priceCents: 1000,
          discountPercent: 0,
          stock: 3,
          createdAt: 1,
          updatedAt: 1,
        ));
    final orderId = await db.into(db.orders).insert(OrdersCompanion.insert(
          orderNumber: 'ORD-000001',
          status: OrderStatus.pending,
          subtotalCents: 1000,
          discountCents: 0,
          totalCents: 1000,
          shippingName: 'Ada',
          shippingPhone: '1',
          shippingAddress: 'X',
          createdAt: 1,
          updatedAt: 1,
        ));
    await db.into(db.orderItems).insert(OrderItemsCompanion.insert(
          orderId: orderId,
          productName: 'T',
          unitPriceCents: 1000,
          quantity: 1,
        ));
    await db.into(db.orderStatusHistory).insert(
      OrderStatusHistoryCompanion.insert(
        orderId: orderId,
        status: OrderStatus.pending,
        changedAt: 1,
      ),
    );

    await (db.delete(db.orders)..where((t) => t.id.equals(orderId))).go();

    expect(await db.select(db.orderItems).get(), isEmpty);
    expect(await db.select(db.orderStatusHistory).get(), isEmpty);
  });

  test('order status enum round-trips through intEnum', () async {
    await db.into(db.orders).insert(OrdersCompanion.insert(
          orderNumber: 'ORD-000001',
          status: OrderStatus.shipped,
          subtotalCents: 1000,
          discountCents: 0,
          totalCents: 1000,
          shippingName: 'Ada',
          shippingPhone: '123',
          shippingAddress: 'X',
          createdAt: 1,
          updatedAt: 1,
        ));

    final row = await db.select(db.orders).getSingle();
    expect(row.status, OrderStatus.shipped);
    expect(row.orderNumber, 'ORD-000001');
    expect(row.totalCents, 1000);
  });

  test('watch() re-emits when data changes', () async {
    final done = expectLater(
      db.select(db.categories).watch(),
      emitsInOrder([isEmpty, hasLength(1)]),
    );

    await pumpEventQueue();
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(name: 'Clothing', createdAt: 1),
        );

    await done;
  });
}
